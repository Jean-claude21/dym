-- 0043 — Créateurs et contenus de tous (spec 036).
-- Toute personne peut devenir créatrice (rôle `creator`, profil public) et publier des posts
-- (photo ou vidéo), avec une catégorie choisie, proposée par l'IA ou « Autre », et des produits
-- en vente de n'importe quelle boutique. Les contenus des boutiques (spec 020) restent inchangés.

alter table public.user_roles drop constraint user_roles_role_check;
alter table public.user_roles add constraint user_roles_role_check
  check (role in ('client', 'vendor', 'admin', 'courier', 'creator'));

create table public.creator_profiles (
  user_id uuid primary key references neon_auth."user" (id) on delete cascade,
  display_name text not null check (length(btrim(display_name)) between 2 and 40),
  bio text check (bio is null or length(bio) <= 200),
  country_code char(2) not null references public.countries (code),
  created_at timestamptz not null default clock_timestamp()
);
alter table public.creator_profiles enable row level security;
create policy creator_profiles_read on public.creator_profiles for select to authenticated, anonymous using (true);
revoke all on public.creator_profiles from authenticated, anonymous;
grant select (user_id, display_name, bio, country_code, created_at) on public.creator_profiles
  to authenticated, anonymous;

create table public.content_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z]+(_[a-z]+)*$'),
  label jsonb not null check (jsonb_typeof(label) = 'object'),
  sort smallint not null default 0,
  is_active boolean not null default true
);
alter table public.content_categories enable row level security;
create policy content_categories_read on public.content_categories for select
  to authenticated, anonymous using (is_active);
revoke all on public.content_categories from authenticated, anonymous;
grant select on public.content_categories to authenticated, anonymous;
insert into public.content_categories (slug, label, sort) values
  ('recettes', '{"fr": "Recettes", "en": "Recipes"}', 1),
  ('astuces', '{"fr": "Astuces", "en": "Tips"}', 2),
  ('marche', '{"fr": "Au marché", "en": "At the market"}', 3),
  ('ustensiles', '{"fr": "Ustensiles", "en": "Kitchenware"}', 4),
  ('nutrition', '{"fr": "Bien manger", "en": "Eating well"}', 5),
  ('autre', '{"fr": "Autre", "en": "Other"}', 99)
on conflict (slug) do nothing;

alter table public.contents alter column store_id drop not null;
alter table public.contents
  add column author_id uuid references neon_auth."user" (id) on delete cascade,
  add column category_id uuid references public.content_categories (id),
  add column category_source text check (category_source in ('chosen', 'ai', 'default')),
  add constraint contents_owner_check check ((store_id is null) <> (author_id is null));
alter table public.contents drop constraint contents_kind_check;
alter table public.contents add constraint contents_kind_check check (kind in ('story', 'video', 'post'));
alter table public.contents drop constraint contents_media_key_check;
alter table public.contents add constraint contents_media_key_check check (
  media_key is null
  or media_key ~ '^stores/[0-9a-f-]{36}/contents/[0-9a-f-]{36}\.(jpg|webp|mp4)$'
  or media_key ~ '^creators/[0-9a-f-]{36}/contents/[0-9a-f-]{36}\.(jpg|webp|mp4)$');
-- Ancienne règle « une story ou une vidéo » : un post peut être une photo.
alter table public.contents drop constraint contents_check;
alter table public.contents add constraint contents_media_shape check (
  kind in ('story', 'post') or media_type = 'video');
create index contents_author on public.contents (author_id, created_at desc) where author_id is not null;

-- Modèle de classement : configuré en base (désactivé si absent).
insert into public.ai_models (usage, provider, model, params, is_active) values
  ('content_classifier', 'openai', 'gpt-5.4-mini', '{"temperature": 0}', true)
on conflict (usage) do nothing;

-- ------------------------------------------------------------------ créatrices

create or replace function public.become_creator(p_display_name text, p_bio text default null) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_name text := regexp_replace(btrim(coalesce(p_display_name, '')), '\s+', ' ', 'g');
  v_country char(2) := (select country_code from public.profiles where user_id = v_user);
  v_new boolean := not exists (select 1 from public.creator_profiles where user_id = v_user);
