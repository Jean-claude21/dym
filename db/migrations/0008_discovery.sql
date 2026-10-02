-- Découverte côté cliente (spec 008) : recherche plein texte, quartiers et
-- délais de référence, fonctions de lecture par écran.
--
-- Les fonctions publiques sont SECURITY DEFINER avec des filtres explicites
-- (boutique active, produit publié) : leur sortie est contrôlée champ par
-- champ, sans adresse, propriétaire ni proposition de l'IA. L'instant est un
-- paramètre (`p_at`) pour des tests déterministes.

-- ------------------------------------------------------------------ recherche

create schema if not exists extensions;
create extension if not exists unaccent schema extensions;

-- Texte comparable : minuscules, sans accents (immuable : colonnes générées).
create or replace function app.normalize(p_text text) returns text
language sql immutable parallel safe set search_path = ''
as $$
  select lower(extensions.unaccent('extensions.unaccent'::regdictionary, coalesce(p_text, '')))
$$;

-- Requête par préfixes : « biss jus » → 'biss':* & 'jus':*. Nulle si vide.
create or replace function app.search_query(p_text text) returns tsquery
language sql immutable parallel safe set search_path = ''
as $$
  select to_tsquery('simple', string_agg(quote_literal(t) || ':*', ' & '))
  from regexp_split_to_table(app.normalize(p_text), '[^[:alnum:]]+') as t
  where t <> ''
$$;

alter table public.products add column search tsvector generated always as (
  to_tsvector('simple', app.normalize(name || ' ' || coalesce(description, '')))
) stored;
alter table public.stores add column search tsvector generated always as (
  to_tsvector('simple', app.normalize(name || ' ' || coalesce(description, '')))
) stored;

create index products_search on public.products using gin (search);
create index stores_search on public.stores using gin (search);

-- ------------------------------------------------------------------ référence

-- Centre approximatif d'un quartier (à vérifier sur le terrain) : propose un
-- quartier à partir d'une position, que la cliente confirme.
alter table public.zones
  add column latitude numeric(9, 6) check (latitude between -90 and 90),
  add column longitude numeric(9, 6) check (longitude between -180 and 180),
  add constraint zones_position_complete check ((latitude is null) = (longitude is null));

-- Délai de livraison indicatif de la ville (minutes), à calibrer au pilote.
alter table public.cities
  add column delivery_minutes smallint not null default 30 check (delivery_minutes between 5 and 240);

update public.zones z set latitude = v.lat, longitude = v.lng
from (values
  ('lome', 'be', 6.130000, 1.239000),
  ('lome', 'be-kpota', 6.147000, 1.252000),
  ('lome', 'tokoin', 6.152000, 1.218000),
  ('lome', 'adawlato', 6.129000, 1.219000),
  ('lome', 'nyekonakpoe', 6.130000, 1.205000),
  ('lome', 'kodjoviakope', 6.129000, 1.199000),
  ('lome', 'hedzranawoe', 6.165000, 1.242000),
  ('lome', 'adidogome', 6.172000, 1.165000),
  ('lome', 'agoe', 6.225000, 1.210000),
  ('lome', 'kegue', 6.178000, 1.263000),
  ('lome', 'baguida', 6.164000, 1.320000),
  ('accra', 'osu', 5.556000, -0.180000),
  ('accra', 'madina', 5.673000, -0.166000),
  ('accra', 'makola', 5.548000, -0.208000),
  ('accra', 'kaneshie', 5.570000, -0.235000),
  ('accra', 'east-legon', 5.638000, -0.158000)
) as v (city, slug, lat, lng)
join public.cities c on c.slug = v.city
where z.city_id = c.id and z.slug = v.slug;

update public.cities set delivery_minutes = 20 where slug = 'lome';
update public.cities set delivery_minutes = 30 where slug = 'accra';

-- ------------------------------------------------------------------ calculs

-- Heure locale du pays de la boutique.
create or replace function app.store_local_time(p_store uuid, p_at timestamptz)
returns timestamp
language sql stable security definer set search_path = ''
as $$
  select p_at at time zone c.timezone
  from public.stores s join public.countries c on c.code = s.country_code
  where s.id = p_store
$$;

-- Horaires du jour (local), ou rien.
create or replace function app.store_hours_today(p_store uuid, p_at timestamptz)
returns public.store_hours
language sql stable security definer set search_path = ''
as $$
  select h.* from public.store_hours h
  where h.store_id = p_store
    and h.weekday = extract(isodow from app.store_local_time(p_store, p_at))
$$;

