-- 0040 — Précommande et créneaux (spec 033).
-- 1. Créneaux de livraison par pays (données de référence) et horizon en jours.
-- 2. Arrivages : la vendeuse indique la date d'arrivée d'un produit ; on le commande dès
--    maintenant au prix du jour (figé par ligne), livré à partir de cette date.
-- 3. Commande programmée : créneau validé en base dans la même transaction que la création ;
--    l'heure affichée devient le début du créneau.

alter table public.countries add column schedule_days_ahead smallint not null default 7
  check (schedule_days_ahead between 0 and 30);

create table public.delivery_windows (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries (code),
  starts_at time not null,
  ends_at time not null,
  sort smallint not null default 0,
  is_active boolean not null default true,
  check (starts_at < ends_at),
  unique (country_code, starts_at, ends_at)
);
alter table public.delivery_windows enable row level security;
create policy delivery_windows_read on public.delivery_windows for select
  to authenticated, anonymous using (is_active);
revoke all on public.delivery_windows from authenticated, anonymous;
grant select on public.delivery_windows to authenticated, anonymous;

-- Créneaux de départ (deux heures, de 8 h à 20 h) pour chaque pays ; réglables ensuite.
insert into public.delivery_windows (country_code, starts_at, ends_at, sort)
select c.code, w.s, w.e, w.n
from public.countries c,
     (values (time '08:00', time '10:00', 1), (time '10:00', time '12:00', 2),
             (time '12:00', time '14:00', 3), (time '14:00', time '16:00', 4),
             (time '16:00', time '18:00', 5), (time '18:00', time '20:00', 6)) as w (s, e, n)
on conflict do nothing;

alter table public.products add column arrival_on date;
alter table public.orders
  add column scheduled_start timestamptz,
  add column scheduled_end timestamptz,
  add constraint orders_schedule_check check (
    (scheduled_start is null) = (scheduled_end is null)
    and (scheduled_start is null or scheduled_start < scheduled_end));

-- ------------------------------------------------------------------ arrivages

-- Date d'arrivage d'un produit de sa boutique (nul : produit normal) ; aujourd'hui au plus tôt.
create or replace function public.set_product_arrival(p_product uuid, p_arrival_on date) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store uuid := app.own_store_id();
  v_today date;
  v_country char(2);
begin
  select s.country_code into v_country from public.products p join public.stores s on s.id = p.store_id
  where p.id = p_product and p.store_id = v_store;
  if v_country is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  v_today := (now() at time zone (select timezone from public.countries where code = v_country))::date;
  if p_arrival_on is not null and p_arrival_on < v_today then
    raise exception 'invalid_arrival' using errcode = '22023';
  end if;
  update public.products set arrival_on = p_arrival_on, updated_at = now() where id = p_product;
  if p_arrival_on is not null then
    perform app.emit_event('product_arrival_set', app.current_user_id(), 'vendor', 'server', v_country,
      'product', p_product::text, jsonb_build_object('days_ahead', p_arrival_on - v_today));
  end if;
  return app.product_json(p_product);
end
$fn$;

-- Arrivage encore à venir (date future) d'un produit.
create or replace function app.product_arrival(p_product uuid) returns date
language sql stable security definer set search_path = ''
as $$
  select p.arrival_on from public.products p
  join public.stores s on s.id = p.store_id
  join public.countries c on c.code = s.country_code
  where p.id = p_product and p.arrival_on > (now() at time zone c.timezone)::date
$$;

-- ------------------------------------------------------------------ créneaux

-- Créneaux proposés pour le panier de la personne : jours (aujourd'hui à l'horizon du pays),
-- créneaux encore possibles, premier jour permis (arrivages du panier).
create or replace function public.delivery_slots(p_at timestamptz default now()) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_cart public.carts;
  v_country public.countries;
  v_today date;
  v_min date;
  v_prep int;
begin
  select * into v_cart from public.carts where user_id = v_user;
  select * into v_country from public.countries
  where code = coalesce(v_cart.country_code, (select country_code from public.profiles where user_id = v_user));
  if v_country.code is null then raise exception 'profile_required' using errcode = '22023'; end if;
  v_today := (p_at at time zone v_country.timezone)::date;
  select max(app.product_arrival(v.product_id)),
         coalesce(max(s.prep_time_minutes), 0)
  into v_min, v_prep
  from public.cart_items i
  join public.product_variants v on v.id = i.variant_id
  join public.products p on p.id = v.product_id
  join public.stores s on s.id = p.store_id
  where i.cart_id = v_cart.id;
  return jsonb_build_object(
    'required', v_min is not null,
    'min_date', coalesce(v_min, v_today),
    'days', coalesce((
      select jsonb_agg(jsonb_build_object('date', d.day, 'windows', d.windows) order by d.day)
      from (
        select g.day::date as day,
               (select coalesce(jsonb_agg(jsonb_build_object(
                    'id', w.id, 'starts_at', to_char(w.starts_at, 'HH24:MI'),
                    'ends_at', to_char(w.ends_at, 'HH24:MI')) order by w.sort, w.starts_at), '[]'::jsonb)
                from public.delivery_windows w
                where w.country_code = v_country.code and w.is_active
                  and ((g.day::date + w.starts_at) at time zone v_country.timezone)
                      > p_at + make_interval(mins => v_prep)) as windows
        from generate_series(greatest(v_today, coalesce(v_min, v_today)),
                             v_today + v_country.schedule_days_ahead, interval '1 day') g (day)
      ) d where jsonb_array_length(d.windows) > 0), '[]'::jsonb));