begin
  if v_country is null then raise exception 'profile_required' using errcode = '22023'; end if;
  if length(v_name) not between 2 and 40 then raise exception 'invalid_name' using errcode = '22023'; end if;
  insert into public.creator_profiles (user_id, display_name, bio, country_code)
  values (v_user, v_name, nullif(left(btrim(coalesce(p_bio, '')), 200), ''), v_country)
  on conflict (user_id) do update set display_name = excluded.display_name, bio = excluded.bio;
  insert into public.user_roles (user_id, role) values (v_user, 'creator') on conflict do nothing;
  if v_new then
    perform app.emit_event('creator_joined', v_user, 'client', 'server', v_country, 'creator', v_user::text,
      '{}'::jsonb);
  end if;
  return public.my_creator_profile();
end
$fn$;

create or replace function public.my_creator_profile() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select to_jsonb(c) - 'country_code' from public.creator_profiles c where c.user_id = app.current_user_id()
$$;

-- Contexte du classement (Function) : modèle actif, catégories du référentiel.
create or replace function app.content_classifier_context(p_user uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_model jsonb;
begin
  if not exists (select 1 from public.creator_profiles where user_id = p_user) then
    raise exception 'not_creator' using errcode = '42501';
  end if;
  select jsonb_build_object('provider', provider, 'model', model, 'params', params)
  into v_model from public.ai_models where usage = 'content_classifier' and is_active;
  if v_model is null then raise exception 'feature_disabled' using errcode = 'P0001'; end if;
  return jsonb_build_object('model', v_model, 'categories', (
    select jsonb_agg(jsonb_build_object('slug', slug, 'label', label ->> 'fr') order by sort)
    from public.content_categories where is_active));
end
$fn$;

-- Publication d'un post de créatrice : média dans son dossier, catégorie du référentiel
-- (« Autre » par défaut), produits en vente (5 au plus).
create or replace function public.save_creator_content(p_content jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_id uuid := (p_content ->> 'id')::uuid;
  v_kind text := coalesce(p_content ->> 'kind', 'post');
  v_key text := p_content ->> 'media_key';
  v_category uuid := nullif(p_content ->> 'category_id', '')::uuid;
  v_source text := coalesce(p_content ->> 'category_source', 'chosen');
  v_products uuid[] := array(select jsonb_array_elements_text(coalesce(p_content -> 'product_ids', '[]'))::uuid);
  v_country char(2);
begin
  select country_code into v_country from public.creator_profiles where user_id = v_user;
  if v_country is null then raise exception 'not_creator' using errcode = '42501'; end if;
  if v_id is null or v_kind not in ('post', 'video') then
    raise exception 'invalid_content' using errcode = '22023';
  end if;
  if v_key is null or v_key !~ ('^creators/' || v_user || '/contents/' || v_id || '\.(jpg|webp|mp4)$') then
    raise exception 'invalid_media' using errcode = '22023';
  end if;
  if v_kind = 'video' and v_key !~ '\.mp4$' then raise exception 'invalid_media' using errcode = '22023'; end if;
  if v_category is null then
    v_category := (select id from public.content_categories where slug = 'autre');
    v_source := 'default';
  elsif not exists (select 1 from public.content_categories where id = v_category and is_active) then
    raise exception 'invalid_category' using errcode = '22023';
  end if;
  if v_source not in ('chosen', 'ai', 'default') then v_source := 'chosen'; end if;
  if cardinality(v_products) > 5 or exists (
    select 1 from unnest(v_products) pid
    where not exists (select 1 from public.products p join public.stores s on s.id = p.store_id
                      where p.id = pid and p.status = 'published' and s.status = 'active')) then
    raise exception 'invalid_products' using errcode = '22023';
  end if;
  if exists (select 1 from public.contents where id = v_id) then
    raise exception 'already_published' using errcode = '23505';
  end if;
  insert into public.contents (id, author_id, kind, media_key, media_type, caption, category_id, category_source)
  values (v_id, v_user, v_kind, v_key, case when v_key like '%.mp4' then 'video' else 'image' end,
          nullif(left(btrim(coalesce(p_content ->> 'caption', '')), 200), ''), v_category, v_source);
  insert into public.content_products (content_id, product_id, sort)
  select v_id, pid, ord - 1 from unnest(v_products) with ordinality as t(pid, ord);
  perform app.emit_event('content_published', v_user, 'client', 'server', v_country, 'content', v_id::text,
    jsonb_build_object('kind', v_kind, 'products_count', cardinality(v_products),
      'category', (select slug from public.content_categories where id = v_category), 'category_source', v_source,
      'creator', true));
  return app.content_json(v_id, v_user);
end
$fn$;

-- Mes posts de créatrice, avec statistiques.
create or replace function public.my_creator_contents() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.content_json(c.id, null) || jsonb_build_object(
           'view_count', c.view_count, 'click_count', c.click_count,
           'report_count', (select count(*) from public.reports r
                            where r.target_type = 'content' and r.target_id = c.id))
         order by c.created_at desc), '[]'::jsonb)
  from public.contents c
  where c.author_id = app.require_user() and c.status <> 'removed'
