-- 0015 — Admin des opérations (spec 013 : A-AUTH-04, A-ORD-01..06/08, A-VEN-01..05/08/09,
-- A-LIV-04, A-LOG-01/02, A-FIN-03/04, A-CFG-01..06).
-- Toute lecture et toute action exigent le rôle admin. Les actions qui
-- préviennent quelqu'un ou appellent un fournisseur sont des fonctions `app.*`
-- appelées par la Function (admin explicite) ; les réglages et corrections sans
-- effet externe sont des fonctions `public.admin_*` (Data API). Chaque action
-- écrit dans `audit_log` et émet `admin_action_performed`.

-- ------------------------------------------------------------------ garde et trace

create or replace function app.require_admin() returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  if not app.is_admin() then
    raise exception 'rôle admin requis' using errcode = '42501';
  end if;
  return v_user;
end
$$;

create or replace function app.assert_admin(p_user uuid) returns void
language plpgsql stable security definer set search_path = ''
as $$
begin
  if p_user is null or not app.user_is_admin(p_user) then
    raise exception 'rôle admin requis' using errcode = '42501';
  end if;
end
$$;

-- Raison obligatoire d'une action (3 à 200 caractères).
create or replace function app.admin_reason(p_reason text) returns text
language plpgsql immutable
as $$
begin
  if p_reason is null or length(trim(p_reason)) < 3 then
    raise exception 'reason_required' using errcode = 'P0001';
  end if;
  return left(trim(p_reason), 200);
end
$$;

-- Audit et événement d'une action de l'équipe (sans donnée personnelle).
create or replace function app.admin_did(
  p_admin uuid,
  p_action text,
  p_entity_type text,
  p_entity_id text,
  p_before jsonb,
  p_after jsonb,
  p_reason text,
  p_country char(2) default null
) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  perform app.audit(p_admin, p_action, p_entity_type, p_entity_id, p_before, p_after, p_reason);
  perform app.emit_event('admin_action_performed', p_admin, 'admin', 'admin', p_country,
    p_entity_type, p_entity_id, jsonb_build_object('action', p_action, 'entity_type', p_entity_type));
end
$$;

-- Identifiant lisible : 8 premiers caractères en majuscules.
create or replace function app.short_ref(p_id uuid) returns text
language sql immutable
as $$
  select upper(left(p_id::text, 8))
$$;

-- Slug à partir d'un libellé (accents retirés).
create or replace function app.slugify(p_text text) returns text
language sql immutable
as $$
  select coalesce(nullif(trim(both '-' from regexp_replace(lower(translate(coalesce(p_text, ''),
    'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœÀÂÄÁÃÅÇÉÈÊËÍÌÎÏÑÓÒÔÖÕÚÙÛÜÝ',
    'aaaaaaceeeeiiiinooooouuuuyyoaaaaaaceeeeiiiinooooouuuuy')), '[^a-z0-9]+', '-', 'g')), ''), 'x')
$$;

insert into public.event_names (name, emitted_by, description) values
  ('refund_completed', 'server', 'Remboursement exécuté (méthode, montant, issue)');

-- ------------------------------------------------------------------ tables

-- Livreur externe assigné par l'équipe (pas d'app livreur en Phase 1).
create table public.order_couriers (
  order_id uuid primary key references public.orders (id) on delete cascade,
  name text not null check (length(trim(name)) between 2 and 60),
  phone text not null check (phone ~ '^\+?[0-9 ]{6,20}$'),
  assigned_by uuid references neon_auth."user" (id) on delete set null,
  assigned_at timestamptz not null default now()
);

alter table public.order_couriers enable row level security;
-- Lu et écrit par fonctions seulement.

-- Remboursement en cours d'exécution (un seul appel au fournisseur à la fois).
alter table public.refunds drop constraint refunds_status_check;
alter table public.refunds add constraint refunds_status_check
  check (status in ('pending', 'processing', 'succeeded', 'failed'));
alter table public.refunds add column claimed_at timestamptz;

-- ------------------------------------------------------------------ notifications

create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
                              'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor',
                              'order_status_forced', 'delivery_assigned', 'store_suspended',
                              'store_reactivated')
              then 'vendor' else 'client' end
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('order_cancelled', 'fr', 'Commande annulée', 'L''équipe DYM a annulé ta commande chez {store_name}.'),
  ('order_cancelled', 'en', 'Order cancelled', 'The DYM team cancelled your order at {store_name}.'),
  ('order_cancelled_vendor', 'fr', 'Commande annulée', 'L''équipe DYM a annulé une commande.'),
  ('order_cancelled_vendor', 'en', 'Order cancelled', 'The DYM team cancelled an order.'),
  ('order_status_forced', 'fr', 'Commande mise à jour', 'L''équipe DYM a mis à jour une de tes commandes.'),
  ('order_status_forced', 'en', 'Order updated', 'The DYM team updated one of your orders.'),
  ('delivery_assigned', 'fr', 'Livreur assigné', '{courier_name} ({courier_phone}) vient chercher la commande.'),
  ('delivery_assigned', 'en', 'Courier assigned', '{courier_name} ({courier_phone}) will pick up the order.'),
  ('store_suspended', 'fr', 'Boutique suspendue', 'L''équipe DYM a suspendu ta boutique : {reason}'),
  ('store_suspended', 'en', 'Shop suspended', 'The DYM team suspended your shop: {reason}'),
  ('store_reactivated', 'fr', 'Boutique réactivée', 'Ta boutique est réactivée : tu peux l''ouvrir.'),
  ('store_reactivated', 'en', 'Shop reactivated', 'Your shop is reactivated: you can open it.'),
  ('refund_succeeded', 'fr', 'Remboursement effectué', 'Ton remboursement pour {store_name} est effectué.'),
  ('refund_succeeded', 'en', 'Refund done', 'Your refund for {store_name} is done.');

-- ------------------------------------------------------------------ commandes

-- Statuts actifs et délai au-delà duquel une commande est « bloquée » (minutes).
create or replace function app.order_stale_minutes(p_status text) returns int
language sql immutable
as $$
  select case p_status
    when 'pending' then 15
    when 'accepted' then 60
    when 'preparing' then 60
    when 'ready' then 30
    when 'out_for_delivery' then 60
  end
$$;

-- Dernière étape franchie.
create or replace function app.order_last_change(p_order public.orders) returns timestamptz
language sql immutable
as $$
  select greatest(p_order.created_at, p_order.accepted_at, p_order.preparing_at, p_order.ready_at,
                  p_order.out_for_delivery_at)
$$;

create or replace function app.order_stuck(p_order public.orders, p_payment_status text) returns boolean
language sql stable
as $$
  select app.order_stale_minutes(p_order.status) is not null
     and p_payment_status in ('cash_on_delivery', 'paid')
     and app.order_last_change(p_order) < now() - make_interval(mins => app.order_stale_minutes(p_order.status))
$$;

-- Statuts que l'équipe peut forcer depuis [p_from] (vers l'avant ou l'arrière,
-- jamais depuis un statut final).
create or replace function app.admin_forceable(p_fulfillment text, p_from text) returns jsonb
language sql immutable
as $$
  select case when app.order_stale_minutes(p_from) is null then '[]'::jsonb else (
    select coalesce(jsonb_agg(s order by o), '[]'::jsonb)
    from unnest(array['pending', 'accepted', 'preparing', 'ready', 'out_for_delivery', 'delivered'])
      with ordinality as t(s, o)
    where s <> p_from and (s <> 'out_for_delivery' or p_fulfillment = 'delivery'))
  end