end
$fn$;

-- Programme les commandes d'un achat (créneau `{date, window_id}`) ; refus : slot_required,
-- invalid_slot, slot_too_early (avant un arrivage), store_closed_at_slot.
create or replace function app.schedule_purchase(p_purchase uuid, p_slot jsonb, p_at timestamptz)
returns void
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_country public.countries;
  v_window public.delivery_windows;
  v_date date;
  v_start timestamptz;
  v_end timestamptz;
  v_min date;
  v_today date;
  v_order record;
  v_user uuid;
begin
  select c.* into v_country
  from public.purchases pu join public.countries c on c.code = pu.country_code where pu.id = p_purchase;
  v_user := (select user_id from public.purchases where id = p_purchase);
  v_today := (p_at at time zone v_country.timezone)::date;
  select max(app.product_arrival(i.product_id)) into v_min
  from public.order_items i join public.orders o on o.id = i.order_id where o.purchase_id = p_purchase;
  if p_slot is null or jsonb_typeof(p_slot) <> 'object' then
    if v_min is not null then raise exception 'slot_required' using errcode = 'P0001'; end if;
    return;
  end if;
  begin
    v_date := (p_slot ->> 'date')::date;
    select * into v_window from public.delivery_windows
    where id = (p_slot ->> 'window_id')::uuid and country_code = v_country.code and is_active;
  exception when others then
    raise exception 'invalid_slot' using errcode = 'P0001';
  end;
  if v_window.id is null or v_date is null or v_date < v_today
     or v_date > v_today + v_country.schedule_days_ahead then
    raise exception 'invalid_slot' using errcode = 'P0001';
  end if;
  if v_min is not null and v_date < v_min then raise exception 'slot_too_early' using errcode = 'P0001'; end if;
  v_start := (v_date + v_window.starts_at) at time zone v_country.timezone;
  v_end := (v_date + v_window.ends_at) at time zone v_country.timezone;
  for v_order in
    select o.id, o.store_id, s.prep_time_minutes from public.orders o join public.stores s on s.id = o.store_id
    where o.purchase_id = p_purchase
  loop
    if v_start <= p_at + make_interval(mins => v_order.prep_time_minutes) then
      raise exception 'invalid_slot' using errcode = 'P0001';
    end if;
    if not app.store_open_at(v_order.store_id, v_start) then
      raise exception 'store_closed_at_slot' using errcode = 'P0001';
    end if;
    update public.orders set scheduled_start = v_start, scheduled_end = v_end where id = v_order.id;
  end loop;
  perform app.emit_event('order_scheduled', v_user, 'client', 'server', v_country.code, 'purchase',
    p_purchase::text, jsonb_build_object('days_ahead', v_date - v_today, 'preorder', v_min is not null));
end
$fn$;

-- Création de commande avec créneau (Function) : `place_order`, puis programmation dans la même
-- transaction ; un refus annule tout. Un rejeu (même clé) rend l'achat existant.
create or replace function app.place_order_scheduled(
  p_user uuid, p_key uuid, p_request jsonb, p_at timestamptz, p_providers text[]
) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_result jsonb := app.place_order(p_user, p_key, p_request, p_at, p_providers);
  v_purchase uuid := (v_result -> 'purchase' ->> 'id')::uuid;
begin
  if not (v_result ->> 'replayed')::boolean then
    perform app.schedule_purchase(v_purchase, p_request -> 'slot', p_at);
    if p_request -> 'slot' is not null and jsonb_typeof(p_request -> 'slot') = 'object' then
      v_result := jsonb_set(v_result, '{purchase}', app.purchase_json(v_purchase));
    end if;
  end if;
  return v_result;
end
$fn$;

