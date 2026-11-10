-- 0035 — Recherche et classement réglables (spec 028).
-- 1. Poids de classement par pays (défaut : pays nul), réglables depuis l'admin, audités.
-- 2. Noms locaux : synonymes par pays (gboma, adémè…), en données de référence.
-- 3. Recherche élargie aux synonymes ; choix du copilote noté selon les poids, avec une raison par
--    article (même boutique, ouverte, mieux notée, moins chère, du quartier, meilleure
--    correspondance). Aucune règle dans les apps.

create table public.ranking_rules (
  country_code char(2) references public.countries (code),
  weight_text integer not null default 40 check (weight_text between 0 and 100),
  weight_same_store integer not null default 30 check (weight_same_store between 0 and 100),
  weight_open integer not null default 20 check (weight_open between 0 and 100),
  weight_rating integer not null default 10 check (weight_rating between 0 and 100),
  weight_price integer not null default 10 check (weight_price between 0 and 100),
  weight_same_zone integer not null default 10 check (weight_same_zone between 0 and 100),
  updated_at timestamptz not null default now()
);
create unique index ranking_rules_country on public.ranking_rules (coalesce(country_code, '--'));
alter table public.ranking_rules enable row level security;
revoke all on public.ranking_rules from authenticated, anonymous;
insert into public.ranking_rules (country_code) values (null);

create table public.search_synonyms (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) references public.countries (code),
  term text not null check (term = lower(btrim(term)) and length(term) between 2 and 40),
  synonyms text[] not null check (cardinality(synonyms) between 1 and 10),
  created_at timestamptz not null default now()
);
create unique index search_synonyms_term on public.search_synonyms (coalesce(country_code, '--'), term);
alter table public.search_synonyms enable row level security;
revoke all on public.search_synonyms from authenticated, anonymous;

-- Noms locaux courants au Togo (à compléter depuis l'admin).
insert into public.search_synonyms (country_code, term, synonyms)
select 'TG', v.term, v.syn from (values
  ('gboma', array['épinard', 'feuille']),
  ('ademe', array['corète', 'feuille']),
  ('adjovan', array['poisson fumé']),
  ('gari', array['manioc']),
  ('akpan', array['maïs fermenté']),
  ('wagashi', array['fromage peul'])
) as v (term, syn)
where exists (select 1 from public.countries where code = 'TG');

-- Pays d'un quartier.
create or replace function app.zone_country(p_zone uuid) returns char(2)
language sql stable security definer set search_path = ''
as $$
  select c.country_code from public.zones z join public.cities c on c.id = z.city_id where z.id = p_zone
$$;

-- Requête élargie : chaque mot peut aussi valoir l'un de ses synonymes (pays ou tous pays).
create or replace function app.expand_query(p_text text, p_country char(2)) returns tsquery
language sql stable security definer set search_path = ''
as $$
  select to_tsquery('simple', string_agg(alt, ' & '))
  from (
    select '(' || quote_literal(t) || ':*' || coalesce((
      select string_agg(' | (' || (
        select string_agg(quote_literal(w) || ':*', ' & ')
        from regexp_split_to_table(app.normalize(s), '[^[:alnum:]]+') w where w <> '') || ')', '')
      from public.search_synonyms ss, unnest(ss.synonyms) s
      where ss.term = t and (ss.country_code is null or ss.country_code = p_country)), '') || ')' as alt
    from regexp_split_to_table(app.normalize(p_text), '[^[:alnum:]]+') t
    where t <> '') x
$$;

-- Poids du pays, sinon les poids par défaut.
create or replace function app.ranking_weights(p_country char(2)) returns public.ranking_rules
language sql stable security definer set search_path = ''
as $$
  select r.* from public.ranking_rules r
  where r.country_code = p_country or r.country_code is null
  order by r.country_code nulls last limit 1
$$;

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

create or replace function app.copilot_quote(p_items jsonb) returns jsonb
language sql stable security definer set search_path = ''
as $$
  with raw as (
    select (i ->> 'variant_id')::uuid as variant_id,
           greatest(1, least(coalesce((i ->> 'quantity')::int, 1), 10)) as quantity,
           left(i ->> 'need', 60) as need, left(i ->> 'reason', 20) as reason, ord
    from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) with ordinality as t(i, ord)
  ),
  lines as (
    select distinct on (r.variant_id)
           r.variant_id, r.need, r.reason, r.ord, v.product_id, p.name, v.label as variant_label,
           u.label as unit_label, p.currency_code, s.id as store_id, s.name as store_name,
           least(r.quantity, coalesce(v.stock_quantity, 10)) as quantity,
           app.variant_price(v.id) as unit_price_minor,
           (select f.object_key from public.product_photos f where f.product_id = p.id
            order by f.sort limit 1) as photo_key
    from raw r
    join public.product_variants v on v.id = r.variant_id
    join public.products p on p.id = v.product_id
    join public.stores s on s.id = p.store_id
    left join public.units u on u.id = p.unit_id
    where p.status = 'published' and s.status = 'active'
      and app.product_available(p.id) and coalesce(v.stock_quantity, 1) > 0
    order by r.variant_id, r.ord
  ),
  priced as (
    select l.*, l.quantity * l.unit_price_minor as line_minor
    from lines l
    where l.currency_code = (select currency_code from lines order by ord limit 1)
  )
  select jsonb_build_object(
    'currency_code', (select currency_code from priced limit 1),
    'total_minor', coalesce((select sum(line_minor) from priced), 0),
    'item_count', (select count(*) from priced),
    'stores', coalesce((
      select jsonb_agg(jsonb_build_object('id', store_id, 'name', store_name, 'items', items)
                       order by first_ord)
      from (
        select store_id, store_name, min(ord) as first_ord,
               jsonb_agg(jsonb_build_object(
                 'variant_id', variant_id, 'product_id', product_id, 'name', name,
                 'variant_label', variant_label, 'unit_label', unit_label, 'quantity', quantity,
                 'unit_price_minor', unit_price_minor, 'line_minor', line_minor,
                 'photo_key', photo_key, 'need', need, 'reason', reason) order by ord) as items
        from priced group by store_id, store_name) g), '[]'::jsonb))
