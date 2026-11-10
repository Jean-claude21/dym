-- 0048 — App livreur : inscription, missions, acceptation (spec 041, VISION §3 « Livreur »).
-- Modèle : zems indépendants qui acceptent des missions. Un même compte DYM peut être livreur.
-- 1. Profil livreur (nom, téléphone, moyen, zones), en ligne ou non ; suspendu par l'équipe.
-- 2. Missions : commandes à livrer, acceptées, sans livreur, dans ses zones (boutique ou cliente).
-- 3. Acceptation atomique (une commande, un livreur ; nombre de courses limité par pays), retrait
--    et remise par le livreur (rôle `courier` dans la machine d'états).
-- 4. Notifications vers l'app livreur ; rôle et app `delivery` acceptés partout.

alter table public.countries add column courier_max_active smallint not null default 3
  check (courier_max_active between 1 and 10);

create table public.courier_profiles (
  user_id uuid primary key references neon_auth."user" (id) on delete cascade,
  display_name text not null check (length(btrim(display_name)) between 2 and 40),
  phone text not null check (phone ~ '^\+?[0-9 ]{8,20}$'),
  vehicle text not null check (vehicle in ('foot', 'bike', 'moto', 'car')),
  country_code char(2) not null references public.countries (code),
  status text not null default 'active' check (status in ('active', 'suspended')),
  is_online boolean not null default false,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp()
);
alter table public.courier_profiles enable row level security;
revoke all on public.courier_profiles from authenticated, anonymous;

create table public.courier_zones (
  user_id uuid not null references public.courier_profiles (user_id) on delete cascade,
  zone_id uuid not null references public.zones (id) on delete cascade,
  primary key (user_id, zone_id)
);
create index courier_zones_zone on public.courier_zones (zone_id);
alter table public.courier_zones enable row level security;
revoke all on public.courier_zones from authenticated, anonymous;

-- Livreur DYM (nul : livreur saisi à la main par l'équipe, spec 013).
alter table public.order_couriers
  add column courier_id uuid references neon_auth."user" (id) on delete set null,
  add column accepted_at timestamptz;
create index order_couriers_courier on public.order_couriers (courier_id) where courier_id is not null;

alter table public.order_status_events drop constraint order_status_events_actor_role_check;
alter table public.order_status_events add constraint order_status_events_actor_role_check
  check (actor_role in ('client', 'vendor', 'admin', 'courier', 'system'));
alter table public.push_tokens drop constraint push_tokens_app_check;
alter table public.push_tokens add constraint push_tokens_app_check
  check (app in ('client', 'vendor', 'admin', 'delivery'));

-- ------------------------------------------------------------------ profil

create or replace function app.courier_json(p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('display_name', c.display_name, 'phone', c.phone, 'vehicle', c.vehicle,
    'status', c.status, 'is_online', c.is_online, 'country_code', c.country_code,
    'zone_ids', coalesce((select jsonb_agg(z.zone_id order by z.zone_id) from public.courier_zones z
                          where z.user_id = c.user_id), '[]'::jsonb))
  from public.courier_profiles c where c.user_id = p_user
$$;

create or replace function public.my_courier_profile() returns jsonb
language sql stable security definer set search_path = ''
as $$ select app.courier_json(app.current_user_id()) $$;

-- Zones du pays du livreur, actives ; 1 à 20.
create or replace function app.set_courier_zones(p_user uuid, p_country char(2), p_zones uuid[]) returns void
language plpgsql security definer set search_path = ''
as $fn$
begin
  if coalesce(array_length(p_zones, 1), 0) not between 1 and 20 then
    raise exception 'invalid_zones' using errcode = '22023';
  end if;
  if exists (select 1 from unnest(p_zones) z(id)
             where not exists (select 1 from public.zones zo join public.cities ci on ci.id = zo.city_id
                               where zo.id = z.id and zo.is_active and ci.country_code = p_country)) then
    raise exception 'invalid_zones' using errcode = '22023';
  end if;
  delete from public.courier_zones where user_id = p_user;
  insert into public.courier_zones (user_id, zone_id) select distinct p_user, z from unnest(p_zones) z;
end
$fn$;

-- Inscription (ou mise à jour) : profil, zones, rôle `courier`.
create or replace function public.become_courier(p_name text, p_phone text, p_vehicle text, p_zones uuid[])
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_country char(2) := (select country_code from public.profiles where user_id = v_user);
  v_created boolean;
begin
  if v_country is null then raise exception 'profile_required' using errcode = '22023'; end if;
  if length(btrim(coalesce(p_name, ''))) not between 2 and 40 then
    raise exception 'invalid_name' using errcode = '22023';
  end if;
  if coalesce(p_phone, '') !~ '^\+?[0-9 ]{8,20}$' then raise exception 'invalid_phone' using errcode = '22023'; end if;
  if p_vehicle is null or p_vehicle not in ('foot', 'bike', 'moto', 'car') then
    raise exception 'invalid_vehicle' using errcode = '22023';
  end if;
  insert into public.courier_profiles (user_id, display_name, phone, vehicle, country_code)
  values (v_user, btrim(p_name), btrim(p_phone), p_vehicle, v_country)
  on conflict (user_id) do update set display_name = excluded.display_name, phone = excluded.phone,
    vehicle = excluded.vehicle, updated_at = clock_timestamp()
  returning (xmax = 0) into v_created;
  perform app.set_courier_zones(v_user, v_country, p_zones);
  insert into public.user_roles (user_id, role) values (v_user, 'courier') on conflict do nothing;
  if v_created then
    perform app.emit_event('courier_joined', v_user, 'courier', 'server', v_country, 'courier', v_user::text,
      jsonb_build_object('vehicle', p_vehicle, 'zones', coalesce(array_length(p_zones, 1), 0)));
  end if;
  return app.courier_json(v_user);
end
$fn$;

-- En ligne : les missions lui sont proposées. Suspendu : jamais.
create or replace function public.set_courier_online(p_online boolean) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_status text := (select status from public.courier_profiles where user_id = v_user);
begin
  if v_status is null then raise exception 'not_courier' using errcode = '42501'; end if;
  if v_status = 'suspended' and p_online then raise exception 'courier_suspended' using errcode = '42501'; end if;
  update public.courier_profiles set is_online = p_online, updated_at = clock_timestamp() where user_id = v_user;
  perform app.emit_event(case when p_online then 'courier_online' else 'courier_offline' end, v_user, 'courier',
    'server', (select country_code from public.courier_profiles where user_id = v_user), 'courier', v_user::text,
    '{}'::jsonb);
  return app.courier_json(v_user);
end
$fn$;

-- ------------------------------------------------------------------ missions

-- Commande livrable par ce livreur : à livrer, acceptée par la boutique, sans livreur, dans son
-- pays, boutique ou cliente dans une de ses zones.
create or replace function app.mission_open_for(p_order uuid, p_user uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    join public.stores s on s.id = o.store_id
    join public.courier_profiles c on c.user_id = p_user and c.status = 'active' and c.is_online
    where o.id = p_order and o.fulfillment = 'delivery' and o.status in ('accepted', 'preparing', 'ready')
      and pu.country_code = c.country_code and pu.user_id <> p_user and s.owner_id <> p_user
      and not exists (select 1 from public.order_couriers oc where oc.order_id = o.id)
      and exists (select 1 from public.courier_zones z where z.user_id = p_user
                  and (z.zone_id = s.zone_id or z.zone_id = (pu.address ->> 'zone_id')::uuid)))
$$;

-- Fiche d'une mission. Avant acceptation : ni téléphone ni repère de la cliente.
create or replace function app.mission_json(p_order uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'order_id', o.id, 'status', o.status, 'created_at', o.created_at,
    'ready_at', o.ready_at, 'eta_at', app.order_eta(o.id),
    'delivery_fee_minor', o.delivery_fee_minor, 'currency_code', o.currency_code,
    'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
    'store', jsonb_build_object('name', s.name,
      'zone_name', (select z.name from public.zones z where z.id = s.zone_id),
      'landmark', case when mine then (select concat_ws(' · ', a.address, a.landmark)
                                       from public.store_pickup_addresses a where a.store_id = s.id) end,
      'phone', case when mine then (select a.contact_phone from public.store_pickup_addresses a
                                    where a.store_id = s.id) end),
    'customer', jsonb_build_object(
      'zone_name', (select z.name from public.zones z where z.id = (pu.address ->> 'zone_id')::uuid),
      'first_name', case when mine then (select p.first_name from public.profiles p where p.user_id = pu.user_id) end,
      'landmark', case when mine then pu.address ->> 'landmark' end,
      'phone', case when mine then pu.address ->> 'phone' end,
      'latitude', case when mine then pu.address -> 'latitude' end,
      'longitude', case when mine then pu.address -> 'longitude' end),
    'accepted_at', oc.accepted_at,
    'next', case when mine then app.order_next_statuses('courier', o.fulfillment, o.status) else '[]'::jsonb end)
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.stores s on s.id = o.store_id
  left join public.order_couriers oc on oc.order_id = o.id
  cross join lateral (select oc.courier_id is not distinct from p_user and oc.courier_id is not null as mine) m
  where o.id = p_order
$$;

create or replace function public.available_missions() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.mission_json(o.id, app.current_user_id()) order by o.created_at), '[]'::jsonb)
  from (select o.id, o.created_at from public.orders o
        where o.fulfillment = 'delivery' and o.status in ('accepted', 'preparing', 'ready')
          and app.mission_open_for(o.id, app.current_user_id())
        order by o.created_at limit 30) o
$$;

create or replace function public.my_missions() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.mission_json(oc.order_id, app.current_user_id())
                            order by (o.status = 'delivered'), oc.accepted_at desc), '[]'::jsonb)
  from public.order_couriers oc join public.orders o on o.id = oc.order_id
  where oc.courier_id = app.current_user_id()
    and (o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery')
         or (o.status = 'delivered' and o.delivered_at > now() - interval '24 hours'))
