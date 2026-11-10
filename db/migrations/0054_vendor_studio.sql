-- 0054 — Boutique partageable, prix de fin de marché (spec 048, VISION §3 « Vendeuse » : boutique
-- partageable sur WhatsApp ; arrivages, prix de fin de marché). Le studio IA et les arrivages
-- existent déjà (specs 007, 019, 033).
-- 1. Fin de marché : la vendeuse baisse ses prix d'un pourcentage (5 à 70 %) pour quelques heures,
--    sur toute la boutique ou des produits choisis. Le prix réduit passe par la fonction de prix
--    unique : affichage, panier et commande restent d'accord.
-- 2. Partage : lien public de la boutique (page légère de la Function), qui ouvre la boutique
--    dans l'app web.

alter table public.products
  add column eom_percent smallint check (eom_percent is null or eom_percent between 5 and 70),
  add column eom_until timestamptz,
  add check ((eom_percent is null) = (eom_until is null));

-- Prix pendant la fin de marché (arrondi vers le bas, en unités mineures).
create or replace function app.eom_price(p_price bigint, p_product uuid) returns bigint
language sql stable security definer set search_path = ''
as $$
  select case when p.eom_until > now() then (p_price * (100 - p.eom_percent)) / 100 else p_price end
  from public.products p where p.id = p_product
$$;

-- Fin de marché : [p_products] nul = toute la boutique ; durée 1 à 12 heures.
create or replace function public.set_end_of_market(p_percent integer, p_hours integer default 3,
  p_products uuid[] default null) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store uuid := app.own_store_id();
  v_count integer;
begin
  if v_store is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if p_percent is null or p_percent not between 5 and 70 then raise exception 'invalid_percent' using errcode = '22023'; end if;
  if p_hours is null or p_hours not between 1 and 12 then raise exception 'invalid_hours' using errcode = '22023'; end if;
  update public.products set eom_percent = p_percent, eom_until = now() + make_interval(hours => p_hours)
  where store_id = v_store and status = 'published' and (p_products is null or id = any (p_products));
  get diagnostics v_count = row_count;
  perform app.emit_event('end_of_market_started', app.current_user_id(), 'vendor', 'server',
    (select country_code from public.stores where id = v_store), 'store', v_store::text,
    jsonb_build_object('percent', p_percent, 'hours', p_hours, 'products', v_count));
  return public.my_end_of_market();
end
$fn$;

create or replace function public.clear_end_of_market() returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
begin
  update public.products set eom_percent = null, eom_until = null where store_id = app.own_store_id();
  return public.my_end_of_market();
end
$fn$;

-- Vendeuse : fin de marché en cours (produits, pourcentage, fin).
create or replace function public.my_end_of_market() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'active', exists (select 1 from public.products where store_id = app.own_store_id() and eom_until > now()),
    'percent', (select max(eom_percent) from public.products where store_id = app.own_store_id() and eom_until > now()),
    'until', (select max(eom_until) from public.products where store_id = app.own_store_id() and eom_until > now()),
    'products', (select count(*) from public.products where store_id = app.own_store_id() and eom_until > now()))
$$;

-- Page publique d'une boutique partagée (Function) : nom, origine, quartier, photo.
create or replace function app.store_share_preview(p_store uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('id', s.id, 'name', s.name, 'zone_name', z.name,
    'cover_key', (select f.object_key from public.products p join public.product_photos f on f.product_id = p.id
                  where p.store_id = s.id and p.status = 'published' order by p.published_at, f.sort limit 1),
    'product_count', (select count(*) from public.products p where p.store_id = s.id and p.status = 'published'))
  from public.stores s join public.zones z on z.id = s.zone_id
  where s.id = p_store and s.status = 'active'
$$;

insert into public.event_names (name, emitted_by, description) values
  ('end_of_market_started', 'server', 'Fin de marché lancée (pourcentage, durée, produits)')
on conflict do nothing;

-- Prix (0011, 0008, 0040) : fin de marché appliquée partout.
create or replace function app.variant_price(p_variant uuid) returns bigint
language sql stable security definer set search_path = ''
as $$
  select app.eom_price(coalesce(v.price_minor, p.price_minor), p.id)
  from public.product_variants v join public.products p on p.id = v.product_id
  where v.id = p_variant
$$;

create or replace function app.product_min_price(p_product uuid) returns bigint
language sql stable security definer set search_path = ''
as $$
  select app.eom_price(least(p.price_minor,
    (select min(v.price_minor) from public.product_variants v where v.product_id = p.id)), p.id)
  from public.products p where p.id = p_product
$$;

create or replace function app.catalog_item(p_product uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', p.id, 'name', p.name, 'category_id', p.category_id,
    'price_minor', app.eom_price(p.price_minor, p.id), 'min_price_minor', app.product_min_price(p.id),
    -- Fin de marché (spec 048) : prix d'origine et fin de la remise.
    'end_of_market', case when p.eom_until > now() then jsonb_build_object(
      'percent', p.eom_percent, 'until', p.eom_until, 'original_price_minor', p.price_minor) end,
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
        'price_minor', app.eom_price(coalesce(v.price_minor, p.price_minor), p.id),
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

revoke all on function app.eom_price(bigint, uuid), public.set_end_of_market(integer, integer, uuid[]),
  public.clear_end_of_market(), public.my_end_of_market(), app.store_share_preview(uuid) from public;
grant execute on function public.set_end_of_market(integer, integer, uuid[]), public.clear_end_of_market(),
  public.my_end_of_market() to authenticated;
