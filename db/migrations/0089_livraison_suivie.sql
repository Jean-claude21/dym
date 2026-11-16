-- Livraison suivie (spec 096) : frais par tranches de distance, position du livreur et suivi,
-- code de récupération, lien de suivi partagé, client injoignable et SOS, livreurs de la
-- boutique, validation des comptes vendeuse et livreur.

-- ------------------------------------------------------------------ drapeaux

-- Drapeau d'un pays, sinon le drapeau global, sinon coupé.
create or replace function app.flag_on(p_key text, p_country char(2))
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    (select f.is_enabled from public.feature_flags f where f.key = p_key and f.country_code = p_country),
    (select f.is_enabled from public.feature_flags f where f.key = p_key and f.country_code is null),
    false)
$$;
revoke all on function app.flag_on(text, char) from public;

insert into public.feature_flags (key, country_code, is_enabled, description)
select 'account_review', null, false,
       'Comptes vendeuse et livreur validés par l''équipe avant d''être visibles ou en ligne (spec 096)'
where not exists (select 1 from public.feature_flags where key = 'account_review' and country_code is null);

-- ------------------------------------------------------------------ frais par distance

create table public.delivery_fee_bands (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries (code),
  city_id uuid references public.cities (id),
  currency_code char(3) not null references public.currencies (code),
  max_distance_m integer not null check (max_distance_m between 100 and 100000),
  fee_minor bigint not null check (fee_minor >= 0),
  created_at timestamptz not null default now(),
  unique nulls not distinct (country_code, city_id, max_distance_m)
);
alter table public.delivery_fee_bands enable row level security;
create policy delivery_fee_bands_read on public.delivery_fee_bands for select
  to anonymous, authenticated using (true);
grant select on public.delivery_fee_bands to anonymous, authenticated;

-- Frais de la tranche qui contient la distance (ville d'abord, puis pays) ; nul sans tranche.
create or replace function app.distance_fee(p_country char(2), p_city uuid, p_meters numeric)
returns bigint
language sql stable security definer set search_path = ''
as $$
  select b.fee_minor from public.delivery_fee_bands b
  where b.country_code = p_country and (b.city_id = p_city or b.city_id is null)
    and p_meters is not null and b.max_distance_m >= p_meters
  order by b.city_id nulls last, b.max_distance_m
  limit 1
$$;
revoke all on function app.distance_fee(char, uuid, numeric) from public;

-- Admin : remplace les tranches d'un pays (ou d'une ville). Audité.
create or replace function public.admin_set_delivery_fee_bands(
  p_country char(2), p_city uuid, p_bands jsonb
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_currency char(3) := (select currency_code from public.countries where code = p_country);
  v_before jsonb;
  v_after jsonb;
begin
  if v_currency is null then raise exception 'pays inconnu' using errcode = 'P0002'; end if;
  if jsonb_typeof(coalesce(p_bands, 'null'::jsonb)) <> 'array' then
    raise exception 'bands_required' using errcode = '22023';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('max_distance_m', max_distance_m, 'fee_minor', fee_minor)
                            order by max_distance_m), '[]'::jsonb)
  into v_before from public.delivery_fee_bands
  where country_code = p_country and city_id is not distinct from p_city;
  delete from public.delivery_fee_bands where country_code = p_country and city_id is not distinct from p_city;
  insert into public.delivery_fee_bands (country_code, city_id, currency_code, max_distance_m, fee_minor)
  select p_country, p_city, v_currency, (b ->> 'max_distance_m')::int, (b ->> 'fee_minor')::bigint
  from jsonb_array_elements(p_bands) b;
  select coalesce(jsonb_agg(jsonb_build_object('max_distance_m', max_distance_m, 'fee_minor', fee_minor)
                            order by max_distance_m), '[]'::jsonb)
  into v_after from public.delivery_fee_bands
  where country_code = p_country and city_id is not distinct from p_city;
  perform app.audit(v_admin, 'delivery_fee_bands_set', 'country', p_country, v_before, v_after, null);
  return v_after;
end
$$;
revoke all on function public.admin_set_delivery_fee_bands(char, uuid, jsonb) from public;
grant execute on function public.admin_set_delivery_fee_bands(char, uuid, jsonb) to authenticated;

-- ------------------------------------------------------------------ vitesse et position du livreur

create table public.vehicle_speeds (
  vehicle text primary key check (vehicle in ('foot', 'bike', 'moto', 'car')),
  kmh smallint not null check (kmh between 3 and 80)
);
alter table public.vehicle_speeds enable row level security;
create policy vehicle_speeds_read on public.vehicle_speeds for select to anonymous, authenticated using (true);
grant select on public.vehicle_speeds to anonymous, authenticated;
insert into public.vehicle_speeds (vehicle, kmh) values ('foot', 5), ('bike', 12), ('moto', 22), ('car', 20);