$$;

-- Choix du copilote : meilleur score selon les poids du pays, raison du choix gardée.
create or replace function app.copilot_pick(p_zone uuid, p_needs jsonb) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_need jsonb;
  v_query tsquery;
  v_country char(2) := app.zone_country(p_zone);
  w public.ranking_rules := app.ranking_weights(v_country);
  v_stores uuid[] := '{}';
  v_items jsonb := '[]'::jsonb;
  v_missing jsonb := '[]'::jsonb;
  v_pick record;
  v_label text;
begin
  for v_need in select n from jsonb_array_elements(coalesce(p_needs, '[]'::jsonb)) n limit 7 loop
    v_label := left(trim(coalesce(v_need ->> 'label', v_need ->> 'query', '')), 60);
    v_query := app.expand_query(v_need ->> 'query', v_country);
    v_pick := null;
    if v_query is not null then
      with cand as (
        select p.id as product_id, s.id as store_id,
               ts_rank(p.search, v_query) as text_rank,
               (s.id = any(v_stores)) as same_store,
               app.store_open_at(s.id, now()) as open_now,
               coalesce((app.store_rating(s.id) ->> 'rating')::numeric, 0) / 5 as rating,
               app.product_min_price(p.id) as price,
               (s.zone_id = p_zone) as same_zone
        from public.products p
        join public.stores s on s.id = p.store_id
        where p.status = 'published' and s.status = 'active'
          and p.search @@ v_query
          and app.store_serves(s.id, p_zone)
          and app.product_available(p.id)
      ),
      norm as (
        select c.*,
               c.text_rank / nullif(max(c.text_rank) over (), 0) as text_n,
               case when max(c.price) over () = min(c.price) over () then 1
                    else 1 - (c.price - min(c.price) over ())::numeric
                         / (max(c.price) over () - min(c.price) over ()) end as price_n
        from cand c
      ),
      scored as (
        select n.*,
               w.weight_text * coalesce(n.text_n, 0) as s_text,
               w.weight_same_store * n.same_store::int as s_store,
               w.weight_open * n.open_now::int as s_open,
               w.weight_rating * n.rating as s_rating,
               w.weight_price * n.price_n as s_price,
               w.weight_same_zone * coalesce(n.same_zone, false)::int as s_zone
        from norm n
      )
      select s.product_id, s.store_id,
             (select v.id from public.product_variants v
              where v.product_id = s.product_id and coalesce(v.stock_quantity, 1) > 0
              order by app.variant_price(v.id), v.sort limit 1) as variant_id,
             (select r.code from (values
                ('same_store', s.s_store), ('open_now', s.s_open), ('top_rated', s.s_rating),
                ('best_price', s.s_price), ('nearby', s.s_zone), ('best_match', s.s_text)
              ) as r (code, v) order by r.v desc, r.code limit 1) as reason
      into v_pick
      from scored s
      order by s.s_text + s.s_store + s.s_open + s.s_rating + s.s_price + s.s_zone desc,
               s.price, s.product_id
      limit 1;
    end if;
    if v_pick.variant_id is null then
      if length(v_label) > 0 then
        v_missing := v_missing || to_jsonb(v_label);
      end if;
    else
      v_stores := array_append(v_stores, v_pick.store_id);
      v_items := v_items || jsonb_build_object('variant_id', v_pick.variant_id,
        'quantity', coalesce((v_need ->> 'quantity')::int, 1), 'need', v_label,
        'reason', v_pick.reason);
    end if;
  end loop;
  return app.copilot_quote(v_items) || jsonb_build_object('missing', v_missing);
