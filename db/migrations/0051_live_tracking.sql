-- 0051 — Suivi en direct, score, bonus, zones (spec 044, VISION §3 « Livreur »).
-- 1. Position du livreur en course (GPS de l'appareil, ou simulée et signalée quand il n'y en a
--    pas, décision 0015) ; la cliente voit la distance et l'heure d'arrivée, calculées en base.
-- 2. Vitesse par moyen de déplacement : données de référence.
-- 3. Score : la cliente note la remise (1 à 5) ; score du livreur = moyenne des 50 dernières.
-- 4. Zones de forte demande : missions en attente par zone ; une course prise dans une zone en
--    forte demande porte un bonus (réglage du pays), versé par DYM à la livraison.

create table public.courier_vehicle_speeds (
  vehicle text primary key check (vehicle in ('foot', 'bike', 'moto', 'car')),
  kmh numeric(5, 1) not null check (kmh between 1 and 120)
);
alter table public.courier_vehicle_speeds enable row level security;
create policy courier_vehicle_speeds_read on public.courier_vehicle_speeds for select
  to authenticated, anonymous using (true);
revoke all on public.courier_vehicle_speeds from authenticated, anonymous;
grant select on public.courier_vehicle_speeds to authenticated, anonymous;
insert into public.courier_vehicle_speeds (vehicle, kmh) values
  ('foot', 4.5), ('bike', 12), ('moto', 22), ('car', 18)
on conflict do nothing;

alter table public.countries
  add column courier_bonus_threshold smallint not null default 3 check (courier_bonus_threshold between 1 and 100),
  add column courier_bonus_minor bigint not null default 0 check (courier_bonus_minor >= 0);

-- Dernière position connue du livreur.
create table public.courier_positions (
  user_id uuid primary key references public.courier_profiles (user_id) on delete cascade,
  latitude numeric(9, 6) not null check (latitude between -90 and 90),
  longitude numeric(9, 6) not null check (longitude between -180 and 180),
  simulated boolean not null default false,
  recorded_at timestamptz not null default clock_timestamp()
);
alter table public.courier_positions enable row level security;
revoke all on public.courier_positions from authenticated, anonymous;

alter table public.order_couriers
  add column bonus_minor bigint not null default 0 check (bonus_minor >= 0),
  add column rating smallint check (rating between 1 and 5),
  add column rated_at timestamptz;

alter table public.ledger_transactions drop constraint ledger_transactions_kind_check;
alter table public.ledger_transactions add constraint ledger_transactions_kind_check check (kind in (
  'payment_received', 'order_settled', 'cash_commission', 'refund_paid',
  'wallet_topup', 'wallet_transfer', 'cashback', 'space_contribution', 'space_payout', 'order_credit',
  'affiliate_commission', 'courier_fee', 'courier_cash', 'courier_cash_remitted', 'cash_topup',
  'wallet_withdrawal',
  'courier_bonus'         -- bonus de zone versé par DYM au livreur
));

-- Distance à vol d'oiseau en mètres (haversine).
create or replace function app.distance_m(p_lat1 numeric, p_lng1 numeric, p_lat2 numeric, p_lng2 numeric)
returns integer
language sql immutable
as $$
  select round(2 * 6371000 * asin(sqrt(
    power(sin(radians((p_lat2 - p_lat1)::float8) / 2), 2)
    + cos(radians(p_lat1::float8)) * cos(radians(p_lat2::float8))
      * power(sin(radians((p_lng2 - p_lng1)::float8) / 2), 2))))::int
$$;

-- Position envoyée par l'app livreur (en ligne seulement ; au plus une fois toutes les 5 s).
create or replace function public.report_position(p_lat numeric, p_lng numeric, p_simulated boolean default false)
returns void
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if not exists (select 1 from public.courier_profiles where user_id = v_user and is_online and status = 'active') then
    raise exception 'not_online' using errcode = 'P0001';
  end if;
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'invalid_position' using errcode = '22023';
  end if;
  insert into public.courier_positions (user_id, latitude, longitude, simulated)
  values (v_user, round(p_lat, 6), round(p_lng, 6), coalesce(p_simulated, false))
  on conflict (user_id) do update
    set latitude = excluded.latitude, longitude = excluded.longitude, simulated = excluded.simulated,
        recorded_at = clock_timestamp()
    where public.courier_positions.recorded_at < clock_timestamp() - interval '5 seconds';
