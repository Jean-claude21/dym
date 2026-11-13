-- Recherche tolérante aux fautes (spec 079) : si les mots exacts ne trouvent
-- rien, les noms proches (trigrammes) sont proposés et signalés (`fuzzy`).

create extension if not exists pg_trgm schema extensions;

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
  v_query tsquery := app.expand_query(p_query, app.zone_country(p_zone));
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 50));
  v_result jsonb;
  v_norm text := app.normalize(btrim(coalesce(p_query, '')));
  -- Faute de frappe (spec 079) : rien par les mots exacts → noms proches.
  v_fuzzy boolean := false;
begin
  if p_sort not in ('relevance', 'price_asc', 'price_desc') then
    raise exception 'tri inconnu' using errcode = '22023';
  end if;
  if v_query is not null and length(v_norm) >= 3 and not exists (
    select 1 from public.products p join public.stores s on s.id = p.store_id
    where p.status = 'published' and s.status = 'active' and p.search @@ v_query
      and app.store_serves(s.id, p_zone)
  ) then
    v_fuzzy := true;
  end if;
  with matches as (
    select p.id, p.name,
           app.product_min_price(p.id) as price,
           case when v_fuzzy then extensions.word_similarity(v_norm, app.normalize(p.name))
                when v_query is null then 0 else ts_rank(p.search, v_query) end as rank,
           -- Nom exact, puis nom qui commence par la requête : devant les synonymes.
           case when lower(p.name) = lower(btrim(coalesce(p_query, ''))) then 2
                when btrim(coalesce(p_query, '')) <> ''
                 and lower(p.name) like lower(btrim(p_query)) || '%' then 1 else 0 end as name_match
    from public.products p
    join public.stores s on s.id = p.store_id
    left join public.categories cat on cat.id = p.category_id
    where p.status = 'published' and s.status = 'active'
      and (v_query is null or p.search @@ v_query
           or (v_fuzzy and extensions.word_similarity(v_norm, app.normalize(p.name)) >= 0.45))
      and app.store_serves(s.id, p_zone)
      and (p_category is null or p.category_id = p_category or cat.parent_id = p_category)
      and (p_origin is null or s.origin = p_origin)
      and (p_min_price is null or app.product_min_price(p.id) >= p_min_price)
      and (p_max_price is null or app.product_min_price(p.id) <= p_max_price)
      and (not p_available_only or app.product_available(p.id))
  )
  select jsonb_build_object(
    'total', (select count(*) from matches),
    -- Résultats trouvés malgré une faute : l'écran peut le dire.
    'fuzzy', v_fuzzy,
    'products', coalesce((
      select jsonb_agg(app.catalog_item(id) order by ord)
      from (
        select id, row_number() over (order by
          case when p_sort = 'price_asc' then price end asc,
          case when p_sort = 'price_desc' then price end desc,
          name_match desc, rank desc, name, id) as ord
        from matches
        order by ord
        limit v_limit offset greatest(coalesce(p_offset, 0), 0)
      ) page), '[]'::jsonb),
    'stores', case when v_query is null or coalesce(p_offset, 0) > 0 then '[]'::jsonb else coalesce((
      select jsonb_agg(app.store_summary(id, p_at) order by rank desc, name)
      from (
        select s.id, s.name,
               case when v_fuzzy then extensions.word_similarity(v_norm, app.normalize(s.name))
                    else ts_rank(s.search, v_query) end as rank
        from public.stores s
        where s.status = 'active'
          and (s.search @@ v_query
               or (v_fuzzy and extensions.word_similarity(v_norm, app.normalize(s.name)) >= 0.45))
          and app.store_serves(s.id, p_zone)
          and (p_origin is null or s.origin = p_origin)
        order by rank desc, s.name
        limit 5
      ) t), '[]'::jsonb) end
  ) into v_result;
  return v_result;
end
$$;