end
$fn$;

-- ------------------------------------------------------------------ admin

create or replace function public.admin_search_settings() returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
begin
  perform app.require_admin();
  return jsonb_build_object(
    'rules', coalesce((select jsonb_agg(to_jsonb(r) order by r.country_code nulls first)
                       from public.ranking_rules r), '[]'::jsonb),
    'synonyms', coalesce((select jsonb_agg(jsonb_build_object('id', s.id, 'country_code', s.country_code,
                            'term', s.term, 'synonyms', to_jsonb(s.synonyms))
                          order by s.country_code nulls first, s.term)
                          from public.search_synonyms s), '[]'::jsonb));
end
$fn$;

-- Poids d'un pays (nul : défaut) ; audité.
create or replace function public.admin_set_ranking(p_country char(2), p_weights jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_admin uuid := app.require_admin();
  v_before jsonb;
  v_base public.ranking_rules := app.ranking_weights(p_country);
begin
  select to_jsonb(r) into v_before from public.ranking_rules r where r.country_code is not distinct from p_country;
  delete from public.ranking_rules where country_code is not distinct from p_country;
  insert into public.ranking_rules (country_code, weight_text, weight_same_store, weight_open,
                                    weight_rating, weight_price, weight_same_zone)
  values (p_country,
    coalesce((p_weights ->> 'weight_text')::int, v_base.weight_text),
    coalesce((p_weights ->> 'weight_same_store')::int, v_base.weight_same_store),
    coalesce((p_weights ->> 'weight_open')::int, v_base.weight_open),
    coalesce((p_weights ->> 'weight_rating')::int, v_base.weight_rating),
    coalesce((p_weights ->> 'weight_price')::int, v_base.weight_price),
    coalesce((p_weights ->> 'weight_same_zone')::int, v_base.weight_same_zone));
  perform app.admin_did(v_admin, 'ranking_set', 'ranking_rules', coalesce(p_country, '*'),
    v_before, p_weights, null, p_country);
  return public.admin_search_settings();
end
$fn$;

-- Ajoute ou remplace les synonymes d'un terme (liste vide : retire le terme) ; audité.
create or replace function public.admin_set_synonym(p_country char(2), p_term text, p_synonyms text[])
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_admin uuid := app.require_admin();
  v_term text := lower(btrim(p_term));
begin
  delete from public.search_synonyms where country_code is not distinct from p_country and term = v_term;
  if cardinality(coalesce(p_synonyms, '{}')) > 0 then
    insert into public.search_synonyms (country_code, term, synonyms) values (p_country, v_term, p_synonyms);
  end if;
  perform app.admin_did(v_admin, 'synonym_set', 'search_synonyms', v_term, null,
    jsonb_build_object('country_code', p_country, 'synonyms', to_jsonb(p_synonyms)), null, p_country);
  return public.admin_search_settings();
end
$fn$;

revoke all on function public.admin_search_settings(), public.admin_set_ranking(char, jsonb),
  public.admin_set_synonym(char, text, text[]) from public;
grant execute on function public.admin_search_settings(), public.admin_set_ranking(char, jsonb),
  public.admin_set_synonym(char, text, text[]) to authenticated;