-- Heure affichée : début du créneau si la commande est programmée.
create or replace function app.order_eta(p_order uuid) returns timestamptz
language sql stable security definer set search_path = ''
as $$
  select coalesce(o.scheduled_start, coalesce(o.accepted_at, o.created_at)
    + make_interval(mins => s.prep_time_minutes
        + case when o.fulfillment = 'delivery'
               then coalesce((select c.delivery_minutes from public.zones z
                              join public.cities c on c.id = z.city_id
                              where z.id = (pu.address ->> 'zone_id')::uuid), 0)
               else 0 end))
  from public.orders o
  join public.stores s on s.id = o.store_id
  join public.purchases pu on pu.id = o.purchase_id
  where o.id = p_order
$$;

-- Fiche produit (0011) : date d'arrivage.
create or replace function app.catalog_item(p_product uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', p.id, 'name', p.name, 'category_id', p.category_id,
    'price_minor', p.price_minor, 'min_price_minor', app.product_min_price(p.id),
    'currency_code', p.currency_code,
    'unit_label', u.label,
    'photo_key', (select f.object_key from public.product_photos f where f.product_id = p.id order by f.sort limit 1),
    'variant_count', (select count(*) from public.product_variants v where v.product_id = p.id),
    'default_variant_id', (select v.id from public.product_variants v where v.product_id = p.id
                           order by v.sort, v.created_at limit 1),
    'available', app.product_available(p.id),
    'arrival_on', app.product_arrival(p.id),
    'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin, 'zone_name', z.name),
    'store_category_ids', coalesce((
      select jsonb_agg(pc.store_category_id) from public.product_store_categories pc
      join public.store_categories sc on sc.id = pc.store_category_id and not sc.is_archived
      where pc.product_id = p.id), '[]'::jsonb)
  )
  from public.products p
  join public.stores s on s.id = p.store_id
  join public.zones z on z.id = s.zone_id
  left join public.units u on u.id = p.unit_id
  where p.id = p_product and p.status = 'published' and s.status = 'active'
$$;

-- Détail de commande (0013) : créneau.
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
    'next_statuses', app.order_next_statuses(p_role, o.fulfillment, o.status),
    'substitution_allowed', pu.substitution_allowed)
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.payment_methods pm on pm.id = pu.payment_method_id
  join public.stores s on s.id = o.store_id
  join public.zones z on z.id = s.zone_id
  where o.id = p_order
$$;

-- Commandes de la cliente (0013) : créneau.
create or replace function public.my_orders(p_limit int default 50) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', o.id, 'purchase_id', o.purchase_id, 'status', o.status, 'fulfillment', o.fulfillment,
    'created_at', o.created_at, 'delivered_at', o.delivered_at,
    'eta_at', case when o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
                   then app.order_eta(o.id) end,
    'scheduled_start', o.scheduled_start, 'scheduled_end', o.scheduled_end,
    'currency_code', o.currency_code, 'total_minor', o.total_minor,
    'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
    'payment_status', pu.payment_status,
    'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin))
    order by o.created_at desc, o.id), '[]'::jsonb)
  from (select * from public.orders o
        where exists (select 1 from public.purchases p where p.id = o.purchase_id and p.user_id = app.require_user())
        order by o.created_at desc, o.id
        limit least(greatest(coalesce(p_limit, 50), 1), 200)) o
  join public.purchases pu on pu.id = o.purchase_id
  join public.stores s on s.id = o.store_id
$$;

-- Commandes de la boutique (0013) : créneau.
create or replace function public.my_store_orders(p_scope text default null, p_limit int default 50)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.store_order_json(o.id, false)
    || jsonb_build_object('eta_at', case when o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
                                         then app.order_eta(o.id) end,
                                 'scheduled_start', o.scheduled_start, 'scheduled_end', o.scheduled_end)
    order by o.created_at desc, o.id), '[]'::jsonb)
  from (
    select o.id, o.created_at, o.status, o.scheduled_start, o.scheduled_end from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    where o.store_id = app.own_store_id()
      and pu.payment_status in ('cash_on_delivery', 'paid')
      and (p_scope is null
        or (p_scope = 'new' and o.status = 'pending')
        or (p_scope = 'active' and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery'))
        or (p_scope = 'done' and o.status in ('delivered', 'refused', 'cancelled')))
    order by o.created_at desc, o.id
    limit least(greatest(coalesce(p_limit, 50), 1), 200)
  ) o
$$;

insert into public.event_names (name, emitted_by, description) values
  ('order_scheduled', 'server', 'Commande programmée sur un créneau (jours d''avance, précommande)'),
  ('product_arrival_set', 'server', 'Date d''arrivage d''un produit indiquée par la vendeuse')
on conflict do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function public.set_product_arrival(uuid, date), app.product_arrival(uuid),
  public.delivery_slots(timestamptz), app.schedule_purchase(uuid, jsonb, timestamptz),
  app.place_order_scheduled(uuid, uuid, jsonb, timestamptz, text[]) from public;
grant execute on function public.set_product_arrival(uuid, date), public.delivery_slots(timestamptz)
  to authenticated;