end
$fn$;

-- Score : moyenne des 50 dernières notes (nul : pas encore noté).
create or replace function app.courier_score(p_user uuid) returns numeric
language sql stable security definer set search_path = ''
as $$
  select round(avg(rating)::numeric, 1) from (
    select rating from public.order_couriers where courier_id = p_user and rating is not null
    order by rated_at desc limit 50) r
$$;

-- Suivi pour la cliente : livreur, distance, heure d'arrivée (en route seulement).
create or replace function public.order_live(p_order uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select case when o.id is null then null else jsonb_build_object(
    'courier_name', c.display_name,
    'vehicle', c.vehicle,
    'score', app.courier_score(c.user_id),
    'simulated', pos.simulated,
    'position_at', pos.recorded_at,
    'distance_m', d.m,
    'eta_at', case when d.m is null then null
                   else now() + make_interval(secs => round(d.m / (sp.kmh * 1000 / 3600.0))) end)
  end
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id and pu.user_id = app.current_user_id()
  join public.order_couriers oc on oc.order_id = o.id and oc.courier_id is not null
  join public.courier_profiles c on c.user_id = oc.courier_id
  left join public.courier_vehicle_speeds sp on sp.vehicle = c.vehicle
  left join public.courier_positions pos on pos.user_id = c.user_id
    and pos.recorded_at > now() - interval '10 minutes'
  cross join lateral (select case when pos.user_id is not null and pu.address ? 'latitude'
                                       and pu.address ->> 'latitude' is not null
                                  then app.distance_m(pos.latitude, pos.longitude,
                                         (pu.address ->> 'latitude')::numeric, (pu.address ->> 'longitude')::numeric)
                             end as m) d
  where o.id = p_order and o.status = 'out_for_delivery'
$$;

-- La cliente note la remise (une fois, commande livrée par un livreur DYM).
create or replace function public.rate_courier(p_order uuid, p_rating integer) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_courier uuid;
begin
  if p_rating is null or p_rating not between 1 and 5 then raise exception 'invalid_rating' using errcode = '22023'; end if;
  update public.order_couriers oc set rating = p_rating, rated_at = now()
  from public.orders o join public.purchases pu on pu.id = o.purchase_id
  where oc.order_id = p_order and o.id = oc.order_id and pu.user_id = v_user and o.status = 'delivered'
    and oc.courier_id is not null and oc.rating is null
  returning oc.courier_id into v_courier;
  if v_courier is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  perform app.emit_event('courier_rated', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'order', p_order::text,
    jsonb_build_object('rating', p_rating));
  return jsonb_build_object('rating', p_rating);
end
$fn$;

-- Livreur DYM d'une commande livrée, pour la cliente : nom et note déjà donnée.
create or replace function public.order_courier_rating(p_order uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('courier_name', oc.name, 'rating', oc.rating)
  from public.order_couriers oc
  join public.orders o on o.id = oc.order_id
  join public.purchases pu on pu.id = o.purchase_id
  where oc.order_id = p_order and oc.courier_id is not null and o.status = 'delivered'
    and pu.user_id = app.current_user_id()
$$;

-- Demande par zone du pays du livreur : missions en attente d'un livreur.
create or replace function public.zone_demand() returns jsonb
language sql stable security definer set search_path = ''
as $$
  with me as (select * from public.courier_profiles where user_id = app.current_user_id()),
  waiting as (
    select coalesce((pu.address ->> 'zone_id')::uuid, s.zone_id) as zone_id
    from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    join public.stores s on s.id = o.store_id
    where o.fulfillment = 'delivery' and o.status in ('accepted', 'preparing', 'ready')
      and pu.country_code = (select country_code from me)
      and not exists (select 1 from public.order_couriers oc where oc.order_id = o.id))
  select coalesce(jsonb_agg(jsonb_build_object(
      'zone_id', z.id, 'zone_name', z.name, 'waiting', w.n,
      'high', w.n >= c.courier_bonus_threshold,
      'bonus_minor', case when w.n >= c.courier_bonus_threshold then c.courier_bonus_minor else 0 end)
    order by w.n desc, z.name), '[]'::jsonb)
  from (select zone_id, count(*)::int as n from waiting group by zone_id) w
  join public.zones z on z.id = w.zone_id
  join public.countries c on c.code = (select country_code from me)
$$;

-- Prise en forte demande : bonus fixé à l'acceptation (déclencheur sur l'affectation).
create or replace function app.courier_bonus_on_assign() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_zone uuid;
  v_threshold smallint;
  v_bonus bigint;
  v_waiting integer;
begin
  if new.courier_id is null then return null; end if;
  select coalesce((pu.address ->> 'zone_id')::uuid, s.zone_id), c.courier_bonus_threshold, c.courier_bonus_minor
  into v_zone, v_threshold, v_bonus
  from public.orders o join public.purchases pu on pu.id = o.purchase_id
  join public.stores s on s.id = o.store_id join public.countries c on c.code = pu.country_code
  where o.id = new.order_id;
  if v_bonus <= 0 then return null; end if;
  select count(*) into v_waiting
  from public.orders o join public.purchases pu on pu.id = o.purchase_id join public.stores s on s.id = o.store_id
  where o.fulfillment = 'delivery' and o.status in ('accepted', 'preparing', 'ready')
    and coalesce((pu.address ->> 'zone_id')::uuid, s.zone_id) = v_zone
    and (o.id = new.order_id or not exists (select 1 from public.order_couriers oc where oc.order_id = o.id));
  if v_waiting >= v_threshold then
    update public.order_couriers set bonus_minor = v_bonus where order_id = new.order_id;
  end if;
  return null;
end
$fn$;
create trigger order_couriers_bonus after insert on public.order_couriers
  for each row execute function app.courier_bonus_on_assign();

-- Livrée : bonus versé par DYM sur le wallet du livreur.
create or replace function app.courier_bonus_on_order() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
declare
  v record;
begin
  if new.status <> 'delivered' or old.status is not distinct from 'delivered' then return null; end if;
  select courier_id, bonus_minor into v from public.order_couriers where order_id = new.id;
  if v.courier_id is null or v.bonus_minor <= 0 then return null; end if;
  perform app.ledger_post('courier_bonus', 'courier-bonus:' || new.id, new.currency_code, jsonb_build_array(
    jsonb_build_object('account', app.ledger_account('platform_promotions', new.currency_code), 'amount', v.bonus_minor),
    jsonb_build_object('account', app.ledger_user_account('user_wallet', new.currency_code, v.courier_id),
                       'amount', -v.bonus_minor)),
    p_order => new.id, p_user => v.courier_id);
  return null;
end
$fn$;
create trigger orders_courier_bonus after update of status on public.orders
  for each row execute function app.courier_bonus_on_order();

insert into public.event_names (name, emitted_by, description) values
  ('courier_rated', 'server', 'Remise notée par la cliente (note)')
on conflict do nothing;

-- Profil livreur (0048) : score.
create or replace function app.courier_json(p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('display_name', c.display_name, 'phone', c.phone, 'vehicle', c.vehicle,
    'status', c.status, 'is_online', c.is_online, 'country_code', c.country_code,
    'score', app.courier_score(c.user_id),
    'zone_ids', coalesce((select jsonb_agg(z.zone_id order by z.zone_id) from public.courier_zones z
                          where z.user_id = c.user_id), '[]'::jsonb))
  from public.courier_profiles c where c.user_id = p_user
$$;


revoke all on function app.distance_m(numeric, numeric, numeric, numeric), public.report_position(numeric, numeric, boolean),
  public.order_live(uuid), app.courier_score(uuid), public.rate_courier(uuid, integer), public.zone_demand(),
  public.order_courier_rating(uuid),
  app.courier_bonus_on_assign(), app.courier_bonus_on_order() from public;
grant execute on function public.report_position(numeric, numeric, boolean), public.order_live(uuid),
  public.rate_courier(uuid, integer), public.zone_demand(), public.order_courier_rating(uuid) to authenticated;