$$;

-- Visibilité : boutique active, ou post d'une créatrice.
create or replace function app.content_visible(p_content public.contents, p_at timestamptz)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select p_content.status = 'published'
     and (p_content.expires_at is null or p_content.expires_at > p_at)
     and (p_content.author_id is not null
          or exists (select 1 from public.stores s where s.id = p_content.store_id and s.status = 'active'))
$$;

create or replace function public.archive_content(p_content uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  update public.contents c set status = 'archived'
  where c.id = p_content and c.status = 'published'
    and (c.author_id = v_user
         or exists (select 1 from public.stores s where s.id = c.store_id and s.owner_id = v_user));
  if not found then raise exception 'contenu introuvable' using errcode = 'P0002'; end if;
end
$fn$;

create or replace function public.delete_content(p_content uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  delete from public.contents c
  where c.id = p_content
    and (c.author_id = v_user
         or exists (select 1 from public.stores s where s.id = c.store_id and s.owner_id = v_user));
  if not found then raise exception 'contenu introuvable' using errcode = 'P0002'; end if;
end
$fn$;

insert into public.event_names (name, emitted_by, description) values
  ('creator_joined', 'server', 'Profil créateur ouvert')
on conflict do nothing;

-- Contenu (0027) : boutique ou autrice, catégorie.
create or replace function app.content_json(p_content uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', c.id, 'kind', c.kind, 'media_key', c.media_key, 'media_type', c.media_type,
    'background', c.background,
    'caption', c.caption, 'status', c.status, 'created_at', c.created_at, 'expires_at', c.expires_at,
    'store', case when s.id is not null then jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin,
      'cover_key', (select f.object_key from public.products p
                                join public.product_photos f on f.product_id = p.id
                                where p.store_id = s.id and p.status = 'published'
                                order by p.published_at, f.sort limit 1)) end,
    'author', case when cp0.user_id is not null then jsonb_build_object('id', cp0.user_id,
      'display_name', cp0.display_name, 'bio', cp0.bio) end,
    'category', (select jsonb_build_object('id', cc.id, 'slug', cc.slug, 'label', cc.label)
                 from public.content_categories cc where cc.id = c.category_id),
    'category_source', c.category_source,
    'like_count', (select count(*) from public.content_likes l where l.content_id = c.id),
    'liked', p_user is not null and exists (select 1 from public.content_likes l
                                            where l.content_id = c.id and l.user_id = p_user),
    'products', coalesce((
      select jsonb_agg(app.catalog_item(cp.product_id) order by cp.sort)
      from public.content_products cp
      join public.products p on p.id = cp.product_id and p.status = 'published'
      where cp.content_id = c.id), '[]'::jsonb))
  from public.contents c left join public.stores s on s.id = c.store_id
  left join public.creator_profiles cp0 on cp0.user_id = c.author_id
  where c.id = p_content
$$;

-- Fil (0022) : posts et vidéos, des boutiques du quartier et des créatrices du pays.
create or replace function public.content_feed(
  p_zone uuid default null,
  p_tab text default 'for_you',
  p_before timestamptz default null,
  p_limit int default 10,
  p_product uuid default null,
  p_at timestamptz default now()
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
begin
  if p_tab not in ('for_you', 'following') then
    raise exception 'onglet inconnu' using errcode = '22023';
  end if;
  return coalesce((
    select jsonb_agg(app.content_json(c.id, v_user) order by c.created_at desc)
    from (
      select c.id, c.created_at from public.contents c
      where app.content_visible(c, p_at)
        and c.kind in ('video', 'post')
        and (c.store_id is null or app.store_serves(c.store_id, p_zone))
        and (c.author_id is null or p_zone is null or exists (
          select 1 from public.creator_profiles cr join public.zones z on z.id = p_zone
          join public.cities ci on ci.id = z.city_id
          where cr.user_id = c.author_id and cr.country_code = ci.country_code))
        and (p_before is null or c.created_at < p_before)
        and (p_product is null or exists (select 1 from public.content_products cp
                                          where cp.content_id = c.id and cp.product_id = p_product))
        and (p_tab = 'for_you' or (c.store_id is not null and exists (
          select 1 from public.orders o join public.purchases pu on pu.id = o.purchase_id
          where o.store_id = c.store_id and pu.user_id = v_user)))
      order by c.created_at desc
      limit greatest(1, least(coalesce(p_limit, 10), 20))) c), '[]'::jsonb);
end
$$;

-- Modération (0022) : posts de créatrices.
create or replace function public.admin_reports(p_status text default 'open') returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  if p_status not in ('open', 'decided') then
    raise exception 'statut inconnu' using errcode = '22023';
  end if;
  return coalesce((
    select jsonb_agg(row order by (row ->> 'first_at') desc)
    from (
      select jsonb_build_object(
        'target_type', r.target_type, 'target_id', r.target_id,
        'count', count(*), 'first_at', min(r.created_at),
        'reasons', jsonb_agg(distinct r.reason),
        'notes', coalesce(jsonb_agg(r.note) filter (where r.note is not null), '[]'::jsonb),
        'status', max(r.status), 'decision_reason', max(r.decision_reason),
        'preview', case r.target_type
          when 'content' then (select jsonb_build_object('title', coalesce(c.caption, ''), 'kind', c.kind,
                                 'media_key', c.media_key, 'media_type', c.media_type,
                                 'store_name', coalesce(s.name, (select cr.display_name from public.creator_profiles cr
                                                                 where cr.user_id = c.author_id)),
                                 'tags', coalesce((select jsonb_agg(p.name) from public.content_products cp
                                                   join public.products p on p.id = cp.product_id
                                                   where cp.content_id = c.id), '[]'::jsonb))
                               from public.contents c left join public.stores s on s.id = c.store_id
                               where c.id = r.target_id)
          when 'product' then (select jsonb_build_object('title', p.name, 'store_name', s.name,
                                 'media_key', (select f.object_key from public.product_photos f
                                               where f.product_id = p.id order by f.sort limit 1),
                                 'media_type', 'image')
                               from public.products p join public.stores s on s.id = p.store_id
                               where p.id = r.target_id)
          else (select jsonb_build_object('title', coalesce(v.comment, ''), 'store_name', s.name,
                  'rating', v.rating)
                from public.reviews v join public.stores s on s.id = v.store_id
                where v.id = r.target_id) end) as row
      from public.reports r
      where (p_status = 'open') = (r.status = 'open')
      group by r.target_type, r.target_id) g), '[]'::jsonb);
end
$$;

-- ------------------------------------------------------------------ droits

revoke all on function public.become_creator(text, text), public.my_creator_profile(),
  app.content_classifier_context(uuid), public.save_creator_content(jsonb), public.my_creator_contents()
  from public;
grant execute on function public.become_creator(text, text), public.my_creator_profile(),
  public.save_creator_content(jsonb), public.my_creator_contents() to authenticated;