$$;

-- Acceptation : une seule fois par commande, dans la limite du pays.
create or replace function public.accept_mission(p_order uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_courier public.courier_profiles;
  v_order public.orders;
  v_owner uuid;
  v_client uuid;
begin
  select * into v_courier from public.courier_profiles where user_id = v_user;
  if v_courier.user_id is null then raise exception 'not_courier' using errcode = '42501'; end if;
  select * into v_order from public.orders where id = p_order for update;
  if v_order.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if (select count(*) from public.order_couriers oc join public.orders o on o.id = oc.order_id
      where oc.courier_id = v_user and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery'))
     >= (select courier_max_active from public.countries where code = v_courier.country_code) then
    raise exception 'too_many_missions' using errcode = 'P0001';
  end if;
  if not app.mission_open_for(p_order, v_user) then
    raise exception 'mission_taken' using errcode = 'P0001';
  end if;
  insert into public.order_couriers (order_id, name, phone, courier_id, accepted_at)
  values (p_order, v_courier.display_name, v_courier.phone, v_user, now());
  select owner_id into v_owner from public.stores where id = v_order.store_id;
  select user_id into v_client from public.purchases where id = v_order.purchase_id;
  perform app.notify(v_owner, 'delivery_assigned', 'orders', p_order, v_order.purchase_id,
    jsonb_build_object('courier_name', v_courier.display_name, 'courier_phone', v_courier.phone));
  perform app.notify(v_client, 'courier_assigned', 'orders', p_order, v_order.purchase_id,
    jsonb_build_object('courier_name', v_courier.display_name));
  perform app.emit_event('mission_accepted', v_user, 'courier', 'server', v_courier.country_code,
    'order', p_order::text, jsonb_build_object('minutes_since_created',
      round(extract(epoch from now() - v_order.created_at) / 60)::int));
  return app.mission_json(p_order, v_user);
end
$fn$;

-- Le livreur rend une mission tant qu'il n'a pas récupéré la commande.
create or replace function public.release_mission(p_order uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  delete from public.order_couriers oc using public.orders o
  where oc.order_id = p_order and oc.courier_id = v_user and o.id = oc.order_id
    and o.status in ('accepted', 'preparing', 'ready');
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  perform app.emit_event('mission_released', v_user, 'courier', 'server',
    (select country_code from public.courier_profiles where user_id = v_user), 'order', p_order::text, '{}'::jsonb);
end
$fn$;

-- Gestes du livreur : récupérée (prête → en route), livrée (en route → livrée).
create or replace function public.courier_transition(p_order uuid, p_to text, p_expected text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  perform app.transition_order(v_user, p_order, p_to, p_expected);
  return app.mission_json(p_order, v_user);
end
$fn$;

-- Commande prête à confier (acceptée par la boutique) : les livreurs en ligne de la zone sont prévenus.
create or replace function app.notify_couriers() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_zone uuid;
  v_store_zone uuid;
  v_country char(2);
begin
  if new.fulfillment <> 'delivery' or new.status <> 'accepted' or old.status is not distinct from 'accepted' then
    return null;
  end if;
  select (pu.address ->> 'zone_id')::uuid, pu.country_code into v_zone, v_country
  from public.purchases pu where pu.id = new.purchase_id;
  select zone_id into v_store_zone from public.stores where id = new.store_id;
  perform app.notify(c.user_id, 'mission_available', 'orders', null, null,
    jsonb_build_object('store_name', (select name from public.stores where id = new.store_id)))
  from public.courier_profiles c
  where c.status = 'active' and c.is_online and c.country_code = v_country
    and exists (select 1 from public.courier_zones z where z.user_id = c.user_id
                and z.zone_id in (v_zone, v_store_zone))
    and not exists (select 1 from public.purchases pu where pu.id = new.purchase_id and pu.user_id = c.user_id)
  limit 20;
  return null;
end
$fn$;
create trigger orders_notify_couriers after update of status on public.orders
  for each row execute function app.notify_couriers();

insert into public.notification_templates (kind, locale, title, body) values
  ('mission_available', 'fr', 'Nouvelle course', 'Une commande de {store_name} attend un livreur près de toi.'),
  ('mission_available', 'en', 'New delivery', 'An order from {store_name} needs a courier near you.'),
  ('courier_assigned', 'fr', 'Livreur trouvé', '{courier_name} va livrer ta commande.'),
  ('courier_assigned', 'en', 'Courier found', '{courier_name} will deliver your order.')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('courier_joined', 'server', 'Livreur inscrit (moyen, nombre de zones)'),
  ('courier_online', 'server', 'Livreur en ligne'),
  ('courier_offline', 'server', 'Livreur hors ligne'),
  ('mission_accepted', 'server', 'Mission acceptée (minutes depuis la commande)'),
  ('mission_released', 'server', 'Mission rendue avant retrait')
on conflict do nothing;

-- Profil (0005) : app livreur.
create or replace function public.complete_profile(
  p_first_name text,
  p_zone_id uuid,
  p_app text,
  p_locale text default 'fr'
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_country char(2);
  v_created boolean;
  v_role text;
begin
  if v_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  -- App livreur : compte client ; le rôle `courier` vient avec l'inscription (become_courier).
  v_role := case p_app when 'client' then 'client' when 'vendor' then 'vendor' when 'delivery' then 'client' end;
  if v_role is null then
    raise exception 'app inconnue : %', p_app using errcode = '22023';
  end if;
  if length(trim(coalesce(p_first_name, ''))) not between 1 and 40 then
    raise exception 'prénom : 1 à 40 caractères' using errcode = '22023';
  end if;

  -- Le quartier doit être visible (actif, ville et pays actifs) ; il fixe le pays.
  select c.country_code into v_country
  from public.zones z
  join public.cities c on c.id = z.city_id
  where z.id = p_zone_id and z.is_active and app.city_is_visible(c.id);
  if v_country is null then
    raise exception 'quartier inconnu ou inactif' using errcode = '22023';
  end if;

  insert into public.profiles (user_id, first_name, country_code, zone_id, locale)
  values (v_user, trim(p_first_name), v_country, p_zone_id, coalesce(p_locale, 'fr'))
  on conflict (user_id) do update
    set first_name = excluded.first_name,
        country_code = excluded.country_code,
        zone_id = excluded.zone_id,
        locale = excluded.locale
  returning (xmax = 0) into v_created;

  insert into public.user_roles (user_id, role) values (v_user, v_role)
  on conflict (user_id, role) do nothing;

  if v_created then
    perform app.emit_event('user_signed_up', v_user, v_role, p_app, v_country, 'user',
      v_user::text, jsonb_build_object('role', v_role));
  end if;

  return public.me();
end
$$;

-- Transitions (0013) : rôle livreur.
create or replace function app.order_transition_allowed(
  p_role text, p_fulfillment text, p_from text, p_to text
) returns boolean
language sql immutable
as $$
  select case p_role
    when 'vendor' then
      (p_from, p_to) in (('pending', 'accepted'), ('pending', 'refused'), ('accepted', 'preparing'),
                         ('accepted', 'ready'), ('preparing', 'ready'))
      or (p_fulfillment = 'delivery'
          and (p_from, p_to) in (('ready', 'out_for_delivery'), ('out_for_delivery', 'delivered')))
      or (p_fulfillment = 'pickup' and (p_from, p_to) = ('ready', 'delivered'))
    when 'client' then p_from in ('pending', 'accepted') and p_to = 'cancelled'
    when 'courier' then p_fulfillment = 'delivery'
      and (p_from, p_to) in (('ready', 'out_for_delivery'), ('out_for_delivery', 'delivered'))
    else false
  end
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

-- Notifications (0042) : app livreur, suivi de la boutique.
create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor', 'review_received', 'support_replied_vendor', 'low_stock',
    'substitution_answered', 'freshness_claimed', 'incoming_call_vendor',
    'courier_out_for_delivery', 'courier_delivered')
    then 'vendor'
    when p_kind in ('mission_available') then 'delivery'
    else 'client' end
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('courier_out_for_delivery', 'fr', 'Commande récupérée', 'Le livreur a récupéré la commande.'),
  ('courier_out_for_delivery', 'en', 'Order picked up', 'The courier picked up the order.'),
  ('courier_delivered', 'fr', 'Commande livrée', 'Le livreur a remis la commande à la cliente.'),
  ('courier_delivered', 'en', 'Order delivered', 'The courier handed the order to the customer.')
on conflict do nothing;

revoke all on function app.courier_json(uuid), public.my_courier_profile(),
  app.set_courier_zones(uuid, char, uuid[]), public.become_courier(text, text, text, uuid[]),
  public.set_courier_online(boolean), app.mission_open_for(uuid, uuid), app.mission_json(uuid, uuid),
  public.available_missions(), public.my_missions(), public.accept_mission(uuid), public.release_mission(uuid),
  public.courier_transition(uuid, text, text), app.notify_couriers() from public;
grant execute on function public.my_courier_profile(), public.become_courier(text, text, text, uuid[]),
  public.set_courier_online(boolean), public.available_missions(), public.my_missions(),
  public.accept_mission(uuid), public.release_mission(uuid), public.courier_transition(uuid, text, text)
  to authenticated;
