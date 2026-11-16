-- 0094 — Cuisine sociale (spec 101) : profils publics (créatrice et boutique), fil « Près de moi »,
-- « Mes recettes » (enregistrées), « J'ai fait la recette », vidéo adaptative HLS (Bunny Stream).

create table public.content_saves (
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  content_id uuid not null references public.contents (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, content_id)
);
alter table public.content_saves enable row level security;

create table public.content_cooks (
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  content_id uuid not null references public.contents (id) on delete cascade,
  note text check (note is null or length(note) <= 280),
  created_at timestamptz not null default now(),
  primary key (user_id, content_id)
);
alter table public.content_cooks enable row level security;

-- Vidéo adaptative (HLS) : identifiant Bunny, état, adresse de lecture une fois prête.
alter table public.contents
  add column stream_video_id text check (stream_video_id is null or stream_video_id ~ '^[0-9a-f-]{36}$'),
  add column stream_status text check (stream_status in ('processing', 'ready', 'failed')),
  add column stream_url text check (stream_url is null or stream_url ~ '^https://');

create or replace function public.toggle_save_content(p_content uuid, p_on boolean)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  if not exists (select 1 from public.contents c where c.id = p_content and app.content_visible(c, now())) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if p_on then
    insert into public.content_saves (user_id, content_id) values (v_user, p_content) on conflict do nothing;
    perform app.emit_event('recipe_saved', v_user, 'client', 'server',
      (select country_code from public.profiles where user_id = v_user), 'content', p_content::text, '{}'::jsonb);
  else
    delete from public.content_saves where user_id = v_user and content_id = p_content;
  end if;
  return app.content_json(p_content, v_user);
end
$$;
revoke all on function public.toggle_save_content(uuid, boolean) from public;
grant execute on function public.toggle_save_content(uuid, boolean) to authenticated;

create or replace function public.my_saved_contents(p_limit integer default 50)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.content_json(s.content_id, s.user_id) order by s.created_at desc), '[]'::jsonb)
  from (select x.content_id, x.user_id, x.created_at from public.content_saves x
        join public.contents c on c.id = x.content_id
        where x.user_id = app.require_user() and app.content_visible(c, now())
        order by x.created_at desc limit least(greatest(coalesce(p_limit, 50), 1), 200)) s
$$;
revoke all on function public.my_saved_contents(integer) from public;
grant execute on function public.my_saved_contents(integer) to authenticated;

-- « J'ai fait la recette » : une fois par personne, un petit mot facultatif ; l'autrice est prévenue.
create or replace function public.i_cooked_it(p_content uuid, p_note text default null)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_c public.contents;
  v_owner uuid;
begin
  select * into v_c from public.contents c where c.id = p_content and app.content_visible(c, now());
  if v_c.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  insert into public.content_cooks (user_id, content_id, note)
  values (v_user, p_content, left(nullif(btrim(p_note), ''), 280))
  on conflict (user_id, content_id) do update set note = excluded.note;
  v_owner := coalesce(v_c.author_id, (select owner_id from public.stores where id = v_c.store_id));
  if v_owner is not null and v_owner <> v_user then
    perform app.notify(v_owner, 'recipe_cooked', 'promotions', null, null, jsonb_build_object(
      'cook_name', coalesce((select first_name from public.profiles where user_id = v_user), '')));
  end if;
  perform app.emit_event('recipe_cooked', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'content', p_content::text, '{}'::jsonb);
  return app.content_json(p_content, v_user);
end
$$;
revoke all on function public.i_cooked_it(uuid, text) from public;
grant execute on function public.i_cooked_it(uuid, text) to authenticated;