$$;

-- Ligne de liste d'une commande.
create or replace function app.admin_order_row(p_order uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id, 'reference', app.short_ref(o.id), 'status', o.status, 'fulfillment', o.fulfillment,
    'payment_status', pu.payment_status, 'store_id', s.id, 'store_name', s.name,
    'customer_first_name', pr.first_name, 'total_minor', o.total_minor,
    'currency_code', o.currency_code, 'created_at', o.created_at,
    'last_change_at', app.order_last_change(o), 'stuck', app.order_stuck(o, pu.payment_status),
    'refund_due', o.refund_due,
    'has_open_dispute', exists (select 1 from public.disputes d where d.order_id = o.id and d.status = 'open'))
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.stores s on s.id = o.store_id
  left join public.profiles pr on pr.user_id = pu.user_id
  where o.id = p_order
$$;

-- Liste des commandes (A-ORD-01/06) : filtre, recherche (référence de
-- commande ou de paiement, prénom de la cliente, boutique), pagination.
create or replace function public.admin_orders(
  p_filter text default 'all',
  p_query text default null,
  p_limit int default 50,
  p_offset int default 0
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_q text := nullif(trim(p_query), '');
  v_like text;
begin
  perform app.require_admin();
  if p_filter is null or p_filter not in ('all', 'pending', 'active', 'stuck', 'delivered', 'closed') then
    raise exception 'filtre inconnu' using errcode = '22023';
  end if;
  v_like := '%' || replace(replace(replace(coalesce(v_q, ''), '\', '\\'), '%', '\%'), '_', '\_') || '%';
  return (
    with hits as (
      select o.id, o.status, o.created_at, app.order_last_change(o) as last_change,
             app.order_stuck(o, pu.payment_status) as stuck
      from public.orders o
      join public.purchases pu on pu.id = o.purchase_id
      join public.stores s on s.id = o.store_id
      left join public.profiles pr on pr.user_id = pu.user_id
      where v_q is null
         or app.short_ref(o.id) like upper(v_q) || '%'
         or s.name ilike v_like
         or pr.first_name ilike v_like
         or exists (select 1 from public.payments p
                    where p.purchase_id = pu.id and app.payment_reference(p.id) = upper(v_q))
    ), filtered as (
      select * from hits
      where case p_filter
        when 'all' then true
        when 'pending' then status = 'pending'
        when 'active' then status in ('accepted', 'preparing', 'ready', 'out_for_delivery')
        when 'stuck' then stuck
        when 'delivered' then status = 'delivered'
        when 'closed' then status in ('refused', 'cancelled')
      end
    ), page as (
      select id, row_number() over (
               order by case when p_filter = 'stuck' then last_change end asc nulls last, created_at desc) as n
      from filtered
      order by n
      limit least(greatest(coalesce(p_limit, 50), 1), 200) offset greatest(coalesce(p_offset, 0), 0)
    )
    select jsonb_build_object(
      'total', (select count(*) from filtered),
      'stuck_count', (select count(*) from hits where stuck),
      'orders', (select coalesce(jsonb_agg(app.admin_order_row(id) order by n), '[]'::jsonb) from page)));
end
$$;

-- Détail complet d'une commande (A-ORD-02/05) : la commande, la cliente et
-- l'adresse, la chronologie, les paiements, les remboursements, le litige, le
-- livreur, les actions de l'équipe et les statuts forçables.
create or replace function app.admin_order_json(p_order uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select app.order_json(o.id, 'admin') || app.admin_order_row(o.id) || jsonb_build_object(
    'customer', jsonb_build_object('first_name', pr.first_name, 'phone', pu.address ->> 'phone'),
    'address', pu.address,
    'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin, 'status', s.status,
                                'owner_first_name', (select first_name from public.profiles
                                                     where user_id = s.owner_id)),
    'commission_minor', o.commission_minor,
    'timeline', (select coalesce(jsonb_agg(jsonb_build_object(
                   'from_status', e.from_status, 'to_status', e.to_status, 'actor_role', e.actor_role,
                   'reason', e.reason, 'note', e.note, 'occurred_at', e.occurred_at)
                   order by e.occurred_at, e.id), '[]'::jsonb)
                 from public.order_status_events e where e.order_id = o.id),
    'payments', (select coalesce(jsonb_agg(jsonb_build_object(
                   'id', p.id, 'reference', app.payment_reference(p.id), 'provider_code', p.provider_code,
                   'status', p.status, 'amount_minor', p.amount_minor, 'currency_code', p.currency_code,
                   'last_error', p.last_error, 'created_at', p.created_at, 'completed_at', p.completed_at)
                   order by p.created_at), '[]'::jsonb)
                 from public.payments p where p.purchase_id = pu.id),
    'refunds', (select coalesce(jsonb_agg(jsonb_build_object(
                  'id', r.id, 'dispute_id', r.dispute_id, 'amount_minor', r.amount_minor,
                  'method', r.method, 'status', r.status, 'last_error', r.last_error,
                  'created_at', r.created_at, 'completed_at', r.completed_at) order by r.created_at), '[]'::jsonb)
                from public.refunds r where r.order_id = o.id),
    'dispute', (select jsonb_build_object('id', d.id, 'status', d.status, 'reason', d.reason,
                                          'resolution', d.resolution, 'created_at', d.created_at)
                from public.disputes d where d.order_id = o.id order by d.created_at desc limit 1),
    'courier', (select jsonb_build_object('name', c.name, 'phone', c.phone, 'assigned_at', c.assigned_at)
                from public.order_couriers c where c.order_id = o.id),
    'audit', (select coalesce(jsonb_agg(jsonb_build_object(
                'action', a.action, 'reason', a.reason, 'occurred_at', a.occurred_at,
                'actor_first_name', (select first_name from public.profiles where user_id = a.actor_id))
                order by a.occurred_at, a.id), '[]'::jsonb)
              from public.audit_log a where a.entity_type = 'order' and a.entity_id = o.id::text),
    'forceable_statuses', app.admin_forceable(o.fulfillment, o.status),
    'can_cancel', o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery'),
    'can_assign_courier', o.fulfillment = 'delivery'
                          and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery'))
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.stores s on s.id = o.store_id
  left join public.profiles pr on pr.user_id = pu.user_id
  where o.id = p_order
$$;

create or replace function public.admin_order(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v jsonb;
begin
  perform app.require_admin();
  v := app.admin_order_json(p_id);
  if v is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  return v;
end
$$;

-- Forcer un statut (A-ORD-03). Refus (P0001) : status_changed, order_closed,
-- payment_pending, transition_not_allowed, reason_required.
create or replace function app.admin_force_status(
  p_admin uuid,
  p_order uuid,
  p_to text,
  p_expected text,
  p_reason text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
  v_purchase public.purchases;
  v_owner uuid;
  v_store_name text;
  v_reason text;
  v_event text;
begin
  perform app.assert_admin(p_admin);
  select * into v_order from public.orders where id = p_order for update;
  if v_order.id is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  if p_expected is distinct from v_order.status then
    raise exception 'status_changed' using errcode = 'P0001';
  end if;
  if app.order_stale_minutes(v_order.status) is null then
    raise exception 'order_closed' using errcode = 'P0001';
  end if;
  select * into v_purchase from public.purchases where id = v_order.purchase_id;
  if v_purchase.payment_status not in ('cash_on_delivery', 'paid') then
    raise exception 'payment_pending' using errcode = 'P0001';
  end if;
  if not app.admin_forceable(v_order.fulfillment, v_order.status) ? coalesce(p_to, '') then
    raise exception 'transition_not_allowed' using errcode = 'P0001';
  end if;
  v_reason := app.admin_reason(p_reason);
  select owner_id, name into v_owner, v_store_name from public.stores where id = v_order.store_id;

  update public.orders set
    status = p_to,
    accepted_at = case when p_to = 'accepted' then now() else accepted_at end,
    preparing_at = case when p_to = 'preparing' then now() else preparing_at end,
    ready_at = case when p_to = 'ready' then now() else ready_at end,
    out_for_delivery_at = case when p_to = 'out_for_delivery' then now() else out_for_delivery_at end,
    delivered_at = case when p_to = 'delivered' then now() else delivered_at end
  where id = p_order;
  insert into public.order_status_events (order_id, from_status, to_status, actor_role, actor_id, note)
  values (p_order, v_order.status, p_to, 'admin', p_admin, v_reason);

  if p_to <> 'pending' then
    perform app.notify(v_purchase.user_id, 'order_' || p_to, 'orders', p_order, v_purchase.id,
      jsonb_build_object('store_name', v_store_name, 'fulfillment', v_order.fulfillment,
                         'eta_at', case when p_to = 'accepted' then app.order_eta(p_order) end));
  end if;
  perform app.notify(v_owner, 'order_status_forced', 'orders', p_order, v_purchase.id,
    jsonb_build_object('status', p_to));

  perform app.emit_event('order_status_changed', p_admin, 'admin', 'server', v_purchase.country_code,
    'order', p_order::text,
    jsonb_build_object('from', v_order.status, 'to', p_to, 'fulfillment', v_order.fulfillment));
  v_event := case p_to when 'accepted' then 'order_accepted' when 'delivered' then 'order_delivered' end;
  if v_event is not null then
    perform app.emit_event(v_event, p_admin, 'admin', 'server', v_purchase.country_code, 'order',
      p_order::text, jsonb_build_object('fulfillment', v_order.fulfillment,
        'minutes_since_created', round(extract(epoch from now() - v_order.created_at) / 60)::int));
  end if;
  perform app.admin_did(p_admin, 'order_status_forced', 'order', p_order::text,
    jsonb_build_object('status', v_order.status), jsonb_build_object('status', p_to), v_reason,
    v_purchase.country_code);
  return app.admin_order_json(p_order);
end
$$;

-- Annuler une commande (A-ORD-04) : stock rendu, remboursement du total si
-- l'achat est payé en ligne. Refus (P0001) : status_changed, order_closed,
-- reason_required.
create or replace function app.admin_cancel_order(
  p_admin uuid,
  p_order uuid,
  p_expected text,
  p_reason text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
  v_purchase public.purchases;
  v_owner uuid;
  v_store_name text;
  v_reason text;
  v_refund boolean;
begin
  perform app.assert_admin(p_admin);
  select * into v_order from public.orders where id = p_order for update;
  if v_order.id is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  if p_expected is distinct from v_order.status then
    raise exception 'status_changed' using errcode = 'P0001';
  end if;
  if app.order_stale_minutes(v_order.status) is null then
    raise exception 'order_closed' using errcode = 'P0001';
  end if;
  v_reason := app.admin_reason(p_reason);
  select * into v_purchase from public.purchases where id = v_order.purchase_id;
  select owner_id, name into v_owner, v_store_name from public.stores where id = v_order.store_id;
  v_refund := v_purchase.payment_status = 'paid';

  update public.orders set
    status = 'cancelled', cancelled_at = now(), cancelled_by = 'admin', status_note = v_reason,
    refund_due = refund_due or v_refund
  where id = p_order;
  insert into public.order_status_events (order_id, from_status, to_status, actor_role, actor_id, note)
  values (p_order, v_order.status, 'cancelled', 'admin', p_admin, v_reason);
  update public.product_variants v
  set stock_quantity = v.stock_quantity + i.quantity
  from public.order_items i
  where i.order_id = p_order and i.variant_id = v.id and v.stock_quantity is not null;
  if v_refund then
    insert into public.refunds (order_id, amount_minor, currency_code, method, requested_by)
    values (p_order, v_order.total_minor, v_order.currency_code, 'provider', p_admin);
  end if;

  perform app.notify(v_purchase.user_id, 'order_cancelled', 'orders', p_order, v_purchase.id,
    jsonb_build_object('store_name', v_store_name, 'refund', v_refund));
  if v_purchase.payment_status in ('cash_on_delivery', 'paid') then
    perform app.notify(v_owner, 'order_cancelled_vendor', 'orders', p_order, v_purchase.id,
      jsonb_build_object('total_minor', v_order.total_minor, 'currency_code', v_order.currency_code));
  end if;
  perform app.emit_event('order_status_changed', p_admin, 'admin', 'server', v_purchase.country_code,
    'order', p_order::text,
    jsonb_build_object('from', v_order.status, 'to', 'cancelled', 'fulfillment', v_order.fulfillment));
  perform app.emit_event('order_cancelled', p_admin, 'admin', 'server', v_purchase.country_code,
    'order', p_order::text, jsonb_build_object('fulfillment', v_order.fulfillment,
      'minutes_since_created', round(extract(epoch from now() - v_order.created_at) / 60)::int));
  perform app.admin_did(p_admin, 'order_cancelled', 'order', p_order::text,
    jsonb_build_object('status', v_order.status),
    jsonb_build_object('status', 'cancelled', 'refund_minor', case when v_refund then v_order.total_minor end),
    v_reason, v_purchase.country_code);
  return app.admin_order_json(p_order);
end
$$;

-- Livreur externe (A-ORD-08, A-LIV-04). Refus (P0001) : courier_not_allowed.
create or replace function app.admin_assign_courier(
  p_admin uuid,
  p_order uuid,
  p_name text,
  p_phone text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
  v_before jsonb;
  v_owner uuid;
  v_country char(2);
begin
  perform app.assert_admin(p_admin);
  select * into v_order from public.orders where id = p_order for update;
  if v_order.id is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  if v_order.fulfillment <> 'delivery'
     or v_order.status not in ('accepted', 'preparing', 'ready', 'out_for_delivery') then
    raise exception 'courier_not_allowed' using errcode = 'P0001';
  end if;
  select jsonb_build_object('name', name, 'phone', phone) into v_before
  from public.order_couriers where order_id = p_order;
  insert into public.order_couriers (order_id, name, phone, assigned_by)
  values (p_order, trim(p_name), trim(p_phone), p_admin)
  on conflict (order_id) do update
    set name = excluded.name, phone = excluded.phone, assigned_by = excluded.assigned_by,
        assigned_at = now();
  select owner_id into v_owner from public.stores where id = v_order.store_id;
  select country_code into v_country from public.purchases where id = v_order.purchase_id;
  perform app.notify(v_owner, 'delivery_assigned', 'orders', p_order, v_order.purchase_id,
    jsonb_build_object('courier_name', trim(p_name), 'courier_phone', trim(p_phone)));
  perform app.admin_did(p_admin, 'courier_assigned', 'order', p_order::text, v_before,
    jsonb_build_object('name', trim(p_name), 'phone', trim(p_phone)), null, v_country);
  return app.admin_order_json(p_order);
end
$$;

-- ------------------------------------------------------------------ remboursements et paiements

create or replace function app.admin_refund_json(p_refund uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', r.id, 'order_id', r.order_id, 'order_reference', app.short_ref(r.order_id),
    'dispute_id', r.dispute_id, 'reason', case when r.dispute_id is null then 'cancellation' else 'dispute' end,
    'method', r.method,
    'provider_code', (select p.provider_code from public.payments p
                      where p.purchase_id = o.purchase_id and p.status = 'succeeded'),
    'amount_minor', r.amount_minor, 'currency_code', r.currency_code, 'status', r.status,
    'last_error', r.last_error, 'store_name', s.name,
    'created_at', r.created_at, 'completed_at', r.completed_at)
  from public.refunds r
  join public.orders o on o.id = r.order_id
  join public.stores s on s.id = o.store_id
  where r.id = p_refund
$$;

-- Remboursements (A-FIN-04) : à exécuter (`pending`, en cours compris),
-- effectués ou échoués.
create or replace function public.admin_refunds(p_status text default 'pending', p_limit int default 100)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  if p_status is null or p_status not in ('pending', 'succeeded', 'failed') then
    raise exception 'statut inconnu' using errcode = '22023';
  end if;
  return (
    select coalesce(jsonb_agg(app.admin_refund_json(r.id) order by r.created_at), '[]'::jsonb)
    from (select id, created_at from public.refunds
          where status = p_status or (p_status = 'pending' and status = 'processing')
          order by created_at
          limit least(greatest(coalesce(p_limit, 100), 1), 500)) r);
end
$$;

-- Paiements en attente (A-FIN-03), les plus anciens d'abord.
create or replace function public.admin_pending_payments(p_limit int default 100) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', p.id, 'reference', app.payment_reference(p.id), 'purchase_id', p.purchase_id,
      'provider_code', p.provider_code, 'amount_minor', p.amount_minor,
      'currency_code', p.currency_code, 'created_at', p.created_at,
      'orders', (select coalesce(jsonb_agg(jsonb_build_object(
                   'id', o.id, 'reference', app.short_ref(o.id), 'store_name', s.name)
                   order by s.name), '[]'::jsonb)
                 from public.orders o join public.stores s on s.id = o.store_id
                 where o.purchase_id = p.purchase_id))
      order by p.created_at), '[]'::jsonb)
    from (select * from public.payments where status = 'pending'
          order by created_at limit least(greatest(coalesce(p_limit, 100), 1), 500)) p);
end
$$;

-- Réserve un remboursement pour l'appel au fournisseur (A-LIT-04). Refus
-- (P0001) : refund_not_pending, refund_not_provider, payment_not_found.
create or replace function app.refund_claim(p_admin uuid, p_refund uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_refund public.refunds;
  v_payment public.payments;
begin
  perform app.assert_admin(p_admin);
  select * into v_refund from public.refunds where id = p_refund for update;
  if v_refund.id is null then
    raise exception 'remboursement introuvable' using errcode = 'P0002';
  end if;
  if v_refund.method <> 'provider' then
    raise exception 'refund_not_provider' using errcode = 'P0001';
  end if;
  if not (v_refund.status in ('pending', 'failed')
          or (v_refund.status = 'processing' and v_refund.claimed_at < now() - interval '10 minutes')) then
    raise exception 'refund_not_pending' using errcode = 'P0001';
  end if;
  select p.* into v_payment from public.payments p
  join public.orders o on o.purchase_id = p.purchase_id
  where o.id = v_refund.order_id and p.status = 'succeeded';
  if v_payment.id is null then
    raise exception 'payment_not_found' using errcode = 'P0001';
  end if;
  update public.refunds set status = 'processing', claimed_at = now(), last_error = null
  where id = p_refund;
  return jsonb_build_object(
    'refund_id', v_refund.id, 'amount_minor', v_refund.amount_minor,
    'currency_code', v_refund.currency_code, 'payment_id', v_payment.id,
    'provider_code', v_payment.provider_code, 'provider_reference', v_payment.provider_reference);
end
$$;

-- Fin d'un remboursement (commun au fournisseur et au cash).
create or replace function app.refund_finish(
  p_admin uuid,
  p_refund uuid,
  p_ok boolean,
  p_provider_reference text,
  p_error text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_refund public.refunds;
  v_order public.orders;
  v_purchase public.purchases;
begin
  select * into v_refund from public.refunds where id = p_refund;
  select * into v_order from public.orders where id = v_refund.order_id;
  select * into v_purchase from public.purchases where id = v_order.purchase_id;
  update public.refunds set
    status = case when p_ok then 'succeeded' else 'failed' end,
    provider_reference = coalesce(left(p_provider_reference, 200), provider_reference),
    last_error = case when p_ok then null else left(coalesce(p_error, 'refus'), 500) end,
    completed_at = case when p_ok then now() end
  where id = p_refund;
  if p_ok then
    update public.orders set refund_due = exists (
      select 1 from public.refunds where order_id = v_order.id and status <> 'succeeded')
    where id = v_order.id;
    perform app.notify(v_purchase.user_id, 'refund_succeeded', 'payments', v_order.id, v_purchase.id,
      jsonb_build_object('store_name', (select name from public.stores where id = v_order.store_id),
                         'amount_minor', v_refund.amount_minor, 'currency_code', v_refund.currency_code));
  end if;
  perform app.emit_event('refund_completed', p_admin, 'admin', 'server', v_purchase.country_code,
    'refund', p_refund::text,
    jsonb_build_object('method', v_refund.method, 'amount_minor', v_refund.amount_minor,
                       'currency_code', v_refund.currency_code,
                       'outcome', case when p_ok then 'succeeded' else 'failed' end));
  perform app.admin_did(p_admin, case when p_ok then 'refund_succeeded' else 'refund_failed' end,
    'refund', p_refund::text, jsonb_build_object('status', v_refund.status),
    jsonb_build_object('status', case when p_ok then 'succeeded' else 'failed' end,
                       'amount_minor', v_refund.amount_minor, 'method', v_refund.method),
    case when p_ok then null else left(p_error, 200) end, v_purchase.country_code);
  return app.admin_refund_json(p_refund);
end
$$;

-- Résultat de l'appel au fournisseur. Refus (P0001) : refund_not_processing.
create or replace function app.refund_result(
  p_admin uuid,
  p_refund uuid,
  p_ok boolean,
  p_provider_reference text,
  p_error text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_status text;
begin
  perform app.assert_admin(p_admin);
  select status into v_status from public.refunds where id = p_refund for update;
  if v_status is distinct from 'processing' then
    raise exception 'refund_not_processing' using errcode = 'P0001';
  end if;
  return app.refund_finish(p_admin, p_refund, p_ok, p_provider_reference, p_error);
end
$$;

-- Remboursement cash remis en main propre. Refus (P0001) : refund_not_cash,
-- refund_not_pending.
create or replace function app.refund_mark_cash(p_admin uuid, p_refund uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_refund public.refunds;
begin
  perform app.assert_admin(p_admin);
  select * into v_refund from public.refunds where id = p_refund for update;
  if v_refund.id is null then
    raise exception 'remboursement introuvable' using errcode = 'P0002';
  end if;
  if v_refund.method <> 'cash' then
    raise exception 'refund_not_cash' using errcode = 'P0001';
  end if;
  if v_refund.status not in ('pending', 'failed') then
    raise exception 'refund_not_pending' using errcode = 'P0001';
  end if;
  return app.refund_finish(p_admin, p_refund, true, null, null);
end
$$;

-- ------------------------------------------------------------------ boutiques

create or replace function app.admin_store_row(p_store uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', s.id, 'name', s.name, 'status', s.status, 'is_open', s.is_open, 'origin', s.origin,
    'origin_label', (select o.label from public.store_origins o where o.code = s.origin),
    'owner_first_name', pr.first_name, 'zone_name', z.name, 'city_name', c.name,
    'country_code', s.country_code, 'created_at', s.created_at, 'published_at', s.published_at)
  from public.stores s
  left join public.profiles pr on pr.user_id = s.owner_id
  left join public.zones z on z.id = s.zone_id
  left join public.cities c on c.id = z.city_id
  where s.id = p_store
$$;

-- Liste des boutiques (A-VEN-01) : par statut, recherche (boutique ou vendeuse).
create or replace function public.admin_stores(
  p_status text default 'active',
  p_query text default null,
  p_limit int default 50,
  p_offset int default 0
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_q text := nullif(trim(p_query), '');
  v_like text;
begin
  perform app.require_admin();
  if p_status is null or p_status not in ('active', 'draft', 'suspended') then
    raise exception 'statut inconnu' using errcode = '22023';
  end if;
  v_like := '%' || replace(replace(replace(coalesce(v_q, ''), '\', '\\'), '%', '\%'), '_', '\_') || '%';
  return jsonb_build_object(
    'counts', (select jsonb_build_object(
                 'active', count(*) filter (where status = 'active'),
                 'draft', count(*) filter (where status = 'draft'),
                 'suspended', count(*) filter (where status = 'suspended'))
               from public.stores),
    'stores', (select coalesce(jsonb_agg(app.admin_store_row(x.id) order by x.name), '[]'::jsonb)
               from (select s.id, s.name from public.stores s
                     left join public.profiles pr on pr.user_id = s.owner_id
                     where s.status = p_status
                       and (v_q is null or s.name ilike v_like or pr.first_name ilike v_like)
                     order by s.name
                     limit least(greatest(coalesce(p_limit, 50), 1), 200)
                     offset greatest(coalesce(p_offset, 0), 0)) x));
end
$$;

-- Profil d'une boutique (A-VEN-02/09) : indicateurs des 7 derniers jours,
-- historique des actions de l'équipe.
create or replace function app.admin_store_json(p_store uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select app.admin_store_row(s.id) || jsonb_build_object(
    'description', s.description, 'zone_id', s.zone_id, 'currency_code', s.currency_code,
    'prep_time_minutes', s.prep_time_minutes, 'offers_pickup', s.offers_pickup,
    'orders_7d', (select count(*) from public.orders o join public.purchases pu on pu.id = o.purchase_id
                  where o.store_id = s.id and o.created_at > now() - interval '7 days'
                    and pu.payment_status in ('cash_on_delivery', 'paid')),
    'sales_7d_minor', (select coalesce(sum(o.total_minor), 0) from public.orders o
                       where o.store_id = s.id and o.status = 'delivered'
                         and o.delivered_at > now() - interval '7 days'),
    'published_products', (select count(*) from public.products p
                           where p.store_id = s.id and p.status = 'published'),
    'open_disputes', (select count(*) from public.disputes d join public.orders o on o.id = d.order_id
                      where o.store_id = s.id and d.status = 'open'),
    'audit', (select coalesce(jsonb_agg(jsonb_build_object(
                'action', a.action, 'reason', a.reason, 'occurred_at', a.occurred_at,
                'before', a.before, 'after', a.after,
                'actor_first_name', (select first_name from public.profiles where user_id = a.actor_id))
                order by a.occurred_at desc, a.id desc), '[]'::jsonb)
              from (select * from public.audit_log
                    where entity_type = 'store' and entity_id = s.id::text
                    order by occurred_at desc limit 50) a))
  from public.stores s
  where s.id = p_store
$$;

create or replace function public.admin_store(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v jsonb;
begin
  perform app.require_admin();
  v := app.admin_store_json(p_id);
  if v is null then
    raise exception 'boutique introuvable' using errcode = 'P0002';
  end if;
  return v;
end
$$;

-- Suspendre ou réactiver (A-VEN-03/04/05). Refus (P0001) : reason_required,
-- store_status_unchanged.
create or replace function app.admin_set_store_status(
  p_admin uuid,
  p_store uuid,
  p_status text,
  p_reason text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store public.stores;
  v_to text;
  v_reason text;
begin
  perform app.assert_admin(p_admin);
  if p_status is null or p_status not in ('active', 'suspended') then
    raise exception 'statut inconnu' using errcode = '22023';
  end if;
  select * into v_store from public.stores where id = p_store for update;
  if v_store.id is null then
    raise exception 'boutique introuvable' using errcode = 'P0002';
  end if;
  v_reason := app.admin_reason(p_reason);
  if (p_status = 'suspended' and v_store.status = 'suspended')
     or (p_status = 'active' and v_store.status <> 'suspended') then
    raise exception 'store_status_unchanged' using errcode = 'P0001';
  end if;
  -- Réactivée : redevient active si elle avait été publiée, brouillon sinon.
  v_to := case when p_status = 'active' and v_store.published_at is null then 'draft' else p_status end;
  update public.stores set status = v_to, is_open = false where id = p_store;
  perform app.notify(v_store.owner_id, case when p_status = 'suspended' then 'store_suspended'
                                            else 'store_reactivated' end,
    'orders', null, null,
    case when p_status = 'suspended' then jsonb_build_object('reason', v_reason) else '{}'::jsonb end);
  if v_store.is_open then
    perform app.emit_event('store_closed', p_admin, 'admin', 'server', v_store.country_code,
      'store', p_store::text, jsonb_build_object('store_origin', v_store.origin));
  end if;
  perform app.admin_did(p_admin, case when p_status = 'suspended' then 'store_suspended'
                                      else 'store_reactivated' end,
    'store', p_store::text, jsonb_build_object('status', v_store.status, 'is_open', v_store.is_open),
    jsonb_build_object('status', v_to, 'is_open', false), v_reason, v_store.country_code);
  return app.admin_store_json(p_store);
end
$$;

-- Corriger les données d'une boutique (A-VEN-08) : nom, description,
-- quartier (du pays de la boutique), temps de préparation, retrait.
create or replace function public.admin_update_store(p_id uuid, p_patch jsonb, p_reason text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_store public.stores;
  v_after public.stores;
  v_reason text := app.admin_reason(p_reason);
  v_before jsonb;
  v_changed jsonb;
begin
  select * into v_store from public.stores where id = p_id for update;
  if v_store.id is null then
    raise exception 'boutique introuvable' using errcode = 'P0002';
  end if;
  if p_patch ? 'zone_id' and not exists (
    select 1 from public.zones z join public.cities c on c.id = z.city_id
    where z.id = (p_patch ->> 'zone_id')::uuid and c.country_code = v_store.country_code and z.is_active) then
    raise exception 'quartier hors du pays de la boutique' using errcode = '22023';
  end if;
  update public.stores set
    name = case when p_patch ? 'name' then trim(p_patch ->> 'name') else name end,
    description = case when p_patch ? 'description' then nullif(trim(p_patch ->> 'description'), '')
                       else description end,
    zone_id = case when p_patch ? 'zone_id' then (p_patch ->> 'zone_id')::uuid else zone_id end,
    prep_time_minutes = case when p_patch ? 'prep_time_minutes'
                             then (p_patch ->> 'prep_time_minutes')::smallint else prep_time_minutes end,
    offers_pickup = case when p_patch ? 'offers_pickup'
                         then (p_patch ->> 'offers_pickup')::boolean else offers_pickup end
  where id = p_id
  returning * into v_after;
  select jsonb_object_agg(k, to_jsonb(v_store) -> k), jsonb_object_agg(k, to_jsonb(v_after) -> k)
  into v_before, v_changed
  from unnest(array['name', 'description', 'zone_id', 'prep_time_minutes', 'offers_pickup']) k
  where to_jsonb(v_store) -> k is distinct from to_jsonb(v_after) -> k;
  if v_changed is not null then
    perform app.admin_did(v_admin, 'store_updated', 'store', p_id::text, v_before, v_changed, v_reason,
      v_store.country_code);
  end if;
  return app.admin_store_json(p_id);
end
$$;

-- ------------------------------------------------------------------ réglages

-- Ce qui manque à un pays pour être activé.
create or replace function app.country_missing(p_country char(2)) returns text[]
language sql stable security definer set search_path = ''
as $$
  select array_remove(array[
    case when not exists (select 1 from public.zones z join public.cities c on c.id = z.city_id
                          where c.country_code = p_country and c.is_active and z.is_active)
         then 'zones' end,
    case when not exists (select 1 from public.payment_methods pm
                          join public.payment_providers pp on pp.code = pm.provider_code
                          where pm.country_code = p_country and pm.is_active and pp.is_active)
         then 'payment_methods' end,
    case when not exists (select 1 from public.delivery_fee_defaults f
                          where f.country_code = p_country and f.valid_to is null)
         then 'delivery_fees' end], null)
$$;

create or replace function public.admin_countries() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'code', c.code, 'name', c.name, 'currency_code', c.currency_code, 'dial_code', c.dial_code,
      'timezone', c.timezone, 'is_active', c.is_active, 'missing', to_jsonb(app.country_missing(c.code)))
      order by c.sort, c.code), '[]'::jsonb)
    from public.countries c);
end
$$;

-- Activer un pays prêt (A-CFG-01). Refus (P0001) : country_not_ready.
create or replace function public.admin_set_country_active(p_code char(2), p_active boolean)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_before boolean;
begin
  select is_active into v_before from public.countries where code = p_code for update;
  if v_before is null then
    raise exception 'pays introuvable' using errcode = 'P0002';
  end if;
  if p_active and cardinality(app.country_missing(p_code)) > 0 then
    raise exception 'country_not_ready' using errcode = 'P0001';
  end if;
  if v_before is distinct from p_active then
    update public.countries set is_active = p_active where code = p_code;
    perform app.admin_did(v_admin, case when p_active then 'country_activated' else 'country_deactivated' end,
      'country', p_code, jsonb_build_object('is_active', v_before), jsonb_build_object('is_active', p_active),
      null, p_code);
  end if;
  return public.admin_countries();
end
$$;

-- Villes et quartiers d'un pays (saisis par l'équipe).
create or replace function public.admin_geography(p_country char(2)) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', c.id, 'name', c.name, 'is_active', c.is_active, 'delivery_minutes', c.delivery_minutes,
      'zones', (select coalesce(jsonb_agg(jsonb_build_object(
                  'id', z.id, 'name', z.name, 'is_active', z.is_active,
                  'latitude', z.latitude, 'longitude', z.longitude,
                  'store_count', (select count(*) from public.stores s where s.zone_id = z.id))
                  order by z.sort, z.name), '[]'::jsonb)
                from public.zones z where z.city_id = c.id))
      order by c.sort, c.name), '[]'::jsonb)
    from public.cities c where c.country_code = p_country);
end
$$;

-- Slug libre dans un ensemble (suffixe numérique si pris).
create or replace function app.free_slug(p_base text, p_taken text[]) returns text
language sql immutable
as $$
  select case when not (p_base = any (coalesce(p_taken, '{}'))) then p_base else (
    select p_base || '-' || n from generate_series(2, 1000) n
    where not ((p_base || '-' || n) = any (p_taken)) limit 1) end
$$;

-- Créer ou modifier une ville : {id?, country_code, name, delivery_minutes?, is_active?}.
create or replace function public.admin_save_city(p_city jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_id uuid := (p_city ->> 'id')::uuid;
  v_before public.cities;
  v_after public.cities;
  v_country char(2);
begin
  if v_id is not null then
    select * into v_before from public.cities where id = v_id for update;
    if v_before.id is null then
      raise exception 'ville introuvable' using errcode = 'P0002';
    end if;
    update public.cities set
      name = coalesce(nullif(trim(p_city ->> 'name'), ''), name),
      delivery_minutes = coalesce((p_city ->> 'delivery_minutes')::smallint, delivery_minutes),
      is_active = coalesce((p_city ->> 'is_active')::boolean, is_active)
    where id = v_id returning * into v_after;
  else
    v_country := p_city ->> 'country_code';
    insert into public.cities (country_code, slug, name, delivery_minutes, is_active)
    values (v_country,
            app.free_slug(app.slugify(p_city ->> 'name'),
                          array(select slug from public.cities where country_code = v_country)),
            trim(p_city ->> 'name'), coalesce((p_city ->> 'delivery_minutes')::smallint, 30),
            coalesce((p_city ->> 'is_active')::boolean, true))
    returning * into v_after;
  end if;
  perform app.admin_did(v_admin, case when v_id is null then 'city_created' else 'city_updated' end,
    'city', v_after.id::text,
    case when v_id is null then null else jsonb_build_object('name', v_before.name,
      'delivery_minutes', v_before.delivery_minutes, 'is_active', v_before.is_active) end,
    jsonb_build_object('name', v_after.name, 'delivery_minutes', v_after.delivery_minutes,
                       'is_active', v_after.is_active), null, v_after.country_code);
  return public.admin_geography(v_after.country_code);
end
$$;

-- Créer ou modifier un quartier : {id?, city_id, name, is_active?, latitude?, longitude?}.
create or replace function public.admin_save_zone(p_zone jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_id uuid := (p_zone ->> 'id')::uuid;
  v_before public.zones;
  v_after public.zones;
  v_city uuid;
  v_country char(2);
begin
  if v_id is not null then
    select * into v_before from public.zones where id = v_id for update;
    if v_before.id is null then
      raise exception 'quartier introuvable' using errcode = 'P0002';
    end if;
    update public.zones set
      name = coalesce(nullif(trim(p_zone ->> 'name'), ''), name),
      is_active = coalesce((p_zone ->> 'is_active')::boolean, is_active),
      latitude = case when p_zone ? 'latitude' then (p_zone ->> 'latitude')::numeric else latitude end,
      longitude = case when p_zone ? 'longitude' then (p_zone ->> 'longitude')::numeric else longitude end
    where id = v_id returning * into v_after;
  else
    v_city := (p_zone ->> 'city_id')::uuid;
    insert into public.zones (city_id, slug, name, is_active, latitude, longitude)
    values (v_city,
            app.free_slug(app.slugify(p_zone ->> 'name'),
                          array(select slug from public.zones where city_id = v_city)),
            trim(p_zone ->> 'name'), coalesce((p_zone ->> 'is_active')::boolean, true),
            (p_zone ->> 'latitude')::numeric, (p_zone ->> 'longitude')::numeric)
    returning * into v_after;
  end if;
  select country_code into v_country from public.cities where id = v_after.city_id;
  perform app.admin_did(v_admin, case when v_id is null then 'zone_created' else 'zone_updated' end,
    'zone', v_after.id::text,
    case when v_id is null then null else jsonb_build_object('name', v_before.name,
      'is_active', v_before.is_active, 'latitude', v_before.latitude, 'longitude', v_before.longitude) end,
    jsonb_build_object('name', v_after.name, 'is_active', v_after.is_active,
                       'latitude', v_after.latitude, 'longitude', v_after.longitude), null, v_country);
  return public.admin_geography(v_country);
end
$$;

-- Moyens de paiement d'un pays et fournisseurs disponibles (A-CFG-03).
create or replace function public.admin_payment_methods(p_country char(2)) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return jsonb_build_object(
    'methods', (select coalesce(jsonb_agg(jsonb_build_object(
                  'id', pm.id, 'country_code', pm.country_code, 'provider_code', pm.provider_code,
                  'operator_code', pm.operator_code, 'label', pm.label, 'sort', pm.sort,
                  'is_active', pm.is_active, 'provider_active', pp.is_active, 'kind', pp.kind)
                  order by pm.sort, pm.provider_code), '[]'::jsonb)
                from public.payment_methods pm
                join public.payment_providers pp on pp.code = pm.provider_code
                where pm.country_code = p_country),
    'providers', (select coalesce(jsonb_agg(jsonb_build_object(
                    'code', pp.code, 'label', pp.label, 'kind', pp.kind, 'is_active', pp.is_active)
                    order by pp.code), '[]'::jsonb)
                  from public.payment_providers pp));
end
$$;

-- Créer ou modifier un moyen : {id?, country_code, provider_code, operator_code?,
-- label {fr, en}, sort?, is_active?}. Refus (P0001) : provider_inactive.
create or replace function public.admin_save_payment_method(p_method jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_id uuid := (p_method ->> 'id')::uuid;
  v_before public.payment_methods;
  v_after public.payment_methods;
begin
  if v_id is not null then
    select * into v_before from public.payment_methods where id = v_id for update;
    if v_before.id is null then
      raise exception 'moyen introuvable' using errcode = 'P0002';
    end if;
    update public.payment_methods set
      label = coalesce(p_method -> 'label', label),
      sort = coalesce((p_method ->> 'sort')::smallint, sort),
      is_active = coalesce((p_method ->> 'is_active')::boolean, is_active)
    where id = v_id returning * into v_after;
  else
    insert into public.payment_methods (country_code, provider_code, operator_code, label, sort, is_active)
    values (p_method ->> 'country_code', p_method ->> 'provider_code',
            nullif(trim(p_method ->> 'operator_code'), ''), p_method -> 'label',
            coalesce((p_method ->> 'sort')::smallint, 0), coalesce((p_method ->> 'is_active')::boolean, false))
    returning * into v_after;
  end if;
  if v_after.is_active and not (select is_active from public.payment_providers
                                where code = v_after.provider_code) then
    raise exception 'provider_inactive' using errcode = 'P0001';
  end if;
  perform app.admin_did(v_admin, case when v_id is null then 'payment_method_created'
                                      else 'payment_method_updated' end,
    'payment_method', v_after.id::text,
    case when v_id is null then null else jsonb_build_object('label', v_before.label,
      'sort', v_before.sort, 'is_active', v_before.is_active) end,
    jsonb_build_object('label', v_after.label, 'sort', v_after.sort, 'is_active', v_after.is_active),
    null, v_after.country_code);
  return public.admin_payment_methods(v_after.country_code);
end
$$;

-- Commission et frais en vigueur (A-CFG-04/05).
create or replace function public.admin_pricing(p_country char(2)) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return jsonb_build_object(
    'currency_code', (select currency_code from public.countries where code = p_country),
    'commissions', (select coalesce(jsonb_agg(jsonb_build_object(
                      'id', r.id, 'category_id', r.category_id, 'category_label', cat.label,
                      'rate_bps', r.rate_bps, 'valid_from', r.valid_from)
                      order by r.category_id nulls first), '[]'::jsonb)
                    from public.commission_rules r
                    left join public.categories cat on cat.id = r.category_id
                    where r.country_code = p_country and r.valid_to is null),
    'delivery_fees', (select coalesce(jsonb_agg(jsonb_build_object(
                        'id', f.id, 'city_id', f.city_id, 'city_name', c.name,
                        'base_fee_minor', f.base_fee_minor, 'extra_pickup_fee_minor', f.extra_pickup_fee_minor,
                        'free_threshold_minor', f.free_threshold_minor, 'valid_from', f.valid_from)
                        order by f.city_id nulls first), '[]'::jsonb)
                      from public.delivery_fee_defaults f
                      left join public.cities c on c.id = f.city_id
                      where f.country_code = p_country and f.valid_to is null));
end
$$;

-- Nouvelle commission : l'ancienne règle (même pays, même catégorie) est close.
create or replace function public.admin_set_commission(p_country char(2), p_category uuid, p_rate_bps int)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_before int;
begin
  if p_rate_bps is null or p_rate_bps not between 0 and 10000 then
    raise exception 'taux invalide' using errcode = '22023';
  end if;
  update public.commission_rules
  set valid_to = greatest(clock_timestamp(), valid_from + interval '1 microsecond')
  where country_code = p_country and category_id is not distinct from p_category and valid_to is null
  returning rate_bps into v_before;
  insert into public.commission_rules (country_code, category_id, rate_bps, valid_from)
  values (p_country, p_category, p_rate_bps, clock_timestamp());
  perform app.admin_did(v_admin, 'commission_set', 'country', p_country,
    jsonb_build_object('category_id', p_category, 'rate_bps', v_before),
    jsonb_build_object('category_id', p_category, 'rate_bps', p_rate_bps), null, p_country);
  return public.admin_pricing(p_country);
end
$$;

-- Nouveaux frais par défaut (pays, ou ville du pays) ; les anciens sont clos.
create or replace function public.admin_set_delivery_fee(
  p_country char(2),
  p_city uuid,
  p_base_fee_minor bigint,
  p_extra_pickup_fee_minor bigint,
  p_free_threshold_minor bigint
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_before jsonb;
begin
  update public.delivery_fee_defaults
  set valid_to = greatest(clock_timestamp(), valid_from + interval '1 microsecond')
  where country_code = p_country and city_id is not distinct from p_city and valid_to is null
  returning jsonb_build_object('base_fee_minor', base_fee_minor, 'extra_pickup_fee_minor',
    extra_pickup_fee_minor, 'free_threshold_minor', free_threshold_minor) into v_before;
  insert into public.delivery_fee_defaults (country_code, city_id, currency_code, base_fee_minor,
    extra_pickup_fee_minor, free_threshold_minor, valid_from)
  values (p_country, p_city, (select currency_code from public.countries where code = p_country),
          p_base_fee_minor, coalesce(p_extra_pickup_fee_minor, 0), p_free_threshold_minor,
          clock_timestamp());
  perform app.admin_did(v_admin, 'delivery_fee_set', 'country', p_country,
    v_before || jsonb_build_object('city_id', p_city),
    jsonb_build_object('city_id', p_city, 'base_fee_minor', p_base_fee_minor,
      'extra_pickup_fee_minor', coalesce(p_extra_pickup_fee_minor, 0),
      'free_threshold_minor', p_free_threshold_minor), null, p_country);
  return public.admin_pricing(p_country);
end
$$;

-- Catégories générales (A-CFG-06).
create or replace function public.admin_categories() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', c.id, 'parent_id', c.parent_id, 'slug', c.slug, 'label', c.label, 'icon', c.icon,
      'sort', c.sort, 'is_active', c.is_active)
      order by coalesce(p.sort, c.sort), coalesce(p.slug, c.slug), c.parent_id nulls first, c.sort), '[]'::jsonb)
    from public.categories c
    left join public.categories p on p.id = c.parent_id);
end
$$;

-- Créer ou modifier : {id?, parent_id?, label {fr, en}, icon?, sort?, is_active?}.
create or replace function public.admin_save_category(p_category jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_id uuid := (p_category ->> 'id')::uuid;
  v_before public.categories;
  v_after public.categories;
begin
  if v_id is not null then
    select * into v_before from public.categories where id = v_id for update;
    if v_before.id is null then
      raise exception 'catégorie introuvable' using errcode = 'P0002';
    end if;
    update public.categories set
      label = coalesce(p_category -> 'label', label),
      icon = case when p_category ? 'icon' then nullif(trim(p_category ->> 'icon'), '') else icon end,
      sort = coalesce((p_category ->> 'sort')::smallint, sort),
      is_active = coalesce((p_category ->> 'is_active')::boolean, is_active)
    where id = v_id returning * into v_after;
  else
    insert into public.categories (parent_id, slug, label, icon, sort, is_active)
    values ((p_category ->> 'parent_id')::uuid,
            app.free_slug(app.slugify(p_category -> 'label' ->> 'fr'),
                          array(select slug from public.categories)),
            p_category -> 'label', nullif(trim(p_category ->> 'icon'), ''),
            coalesce((p_category ->> 'sort')::smallint, 0),
            coalesce((p_category ->> 'is_active')::boolean, true))
    returning * into v_after;
  end if;
  perform app.admin_did(v_admin, case when v_id is null then 'category_created' else 'category_updated' end,
    'category', v_after.id::text,
    case when v_id is null then null else jsonb_build_object('label', v_before.label,
      'icon', v_before.icon, 'sort', v_before.sort, 'is_active', v_before.is_active) end,
    jsonb_build_object('label', v_after.label, 'icon', v_after.icon, 'sort', v_after.sort,
                       'is_active', v_after.is_active), null, null);
  return public.admin_categories();
end
$$;

-- ------------------------------------------------------------------ journal

-- Journal d'audit (A-LOG-01/02) : recherche (action, entité, raison), filtres,
-- pagination ; les plus récentes d'abord.
create or replace function public.admin_audit(
  p_query text default null,
  p_action text default null,
  p_entity_type text default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_limit int default 50,
  p_offset int default 0
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_q text := nullif(trim(p_query), '');
  v_like text;
begin
  perform app.require_admin();
  v_like := '%' || replace(replace(replace(coalesce(v_q, ''), '\', '\\'), '%', '\%'), '_', '\_') || '%';
  return (
    with hits as (
      select a.* from public.audit_log a
      where (p_action is null or a.action = p_action)
        and (p_entity_type is null or a.entity_type = p_entity_type)
        and (p_from is null or a.occurred_at >= p_from)
        and (p_to is null or a.occurred_at < p_to)
        and (v_q is null or a.action ilike v_like or a.entity_id ilike v_like
             or a.reason ilike v_like or a.entity_type ilike v_like))
    select jsonb_build_object(
      'total', (select count(*) from hits),
      'entries', (select coalesce(jsonb_agg(jsonb_build_object(
                    'id', h.id, 'occurred_at', h.occurred_at, 'actor_id', h.actor_id,
                    'actor_first_name', (select first_name from public.profiles where user_id = h.actor_id),
                    'action', h.action, 'entity_type', h.entity_type, 'entity_id', h.entity_id,
                    'before', h.before, 'after', h.after, 'reason', h.reason)
                    order by h.occurred_at desc, h.id desc), '[]'::jsonb)
                  from (select * from hits order by occurred_at desc, id desc
                        limit least(greatest(coalesce(p_limit, 50), 1), 200)
                        offset greatest(coalesce(p_offset, 0), 0)) h),
      'actions', (select coalesce(jsonb_agg(distinct action), '[]'::jsonb) from public.audit_log),
      'entity_types', (select coalesce(jsonb_agg(distinct entity_type), '[]'::jsonb) from public.audit_log)));
end
$$;

-- ------------------------------------------------------------------ droits

revoke all on function
  app.require_admin(), app.assert_admin(uuid), app.admin_did(uuid, text, text, text, jsonb, jsonb, text, char),
  app.admin_order_row(uuid), app.admin_order_json(uuid),
  app.admin_force_status(uuid, uuid, text, text, text), app.admin_cancel_order(uuid, uuid, text, text),
  app.admin_assign_courier(uuid, uuid, text, text), app.admin_refund_json(uuid),
  app.refund_claim(uuid, uuid), app.refund_finish(uuid, uuid, boolean, text, text),
  app.refund_result(uuid, uuid, boolean, text, text), app.refund_mark_cash(uuid, uuid),
  app.admin_store_row(uuid), app.admin_store_json(uuid), app.admin_set_store_status(uuid, uuid, text, text),
  app.country_missing(char),
  public.admin_orders(text, text, int, int), public.admin_order(uuid),
  public.admin_refunds(text, int), public.admin_pending_payments(int),
  public.admin_stores(text, text, int, int), public.admin_store(uuid),
  public.admin_update_store(uuid, jsonb, text),
  public.admin_countries(), public.admin_set_country_active(char, boolean),
  public.admin_geography(char), public.admin_save_city(jsonb), public.admin_save_zone(jsonb),
  public.admin_payment_methods(char), public.admin_save_payment_method(jsonb),
  public.admin_pricing(char), public.admin_set_commission(char, uuid, int),
  public.admin_set_delivery_fee(char, uuid, bigint, bigint, bigint),
  public.admin_categories(), public.admin_save_category(jsonb),
  public.admin_audit(text, text, text, timestamptz, timestamptz, int, int)
from public;

grant execute on function
  public.admin_orders(text, text, int, int), public.admin_order(uuid),
  public.admin_refunds(text, int), public.admin_pending_payments(int),
  public.admin_stores(text, text, int, int), public.admin_store(uuid),
  public.admin_update_store(uuid, jsonb, text),
  public.admin_countries(), public.admin_set_country_active(char, boolean),
  public.admin_geography(char), public.admin_save_city(jsonb), public.admin_save_zone(jsonb),
  public.admin_payment_methods(char), public.admin_save_payment_method(jsonb),
  public.admin_pricing(char), public.admin_set_commission(char, uuid, int),
  public.admin_set_delivery_fee(char, uuid, bigint, bigint, bigint),
  public.admin_categories(), public.admin_save_category(jsonb),
  public.admin_audit(text, text, text, timestamptz, timestamptz, int, int)
to authenticated;
