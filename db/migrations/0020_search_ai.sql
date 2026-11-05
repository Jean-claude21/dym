-- Spec 018 : recherche vocale et par photo, historique, suggestions.
-- La voix est transcrite et la photo décrite par une Function (modèles de
-- `ai_models`) ; le texte obtenu passe par la recherche plein texte existante
-- (search_catalog). Tout est derrière le flag `ai_search` (coupé par défaut).

-- ------------------------------------------------------------------ flags

-- Flag actif pour un pays : flag du pays, à défaut flag global ; absent : non.
create or replace function app.feature_enabled(p_key text, p_country char(2))
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    (select is_enabled from public.feature_flags where key = p_key and country_code = p_country),
    (select is_enabled from public.feature_flags where key = p_key and country_code is null),
    false)
$$;

-- ------------------------------------------------------------------ historique

create table public.search_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  query text not null check (length(query) between 2 and 80),
  source text not null default 'text' check (source in ('text', 'voice', 'photo')),
  searched_at timestamptz not null default clock_timestamp()
);

create unique index search_history_query on public.search_history (user_id, lower(query));
create index search_history_recent on public.search_history (user_id, searched_at desc);

alter table public.search_history enable row level security;
revoke all on public.search_history from anonymous, authenticated;

-- Retient une recherche (la remonte si elle existe) ; 20 au plus par personne.
create or replace function public.remember_search(p_query text, p_source text default 'text')
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_query text := left(regexp_replace(trim(coalesce(p_query, '')), '\s+', ' ', 'g'), 80);
begin
  if p_source not in ('text', 'voice', 'photo') then
    raise exception 'source inconnue' using errcode = '22023';
  end if;
  if length(v_query) < 2 then
    return;
  end if;
  insert into public.search_history (user_id, query, source)
  values (v_user, v_query, p_source)
  on conflict (user_id, lower(query))
  do update set searched_at = clock_timestamp(), source = excluded.source, query = excluded.query;
  delete from public.search_history
  where user_id = v_user and id not in (
    select id from public.search_history where user_id = v_user
    order by searched_at desc limit 20);
end
$$;

-- Dernières recherches de la personne connectée (les plus récentes d'abord).
create or replace function public.my_searches(p_limit int default 8)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object('query', query, 'source', source,
           'searched_at', searched_at) order by searched_at desc), '[]'::jsonb)
  from (select query, source, searched_at from public.search_history
        where user_id = app.require_user()
        order by searched_at desc
        limit greatest(1, least(coalesce(p_limit, 8), 20))) h
$$;

create or replace function public.forget_searches() returns void
language sql security definer set search_path = ''
as $$
  delete from public.search_history where user_id = app.require_user()
$$;

-- ------------------------------------------------------------------ suggestions

-- Complétions pendant la saisie : rayons puis produits en vente dans le
-- quartier, dont un mot commence par le texte saisi. 8 au plus.
create or replace function public.search_suggestions(p_prefix text, p_zone uuid default null)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_prefix text := lower(left(trim(coalesce(p_prefix, '')), 40));
  v_like text;
begin
  if length(v_prefix) < 1 then
    return '[]'::jsonb;
  end if;
  v_like := replace(replace(replace(v_prefix, '\', '\\'), '%', '\%'), '_', '\_');
  return coalesce((
    select jsonb_agg(jsonb_build_object('kind', kind, 'label', label, 'category_id', category_id)
                     order by ord, lower(label ->> 'fr'))
    from (
      select * from (
        select distinct on (c.id) 'category' as kind, c.label, c.id as category_id, 0 as ord
        from public.categories c
        where c.is_active
          and exists (select 1 from jsonb_each_text(c.label) l
                      where lower(l.value) like v_like || '%' or lower(l.value) like '% ' || v_like || '%')
        limit 3) cats
      union all
      select * from (
        select distinct on (lower(p.name)) 'product' as kind, jsonb_build_object('fr', p.name),
               null::uuid, 1
        from public.products p
        join public.stores s on s.id = p.store_id
        where p.status = 'published' and s.status = 'active'
          and app.store_serves(s.id, p_zone)
          and (lower(p.name) like v_like || '%' or lower(p.name) like '% ' || v_like || '%')
        order by lower(p.name)
        limit 5) prods
    ) t), '[]'::jsonb);
end
$$;

-- ------------------------------------------------------------------ IA

-- Requêtes IA (A-AI-01..03, suivi en spec 021) : résultat et latence, sans
-- contenu (ni audio, ni photo, ni texte).
create table public.ai_requests (
  id bigint generated always as identity primary key,
  usage text not null check (usage ~ '^[a-z][a-z0-9_]*$'),
  user_id uuid references neon_auth."user" (id) on delete set null,
  country_code char(2) references public.countries (code),
  outcome text not null check (outcome in ('success', 'no_result', 'failure')),
  latency_ms int not null check (latency_ms >= 0),
  created_at timestamptz not null default clock_timestamp()
);

create index ai_requests_recent on public.ai_requests (usage, created_at desc);

alter table public.ai_requests enable row level security;
revoke all on public.ai_requests from anonymous, authenticated;

-- Contexte d'une recherche IA (Function) : flag `ai_search` actif pour le pays
-- de la personne, modèle actif pour l'usage. Refus : `feature_disabled`.
create or replace function app.search_ai_context(p_user uuid, p_usage text)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_country char(2) := (select country_code from public.profiles where user_id = p_user);
  v_model jsonb;
begin
  if p_usage not in ('search_transcription', 'search_from_photo') then
    raise exception 'usage inconnu' using errcode = '22023';
  end if;
  if v_country is null or not app.feature_enabled('ai_search', v_country) then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  select jsonb_build_object('provider', provider, 'model', model, 'params', params)
  into v_model from public.ai_models where usage = p_usage and is_active;
  if v_model is null then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  return jsonb_build_object('country_code', v_country, 'model', v_model);
end
$$;

-- Résultat d'une requête IA : journal et événement serveur (sans contenu).
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
begin
  insert into public.ai_requests (usage, user_id, country_code, outcome, latency_ms)
  values (p_usage, p_user, v_country, p_outcome, greatest(coalesce(p_latency_ms, 0), 0));
  perform app.emit_event(
    case p_usage when 'search_transcription' then 'voice_search_used' else 'photo_search_used' end,
    p_user, 'client', 'client', v_country, null, null,
    jsonb_build_object('outcome', p_outcome, 'latency_ms', p_latency_ms));
end
$$;

-- ------------------------------------------------------------------ référentiel

insert into public.ai_models (usage, provider, model, params, is_active) values
  ('search_transcription', 'openai', 'gpt-4o-mini-transcribe', '{}', true),
  ('search_from_photo', 'openai', 'gpt-5.4-mini', '{"temperature": 0.2}', true)
on conflict (usage) do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('voice_search_used', 'server', 'Recherche vocale transcrite (résultat, latence)'),
  ('photo_search_used', 'server', 'Recherche par photo décrite (résultat, latence)')
on conflict (name) do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function
  app.feature_enabled(text, char), app.search_ai_context(uuid, text),
  app.record_ai_request(uuid, text, text, int),
  public.remember_search(text, text), public.my_searches(int), public.forget_searches(),
  public.search_suggestions(text, uuid)
from public;

grant execute on function public.search_suggestions(text, uuid) to authenticated, anonymous;
grant execute on function
  public.remember_search(text, text), public.my_searches(int), public.forget_searches()
to authenticated;