-- Profil public : créatrice ou boutique, abonnés, abonnement, contenus récents.
create or replace function public.content_profile(p_kind text, p_id uuid, p_limit integer default 30)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
begin
  if p_kind = 'creator' then
    return (
      select jsonb_build_object(
        'kind', 'creator', 'id', cp.user_id, 'name', cp.display_name, 'bio', cp.bio,
        'followers', (select count(*) from public.follows f where f.creator_id = cp.user_id),
        'following', v_user is not null and exists (
          select 1 from public.follows f where f.creator_id = cp.user_id and f.follower_id = v_user),
        'contents', coalesce((
          select jsonb_agg(app.content_json(c.id, v_user) order by c.created_at desc)
          from (select * from public.contents x where x.author_id = cp.user_id and app.content_visible(x, now())
                order by x.created_at desc limit least(greatest(coalesce(p_limit, 30), 1), 60)) c), '[]'::jsonb))
      from public.creator_profiles cp where cp.user_id = p_id);
  elsif p_kind = 'store' then
    return (
      select jsonb_build_object(
        'kind', 'store', 'id', s.id, 'name', s.name, 'bio', s.description, 'origin', s.origin,
        'followers', (select count(*) from public.follows f where f.store_id = s.id),
        'following', v_user is not null and exists (
          select 1 from public.follows f where f.store_id = s.id and f.follower_id = v_user),
        'contents', coalesce((
          select jsonb_agg(app.content_json(c.id, v_user) order by c.created_at desc)
          from (select * from public.contents x where x.store_id = s.id and app.content_visible(x, now())
                order by x.created_at desc limit least(greatest(coalesce(p_limit, 30), 1), 60)) c), '[]'::jsonb))
      from public.stores s where s.id = p_id and s.status = 'active');
  end if;
  raise exception 'kind_invalid' using errcode = '22023';
end
$$;
revoke all on function public.content_profile(text, uuid, integer) from public;
grant execute on function public.content_profile(text, uuid, integer) to anonymous, authenticated;

-- Vidéo HLS (Functions) : contenus vidéo à envoyer à Bunny, puis à suivre jusqu'à « prête ».
create or replace function app.stream_pending(p_limit integer default 10)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', c.id, 'media_key', c.media_key,
                                               'stream_video_id', c.stream_video_id, 'stream_status', c.stream_status)), '[]'::jsonb)
  from (select * from public.contents x
        where x.kind = 'video' and x.media_key is not null and x.status = 'published'
          and (x.stream_status is null or x.stream_status = 'processing')
        order by x.created_at desc limit p_limit) c
$$;
revoke all on function app.stream_pending(integer) from public;

create or replace function app.set_stream(p_content uuid, p_video_id text, p_status text, p_url text)
returns void
language sql security definer set search_path = ''
as $$
  update public.contents set stream_video_id = coalesce(p_video_id, stream_video_id),
    stream_status = p_status, stream_url = coalesce(p_url, stream_url)
  where id = p_content
$$;
revoke all on function app.set_stream(uuid, text, text, text) from public;

insert into public.notification_templates (kind, locale, title, body) values
  ('recipe_cooked', 'fr', 'Ta recette a été faite', '{cook_name} a fait ta recette.'),
  ('recipe_cooked', 'en', 'Your recipe was cooked', '{cook_name} cooked your recipe.');

insert into public.event_names (name, emitted_by, description) values
  ('recipe_saved', 'server', 'Recette enregistrée dans « Mes recettes » (spec 101)'),
  ('recipe_cooked', 'server', '« J''ai fait la recette » (spec 101)')
on conflict do nothing;

-- ------------------------------------------------------------------ fonctions existantes modifiées

