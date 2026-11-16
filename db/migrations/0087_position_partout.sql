-- 0087 — Tout par position (spec 094, phase 15). La position remplace le quartier comme base :
-- chaque boutique a une position (adresse de retrait, sinon centre de son quartier) et un rayon de
-- livraison ; elle sert toute position dans ce rayon, en plus des quartiers cochés (repris tels
-- quels). La découverte accepte la position de la cliente et trie par distance. Les quartiers
-- restent des repères (nom lisible, repli sans GPS, statistiques). Les frais par distance
-- arrivent avec l'adresse exacte sur la carte (spec 096).

-- Distance en mètres entre deux points (haversine, rayon terrestre moyen).
create or replace function app.distance_m(
  p_lat1 numeric, p_lng1 numeric, p_lat2 numeric, p_lng2 numeric
) returns double precision
language sql immutable parallel safe set search_path = ''
as $$
  select 6371000 * 2 * asin(sqrt(
    power(sin(radians(p_lat2 - p_lat1) / 2), 2)
    + cos(radians(p_lat1)) * cos(radians(p_lat2))
      * power(sin(radians(p_lng2 - p_lng1) / 2), 2)))
$$;

-- Rayon de livraison de la boutique (500 m à 50 km) ; 5 km par défaut.
alter table public.stores add column delivery_radius_m integer not null default 5000
  check (delivery_radius_m between 500 and 50000);

-- Position de la boutique : adresse de retrait, sinon centre de son quartier.
create or replace function app.store_point(p_store uuid)
returns table (lat numeric, lng numeric)
language sql stable security definer set search_path = ''
as $$
  select coalesce(a.latitude, z.latitude), coalesce(a.longitude, z.longitude)
  from public.stores s
  left join public.store_pickup_addresses a on a.store_id = s.id
  left join public.zones z on z.id = s.zone_id
  where s.id = p_store
$$;

-- La boutique livre-t-elle cette position (rayon) ?
create or replace function app.store_serves_point(p_store uuid, p_lat numeric, p_lng numeric)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select p_lat is not null and p_lng is not null and exists (
    select 1 from public.stores s, app.store_point(s.id) sp
    where s.id = p_store and sp.lat is not null
      and app.distance_m(sp.lat, sp.lng, p_lat, p_lng) <= s.delivery_radius_m)
$$;

-- Quartier servi : quartier de la boutique, quartier coché, ou centre du quartier dans le rayon.
create or replace function app.store_serves(p_store uuid, p_zone uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select p_zone is null
    or exists (select 1 from public.stores s where s.id = p_store and s.zone_id = p_zone)
    or exists (select 1 from public.store_delivery_zones d where d.store_id = p_store and d.zone_id = p_zone)
    or exists (select 1 from public.zones z where z.id = p_zone
               and app.store_serves_point(p_store, z.latitude, z.longitude))
$$;

CREATE OR REPLACE FUNCTION app.store_summary(p_store uuid, p_at timestamp with time zone)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'id', s.id, 'name', s.name, 'description', s.description, 'origin', s.origin,
    'zone_id', s.zone_id, 'zone_name', z.name,
    'zone_latitude', z.latitude, 'zone_longitude', z.longitude,
    'latitude', (select sp.lat from app.store_point(s.id) sp),
    'longitude', (select sp.lng from app.store_point(s.id) sp),
    'delivery_radius_m', s.delivery_radius_m,
    'country_code', s.country_code, 'currency_code', s.currency_code,
    'prep_time_minutes', s.prep_time_minutes, 'offers_pickup', s.offers_pickup,
    'open_now', app.store_open_at(s.id, p_at),
    'closes_at', (select to_char(h.closes_at, 'HH24:MI') from app.store_hours_today(s.id, p_at) h
                  where h.store_id is not null),
    'delivery_minutes', s.prep_time_minutes + c.delivery_minutes,
    'cover_key', (
      select f.object_key from public.products p
      join public.product_photos f on f.product_id = p.id
      where p.store_id = s.id and p.status = 'published'
      order by p.published_at, f.sort limit 1),
    'product_count', (select count(*) from public.products p where p.store_id = s.id and p.status = 'published'),
    'rating', (select round(avg(r.rating)::numeric, 1) from public.reviews r
               where r.store_id = s.id and r.status = 'published'),
    'review_count', (select count(*) from public.reviews r where r.store_id = s.id and r.status = 'published')
  )
  from public.stores s
  join public.zones z on z.id = s.zone_id
  join public.cities c on c.id = z.city_id
  where s.id = p_store and s.status = 'active'
$function$;

-- Découverte par position : la position donnée, sinon le centre du quartier ; boutiques qui
-- servent ce point (rayon) ou ce quartier, triées par ouverture puis distance.
drop function public.discover_stores(uuid, integer, timestamptz);
create function public.discover_stores(
  p_zone uuid,
  p_limit integer default 20,
  p_at timestamptz default now(),
  p_latitude numeric default null,
  p_longitude numeric default null
) returns jsonb
language sql stable security definer set search_path = ''
as $$
  with here as (
    select coalesce(p_latitude, z.latitude) as lat, coalesce(p_longitude, z.longitude) as lng
    from (select 1) one left join public.zones z on z.id = p_zone
  ),
  candidates as (
    select s.id, s.name, s.zone_id = p_zone as same_zone,
           app.store_open_at(s.id, p_at) as open_now, s.prep_time_minutes,
           (select app.distance_m(sp.lat, sp.lng, h.lat, h.lng)
            from app.store_point(s.id) sp where sp.lat is not null and h.lat is not null) as meters
    from public.stores s, here h
    where s.status = 'active'
      and ((p_zone is not null and app.store_serves(s.id, p_zone))
           or app.store_serves_point(s.id, h.lat, h.lng))
  )
  select jsonb_build_object(
    'estimate_minutes', (
      select min(cd.prep_time_minutes) + coalesce(max(c.delivery_minutes), 30)
      from candidates cd
      left join public.zones z on z.id = p_zone
      left join public.cities c on c.id = z.city_id
      where cd.open_now),
    'stores', coalesce((
      select jsonb_agg(app.store_summary(id, p_at)
                       || jsonb_build_object('distance_m', round(meters)::int)
                       order by open_now desc, meters nulls last, same_zone desc, name)
      from (select * from candidates
            order by open_now desc, meters nulls last, same_zone desc, name
            limit greatest(1, least(p_limit, 50))) t), '[]'::jsonb),
    -- « À la une » (spec 052) : boutiques sponsorisées qui livrent ici, signalées comme telles.
    'sponsored', coalesce((
      select jsonb_agg(app.store_summary(cd.id, p_at) order by cd.open_now desc, cd.name)
      from candidates cd where app.member_flag(null, cd.id, 'sponsored', p_at)), '[]'::jsonb)
  )
