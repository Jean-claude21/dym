-- 0065 — Rayon de service par ville (spec 065).
-- Une position trop loin de tout quartier n'est plus rattachée au plus proche
-- sans le dire : `nearest_zone` indique si elle est couverte. Le rayon est une
-- donnée de la ville, réglée depuis Configuration. Les positions hors zone sont
-- comptées (événement client, sans coordonnées) pour décider où ouvrir.

alter table public.cities
  add column service_radius_m integer not null default 15000
    check (service_radius_m between 1000 and 200000);

comment on column public.cities.service_radius_m is
  'Distance maximale (m) entre une position et le quartier le plus proche de la ville pour être desservie';

-- Quartier le plus proche (pays actifs ; [p_country] pour restreindre), avec
-- `covered` : la distance tient dans le rayon de service de sa ville.
create or replace function public.nearest_zone(
  p_latitude numeric,
  p_longitude numeric,
  p_country char(2) default null
) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'zone_id', z.id, 'zone_name', z.name, 'city_id', c.id, 'city_name', c.name,
    'country_code', c.country_code,
    'distance_m', round(d.meters)::int,
    'service_radius_m', c.service_radius_m,
    'covered', d.meters <= c.service_radius_m)
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
$$;

-- Villes et quartiers d'un pays, avec le rayon de service.
create or replace function public.admin_geography(p_country char(2)) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', c.id, 'name', c.name, 'is_active', c.is_active, 'delivery_minutes', c.delivery_minutes,
      'service_radius_m', c.service_radius_m,
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

-- Créer ou modifier une ville : {id?, country_code, name, delivery_minutes?,
-- service_radius_m?, is_active?}. Journalisé avec l'avant et l'après.
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
      service_radius_m = coalesce((p_city ->> 'service_radius_m')::integer, service_radius_m),
      is_active = coalesce((p_city ->> 'is_active')::boolean, is_active)
    where id = v_id returning * into v_after;
  else
    v_country := p_city ->> 'country_code';
    insert into public.cities (country_code, slug, name, delivery_minutes, service_radius_m, is_active)
    values (v_country,
            app.free_slug(app.slugify(p_city ->> 'name'),
                          array(select slug from public.cities where country_code = v_country)),
            trim(p_city ->> 'name'), coalesce((p_city ->> 'delivery_minutes')::smallint, 30),
            coalesce((p_city ->> 'service_radius_m')::integer, 15000),
            coalesce((p_city ->> 'is_active')::boolean, true))
    returning * into v_after;
  end if;
  perform app.admin_did(v_admin, case when v_id is null then 'city_created' else 'city_updated' end,
    'city', v_after.id::text,
    case when v_id is null then null else jsonb_build_object('name', v_before.name,
      'delivery_minutes', v_before.delivery_minutes, 'service_radius_m', v_before.service_radius_m,
      'is_active', v_before.is_active) end,
    jsonb_build_object('name', v_after.name, 'delivery_minutes', v_after.delivery_minutes,
                       'service_radius_m', v_after.service_radius_m,
                       'is_active', v_after.is_active), null, v_after.country_code);
  return public.admin_geography(v_after.country_code);
end
$$;

-- Position hors zone : émis par l'app (pays du quartier le plus proche,
-- distance arrondie au km ; jamais la position).
insert into public.event_names (name, emitted_by, description) values
  ('location_outside_coverage', 'client',
   'Position hors des zones desservies (pays le plus proche, distance en km, app)')
on conflict do nothing;

-- Couverture : positions hors zone sur la période, par pays le plus proche.
create or replace function public.admin_coverage(p_period text default 'week', p_at timestamptz default now())
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_since timestamptz := p_at - case p_period when 'day' then interval '1 day'
                                              when 'month' then interval '30 days'
                                              else interval '7 days' end;
begin
  perform app.require_admin();
  return jsonb_build_object(
    'total', (select count(*) from public.events e
              where e.name = 'location_outside_coverage' and e.occurred_at > v_since and e.occurred_at <= p_at),
    'countries', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'country_code', x.country_code, 'misses', x.misses, 'median_km', x.median_km)
        order by x.misses desc, x.country_code), '[]'::jsonb)
      from (select coalesce(e.country_code, '??') as country_code, count(*) as misses,
                   round(percentile_cont(0.5) within group (
                     order by nullif(e.props ->> 'distance_km', '')::numeric))::int as median_km
            from public.events e
            where e.name = 'location_outside_coverage' and e.occurred_at > v_since and e.occurred_at <= p_at
            group by 1) x));
end
$$;

revoke all on function public.admin_coverage(text, timestamptz) from public;
grant execute on function public.admin_coverage(text, timestamptz) to authenticated;
