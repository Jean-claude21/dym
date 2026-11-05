-- Spec 019 : copilote d'intention. La Function découpe une intention
-- (« une sauce gombo pour 4 personnes ») en besoins, avec le modèle
-- `intent_copilot` ; ici, chaque besoin devient un produit disponible dans le
-- quartier (en regroupant les boutiques), puis le panier proposé est chiffré.
-- Aucun prix ne vient de l'IA ni de l'app. Derrière le flag `intent_copilot`.

-- ------------------------------------------------------------------ chiffrage

-- Panier proposé, chiffré au prix du jour et groupé par boutique. Lignes
-- `{variant_id, quantity, need}` ; une ligne invalide (produit retiré, en
-- rupture, autre devise) est écartée. Quantité entre 1 et 10, bornée au stock.
create or replace function app.copilot_quote(p_items jsonb) returns jsonb
language sql stable security definer set search_path = ''
as $$
  with raw as (
    select (i ->> 'variant_id')::uuid as variant_id,
           greatest(1, least(coalesce((i ->> 'quantity')::int, 1), 10)) as quantity,
           left(i ->> 'need', 60) as need, ord
    from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) with ordinality as t(i, ord)
  ),
  lines as (
    select distinct on (r.variant_id)
           r.variant_id, r.need, r.ord, v.product_id, p.name, v.label as variant_label,
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
                 'photo_key', photo_key, 'need', need) order by ord) as items
        from priced group by store_id, store_name) g), '[]'::jsonb))
$$;

-- Rechiffrage après un retrait ou un changement de quantité (Data API).
create or replace function public.copilot_quote(p_items jsonb) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_user();
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) > 10 then
    raise exception 'panier proposé invalide' using errcode = '22023';
  end if;
  return app.copilot_quote(p_items);
end
$$;

-- ------------------------------------------------------------------ choix

-- Un produit par besoin `{label, query, quantity}` : en vente, disponible,
-- livré dans le quartier ; d'abord une boutique déjà retenue, puis la
-- pertinence, puis le prix. Variante : la moins chère en stock.
-- Besoin sans produit : rangé dans `missing` (« Je n'ai pas trouvé : … »).
create or replace function app.copilot_pick(p_zone uuid, p_needs jsonb) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_need jsonb;
  v_query tsquery;
  v_stores uuid[] := '{}';
  v_items jsonb := '[]'::jsonb;
  v_missing jsonb := '[]'::jsonb;
  v_pick record;
  v_label text;
begin
  for v_need in select n from jsonb_array_elements(coalesce(p_needs, '[]'::jsonb)) n limit 7 loop
    v_label := left(trim(coalesce(v_need ->> 'label', v_need ->> 'query', '')), 60);
    v_query := app.search_query(v_need ->> 'query');
    v_pick := null;
    if v_query is not null then
      select p.id as product_id, s.id as store_id,
             (select v.id from public.product_variants v
              where v.product_id = p.id and coalesce(v.stock_quantity, 1) > 0
              order by app.variant_price(v.id), v.sort limit 1) as variant_id
      into v_pick
      from public.products p
      join public.stores s on s.id = p.store_id
      where p.status = 'published' and s.status = 'active'
        and p.search @@ v_query
        and app.store_serves(s.id, p_zone)
        and app.product_available(p.id)
      order by (s.id = any(v_stores)) desc, ts_rank(p.search, v_query) desc,
               app.product_min_price(p.id), p.name
      limit 1;
    end if;
    if v_pick.variant_id is null then
      if length(v_label) > 0 then
        v_missing := v_missing || to_jsonb(v_label);
      end if;
    else
      v_stores := array_append(v_stores, v_pick.store_id);
      v_items := v_items || jsonb_build_object('variant_id', v_pick.variant_id,
        'quantity', coalesce((v_need ->> 'quantity')::int, 1), 'need', v_label);
    end if;
  end loop;
  return app.copilot_quote(v_items) || jsonb_build_object('missing', v_missing);
end
$$;

-- ------------------------------------------------------------------ IA

-- Contexte de la Function : flag `intent_copilot` du pays de la personne et
-- modèle actif ; le quartier doit exister dans ce pays. Refus `feature_disabled`.
create or replace function app.copilot_context(p_user uuid, p_zone uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_country char(2) := (select country_code from public.profiles where user_id = p_user);
  v_model jsonb;
begin
  if v_country is null or not app.feature_enabled('intent_copilot', v_country) then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  if p_zone is not null and not exists (
    select 1 from public.zones z join public.cities c on c.id = z.city_id
    where z.id = p_zone and c.country_code = v_country) then
    raise exception 'quartier inconnu' using errcode = '22023';
  end if;
  select jsonb_build_object('provider', provider, 'model', model, 'params', params)
  into v_model from public.ai_models where usage = 'intent_copilot' and is_active;
  if v_model is null then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  return jsonb_build_object('country_code', v_country, 'model', v_model);
end
$$;

-- Journal des requêtes IA : le copilote émet son propre événement (comptes).
create or replace function app.record_ai_request(
  p_user uuid,
  p_usage text,
  p_outcome text,
  p_latency_ms int
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_country char(2) := (select country_code from public.profiles where user_id = p_user);
  v_event text := case p_usage
    when 'search_transcription' then 'voice_search_used'
    when 'search_from_photo' then 'photo_search_used' end;
begin
  insert into public.ai_requests (usage, user_id, country_code, outcome, latency_ms)
  values (p_usage, p_user, v_country, p_outcome, greatest(coalesce(p_latency_ms, 0), 0));
  if v_event is not null then
    perform app.emit_event(v_event, p_user, 'client', 'client', v_country, null, null,
      jsonb_build_object('outcome', p_outcome, 'latency_ms', p_latency_ms));
  end if;
end
$$;

-- Proposition faite : comptes seulement (jamais le texte de l'intention).
create or replace function app.copilot_proposed(p_user uuid, p_proposal jsonb, p_latency_ms int)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_items int := coalesce((p_proposal ->> 'item_count')::int, 0);
  v_country char(2) := (select country_code from public.profiles where user_id = p_user);
begin
  perform app.record_ai_request(p_user, 'intent_copilot',
    case when v_items > 0 then 'success' else 'no_result' end, p_latency_ms);
  perform app.emit_event('copilot_proposed', p_user, 'client', 'client', v_country, null, null,
    jsonb_build_object('items_count', v_items,
      'stores_count', jsonb_array_length(coalesce(p_proposal -> 'stores', '[]'::jsonb)),
      'missing_count', jsonb_array_length(coalesce(p_proposal -> 'missing', '[]'::jsonb)),
      'latency_ms', p_latency_ms));
end
$$;

-- ------------------------------------------------------------------ référentiel

insert into public.ai_models (usage, provider, model, params, is_active) values
  ('intent_copilot', 'openai', 'gpt-5.4-mini', '{"temperature": 0.2}', true)
on conflict (usage) do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('copilot_proposed', 'server', 'Panier proposé par le copilote (articles, boutiques, manquants)'),
  ('copilot_cart_added', 'client', 'Panier du copilote ajouté au panier (articles)')
on conflict (name) do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function
  app.copilot_quote(jsonb), app.copilot_pick(uuid, jsonb), app.copilot_context(uuid, uuid),
  app.copilot_proposed(uuid, jsonb, int), public.copilot_quote(jsonb)
from public;

grant execute on function public.copilot_quote(jsonb) to authenticated;