-- Dernière position connue du livreur, envoyée pendant une course (jamais d'historique).
create table public.courier_positions (
  user_id uuid primary key references public.courier_profiles (user_id) on delete cascade,
  latitude numeric(9, 6) not null check (latitude between -90 and 90),
  longitude numeric(9, 6) not null check (longitude between -180 and 180),
  updated_at timestamptz not null default clock_timestamp()
);
alter table public.courier_positions enable row level security;
-- Aucune lecture directe : la position ne sort que par order_tracking et tracking_by_token.

create or replace function public.courier_ping(p_latitude numeric, p_longitude numeric)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  if not exists (select 1 from public.courier_profiles where user_id = v_user and status = 'active') then
    raise exception 'not_courier' using errcode = '42501';
  end if;
  -- Seulement pendant une course : sinon la position ne sert à rien et ne se garde pas.
  if not exists (select 1 from public.order_couriers oc join public.orders o on o.id = oc.order_id
                 where oc.courier_id = v_user and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery')) then
    delete from public.courier_positions where user_id = v_user;
    return;
  end if;
  insert into public.courier_positions (user_id, latitude, longitude)
  values (v_user, round(p_latitude, 6), round(p_longitude, 6))
  on conflict (user_id) do update set latitude = excluded.latitude, longitude = excluded.longitude,
    updated_at = clock_timestamp();
end
$$;
revoke all on function public.courier_ping(numeric, numeric) from public;
grant execute on function public.courier_ping(numeric, numeric) to authenticated;

-- Suivi d'une commande : points de la boutique, de la porte, du livreur ; minutes restantes.
-- p_precise : porte exacte (cliente, vendeuse) ou arrondie à ~100 m (lien partagé).
create or replace function app.tracking_json(p_order uuid, p_precise boolean)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  with o as (
    select o.*, pu.address, s.name as store_name, oc.courier_id, cp.display_name as courier_name,
           cp.vehicle, pos.latitude as c_lat, pos.longitude as c_lng, pos.updated_at as c_at,
           sp.lat as s_lat, sp.lng as s_lng,
           (pu.address ->> 'latitude')::numeric as d_lat, (pu.address ->> 'longitude')::numeric as d_lng
    from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    join public.stores s on s.id = o.store_id
    cross join lateral app.store_point(s.id) sp
    left join public.order_couriers oc on oc.order_id = o.id
    left join public.courier_profiles cp on cp.user_id = oc.courier_id
    left join public.courier_positions pos on pos.user_id = oc.courier_id
      and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery')
    where o.id = p_order
  )
  select jsonb_build_object(
    'order_id', o.id, 'status', o.status, 'fulfillment', o.fulfillment,
    'store', jsonb_build_object('name', o.store_name, 'latitude', o.s_lat, 'longitude', o.s_lng),
    'destination', case when o.d_lat is null then null else jsonb_build_object(
      'latitude', case when p_precise then o.d_lat else round(o.d_lat, 3) end,
      'longitude', case when p_precise then o.d_lng else round(o.d_lng, 3) end) end,
    'courier', case when o.courier_id is null then null else jsonb_build_object(
      'name', split_part(o.courier_name, ' ', 1), 'vehicle', o.vehicle,
      'latitude', o.c_lat, 'longitude', o.c_lng, 'updated_at', o.c_at) end,
    -- Minutes restantes : distance du livreur (via la boutique s'il n'a pas récupéré) à la porte.
    'eta_minutes', case
      when o.status = 'delivered' then 0
      when o.c_lat is null or o.d_lat is null then null
      else ceil((case when o.status = 'out_for_delivery'
                      then app.distance_m(o.c_lat, o.c_lng, o.d_lat, o.d_lng)
                      else app.distance_m(o.c_lat, o.c_lng, o.s_lat, o.s_lng)
                           + app.distance_m(o.s_lat, o.s_lng, o.d_lat, o.d_lng) end)
                / (coalesce((select kmh from public.vehicle_speeds v where v.vehicle = o.vehicle), 15) * 1000.0 / 60))::int
      end,
    'out_for_delivery_at', o.out_for_delivery_at, 'delivered_at', o.delivered_at)
  from o
$$;
revoke all on function app.tracking_json(uuid, boolean) from public;

-- Cliente de la commande, vendeuse (ou équipe) de la boutique, livreur assigné.
create or replace function public.order_tracking(p_order uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  if not exists (
    select 1 from public.orders o join public.purchases pu on pu.id = o.purchase_id
    left join public.order_couriers oc on oc.order_id = o.id
    where o.id = p_order
      and (pu.user_id = v_user or oc.courier_id = v_user or app.member_store_id(v_user) = o.store_id)
  ) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  return app.tracking_json(p_order, true);
end
$$;
revoke all on function public.order_tracking(uuid) from public;
grant execute on function public.order_tracking(uuid) to authenticated;

-- ------------------------------------------------------------------ lien de suivi partagé

create table public.tracking_links (
  token text primary key check (token ~ '^[A-Za-z0-9_-]{20,64}$'),
  order_id uuid not null references public.orders (id) on delete cascade,
  created_by uuid not null references neon_auth."user" (id) on delete cascade,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
alter table public.tracking_links enable row level security;
-- Aucune lecture directe : le jeton s'échange contre le suivi par tracking_by_token.

-- Cliente ou livreur : crée (ou reprend) un lien valable jusqu'à 2 h après la livraison.
create or replace function public.share_tracking(p_order uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_token text;
  v_expires timestamptz;
begin
  if not exists (
    select 1 from public.orders o join public.purchases pu on pu.id = o.purchase_id
    left join public.order_couriers oc on oc.order_id = o.id
    where o.id = p_order and o.fulfillment = 'delivery'
      and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery')
      and (pu.user_id = v_user or oc.courier_id = v_user)
  ) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  select token, expires_at into v_token, v_expires from public.tracking_links
  where order_id = p_order and created_by = v_user and expires_at > now()
  order by created_at desc limit 1;
  if v_token is null then
    v_token := replace(gen_random_uuid()::text, '-', '') || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
    v_expires := now() + interval '24 hours';
    insert into public.tracking_links (token, order_id, created_by, expires_at)
    values (v_token, p_order, v_user, v_expires);
    perform app.emit_event('tracking_shared', v_user,
      case when exists (select 1 from public.order_couriers oc where oc.order_id = p_order and oc.courier_id = v_user)
           then 'courier' else 'client' end,
      'server', null, 'order', p_order::text, '{}'::jsonb);
  end if;
  return jsonb_build_object('token', v_token, 'expires_at', v_expires);
end
$$;
revoke all on function public.share_tracking(uuid) from public;
grant execute on function public.share_tracking(uuid) to authenticated;

-- Lecture publique d'un lien : porte arrondie, aucun nom ni téléphone de la cliente.
create or replace function public.tracking_by_token(p_token text)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select app.tracking_json(l.order_id, false)
  from public.tracking_links l
  join public.orders o on o.id = l.order_id
  where l.token = p_token
    and l.expires_at > now()
    and (o.delivered_at is null or o.delivered_at > now() - interval '2 hours')
$$;
revoke all on function public.tracking_by_token(text) from public;
grant execute on function public.tracking_by_token(text) to anonymous, authenticated;

-- ------------------------------------------------------------------ code de récupération

alter table public.order_couriers
  add column pickup_code text check (pickup_code ~ '^[0-9]{6}$'),
  add column pickup_attempts smallint not null default 0;

-- Livreur assigné : code à 6 chiffres montré en QR à la vendeuse.
create or replace function public.my_pickup_code(p_order uuid)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_code text;
begin
  select oc.pickup_code into v_code from public.order_couriers oc
  join public.orders o on o.id = oc.order_id
  where oc.order_id = p_order and oc.courier_id = v_user and o.status in ('accepted', 'preparing', 'ready');
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_code is null then
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    update public.order_couriers set pickup_code = v_code where order_id = p_order;
  end if;
  return v_code;
end
$$;
revoke all on function public.my_pickup_code(uuid) from public;
grant execute on function public.my_pickup_code(uuid) to authenticated;

-- Vendeuse (ou équipe) : scanne le QR du livreur ; la commande part avec lui.
create or replace function public.store_confirm_pickup(p_order uuid, p_code text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
  v_oc public.order_couriers;
begin
  select oc.* into v_oc from public.order_couriers oc
  join public.orders o on o.id = oc.order_id
  where oc.order_id = p_order and o.store_id = v_store and o.status = 'ready' and oc.courier_id is not null
  for update of oc;
  if v_oc.order_id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_oc.pickup_attempts >= 5 then raise exception 'code_locked' using errcode = 'P0001'; end if;
  if v_oc.pickup_code is null or btrim(coalesce(p_code, '')) <> v_oc.pickup_code then
    update public.order_couriers set pickup_attempts = pickup_attempts + 1 where order_id = p_order;
    return jsonb_build_object('ok', false, 'attempts_left', greatest(0, 4 - v_oc.pickup_attempts));
  end if;
  perform set_config('dym.pickup_confirmed', p_order::text, true);
  perform app.transition_order(v_oc.courier_id, p_order, 'out_for_delivery', 'ready');
  perform set_config('dym.pickup_confirmed', '', true);
  return jsonb_build_object('ok', true, 'status', 'out_for_delivery');
end
$$;
revoke all on function public.store_confirm_pickup(uuid, text) from public;
grant execute on function public.store_confirm_pickup(uuid, text) to authenticated;
insert into public.store_function_permissions (function_name, permission)
values ('public.store_confirm_pickup', 'orders') on conflict do nothing;

-- ------------------------------------------------------------------ injoignable et SOS

create table public.delivery_incidents (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('unreachable', 'sos')),
  courier_id uuid not null references public.courier_profiles (user_id) on delete cascade,
  order_id uuid references public.orders (id) on delete set null,
  latitude numeric(9, 6),
  longitude numeric(9, 6),
  note text check (note is null or length(note) <= 280),
  resolved_at timestamptz,
  resolved_by uuid,
  created_at timestamptz not null default now()
);
alter table public.delivery_incidents enable row level security;
-- Lecture par les fonctions seulement (admin, livreur concerné).

-- Livreur devant la porte, cliente injoignable : elle est prévenue, l'équipe le voit.
create or replace function public.courier_report_unreachable(p_order uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_client uuid;
begin
  select pu.user_id into v_client from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.order_couriers oc on oc.order_id = o.id and oc.courier_id = v_user
  where o.id = p_order and o.status = 'out_for_delivery';
  if v_client is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  insert into public.delivery_incidents (kind, courier_id, order_id) values ('unreachable', v_user, p_order);
  perform app.notify(v_client, 'courier_at_door', 'orders', p_order, null,
    jsonb_build_object('courier_name', (select split_part(display_name, ' ', 1)
                                        from public.courier_profiles where user_id = v_user)));
  perform app.emit_event('courier_unreachable_reported', v_user, 'courier', 'server', null, 'order',
    p_order::text, '{}'::jsonb);
  return jsonb_build_object('ok', true, 'wait_minutes', 10);
end
$$;
revoke all on function public.courier_report_unreachable(uuid) from public;
grant execute on function public.courier_report_unreachable(uuid) to authenticated;

-- SOS : alerte immédiate de l'équipe, avec la position si elle est donnée.
create or replace function public.courier_sos(
  p_order uuid default null, p_latitude numeric default null, p_longitude numeric default null,
  p_note text default null
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_id uuid;
begin
  if not exists (select 1 from public.courier_profiles where user_id = v_user) then
    raise exception 'not_courier' using errcode = '42501';
  end if;
  insert into public.delivery_incidents (kind, courier_id, order_id, latitude, longitude, note)
  values ('sos', v_user,
          (select oc.order_id from public.order_couriers oc where oc.order_id = p_order and oc.courier_id = v_user),
          p_latitude, p_longitude, left(nullif(btrim(p_note), ''), 280))
  returning id into v_id;
  perform app.emit_event('courier_sos', v_user, 'courier', 'server', null, 'incident', v_id::text, '{}'::jsonb);
  return jsonb_build_object('id', v_id);
end
$$;
revoke all on function public.courier_sos(uuid, numeric, numeric, text) from public;
grant execute on function public.courier_sos(uuid, numeric, numeric, text) to authenticated;

create or replace function public.admin_delivery_incidents(p_open_only boolean default true)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', i.id, 'kind', i.kind, 'order_id', i.order_id, 'courier_name', cp.display_name,
      'courier_phone', cp.phone, 'latitude', i.latitude, 'longitude', i.longitude, 'note', i.note,
      'created_at', i.created_at, 'resolved_at', i.resolved_at)
      order by (i.kind = 'sos') desc, i.created_at desc)
    from public.delivery_incidents i
    join public.courier_profiles cp on cp.user_id = i.courier_id
    where not p_open_only or i.resolved_at is null), '[]'::jsonb);
end
$$;
revoke all on function public.admin_delivery_incidents(boolean) from public;
grant execute on function public.admin_delivery_incidents(boolean) to authenticated;

create or replace function public.admin_resolve_incident(p_incident uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
begin
  update public.delivery_incidents set resolved_at = now(), resolved_by = v_admin
  where id = p_incident and resolved_at is null;
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  perform app.audit(v_admin, 'delivery_incident_resolved', 'incident', p_incident::text, null, null, null);
end
$$;
revoke all on function public.admin_resolve_incident(uuid) from public;
grant execute on function public.admin_resolve_incident(uuid) to authenticated;

-- ------------------------------------------------------------------ livreurs de la boutique

create table public.store_couriers (
  store_id uuid not null references public.stores (id) on delete cascade,
  courier_id uuid not null references public.courier_profiles (user_id) on delete cascade,
  added_by uuid not null,
  created_at timestamptz not null default now(),
  primary key (store_id, courier_id)
);
alter table public.store_couriers enable row level security;
-- Lecture par les fonctions de la boutique seulement.

create or replace function app.store_couriers_json(p_store uuid)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'courier_id', cp.user_id, 'name', cp.display_name, 'phone', cp.phone, 'vehicle', cp.vehicle,
    'status', cp.status, 'is_online', cp.is_online,
    'busy', exists (select 1 from public.order_couriers oc join public.orders o on o.id = oc.order_id
                    where oc.courier_id = cp.user_id
                      and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery')))
    order by cp.is_online desc, cp.display_name), '[]'::jsonb)
  from public.store_couriers sc
  join public.courier_profiles cp on cp.user_id = sc.courier_id
  where sc.store_id = p_store
$$;
revoke all on function app.store_couriers_json(uuid) from public;

create or replace function public.my_store_couriers()
returns jsonb
language sql stable security definer set search_path = ''
as $$ select app.store_couriers_json(app.own_store_id()) $$;
revoke all on function public.my_store_couriers() from public;
grant execute on function public.my_store_couriers() to authenticated;

-- Ajout par le numéro du livreur (compte livreur du même pays, validé).
create or replace function public.store_add_courier(p_phone text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_store uuid := app.own_store_id();
  v_courier uuid;
  v_digits text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
begin
  if length(v_digits) < 8 then raise exception 'phone_invalid' using errcode = '22023'; end if;
  select cp.user_id into v_courier from public.courier_profiles cp
  join public.stores s on s.id = v_store and s.country_code = cp.country_code
  where cp.status = 'active'
    and right(regexp_replace(cp.phone, '[^0-9]', '', 'g'), 8) = right(v_digits, 8)
  limit 1;
  if v_courier is null then raise exception 'courier_not_found' using errcode = 'P0002'; end if;
  insert into public.store_couriers (store_id, courier_id, added_by) values (v_store, v_courier, v_user)
  on conflict do nothing;
  perform app.notify(v_courier, 'store_courier_added', 'orders', null, null,
    jsonb_build_object('store_name', (select name from public.stores where id = v_store)));
  return app.store_couriers_json(v_store);
end
$$;
revoke all on function public.store_add_courier(text) from public;
grant execute on function public.store_add_courier(text) to authenticated;

create or replace function public.store_remove_courier(p_courier uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
begin
  delete from public.store_couriers where store_id = v_store and courier_id = p_courier;
  return app.store_couriers_json(v_store);
end
$$;
revoke all on function public.store_remove_courier(uuid) from public;
grant execute on function public.store_remove_courier(uuid) to authenticated;

-- La vendeuse confie une commande à un de ses livreurs ; il la voit dans ses courses.
create or replace function public.store_assign_courier(p_order uuid, p_courier uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_store uuid := app.own_store_id();
  v_profile public.courier_profiles;
begin
  if not exists (select 1 from public.orders o where o.id = p_order and o.store_id = v_store
                 and o.fulfillment = 'delivery' and o.status in ('accepted', 'preparing', 'ready')) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.order_couriers where order_id = p_order and courier_id is not null) then
    raise exception 'courier_already_assigned' using errcode = 'P0001';
  end if;
  select cp.* into v_profile from public.courier_profiles cp
  join public.store_couriers sc on sc.courier_id = cp.user_id and sc.store_id = v_store
  where cp.user_id = p_courier and cp.status = 'active';
  if v_profile.user_id is null then raise exception 'courier_not_found' using errcode = 'P0002'; end if;
  insert into public.order_couriers (order_id, name, phone, courier_id, accepted_at, assigned_by)
  values (p_order, v_profile.display_name, v_profile.phone, p_courier, now(), v_user)
  on conflict (order_id) do update set name = excluded.name, phone = excluded.phone,
    courier_id = excluded.courier_id, accepted_at = excluded.accepted_at, assigned_by = excluded.assigned_by,
    assigned_at = now(), pickup_code = null, pickup_attempts = 0;
  perform app.notify(p_courier, 'store_mission_assigned', 'orders', p_order, null,
    jsonb_build_object('store_name', (select name from public.stores where id = v_store)));
  return jsonb_build_object('ok', true);
end
$$;
revoke all on function public.store_assign_courier(uuid, uuid) from public;
grant execute on function public.store_assign_courier(uuid, uuid) to authenticated;
insert into public.store_function_permissions (function_name, permission) values
  ('public.my_store_couriers', 'orders'), ('public.store_add_courier', 'orders'),
  ('public.store_remove_courier', 'orders'), ('public.store_assign_courier', 'orders')
on conflict do nothing;

-- ------------------------------------------------------------------ validation des comptes

alter table public.courier_profiles drop constraint courier_profiles_status_check;
alter table public.courier_profiles add constraint courier_profiles_status_check
  check (status in ('pending', 'active', 'rejected', 'suspended'));
alter table public.courier_profiles add column review_note text check (review_note is null or length(review_note) <= 280);

alter table public.stores drop constraint stores_status_check;
alter table public.stores add constraint stores_status_check
  check (status in ('draft', 'review', 'active', 'rejected', 'suspended'));
alter table public.stores add column review_note text check (review_note is null or length(review_note) <= 280);

create or replace function public.admin_pending_accounts()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return jsonb_build_object(
    'stores', coalesce((select jsonb_agg(jsonb_build_object(
        'id', s.id, 'name', s.name, 'origin', s.origin, 'country_code', s.country_code,
        'zone_name', (select z.name from public.zones z where z.id = s.zone_id),
        'owner_email', (select u.email from neon_auth."user" u where u.id = s.owner_id),
        'product_count', (select count(*) from public.products p where p.store_id = s.id),
        'created_at', s.created_at) order by s.updated_at)
      from public.stores s where s.status = 'review'), '[]'::jsonb),
    'couriers', coalesce((select jsonb_agg(jsonb_build_object(
        'id', cp.user_id, 'name', cp.display_name, 'phone', cp.phone, 'vehicle', cp.vehicle,
        'country_code', cp.country_code, 'created_at', cp.created_at) order by cp.created_at)
      from public.courier_profiles cp where cp.status = 'pending'), '[]'::jsonb));
end
$$;
revoke all on function public.admin_pending_accounts() from public;
grant execute on function public.admin_pending_accounts() to authenticated;

-- Valider ou refuser (motif obligatoire au refus). Audité et notifié.
create or replace function public.admin_review_account(
  p_kind text, p_id uuid, p_approve boolean, p_note text default null
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_owner uuid;
  v_before text;
  v_after text := case when p_approve then 'active' else 'rejected' end;
  v_note text := left(nullif(btrim(p_note), ''), 280);
begin
  if not p_approve and v_note is null then raise exception 'reason_required' using errcode = 'P0001'; end if;
  if p_kind = 'store' then
    select owner_id, status into v_owner, v_before from public.stores where id = p_id for update;
    if v_before is distinct from 'review' then raise exception 'not_found' using errcode = 'P0002'; end if;
    update public.stores set status = v_after, review_note = v_note, updated_at = now() where id = p_id;
    perform app.notify(v_owner, case when p_approve then 'store_approved' else 'store_rejected' end,
      'orders', null, null, jsonb_build_object('note', coalesce(v_note, '')));
  elsif p_kind = 'courier' then
    select user_id, status into v_owner, v_before from public.courier_profiles where user_id = p_id for update;
    if v_before is distinct from 'pending' then raise exception 'not_found' using errcode = 'P0002'; end if;
    update public.courier_profiles set status = v_after, review_note = v_note, updated_at = clock_timestamp()
    where user_id = p_id;
    perform app.notify(v_owner, case when p_approve then 'courier_approved' else 'courier_rejected' end,
      'orders', null, null, jsonb_build_object('note', coalesce(v_note, '')));
  else
    raise exception 'kind_invalid' using errcode = '22023';
  end if;
  perform app.audit(v_admin, 'account_reviewed', p_kind, p_id::text,
    jsonb_build_object('status', v_before), jsonb_build_object('status', v_after), v_note);
end
$$;
revoke all on function public.admin_review_account(text, uuid, boolean, text) from public;
grant execute on function public.admin_review_account(text, uuid, boolean, text) to authenticated;

-- ------------------------------------------------------------------ textes des notifications

insert into public.notification_templates (kind, locale, title, body) values
  ('courier_at_door', 'fr', 'Ton livreur est devant chez toi', '{courier_name} n''arrive pas à te joindre. Réponds-lui vite.'),
  ('courier_at_door', 'en', 'Your courier is at your door', '{courier_name} can''t reach you. Please answer.'),
  ('store_courier_added', 'fr', 'Nouvelle boutique', '{store_name} t''a ajouté à ses livreurs.'),
  ('store_courier_added', 'en', 'New shop', '{store_name} added you to its couriers.'),
  ('store_mission_assigned', 'fr', 'Course confiée', '{store_name} te confie une livraison.'),
  ('store_mission_assigned', 'en', 'Delivery assigned', '{store_name} gave you a delivery.'),
  ('store_approved', 'fr', 'Boutique validée', 'Ta boutique est en ligne : ouvre-la quand tu es prête.'),
  ('store_approved', 'en', 'Shop approved', 'Your shop is live: open it when you are ready.'),
  ('store_rejected', 'fr', 'Boutique à revoir', '{note}'),
  ('store_rejected', 'en', 'Shop to review', '{note}'),
  ('courier_approved', 'fr', 'Compte livreur validé', 'Tu peux passer en ligne et accepter des courses.'),
  ('courier_approved', 'en', 'Courier account approved', 'You can go online and accept deliveries.'),
  ('courier_rejected', 'fr', 'Compte livreur à revoir', '{note}'),
  ('courier_rejected', 'en', 'Courier account to review', '{note}');

insert into public.event_names (name, emitted_by, description) values
  ('tracking_shared', 'server', 'Lien de suivi partagé (spec 096)'),
  ('courier_unreachable_reported', 'server', 'Livreur : cliente injoignable (spec 096)'),
  ('courier_sos', 'server', 'Livreur : alerte SOS (spec 096)'),
  ('pickup_confirmed', 'server', 'Code de récupération scanné par la vendeuse (spec 096)')
on conflict do nothing;

insert into public.admin_function_permissions (function_name, permission_code) values
  ('public.admin_set_delivery_fee_bands', 'catalog.write'),
  ('public.admin_delivery_incidents', 'orders.read'),
  ('public.admin_resolve_incident', 'orders.write'),
  ('public.admin_pending_accounts', 'stores.read'),
  ('public.admin_review_account', 'stores.write')
on conflict do nothing;

-- Profil livreur : motif de refus visible par le livreur.
create or replace function app.courier_json(p_user uuid)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('display_name', c.display_name, 'phone', c.phone, 'vehicle', c.vehicle,
    'status', c.status, 'review_note', c.review_note, 'is_online', c.is_online, 'country_code', c.country_code,
    'zone_ids', coalesce((select jsonb_agg(z.zone_id order by z.zone_id) from public.courier_zones z
                          where z.user_id = c.user_id), '[]'::jsonb))
  from public.courier_profiles c where c.user_id = p_user
$$;

-- ------------------------------------------------------------------ fonctions existantes modifiées

drop function app.cart_quote(uuid, uuid, jsonb, uuid, timestamptz);
CREATE OR REPLACE FUNCTION app.cart_quote(p_cart uuid, p_zone uuid, p_modes jsonb, p_payment_method uuid, p_at timestamp with time zone, p_latitude numeric DEFAULT NULL::numeric, p_longitude numeric DEFAULT NULL::numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_cart public.carts;
  v_city uuid := (select city_id from public.zones where id = p_zone);
  v_base bigint;
  v_extra bigint;
  v_threshold bigint;
  v_methods jsonb;
  v_method uuid;
  v_stores jsonb;
  v_delivered_subtotal bigint;
  v_result jsonb;
begin
  select * into v_cart from public.carts where id = p_cart;

  select d.base_fee_minor, d.extra_pickup_fee_minor, d.free_threshold_minor
  into v_base, v_extra, v_threshold
  from public.delivery_fee_defaults d
  where d.country_code = v_cart.country_code and d.valid_to is null
    and (d.city_id = v_city or d.city_id is null)
  order by d.city_id nulls last
  limit 1;

  -- Moyens actifs du pays acceptés par toutes les boutiques du panier.
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', pm.id, 'country_code', pm.country_code, 'provider_code', pm.provider_code,
           'operator_code', pm.operator_code, 'label', pm.label, 'sort', pm.sort) order by pm.sort), '[]'::jsonb)
  into v_methods
  from public.payment_methods pm
  where pm.country_code = v_cart.country_code and pm.is_active
    and not exists (
      select 1 from public.cart_items ci
      join public.product_variants v on v.id = ci.variant_id
      join public.products p on p.id = v.product_id
      where ci.cart_id = p_cart
        and not exists (select 1 from public.store_payment_methods spm
                        where spm.store_id = p.store_id and spm.payment_method_id = pm.id));
  v_method := coalesce(
    (select (m ->> 'id')::uuid from jsonb_array_elements(v_methods) m
     where (m ->> 'id')::uuid = p_payment_method),
    (v_methods -> 0 ->> 'id')::uuid);

  with lines as (
    select ci.variant_id, ci.quantity, ci.added_at, p.id as product_id, p.name, p.category_id,
           v.label as variant_label, v.stock_quantity, u.label as unit_label,
           (select f.object_key from public.product_photos f where f.product_id = p.id
            order by f.sort limit 1) as photo_key,
           app.cart_line_price(p_cart, v.id, ci.quantity) as unit_price, app.variant_price(v.id) as list_price,
           app.cart_line_source(p_cart, v.id, ci.quantity) as price_source,
           ci.unit_price_seen_minor,
           p.store_id,
           array_remove(array[
             case when p.status <> 'published' or not p.is_available
                    or v.stock_quantity = 0 then 'unavailable' end,
             case when v.stock_quantity > 0 and ci.quantity > v.stock_quantity then 'stock' end,
             case when app.cart_line_price(p_cart, v.id, ci.quantity) <> ci.unit_price_seen_minor then 'price_changed' end
           ], null) as issues
    from public.cart_items ci
    join public.product_variants v on v.id = ci.variant_id
    join public.products p on p.id = v.product_id
    left join public.units u on u.id = p.unit_id
    where ci.cart_id = p_cart
  ),
  stores as (
    select s.id, s.name, s.origin, z.name as zone_name, z.city_id as store_city, s.offers_pickup, app.cart_store_fee(p_cart, s.id) as own_fee,
           (select app.distance_m(sp.lat, sp.lng, p_latitude, p_longitude)
            from app.store_point(s.id) sp where sp.lat is not null and p_latitude is not null) as meters,
           s.prep_time_minutes,
           case when coalesce(p_modes ->> s.id::text, 'delivery') = 'pickup' then 'pickup' else 'delivery' end
             as fulfillment,
           app.store_open_at(s.id, p_at) as is_open,
           sum(l.unit_price * l.quantity) as subtotal,
           jsonb_agg(jsonb_build_object(
             'variant_id', l.variant_id, 'product_id', l.product_id, 'name', l.name,
             'variant_label', l.variant_label, 'unit_label', l.unit_label, 'photo_key', l.photo_key,
             'quantity', l.quantity, 'unit_price_minor', l.unit_price, 'list_price_minor', l.list_price, 'price_source', l.price_source,
             'amount_minor', l.unit_price * l.quantity, 'stock_quantity', l.stock_quantity,
             'category_id', l.category_id, 'issues', to_jsonb(l.issues))
             order by l.added_at, l.variant_id) as lines,
           min(l.added_at) as first_added
    from lines l
    join public.stores s on s.id = l.store_id
    join public.zones z on z.id = s.zone_id
    group by s.id, z.name, z.city_id
  ),
  checked as (
    select st.*,
           array_remove(array[
             case when (select status from public.stores where id = st.id) <> 'active' then 'suspended' end,
             case when (select status from public.stores where id = st.id) = 'active' and not st.is_open
                  then 'closed' end,
             case when st.fulfillment = 'delivery'
                    and (p_zone is not null or p_latitude is not null)
                    and not (coalesce(app.store_serves(st.id, p_zone), false)
                             or coalesce(app.store_serves_point(st.id, p_latitude, p_longitude), false))
                  then 'not_delivered' end,
             case when st.fulfillment = 'pickup' and not st.offers_pickup then 'pickup_unavailable' end,
             case when p_payment_method is not null and not exists (
                    select 1 from public.store_payment_methods spm
                    where spm.store_id = st.id and spm.payment_method_id = p_payment_method)
                  then 'payment_not_accepted' end
           ], null) as issues
    from stores st
  ),
  ranked as (
    select c.*,
           case when c.fulfillment = 'delivery'
                then row_number() over (partition by c.fulfillment order by c.subtotal desc, c.id) end
             as delivery_rank
    from checked c
  )
  select jsonb_agg(jsonb_build_object(
           'id', r.id, 'name', r.name, 'origin', r.origin, 'zone_name', r.zone_name,
           'fulfillment', r.fulfillment, 'offers_pickup', r.offers_pickup, 'is_open', r.is_open,
           'prep_time_minutes', r.prep_time_minutes,
           'issues', to_jsonb(r.issues), 'subtotal_minor', r.subtotal,
           'delivery_rank', r.delivery_rank,
           'own_fee_minor', r.own_fee,
           -- Frais par tranche de distance (spec 096) : de la boutique à la porte.
           'distance_m', round(r.meters)::int,
           'distance_fee_minor', app.distance_fee(v_cart.country_code, coalesce(v_city, r.store_city), r.meters::numeric),
           'lines', r.lines)
           order by r.first_added, r.id)
  into v_stores
  from ranked r;

  v_stores := coalesce(v_stores, '[]'::jsonb);
  select coalesce(sum((s ->> 'subtotal_minor')::bigint), 0) into v_delivered_subtotal
  from jsonb_array_elements(v_stores) s where s ->> 'fulfillment' = 'delivery';

  -- Frais par boutique.
  select coalesce(jsonb_agg(
           (s - 'delivery_rank' - 'own_fee_minor' - 'distance_fee_minor') || jsonb_build_object(
             'delivery_fee_minor',
             case
               when s ->> 'fulfillment' <> 'delivery' then 0
               when v_threshold is not null and v_delivered_subtotal >= v_threshold then 0
               when (s ->> 'delivery_rank')::int = 1
                 then coalesce((s ->> 'own_fee_minor')::bigint, (s ->> 'distance_fee_minor')::bigint, v_base, 0)
               else coalesce(v_extra, 0)
             end)
           order by o), '[]'::jsonb)
  into v_stores
  from jsonb_array_elements(v_stores) with ordinality as e(s, o);

  select jsonb_build_object(
    'country_code', v_cart.country_code,
    'currency_code', v_cart.currency_code,
    'currency', (select to_jsonb(cu) - 'created_at' - 'updated_at' from public.currencies cu
                 where cu.code = v_cart.currency_code),
    'stores', v_stores,
    'payment_methods', v_methods,
    'payment_method_id', v_method,
    'item_count', coalesce((select sum((l ->> 'quantity')::int)
                            from jsonb_array_elements(v_stores) s,
                                 jsonb_array_elements(s -> 'lines') l), 0),
    'pickup_count', (select count(*) from jsonb_array_elements(v_stores) s
                     where s ->> 'fulfillment' = 'delivery'),
    'delivery_minutes', coalesce((select delivery_minutes from public.cities where id = v_city), 0)
      + coalesce((select max((s ->> 'prep_time_minutes')::int) from jsonb_array_elements(v_stores) s), 0),
    'subtotal_minor', coalesce((select sum((s ->> 'subtotal_minor')::bigint)
                                from jsonb_array_elements(v_stores) s), 0),
    'delivery_fee_minor', coalesce((select sum((s ->> 'delivery_fee_minor')::bigint)
                                    from jsonb_array_elements(v_stores) s), 0),
    'free_threshold_minor', v_threshold,
    'remaining_for_free_minor', case when v_threshold is null then null
                                     else greatest(v_threshold - v_delivered_subtotal, 0) end,
    'blocking', exists (
      select 1 from jsonb_array_elements(v_stores) s
      where jsonb_array_length(s -> 'issues') > 0
         or exists (select 1 from jsonb_array_elements(s -> 'lines') l
                    where l -> 'issues' ?| array['unavailable', 'stock'])))
  into v_result;

  return v_result || jsonb_build_object(
    'total_minor', (v_result ->> 'subtotal_minor')::bigint + (v_result ->> 'delivery_fee_minor')::bigint);
end
$function$;
revoke all on function app.cart_quote(uuid, uuid, jsonb, uuid, timestamptz, numeric, numeric) from public;

CREATE OR REPLACE FUNCTION public.my_cart(p_address uuid DEFAULT NULL::uuid, p_modes jsonb DEFAULT '{}'::jsonb, p_payment_method uuid DEFAULT NULL::uuid, p_at timestamp with time zone DEFAULT now(), p_slot jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.require_user();
  v_cart public.carts;
  v_address public.customer_addresses;
  v_zone uuid;
  v_country char(2);
begin
  select * into v_cart from public.carts where user_id = v_user;
  if v_cart.id is null or not exists (select 1 from public.cart_items where cart_id = v_cart.id) then
    v_country := coalesce(v_cart.country_code, (select country_code from public.profiles where user_id = v_user));
    return app.empty_cart(v_country);
  end if;
  v_address := app.delivery_address(v_user, p_address, v_cart.country_code);
  v_zone := coalesce(v_address.zone_id,
    (select p.zone_id from public.profiles p
     join public.zones z on z.id = p.zone_id join public.cities c on c.id = z.city_id
     where p.user_id = v_user and c.country_code = v_cart.country_code));
  return app.cart_quote(v_cart.id, v_zone, coalesce(p_modes, '{}'::jsonb), p_payment_method,
                        coalesce(app.slot_start(v_cart.country_code, p_slot), p_at),
                        v_address.latitude, v_address.longitude)
    || jsonb_build_object('address_id', v_address.id, 'zone_id', v_zone);
end
$function$;

CREATE OR REPLACE FUNCTION app.place_order(p_user uuid, p_key uuid, p_request jsonb, p_at timestamp with time zone DEFAULT now(), p_online_providers text[] DEFAULT '{}'::text[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_existing uuid;
  v_cart public.carts;
  v_address public.customer_addresses;
  v_zone uuid;
  v_method public.payment_methods;
  v_quote jsonb;
  v_purchase uuid;
  v_order uuid;
  v_store jsonb;
  v_line jsonb;
  v_commission bigint;
  v_expected bigint := (p_request ->> 'expected_total_minor')::bigint;
begin
  if p_user is null or p_key is null then
    raise exception 'utilisateur et clé obligatoires' using errcode = '22023';
  end if;
  select id into v_existing from public.purchases where user_id = p_user and idempotency_key = p_key;
  if v_existing is not null then
    return jsonb_build_object('replayed', true, 'purchase', app.purchase_json(v_existing));
  end if;

  select * into v_cart from public.carts where user_id = p_user for update;
  -- Une demande concurrente avec la même clé a pu finir pendant l'attente.
  select id into v_existing from public.purchases where user_id = p_user and idempotency_key = p_key;
  if v_existing is not null then
    return jsonb_build_object('replayed', true, 'purchase', app.purchase_json(v_existing));
  end if;
  if v_cart.id is null or not exists (select 1 from public.cart_items where cart_id = v_cart.id) then
    raise exception 'cart_empty' using errcode = 'P0001';
  end if;
  -- Stocks verrouillés avant le devis : il reste vrai jusqu'à la fin.
  perform 1 from public.product_variants v
  join public.cart_items ci on ci.variant_id = v.id
  where ci.cart_id = v_cart.id
  for update of v;

  if p_request ->> 'address_id' is not null then
    v_address := app.delivery_address(p_user, (p_request ->> 'address_id')::uuid, v_cart.country_code);
  end if;
  v_zone := v_address.zone_id;
  select * into v_method from public.payment_methods where id = (p_request ->> 'payment_method_id')::uuid;
  v_quote := app.cart_quote(v_cart.id, v_zone, coalesce(p_request -> 'modes', '{}'::jsonb), v_method.id, p_at,
    v_address.latitude, v_address.longitude);

  if v_address.id is null and exists (
    select 1 from jsonb_array_elements(v_quote -> 'stores') s where s ->> 'fulfillment' = 'delivery'
  ) then
    raise exception 'address_required' using errcode = 'P0001';
  end if;
  if v_method.id is null or not exists (
    select 1 from jsonb_array_elements(v_quote -> 'payment_methods') m where (m ->> 'id')::uuid = v_method.id
  ) then
    raise exception 'payment_not_accepted' using errcode = 'P0001';
  end if;
  if (v_quote ->> 'blocking')::boolean then
    raise exception 'cart_blocked' using errcode = 'P0001';
  end if;
  -- Moyen en ligne : seulement si son fournisseur est disponible ici.
  if v_method.provider_code <> 'cash'
     and not v_method.provider_code = any(coalesce(p_online_providers, '{}')) then
    raise exception 'payment_unavailable' using errcode = 'P0001';
  end if;
  if v_expected is not null and v_expected <> (v_quote ->> 'total_minor')::bigint then
    raise exception 'total_changed' using errcode = 'P0001';
  end if;

  insert into public.purchases (
    user_id, idempotency_key, country_code, currency_code, payment_method_id, address,
    substitution_allowed, subtotal_minor, delivery_fee_minor, total_minor, payment_status)
  values (
    p_user, p_key, v_cart.country_code, v_cart.currency_code, v_method.id,
    case when v_address.id is null then null else (
      select jsonb_build_object(
        'id', v_address.id, 'kind', v_address.kind, 'label', v_address.label,
        'zone_id', z.id, 'zone_name', z.name, 'city_name', c.name,
        'landmark', v_address.landmark, 'phone', v_address.phone,
        'latitude', v_address.latitude, 'longitude', v_address.longitude)
      from public.zones z join public.cities c on c.id = z.city_id where z.id = v_address.zone_id)
    end,
    coalesce((p_request ->> 'substitution_allowed')::boolean, true),
    (v_quote ->> 'subtotal_minor')::bigint, (v_quote ->> 'delivery_fee_minor')::bigint,
    (v_quote ->> 'total_minor')::bigint,
    case when v_method.provider_code = 'cash' then 'cash_on_delivery' else 'awaiting_payment' end)
  returning id into v_purchase;

  -- Moyen en ligne : première tentative, que la Function initie ensuite.
  if v_method.provider_code <> 'cash' then
    insert into public.payments (
      purchase_id, payment_method_id, provider_code, amount_minor, currency_code, idempotency_key)
    values (
      v_purchase, v_method.id, v_method.provider_code, (v_quote ->> 'total_minor')::bigint,
      v_cart.currency_code, p_key);
  end if;

  for v_store in select * from jsonb_array_elements(v_quote -> 'stores') loop
    select coalesce(sum(floor((l ->> 'amount_minor')::bigint
             * app.commission_rate(v_cart.country_code, (l ->> 'category_id')::uuid) / 10000.0)), 0)
    into v_commission
    from jsonb_array_elements(v_store -> 'lines') l;

    insert into public.orders (
      purchase_id, store_id, fulfillment, currency_code,
      subtotal_minor, delivery_fee_minor, total_minor, commission_minor)
    values (
      v_purchase, (v_store ->> 'id')::uuid, v_store ->> 'fulfillment', v_cart.currency_code,
      (v_store ->> 'subtotal_minor')::bigint, (v_store ->> 'delivery_fee_minor')::bigint,
      (v_store ->> 'subtotal_minor')::bigint + (v_store ->> 'delivery_fee_minor')::bigint,
      v_commission)
    returning id into v_order;

    for v_line in select * from jsonb_array_elements(v_store -> 'lines') loop
      insert into public.order_items (
        order_id, product_id, variant_id, product_name, variant_label, unit_label,
        unit_price_minor, quantity, amount_minor)
      values (
        v_order, (v_line ->> 'product_id')::uuid, (v_line ->> 'variant_id')::uuid,
        v_line ->> 'name', v_line ->> 'variant_label', v_line -> 'unit_label',
        (v_line ->> 'unit_price_minor')::bigint, (v_line ->> 'quantity')::smallint,
        (v_line ->> 'amount_minor')::bigint);
      update public.product_variants
      set stock_quantity = stock_quantity - (v_line ->> 'quantity')::int
      where id = (v_line ->> 'variant_id')::uuid and stock_quantity is not null;
    end loop;
  end loop;

  delete from public.cart_items where cart_id = v_cart.id;
  update public.carts set updated_at = now() where id = v_cart.id;

  perform app.emit_event(
    'order_created', p_user, 'client', 'server', v_cart.country_code, 'purchase', v_purchase::text,
    jsonb_build_object(
      'stores_count', jsonb_array_length(v_quote -> 'stores'),
      'items_count', (v_quote ->> 'item_count')::int,
      'delivery_count', (v_quote ->> 'pickup_count')::int,
      'payment_provider', v_method.provider_code));

  return jsonb_build_object('replayed', false, 'purchase', app.purchase_json(v_purchase));
end
$function$;

CREATE OR REPLACE FUNCTION public.courier_transition(p_order uuid, p_to text, p_expected text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.require_user();
begin
  if p_to = 'delivered' then raise exception 'code_required' using errcode = 'P0001'; end if;
  -- Spec 096 : la vendeuse scanne le code du livreur (store_confirm_pickup).
  if p_to = 'out_for_delivery' then raise exception 'pickup_code_required' using errcode = 'P0001'; end if;
  perform app.transition_order(v_user, p_order, p_to, p_expected);
  return app.mission_json(p_order, v_user);
end
$function$;

CREATE OR REPLACE FUNCTION app.notification_app(p_kind text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor', 'review_received', 'support_replied_vendor', 'low_stock',
    'substitution_answered', 'freshness_claimed', 'incoming_call_vendor',
    'courier_out_for_delivery', 'courier_delivered', 'qr_paid',
    'wholesale_confirmed', 'wholesale_cancelled', 'order_auto_refused',
    'store_approved', 'store_rejected')
    then 'vendor'
    when p_kind in ('mission_available', 'courier_cash_confirmed', 'order_ready_pickup',
      'store_courier_added', 'store_mission_assigned', 'courier_approved', 'courier_rejected') then 'delivery'
    else 'client' end
$function$;

CREATE OR REPLACE FUNCTION public.become_courier(p_name text, p_phone text, p_vehicle text, p_zones uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  insert into public.courier_profiles (user_id, display_name, phone, vehicle, country_code, status)
  values (v_user, btrim(p_name), btrim(p_phone), p_vehicle, v_country,
          case when app.flag_on('account_review', v_country) then 'pending' else 'active' end)
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
$function$;

CREATE OR REPLACE FUNCTION public.set_courier_online(p_online boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.require_user();
  v_status text := (select status from public.courier_profiles where user_id = v_user);
begin
  if v_status is null then raise exception 'not_courier' using errcode = '42501'; end if;
  if v_status = 'suspended' and p_online then raise exception 'courier_suspended' using errcode = '42501'; end if;
  -- Spec 096 : compte à valider ou refusé, pas de mise en ligne.
  if v_status in ('pending', 'rejected') and p_online then
    raise exception 'courier_pending' using errcode = '42501';
  end if;
  update public.courier_profiles set is_online = p_online, updated_at = clock_timestamp() where user_id = v_user;
  perform app.emit_event(case when p_online then 'courier_online' else 'courier_offline' end, v_user, 'courier',
    'server', (select country_code from public.courier_profiles where user_id = v_user), 'courier', v_user::text,
    '{}'::jsonb);
  return app.courier_json(v_user);
end
$function$;

CREATE OR REPLACE FUNCTION public.publish_store()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_store uuid := app.own_store_id();
  v_missing text[] := app.store_missing(v_store);
  v_status text;
  v_origin text;
  v_country char(2);
  v_first boolean;
begin
  select status, origin, country_code, published_at is null
  into v_status, v_origin, v_country, v_first
  from public.stores where id = v_store;
  if v_status = 'suspended' then
    raise exception 'boutique suspendue par l''équipe' using errcode = '42501';
  end if;
  if cardinality(v_missing) > 0 then
    raise exception 'boutique incomplète : %', array_to_string(v_missing, ', ') using errcode = 'P0001';
  end if;
  -- Spec 096 : validation par l'équipe quand le pays l'exige.
  if v_status = 'review' then
    raise exception 'store_in_review' using errcode = 'P0001';
  end if;
  if v_status in ('draft', 'rejected') and app.flag_on('account_review', v_country) then
    update public.stores set status = 'review', is_open = false, onboarding_step = 7, review_note = null,
      updated_at = now()
    where id = v_store;
    return public.my_store();
  end if;
  update public.stores
  set status = 'active', is_open = true, onboarding_step = 7,
      published_at = coalesce(published_at, now())
  where id = v_store;
  if v_first then
    perform app.emit_event('store_created', app.current_user_id(), 'vendor', 'vendor', v_country,
      'store', v_store::text, jsonb_build_object('store_origin', v_origin));
  end if;
  perform app.emit_event('store_opened', app.current_user_id(), 'vendor', 'vendor', v_country,
    'store', v_store::text, jsonb_build_object('store_origin', v_origin));
  return public.my_store();
end
$function$;
