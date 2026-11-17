-- 0095 — Cuisine fluide (spec 103) : temps de visionnage et fin de lecture, ventes générées par une
-- vidéo, miniature choisie parmi les images de la vidéo, fin de lecture prise en compte dans le fil.

alter table public.contents
  add column watch_ms_total bigint not null default 0 check (watch_ms_total >= 0),
  add column completion_count integer not null default 0 check (completion_count >= 0),
  -- Image de la vidéo choisie comme miniature (Bunny : thumbnail_<n>.jpg) ; vide : image par défaut.
  add column cover_frame smallint check (cover_frame between 1 and 32),
  add column stream_thumb_count smallint check (stream_thumb_count between 0 and 32);

-- Qui a regardé quoi (personnes connectées) : base des « ventes générées ». Jamais exposé tel quel.
create table public.content_watches (
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  content_id uuid not null references public.contents (id) on delete cascade,
  watched_ms bigint not null default 0 check (watched_ms >= 0),
  completions integer not null default 0 check (completions >= 0),
  first_at timestamptz not null default now(),
  last_at timestamptz not null default now(),
  primary key (user_id, content_id)
);
alter table public.content_watches enable row level security;
create index content_watches_content_idx on public.content_watches (content_id, last_at);

-- Temps regardé (borné à 10 minutes par envoi) et fin de lecture ; visiteuse comprise (compteurs seuls).
create or replace function public.content_watched(p_content uuid, p_ms integer, p_completed boolean default false)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_ms integer := least(greatest(coalesce(p_ms, 0), 0), 600000);
  v_done integer := case when p_completed then 1 else 0 end;
begin
  update public.contents set watch_ms_total = watch_ms_total + v_ms,
                             completion_count = completion_count + v_done
  where id = p_content and status = 'published';
  if not found then return; end if;
  if v_user is not null then
    insert into public.content_watches (user_id, content_id, watched_ms, completions)
    values (v_user, p_content, v_ms, v_done)
    on conflict (user_id, content_id) do update
      set watched_ms = public.content_watches.watched_ms + excluded.watched_ms,
          completions = public.content_watches.completions + excluded.completions,
          last_at = now();
  end if;
end
$$;
revoke all on function public.content_watched(uuid, integer, boolean) from public;
grant execute on function public.content_watched(uuid, integer, boolean) to anonymous, authenticated;

-- Statistiques d'une vidéo pour sa propriétaire : temps moyen, fin de lecture, ventes générées
-- (commandes livrées des produits tagués, passées dans les 7 jours après avoir regardé la vidéo).
create or replace function app.content_stats(p_content uuid)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'watch_ms_total', c.watch_ms_total,
    'avg_watch_ms', case when c.view_count > 0 then c.watch_ms_total / c.view_count else 0 end,
    'completion_rate', case when c.view_count > 0
                            then round(least(1.0, c.completion_count::numeric / c.view_count), 3) else 0 end,
    'sales_orders', coalesce(s.orders, 0),
    'sales_minor', coalesce(s.amount, 0),
    'sales_currency', s.currency)
  from public.contents c
  left join lateral (
    select count(distinct o.id) as orders, sum(oi.amount_minor) as amount, min(o.currency_code) as currency
    from public.content_watches w
    join public.purchases pu on pu.user_id = w.user_id
    join public.orders o on o.purchase_id = pu.id and o.status = 'delivered'
                         and o.created_at >= w.first_at and o.created_at <= w.last_at + interval '7 days'
    join public.order_items oi on oi.order_id = o.id
    join public.content_products cp on cp.content_id = c.id and cp.product_id = oi.product_id
    where w.content_id = c.id) s on true
  where c.id = p_content
$$;
revoke all on function app.content_stats(uuid) from public;

-- Miniature : une des images de la vidéo (1..n), ou l'image par défaut (null). Propriétaire seulement.
create or replace function public.set_content_cover(p_content uuid, p_frame smallint)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_c public.contents;
begin
  select * into v_c from public.contents c
  where c.id = p_content and c.status <> 'removed'
    and (c.author_id = v_user or exists (select 1 from public.stores s where s.id = c.store_id and s.owner_id = v_user));
  if v_c.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if p_frame is not null and (v_c.stream_status is distinct from 'ready'
                              or p_frame < 1 or p_frame > coalesce(v_c.stream_thumb_count, 0)) then
    raise exception 'frame_invalid' using errcode = '22023';
  end if;
  update public.contents set cover_frame = p_frame where id = p_content;
  return app.content_json(p_content, v_user);
end
$$;
revoke all on function public.set_content_cover(uuid, smallint) from public;
grant execute on function public.set_content_cover(uuid, smallint) to authenticated;

-- La conversion connaît le nombre d'images disponibles pour la miniature.
drop function app.set_stream(uuid, text, text, text);
create or replace function app.set_stream(p_content uuid, p_video_id text, p_status text, p_url text,
                                          p_thumbs integer default null)
returns void
language sql security definer set search_path = ''
as $$
  update public.contents set stream_video_id = coalesce(p_video_id, stream_video_id),
    stream_status = p_status, stream_url = coalesce(p_url, stream_url),
    stream_thumb_count = coalesce(least(p_thumbs, 32)::smallint, stream_thumb_count)
  where id = p_content
$$;
revoke all on function app.set_stream(uuid, text, text, text, integer) from public;

-- Définitions reprises et étendues.

create or replace function app.content_json(p_content uuid, p_user uuid)
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
    -- Spec 103 : miniature choisie et nombre d'images disponibles.
    'cover_frame', c.cover_frame,
    'stream_thumb_count', coalesce(c.stream_thumb_count, 0),
    'products', coalesce((
      select jsonb_agg(app.catalog_item(cp.product_id) order by cp.sort)
      from public.content_products cp
      join public.products p on p.id = cp.product_id and p.status = 'published'
      where cp.content_id = c.id), '[]'::jsonb))
  from public.contents c left join public.stores s on s.id = c.store_id
  left join public.creator_profiles cp0 on cp0.user_id = c.author_id
  where c.id = p_content
$function$
;

create or replace function public.content_feed_ranked(p_zone uuid DEFAULT NULL::uuid, p_tab text DEFAULT 'for_you'::text, p_category text DEFAULT NULL::text, p_offset integer DEFAULT 0, p_limit integer DEFAULT 10, p_at timestamp with time zone DEFAULT now())
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
                + c.click_count
                -- Spec 103 : vidéos regardées jusqu'au bout.
                + 2 * c.completion_count)::numeric / (c.view_count + 10))
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
$function$
;

create or replace function public.my_contents()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(jsonb_agg(app.content_json(c.id, null) || jsonb_build_object(
           'view_count', c.view_count, 'click_count', c.click_count, 'stats', app.content_stats(c.id),
           'report_count', (select count(*) from public.reports r
                            where r.target_type = 'content' and r.target_id = c.id))
         order by c.created_at desc), '[]'::jsonb)
  from public.contents c
  join public.stores s on s.id = c.store_id and s.owner_id = app.require_user()
  where c.status <> 'removed'
$function$
;

create or replace function public.my_creator_contents()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(jsonb_agg(app.content_json(c.id, null) || jsonb_build_object(
           'view_count', c.view_count, 'click_count', c.click_count, 'stats', app.content_stats(c.id),
           'report_count', (select count(*) from public.reports r
                            where r.target_type = 'content' and r.target_id = c.id))
         order by c.created_at desc), '[]'::jsonb)
  from public.contents c
  where c.author_id = app.require_user() and c.status <> 'removed'
$function$
;