CREATE OR REPLACE FUNCTION app.content_json(p_content uuid, p_user uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
    'ingredients', c.ingredients,
    'source', c.source, 'source_url', c.source_url,
    'like_count', (select count(*) from public.content_likes l where l.content_id = c.id),
    'liked', p_user is not null and exists (select 1 from public.content_likes l
                                            where l.content_id = c.id and l.user_id = p_user),
    -- Spec 101 : enregistrée, faite, vidéo adaptative.
    'saved', p_user is not null and exists (select 1 from public.content_saves v
                                            where v.content_id = c.id and v.user_id = p_user),
    'save_count', (select count(*) from public.content_saves v where v.content_id = c.id),
    'cooked', p_user is not null and exists (select 1 from public.content_cooks k
                                             where k.content_id = c.id and k.user_id = p_user),
    'cook_count', (select count(*) from public.content_cooks k where k.content_id = c.id),
    'stream_url', case when c.stream_status = 'ready' then c.stream_url end,
    'products', coalesce((
      select jsonb_agg(app.catalog_item(cp.product_id) order by cp.sort)
      from public.content_products cp
      join public.products p on p.id = cp.product_id and p.status = 'published'
      where cp.content_id = c.id), '[]'::jsonb))
  from public.contents c left join public.stores s on s.id = c.store_id
  left join public.creator_profiles cp0 on cp0.user_id = c.author_id
  where c.id = p_content
$function$;

CREATE OR REPLACE FUNCTION public.content_feed_ranked(p_zone uuid DEFAULT NULL::uuid, p_tab text DEFAULT 'for_you'::text, p_category text DEFAULT NULL::text, p_offset integer DEFAULT 0, p_limit integer DEFAULT 10, p_at timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.current_user_id();
  v_country char(2) := coalesce(app.zone_country(p_zone),
    (select country_code from public.profiles where user_id = app.current_user_id()));
  w public.feed_ranking_rules := app.feed_weights(v_country);
begin
  -- Spec 101 : « Près de moi », contenus des boutiques qui livrent ici, par date.
  if p_tab not in ('for_you', 'following', 'near') then
    raise exception 'onglet inconnu' using errcode = '22023';
  end if;
  return coalesce((
    select jsonb_agg(app.content_json(x.id, v_user) || app.content_feed_extra(x.id, v_user)
                     order by case when p_tab in ('following', 'near') then 0 else x.score end desc, x.created_at desc, x.id)
    from (select y.* from (
      select c.id, c.created_at,
             w.weight_recency * (1.0 / (1 + extract(epoch from (p_at - c.created_at)) / 86400.0))
           + w.weight_engagement * least(1.0,
               ((select count(*) from public.content_likes l where l.content_id = c.id)
                + 2 * (select count(*) from public.content_comments k
                       where k.content_id = c.id and k.status = 'published')
                + c.click_count)::numeric / (c.view_count + 10))
           + w.weight_followed * app.follows_content(v_user, c)::int
           + w.weight_local * (c.store_id is not null
                               and (select s.zone_id from public.stores s where s.id = c.store_id) = p_zone)::int
           + w.weight_affinity * least(1.0, (
               select count(*) from public.content_likes l join public.contents o on o.id = l.content_id
               where l.user_id = v_user and o.category_id is not null and o.category_id = c.category_id
                 and l.created_at > p_at - interval '60 days')::numeric / 5)
           + w.weight_shoppable * exists (select 1 from public.content_products cp where cp.content_id = c.id)::int
             as score
      from public.contents c
      where app.content_visible(c, p_at)
        and c.kind in ('video', 'post')
        and (c.store_id is null or app.store_serves(c.store_id, p_zone))
        and (c.author_id is null or v_country is null or exists (
          select 1 from public.creator_profiles cr where cr.user_id = c.author_id and cr.country_code = v_country))
        and (p_category is null or exists (
          select 1 from public.content_categories cc where cc.id = c.category_id and cc.slug = p_category))
        and (p_tab <> 'following' or app.follows_content(v_user, c))
        and (p_tab <> 'near' or c.store_id is not null)) y
      -- Abonnements : par date ; « pour toi » : par score.
      order by case when p_tab in ('following', 'near') then 0 else y.score end desc, y.created_at desc, y.id
      offset greatest(coalesce(p_offset, 0), 0)
      limit greatest(1, least(coalesce(p_limit, 10), 20))) x), '[]'::jsonb);
end
$function$;