$$;
grant execute on function public.discover_stores(uuid, integer, timestamptz, numeric, numeric)
  to anonymous, authenticated;

CREATE OR REPLACE FUNCTION public.nearest_zone(p_latitude numeric, p_longitude numeric, p_country character DEFAULT NULL::bpchar)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'zone_id', z.id, 'zone_name', z.name, 'city_id', c.id, 'city_name', c.name,
    'country_code', c.country_code,
    'distance_m', round(d.meters)::int,
    'service_radius_m', c.service_radius_m,
    -- Couvert : dans le rayon de la ville, ou dans le rayon d'une boutique active (spec 094).
    'covered', d.meters <= c.service_radius_m or exists (
      select 1 from public.stores s
      where s.status = 'active' and app.store_serves_point(s.id, p_latitude, p_longitude)))
  from public.zones z
  join public.cities c on c.id = z.city_id
  cross join lateral (
    select 6371000 * 2 * asin(sqrt(
      power(sin(radians(z.latitude - p_latitude) / 2), 2)
      + cos(radians(p_latitude)) * cos(radians(z.latitude))
        * power(sin(radians(z.longitude - p_longitude) / 2), 2))) as meters
  ) d
  where z.is_active and z.latitude is not null
    and app.city_is_visible(c.id)
    and (p_country is null or c.country_code = p_country)
    and p_latitude between -90 and 90 and p_longitude between -180 and 180
  order by d.meters
  limit 1
$function$;

CREATE OR REPLACE FUNCTION public.update_store(p_patch jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_store uuid := app.own_store_id();
  v_key text;
  v_country char(2);
  v_zone uuid;
begin
  for v_key in select jsonb_object_keys(p_patch) loop
    if v_key not in ('name', 'description', 'origin', 'zone_id', 'main_category_id',
                     'prep_time_minutes', 'offers_pickup', 'delivery_fee_minor', 'onboarding_step',
                     'delivery_radius_m') then
      raise exception 'champ non modifiable : %', v_key using errcode = '22023';
    end if;
  end loop;

  if p_patch ? 'origin' and not exists (
    select 1 from public.store_origins where code = p_patch ->> 'origin' and is_active
  ) then
    raise exception 'origine inconnue' using errcode = '22023';
  end if;

  if p_patch ? 'main_category_id' and not exists (
    select 1 from public.categories
    where id = (p_patch ->> 'main_category_id')::uuid and parent_id is null and is_active
  ) then
    raise exception 'rayon principal inconnu' using errcode = '22023';
  end if;

  if p_patch ? 'zone_id' then
    v_zone := (p_patch ->> 'zone_id')::uuid;
    select c.country_code into v_country
    from public.zones z join public.cities c on c.id = z.city_id
    where z.id = v_zone and z.is_active and app.city_is_visible(c.id);
    if v_country is null then
      raise exception 'quartier inconnu ou inactif' using errcode = '22023';
    end if;
  end if;

  update public.stores s set
    name = coalesce(trim(p_patch ->> 'name'), s.name),
    description = case when p_patch ? 'description' then nullif(trim(p_patch ->> 'description'), '') else s.description end,
    origin = coalesce(p_patch ->> 'origin', s.origin),
    zone_id = coalesce(v_zone, s.zone_id),
    country_code = coalesce(v_country, s.country_code),
    currency_code = case when v_country is null then s.currency_code
      else (select currency_code from public.countries where code = v_country) end,
    main_category_id = coalesce((p_patch ->> 'main_category_id')::uuid, s.main_category_id),
    prep_time_minutes = coalesce((p_patch ->> 'prep_time_minutes')::smallint, s.prep_time_minutes),
    offers_pickup = coalesce((p_patch ->> 'offers_pickup')::boolean, s.offers_pickup),
    delivery_fee_minor = case when p_patch ? 'delivery_fee_minor' then (p_patch ->> 'delivery_fee_minor')::bigint else s.delivery_fee_minor end,
    delivery_radius_m = case when p_patch ? 'delivery_radius_m'
      then (p_patch ->> 'delivery_radius_m')::integer else s.delivery_radius_m end,
    onboarding_step = greatest(s.onboarding_step, coalesce((p_patch ->> 'onboarding_step')::smallint, s.onboarding_step))
  where s.id = v_store;

  -- Changer de ville retire les quartiers desservis d'une autre ville.
  if v_zone is not null then
    delete from public.store_delivery_zones d
    where d.store_id = v_store
      and (select city_id from public.zones where id = d.zone_id)
       <> (select city_id from public.zones where id = v_zone);
  end if;
  return public.my_store();
end
$function$;
