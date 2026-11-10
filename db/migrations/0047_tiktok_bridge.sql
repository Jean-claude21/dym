-- 0047 — Pont TikTok (spec 040, VISION §3 « Lien avec TikTok dans les deux sens »).
-- 1. Import : la créatrice déclare son compte TikTok ; la Function lit la vidéo publique (oEmbed),
--    vérifie qu'elle vient de ce compte et copie sa couverture ; le post DYM garde le lien d'origine.
--    Compte déclaré, non vérifié tant que la connexion TikTok (Login Kit) n'est pas disponible
--    (décision 0015 : signalé à l'écran).
-- 2. Partage : lien court vers un contenu ; ouvert, il mène à « Tout pour la faire ».
--    La commission suit les règles de l'affiliation (spec 039).

alter table public.creator_profiles add column tiktok_handle text
  check (tiktok_handle is null or tiktok_handle ~ '^[a-z0-9._]{2,24}$');
grant select (tiktok_handle) on public.creator_profiles to authenticated, anonymous;

alter table public.contents
  add column source text not null default 'dym' check (source in ('dym', 'tiktok')),
  add column source_url text check (source_url is null or source_url ~ '^https://(www\.|m\.|vm\.)?tiktok\.com/[A-Za-z0-9@._/?=&%-]{1,250}$'),
  add check ((source = 'tiktok') = (source_url is not null));

create table public.share_links (
  code text primary key check (code ~ '^[a-z0-9]{8}$'),
  content_id uuid not null references public.contents (id) on delete cascade,
  created_by uuid not null references neon_auth."user" (id) on delete cascade,
  opens integer not null default 0 check (opens >= 0),
  created_at timestamptz not null default clock_timestamp(),
  unique (content_id, created_by)
);
alter table public.share_links enable row level security;
revoke all on public.share_links from authenticated, anonymous;

-- Compte TikTok déclaré par la créatrice (sans @, en minuscules) ; vide : retiré.
create or replace function public.set_tiktok_handle(p_handle text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_handle text := nullif(lower(ltrim(btrim(coalesce(p_handle, '')), '@')), '');
begin
  if not exists (select 1 from public.creator_profiles where user_id = v_user) then
    raise exception 'not_creator' using errcode = '42501';
  end if;
  if v_handle is not null and v_handle !~ '^[a-z0-9._]{2,24}$' then
    raise exception 'invalid_handle' using errcode = '22023';
  end if;
  update public.creator_profiles set tiktok_handle = v_handle where user_id = v_user;
  return public.my_creator_profile();
end
$fn$;

-- Compte déclaré (Function d'import).
create or replace function app.creator_tiktok_handle(p_user uuid) returns text
language sql stable security definer set search_path = ''
as $$
  select tiktok_handle from public.creator_profiles where user_id = p_user
$$;

-- Post importé de TikTok : lien d'origine, autrice seulement, compte déclaré exigé.
create or replace function public.set_content_source(p_content uuid, p_url text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if app.creator_tiktok_handle(v_user) is null then
    raise exception 'tiktok_handle_required' using errcode = '22023';
  end if;
  update public.contents set source = 'tiktok', source_url = p_url
  where id = p_content and author_id = v_user;
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  perform app.emit_event('tiktok_imported', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'content', p_content::text, '{}'::jsonb);
  return app.content_json(p_content, v_user);
end
$fn$;

-- Lien de partage d'un contenu visible (un par personne et contenu).
create or replace function public.create_share_link(p_content uuid) returns text
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_code text;
begin
  if not exists (select 1 from public.contents c where c.id = p_content and app.content_visible(c, now())) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  select code into v_code from public.share_links where content_id = p_content and created_by = v_user;
  if v_code is not null then return v_code; end if;
  loop
    v_code := substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
    begin
      insert into public.share_links (code, content_id, created_by) values (v_code, p_content, v_user);
      exit;
    exception when unique_violation then
      if exists (select 1 from public.share_links where content_id = p_content and created_by = v_user) then
        return (select code from public.share_links where content_id = p_content and created_by = v_user);
      end if;
    end;
  end loop;
  perform app.emit_event('share_link_created', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'content', p_content::text, '{}'::jsonb);
  return v_code;
end
$fn$;

-- Lien ouvert (app ou page d'accueil) : le contenu, s'il est encore visible.
create or replace function public.open_share_link(p_code text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_link public.share_links;
  v_user uuid := app.current_user_id();
begin
  select * into v_link from public.share_links where code = lower(btrim(p_code));
  if v_link.code is null or not exists (select 1 from public.contents c where c.id = v_link.content_id
                                        and app.content_visible(c, now())) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  update public.share_links set opens = opens + 1 where code = v_link.code;
  perform app.emit_event('share_link_opened', v_user, case when v_user is null then 'anonymous' else 'client' end,
    'server', null, 'content', v_link.content_id::text, '{}'::jsonb);
  return app.content_json(v_link.content_id, v_user);
end
$fn$;

insert into public.event_names (name, emitted_by, description) values
  ('tiktok_imported', 'server', 'Vidéo TikTok importée par sa créatrice'),
  ('share_link_created', 'server', 'Lien de partage d''un contenu créé'),
  ('share_link_opened', 'server', 'Lien de partage ouvert (app ou page d''accueil)')
on conflict do nothing;

-- Contenu (0045) : origine TikTok.
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
    'ingredients', c.ingredients,
    'source', c.source, 'source_url', c.source_url,
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

revoke all on function public.set_tiktok_handle(text), app.creator_tiktok_handle(uuid),
  public.set_content_source(uuid, text), public.create_share_link(uuid), public.open_share_link(text) from public;
grant execute on function public.set_tiktok_handle(text), public.set_content_source(uuid, text),
  public.create_share_link(uuid) to authenticated;
grant execute on function public.open_share_link(text) to authenticated, anonymous;