-- Ouverte maintenant : active, interrupteur ouvert, dans les horaires du jour.
create or replace function app.store_open_at(p_store uuid, p_at timestamptz) returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((
    select s.status = 'active' and s.is_open
      and app.store_local_time(s.id, p_at)::time >= h.opens_at
      and app.store_local_time(s.id, p_at)::time < h.closes_at
    from public.stores s
    join public.store_hours h on h.store_id = s.id
      and h.weekday = extract(isodow from app.store_local_time(s.id, p_at))
    where s.id = p_store
  ), false)
$$;

-- Disponible : pas en rupture, et stock non suivi ou une variante en stock.
create or replace function app.product_available(p_product uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select p.is_available and (
    not exists (select 1 from public.product_variants v where v.product_id = p.id and v.stock_quantity is not null)
    or exists (select 1 from public.product_variants v where v.product_id = p.id
               and (v.stock_quantity is null or v.stock_quantity > 0))
  )
  from public.products p where p.id = p_product
$$;

-- Prix le plus bas (variantes comprises).
create or replace function app.product_min_price(p_product uuid) returns bigint
language sql stable security definer set search_path = ''
as $$
  select least(p.price_minor, (select min(v.price_minor) from public.product_variants v where v.product_id = p.id))
  from public.products p where p.id = p_product
$$;

-- La boutique livre le quartier (ou y est située).
create or replace function app.store_serves(p_store uuid, p_zone uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select p_zone is null
    or exists (select 1 from public.stores s where s.id = p_store and s.zone_id = p_zone)
    or exists (select 1 from public.store_delivery_zones d where d.store_id = p_store and d.zone_id = p_zone)
$$;

-- Résumé public d'une boutique.
create or replace function app.store_summary(p_store uuid, p_at timestamptz) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', s.id, 'name', s.name, 'description', s.description, 'origin', s.origin,
    'zone_id', s.zone_id, 'zone_name', z.name,
    'zone_latitude', z.latitude, 'zone_longitude', z.longitude,
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
    'product_count', (select count(*) from public.products p where p.store_id = s.id and p.status = 'published')
  )
  from public.stores s
  join public.zones z on z.id = s.zone_id
  join public.cities c on c.id = z.city_id
  where s.id = p_store and s.status = 'active'
$$;

-- Élément de liste d'un produit public.
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
    'available', app.product_available(p.id),
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

-- ------------------------------------------------------------------ fonctions publiques

-- Accueil : boutiques actives qui livrent le quartier (ouvertes d'abord, puis
-- celles du quartier), et estimation « Livré en … min » (boutique ouverte la
-- plus rapide + délai de la ville).
create or replace function public.discover_stores(
  p_zone uuid,
  p_limit integer default 20,
  p_at timestamptz default now()
) returns jsonb
language sql stable security definer set search_path = ''
as $$
  with candidates as (
    select s.id, s.name, s.zone_id = p_zone as same_zone,
           app.store_open_at(s.id, p_at) as open_now, s.prep_time_minutes
    from public.stores s
    where s.status = 'active' and app.store_serves(s.id, p_zone)
  )
  select jsonb_build_object(
    'estimate_minutes', (
      select min(cd.prep_time_minutes) + c.delivery_minutes
      from candidates cd, public.zones z join public.cities c on c.id = z.city_id
      where cd.open_now and z.id = p_zone
      group by c.delivery_minutes),
    'stores', coalesce((
      select jsonb_agg(app.store_summary(id, p_at) order by open_now desc, same_zone desc, name)
      from (select * from candidates order by open_now desc, same_zone desc, name
            limit greatest(1, least(p_limit, 50))) t), '[]'::jsonb)
  )
$$;

-- Quartier le plus proche d'une position (pays actifs ; [p_country] pour
-- restreindre). La position n'est pas conservée.
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
    'distance_m', round(d.meters)::int)
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

-- Recherche, rayon et filtres. Tris : relevance, price_asc, price_desc.
-- Boutiques correspondantes : seulement avec un texte (5 au plus).
create or replace function public.search_catalog(
  p_query text default null,
  p_zone uuid default null,
  p_category uuid default null,
  p_origin text default null,
  p_min_price bigint default null,
  p_max_price bigint default null,
  p_available_only boolean default false,
  p_sort text default 'relevance',
  p_limit integer default 20,
  p_offset integer default 0,
  p_at timestamptz default now()
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_query tsquery := app.search_query(p_query);
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 50));
  v_result jsonb;
