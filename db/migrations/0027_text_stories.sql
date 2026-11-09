-- 0027 — Statuts texte (stories écrites, façon WhatsApp) : un texte sur un fond
-- de couleur, sans média, visible 24 h comme les autres stories.

alter table public.contents drop constraint contents_media_key_check;
alter table public.contents drop constraint contents_media_type_check;
alter table public.contents drop constraint contents_caption_check;
alter table public.contents alter column media_key drop not null;

alter table public.contents
  add column background text check (background is null or background ~ '^#[0-9a-f]{6}$'),
  add constraint contents_media_key_check check (
    media_key is null
    or media_key ~ '^stores/[0-9a-f-]{36}/contents/[0-9a-f-]{36}\.(jpg|webp|mp4)$'),
  add constraint contents_media_type_check check (media_type in ('image', 'video', 'text')),
  -- Texte : pas de média, un texte et un fond ; story seulement.
  add constraint contents_text_shape check (
    (media_type = 'text') = (media_key is null)
    and (media_type <> 'text' or (kind = 'story' and caption is not null and background is not null))),
  add constraint contents_caption_check check (
    caption is null or length(caption) <= case when media_type = 'text' then 500 else 200 end);

create or replace function app.content_json(p_content uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', c.id, 'kind', c.kind, 'media_key', c.media_key, 'media_type', c.media_type,
    'background', c.background,
    'caption', c.caption, 'status', c.status, 'created_at', c.created_at, 'expires_at', c.expires_at,
    'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin,
      'cover_key', (select f.object_key from public.products p
                                join public.product_photos f on f.product_id = p.id
                                where p.store_id = s.id and p.status = 'published'
                                order by p.published_at, f.sort limit 1)),
    'like_count', (select count(*) from public.content_likes l where l.content_id = c.id),
    'liked', p_user is not null and exists (select 1 from public.content_likes l
                                            where l.content_id = c.id and l.user_id = p_user),
    'products', coalesce((
      select jsonb_agg(app.catalog_item(cp.product_id) order by cp.sort)
      from public.content_products cp
      join public.products p on p.id = cp.product_id and p.status = 'published'
      where cp.content_id = c.id), '[]'::jsonb))
  from public.contents c join public.stores s on s.id = c.store_id
  where c.id = p_content
$$;

-- Publication : média (photo, vidéo) ou texte (`text` + `background`, story seulement).
create or replace function public.save_content(p_content jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_store uuid := app.photo_upload_store(v_user);
  v_id uuid := (p_content ->> 'id')::uuid;
  v_kind text := p_content ->> 'kind';
  v_key text := p_content ->> 'media_key';
  v_text text := nullif(trim(coalesce(p_content ->> 'text', '')), '');
  v_background text := lower(coalesce(p_content ->> 'background', '#0b5d3b'));
  v_products uuid[] := array(select jsonb_array_elements_text(coalesce(p_content -> 'product_ids', '[]'))::uuid);
  v_type text;
  v_caption text;
begin
  if v_id is null or v_kind not in ('story', 'video') then
    raise exception 'contenu invalide' using errcode = '22023';
  end if;
  if v_text is not null then
    if v_kind <> 'story' or v_key is not null then
      raise exception 'un statut texte est une story sans média' using errcode = '22023';
    end if;
    if length(v_text) > 500 then
      raise exception 'texte : 500 caractères au plus' using errcode = '22023';
    end if;
    if v_background !~ '^#[0-9a-f]{6}$' then
      raise exception 'couleur de fond invalide' using errcode = '22023';
    end if;
    v_type := 'text';
    v_caption := v_text;
  else
    if v_key is null or v_key not like 'stores/' || v_store || '/contents/%' then
      raise exception 'média invalide' using errcode = '22023';
    end if;
    v_type := case when v_key like '%.mp4' then 'video' else 'image' end;
    v_caption := nullif(left(trim(coalesce(p_content ->> 'caption', '')), 200), '');
    v_background := null;
  end if;
  if cardinality(v_products) > 5 or exists (
    select 1 from unnest(v_products) pid
    where not exists (select 1 from public.products p
                      where p.id = pid and p.store_id = v_store and p.status = 'published')) then
    raise exception 'produits tagués invalides' using errcode = '22023';
  end if;
  if exists (select 1 from public.contents where id = v_id) then
    raise exception 'contenu déjà publié' using errcode = '23505';
  end if;
  insert into public.contents (id, store_id, kind, media_key, media_type, caption, background, expires_at)
  values (v_id, v_store, v_kind, v_key, v_type, v_caption, v_background,
          case when v_kind = 'story' then now() + interval '24 hours' end);
  insert into public.content_products (content_id, product_id, sort)
  select v_id, pid, ord - 1 from unnest(v_products) with ordinality as t(pid, ord);
  perform app.emit_event('content_published', v_user, 'vendor', 'vendor',
    (select country_code from public.stores where id = v_store), 'content', v_id::text,
    jsonb_build_object('kind', v_kind, 'media_type', v_type, 'products_count', cardinality(v_products)));
  return app.content_json(v_id, v_user);
end
$$;
