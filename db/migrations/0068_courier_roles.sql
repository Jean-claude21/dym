-- 0068 — Rôles de la livraison (spec 068).
-- Constat sur l'émulateur : avec un livreur DYM assigné, la vendeuse voyait
-- « Partir livrer » et ni elle ni la cliente ne voyaient le livreur. La fiche
-- porte désormais le livreur ; la vendeuse ne peut plus faire partir ni
-- remettre une commande confiée à un livreur DYM (l'équipe garde le statut
-- forcé).

create or replace function app.order_has_dym_courier(p_order uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.order_couriers c where c.order_id = p_order and c.courier_id is not null)
$$;

create or replace function app.order_json(p_order uuid, p_role text) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id, 'purchase_id', o.purchase_id, 'status', o.status, 'fulfillment', o.fulfillment,
    'created_at', o.created_at, 'accepted_at', o.accepted_at, 'preparing_at', o.preparing_at,
    'ready_at', o.ready_at, 'out_for_delivery_at', o.out_for_delivery_at,
    'delivered_at', o.delivered_at, 'refused_at', o.refused_at, 'cancelled_at', o.cancelled_at,
    'status_reason', o.status_reason, 'status_note', o.status_note, 'cancelled_by', o.cancelled_by,
    'cash_collected_at', o.cash_collected_at, 'refund_due', o.refund_due,
    'eta_at', case when o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
                   then app.order_eta(o.id) end,
    'scheduled_start', o.scheduled_start, 'scheduled_end', o.scheduled_end,
    'currency_code', o.currency_code, 'subtotal_minor', o.subtotal_minor,
    'delivery_fee_minor', o.delivery_fee_minor, 'total_minor', o.total_minor,
    'payment_status', pu.payment_status,
    'payment_method', jsonb_build_object('id', pm.id, 'country_code', pm.country_code,
                                         'provider_code', pm.provider_code,
                                         'operator_code', pm.operator_code, 'label', pm.label),
    'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin, 'zone_name', z.name),
    'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
    'items', (select coalesce(jsonb_agg(jsonb_build_object(
                'product_id', i.product_id, 'variant_id', i.variant_id, 'name', i.product_name,
                'variant_label', i.variant_label, 'unit_label', i.unit_label,
                'unit_price_minor', i.unit_price_minor, 'quantity', i.quantity,
                'amount_minor', i.amount_minor) order by i.product_name), '[]'::jsonb)
              from public.order_items i where i.order_id = o.id),
    'history', (select coalesce(jsonb_agg(jsonb_build_object(
                  'to_status', e.to_status, 'actor_role', e.actor_role, 'occurred_at', e.occurred_at)
                  order by e.occurred_at, e.id), '[]'::jsonb)
                from public.order_status_events e where e.order_id = o.id),
    'next_statuses', case
      when p_role = 'vendor' and o.fulfillment = 'delivery' and app.order_has_dym_courier(o.id)
        then coalesce((select jsonb_agg(x) from jsonb_array_elements(
               app.order_next_statuses(p_role, o.fulfillment, o.status)) x
             where x #>> '{}' not in ('out_for_delivery', 'delivered')), '[]'::jsonb)
      else app.order_next_statuses(p_role, o.fulfillment, o.status) end,
    -- Livreur de la commande (spec 068) : nom et téléphone pour la vendeuse
    -- et la cliente ; `is_dym` : livreur de l'app (sinon livreur externe).
    'courier', (select jsonb_build_object('name', c.name, 'phone', c.phone,
                  'assigned_at', c.assigned_at, 'is_dym', c.courier_id is not null)
                from public.order_couriers c where c.order_id = o.id),
    'substitution_allowed', pu.substitution_allowed,
    'adjustments', app.order_adjustments_json(o.id))
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.payment_methods pm on pm.id = pu.payment_method_id
  join public.stores s on s.id = o.store_id
  join public.zones z on z.id = s.zone_id
  where o.id = p_order
$$;

create or replace function app.transition_order(
  p_user uuid,
  p_order uuid,
  p_to text,
  p_expected text,
  p_reason text default null,
  p_note text default null
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
  v_purchase public.purchases;
  v_owner uuid;
  v_store_name text;
  v_role text;
  v_country char(2);
  v_event text;
begin
  select * into v_order from public.orders where id = p_order for update;
  if v_order.id is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  select * into v_purchase from public.purchases where id = v_order.purchase_id;
  select owner_id, name into v_owner, v_store_name from public.stores where id = v_order.store_id;
  v_role := case
    when p_user = v_owner and v_purchase.payment_status in ('cash_on_delivery', 'paid') then 'vendor'
    when p_user = v_purchase.user_id then 'client'
    -- Livreur DYM de la commande (spec 041).
    when exists (select 1 from public.order_couriers oc where oc.order_id = p_order and oc.courier_id = p_user)
      then 'courier'
  end;
  if v_role is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  if p_expected is distinct from v_order.status then
    raise exception 'status_changed' using errcode = 'P0001';
  end if;
  if not app.order_transition_allowed(v_role, v_order.fulfillment, v_order.status, p_to) then
    raise exception 'transition_not_allowed' using errcode = 'P0001';
  end if;
  -- Livreur DYM assigné (spec 068) : la vendeuse ne remet pas elle-même.
  if v_role = 'vendor' and v_order.fulfillment = 'delivery' and p_to in ('out_for_delivery', 'delivered')
     and app.order_has_dym_courier(p_order) then
    raise exception 'courier_assigned' using errcode = 'P0001';
  end if;
  if p_to = 'refused'
     and (p_reason is null or p_reason not in ('out_of_stock', 'too_busy', 'area_not_served', 'other')) then
    raise exception 'reason_required' using errcode = 'P0001';
  end if;

  update public.orders set
    status = p_to,
    accepted_at = case when p_to = 'accepted' then now() else accepted_at end,
    preparing_at = case when p_to = 'preparing' then now() else preparing_at end,
    ready_at = case when p_to = 'ready' then now() else ready_at end,
    out_for_delivery_at = case when p_to = 'out_for_delivery' then now() else out_for_delivery_at end,
    delivered_at = case when p_to = 'delivered' then now() else delivered_at end,
    refused_at = case when p_to = 'refused' then now() else refused_at end,
    cancelled_at = case when p_to = 'cancelled' then now() else cancelled_at end,
    status_reason = case when p_to = 'refused' then p_reason else status_reason end,
    status_note = case when p_to in ('refused', 'cancelled') then left(nullif(trim(p_note), ''), 200)
                       else status_note end,
    cancelled_by = case when p_to = 'cancelled' then v_role else cancelled_by end,
    refund_due = refund_due or (p_to in ('refused', 'cancelled') and v_purchase.payment_status = 'paid')
  where id = p_order;

  insert into public.order_status_events (order_id, from_status, to_status, actor_role, actor_id, reason, note)
  values (p_order, v_order.status, p_to, v_role, p_user,
          case when p_to = 'refused' then p_reason end, left(nullif(trim(p_note), ''), 200));

  -- Refus ou annulation : le stock suivi est rendu.
  if p_to in ('refused', 'cancelled') then
    update public.product_variants v
    set stock_quantity = v.stock_quantity + i.quantity
    from public.order_items i
    where i.order_id = p_order and i.variant_id = v.id and v.stock_quantity is not null;
  end if;

  -- Notifications.
  if v_role in ('vendor', 'courier') then
    perform app.notify(v_purchase.user_id, 'order_' || p_to, 'orders', p_order, v_purchase.id,
      jsonb_build_object('store_name', v_store_name, 'fulfillment', v_order.fulfillment,
                         'reason', case when p_to = 'refused' then p_reason end,
                         'eta_at', case when p_to = 'accepted' then app.order_eta(p_order) end));
  end if;
  if v_role = 'courier' then
    -- La boutique suit sa commande confiée au livreur.
    perform app.notify(v_owner, 'courier_' || p_to, 'orders', p_order, v_purchase.id, '{}'::jsonb);
  elsif v_role = 'client' then
    perform app.notify(v_owner, 'order_cancelled_by_client', 'orders', p_order, v_purchase.id,
      jsonb_build_object('total_minor', v_order.total_minor, 'currency_code', v_order.currency_code));
  end if;

  -- Événements (sans donnée personnelle).
  v_country := v_purchase.country_code;
  perform app.emit_event('order_status_changed', p_user, v_role, 'server', v_country,
    'order', p_order::text,
    jsonb_build_object('from', v_order.status, 'to', p_to, 'fulfillment', v_order.fulfillment));
  v_event := case p_to
    when 'accepted' then 'order_accepted'
    when 'refused' then 'order_rejected'
    when 'delivered' then 'order_delivered'
    when 'cancelled' then 'order_cancelled'
  end;
  if v_event is not null then
    perform app.emit_event(v_event, p_user, v_role, 'server', v_country, 'order', p_order::text,
      jsonb_build_object('fulfillment', v_order.fulfillment, 'reason', p_reason,
                         'minutes_since_created',
                         round(extract(epoch from now() - v_order.created_at) / 60)::int));
  end if;

  return app.order_json(p_order, v_role);
end
$$;

revoke all on function app.order_has_dym_courier(uuid) from public;