begin
  if p_sort not in ('relevance', 'price_asc', 'price_desc') then
    raise exception 'tri inconnu' using errcode = '22023';
  end if;
  with matches as (
    select p.id, p.name,
           app.product_min_price(p.id) as price,
           case when v_query is null then 0 else ts_rank(p.search, v_query) end as rank
    from public.products p
    join public.stores s on s.id = p.store_id
    left join public.categories cat on cat.id = p.category_id
    where p.status = 'published' and s.status = 'active'
      and (v_query is null or p.search @@ v_query)
      and app.store_serves(s.id, p_zone)
      and (p_category is null or p.category_id = p_category or cat.parent_id = p_category)
      and (p_origin is null or s.origin = p_origin)
      and (p_min_price is null or app.product_min_price(p.id) >= p_min_price)
      and (p_max_price is null or app.product_min_price(p.id) <= p_max_price)
      and (not p_available_only or app.product_available(p.id))
  )
  select jsonb_build_object(
    'total', (select count(*) from matches),
    'products', coalesce((
      select jsonb_agg(app.catalog_item(id) order by ord)
      from (
        select id, row_number() over (order by
          case when p_sort = 'price_asc' then price end asc,
          case when p_sort = 'price_desc' then price end desc,
          rank desc, name, id) as ord
        from matches
        order by ord
        limit v_limit offset greatest(coalesce(p_offset, 0), 0)
      ) page), '[]'::jsonb),
    'stores', case when v_query is null or coalesce(p_offset, 0) > 0 then '[]'::jsonb else coalesce((
      select jsonb_agg(app.store_summary(id, p_at) order by rank desc, name)
      from (
        select s.id, s.name, ts_rank(s.search, v_query) as rank
        from public.stores s
        where s.status = 'active' and s.search @@ v_query
          and app.store_serves(s.id, p_zone)
          and (p_origin is null or s.origin = p_origin)
        order by rank desc, s.name
        limit 5
      ) t), '[]'::jsonb) end
  ) into v_result;
  return v_result;
end
$$;

-- Page boutique (écran 04) en un appel. Nulle si la boutique n'est pas active.
create or replace function public.store_page(p_store uuid, p_at timestamptz default now())
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select app.store_summary(s.id, p_at) || jsonb_build_object(
    'hours', coalesce((
      select jsonb_agg(jsonb_build_object('weekday', h.weekday,
        'opens_at', to_char(h.opens_at, 'HH24:MI'), 'closes_at', to_char(h.closes_at, 'HH24:MI'))
        order by h.weekday)
      from public.store_hours h where h.store_id = s.id), '[]'::jsonb),
    'categories', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'name', c.name) order by c.sort, c.name)
      from public.store_categories c
      where c.store_id = s.id and not c.is_archived
        and exists (select 1 from public.product_store_categories pc
                    join public.products p on p.id = pc.product_id and p.status = 'published'
                    where pc.store_category_id = c.id)), '[]'::jsonb),
    'products', coalesce((
      select jsonb_agg(app.catalog_item(p.id) order by app.product_available(p.id) desc, p.published_at desc)
      from public.products p where p.store_id = s.id and p.status = 'published'), '[]'::jsonb)
  )
  from public.stores s where s.id = p_store and s.status = 'active'
$$;

-- Fiche produit (écran 28) en un appel. Nulle si le produit n'est pas public.
create or replace function public.product_page(
  p_product uuid,
  p_zone uuid default null,
  p_at timestamptz default now()
) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select app.catalog_item(p.id) || jsonb_build_object(
    'description', p.description,
    'photo_keys', coalesce((select jsonb_agg(f.object_key order by f.sort)
                            from public.product_photos f where f.product_id = p.id), '[]'::jsonb),
    'variants', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', v.id, 'label', v.label,
        'price_minor', coalesce(v.price_minor, p.price_minor),
        'available', p.is_available and (v.stock_quantity is null or v.stock_quantity > 0))
        order by v.sort, v.created_at)
      from public.product_variants v where v.product_id = p.id), '[]'::jsonb),
    'store', app.store_summary(p.store_id, p_at),
    'zone_name', (select z.name from public.zones z where z.id = p_zone),
    'serves_zone', app.store_serves(p.store_id, p_zone)
  )
  from public.products p
  join public.stores s on s.id = p.store_id
  where p.id = p_product and p.status = 'published' and s.status = 'active'
$$;

revoke all on function
  public.discover_stores(uuid, integer, timestamptz),
  public.nearest_zone(numeric, numeric, char),
  public.search_catalog(text, uuid, uuid, text, bigint, bigint, boolean, text, integer, integer, timestamptz),
  public.store_page(uuid, timestamptz),
  public.product_page(uuid, uuid, timestamptz)
  from public;
grant execute on function
  public.discover_stores(uuid, integer, timestamptz),
  public.nearest_zone(numeric, numeric, char),
  public.search_catalog(text, uuid, uuid, text, bigint, bigint, boolean, text, integer, integer, timestamptz),
  public.store_page(uuid, timestamptz),
  public.product_page(uuid, uuid, timestamptz)
  to authenticated, anonymous;
