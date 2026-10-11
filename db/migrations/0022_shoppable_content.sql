-- Spec 020 : stories 24 h et vidéos shoppables, statistiques, signalements et
-- modération. Derrière le flag `shoppable_content` (coupé par défaut) côté
-- apps ; les règles (qui publie, quoi, combien de temps, qui modère) sont ici.

-- ------------------------------------------------------------------ contenus

create table public.contents (
  id uuid primary key,
  store_id uuid not null references public.stores (id) on delete cascade,
  kind text not null check (kind in ('story', 'video')),
  media_key text not null check (media_key ~ '^stores/[0-9a-f-]{36}/contents/[0-9a-f-]{36}\.(jpg|webp|mp4)$'),
  media_type text not null check (media_type in ('image', 'video')),
  caption text check (caption is null or length(caption) <= 200),
  status text not null default 'published' check (status in ('published', 'archived', 'removed')),
  created_at timestamptz not null default clock_timestamp(),
  -- Story : visible 24 h ; vidéo : sans limite.
  expires_at timestamptz,
  view_count int not null default 0,
  click_count int not null default 0,
  check (kind = 'story' or media_type = 'video'),
  check ((kind = 'story') = (expires_at is not null))
);

create index contents_feed on public.contents (status, created_at desc);
create index contents_store on public.contents (store_id, created_at desc);

create table public.content_products (
  content_id uuid not null references public.contents (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  sort smallint not null default 0,
  primary key (content_id, product_id)
);

create table public.content_likes (
  content_id uuid not null references public.contents (id) on delete cascade,
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (content_id, user_id)
);

-- ------------------------------------------------------------------ signalements

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('content', 'product', 'review')),
  target_id uuid not null,
  reporter_id uuid references neon_auth."user" (id) on delete set null,
  reason text not null check (reason in ('misleading', 'offensive', 'forbidden', 'spam', 'other')),
  note text check (note is null or length(note) <= 500),
  status text not null default 'open' check (status in ('open', 'kept', 'removed')),
  created_at timestamptz not null default clock_timestamp(),
  decided_by uuid references neon_auth."user" (id) on delete set null,
  decided_at timestamptz,
  decision_reason text
);

create unique index reports_once on public.reports (target_type, target_id, reporter_id);
create index reports_open on public.reports (status, created_at);

alter table public.contents enable row level security;
alter table public.content_products enable row level security;
alter table public.content_likes enable row level security;
alter table public.reports enable row level security;
revoke all on public.contents, public.content_products, public.content_likes, public.reports
  from anonymous, authenticated;

-- Un produit retiré par l'équipe sort du catalogue (A-MOD-03).
alter table public.products drop constraint products_status_check;
alter table public.products add constraint products_status_check
  check (status in ('draft', 'published', 'archived', 'removed'));

-- ------------------------------------------------------------------ lectures

-- Contenu visible : publié, non expiré, boutique active.
create or replace function app.content_visible(p_content public.contents, p_at timestamptz)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select p_content.status = 'published'
     and (p_content.expires_at is null or p_content.expires_at > p_at)
     and exists (select 1 from public.stores s where s.id = p_content.store_id and s.status = 'active')
$$;

create or replace function app.content_json(p_content uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', c.id, 'kind', c.kind, 'media_key', c.media_key, 'media_type', c.media_type,
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

-- Fil (74) : « pour toi » (quartier) ou « boutiques suivies » (celles où la
-- cliente a déjà commandé). Pagination par date.
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
        and c.kind = 'video'
        and app.store_serves(c.store_id, p_zone)
        and (p_before is null or c.created_at < p_before)
        and (p_product is null or exists (select 1 from public.content_products cp
                                          where cp.content_id = c.id and cp.product_id = p_product))
        and (p_tab = 'for_you' or exists (
          select 1 from public.orders o join public.purchases pu on pu.id = o.purchase_id
          where o.store_id = c.store_id and pu.user_id = v_user))
      order by c.created_at desc
      limit greatest(1, least(coalesce(p_limit, 10), 20))) c), '[]'::jsonb);
end
$$;

-- Stories du quartier (C-HOME-07), groupées par boutique, les plus récentes d'abord.
create or replace function public.content_stories(p_zone uuid default null, p_at timestamptz default now())
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'store', jsonb_build_object('id', s.id, 'name', s.name, 'cover_key', (select f.object_key from public.products p
                                join public.product_photos f on f.product_id = p.id
                                where p.store_id = s.id and p.status = 'published'
                                order by p.published_at, f.sort limit 1)),
           'stories', stories) order by latest desc), '[]'::jsonb)
  from (
    select c.store_id, max(c.created_at) as latest,
           jsonb_agg(app.content_json(c.id, app.current_user_id()) order by c.created_at) as stories
    from public.contents c
    where c.kind = 'story' and app.content_visible(c, p_at) and app.store_serves(c.store_id, p_zone)
    group by c.store_id) g
  join public.stores s on s.id = g.store_id
$$;

-- Vidéos d'un produit (C-CAT-12) : nombre, pour la fiche produit.
create or replace function public.product_video_count(p_product uuid, p_at timestamptz default now())
returns int
language sql stable security definer set search_path = ''
as $$
  select count(*)::int from public.content_products cp
  join public.contents c on c.id = cp.content_id
  where cp.product_id = p_product and c.kind = 'video' and app.content_visible(c, p_at)
$$;

-- ------------------------------------------------------------------ gestes clientes

-- Vue et clic sur un produit tagué (statistiques V-CONT-05), visiteuse comprise.
create or replace function public.content_viewed(p_content uuid) returns void
language sql security definer set search_path = ''
as $$
  update public.contents set view_count = view_count + 1
  where id = p_content and status = 'published'
$$;

create or replace function public.content_clicked(p_content uuid, p_product uuid) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.content_products where content_id = p_content and product_id = p_product) then
    raise exception 'produit non tagué' using errcode = 'P0002';
  end if;
  update public.contents set click_count = click_count + 1 where id = p_content;
  perform app.emit_event('content_product_clicked', app.current_user_id(),
    case when app.current_user_id() is null then 'anonymous' else 'client' end, 'client',
    (select s.country_code from public.contents c join public.stores s on s.id = c.store_id where c.id = p_content),
    'content', p_content::text, '{}'::jsonb);
end
$$;

create or replace function public.like_content(p_content uuid, p_like boolean) returns int
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  if p_like then
    insert into public.content_likes (content_id, user_id)
    select p_content, v_user where exists (select 1 from public.contents where id = p_content and status = 'published')
    on conflict do nothing;
  else
    delete from public.content_likes where content_id = p_content and user_id = v_user;
  end if;
  return (select count(*)::int from public.content_likes where content_id = p_content);
end
$$;

-- Signalement (A-MOD-01) : une fois par personne et par cible.
create or replace function public.report(p_target_type text, p_target_id uuid, p_reason text, p_note text default null)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_found boolean;
begin
  if p_target_type not in ('content', 'product', 'review') then
    raise exception 'cible inconnue' using errcode = '22023';
  end if;
  if p_reason not in ('misleading', 'offensive', 'forbidden', 'spam', 'other') then
    raise exception 'motif inconnu' using errcode = '22023';
  end if;
  select case p_target_type
    when 'content' then exists (select 1 from public.contents where id = p_target_id)
    when 'product' then exists (select 1 from public.products where id = p_target_id)
    else exists (select 1 from public.reviews where id = p_target_id) end
  into v_found;
  if not v_found then
    raise exception 'cible introuvable' using errcode = 'P0002';
  end if;
  insert into public.reports (target_type, target_id, reporter_id, reason, note)
  values (p_target_type, p_target_id, v_user, p_reason, nullif(left(trim(coalesce(p_note, '')), 500), ''))
  on conflict (target_type, target_id, reporter_id) do nothing;
  perform app.emit_event('content_reported', v_user, 'client', 'client',
    (select country_code from public.profiles where user_id = v_user), p_target_type, p_target_id::text,
    jsonb_build_object('reason', p_reason));
end
$$;

-- ------------------------------------------------------------------ vendeuse

-- Publication (V-CONT-01..04, 08) : média déjà envoyé dans le dossier de la
-- boutique, 5 produits tagués au plus, publiés et de la boutique.
create or replace function public.save_content(p_content jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_store uuid := app.photo_upload_store(v_user);
  v_id uuid := (p_content ->> 'id')::uuid;
  v_kind text := p_content ->> 'kind';
  v_key text := p_content ->> 'media_key';
  v_products uuid[] := array(select jsonb_array_elements_text(coalesce(p_content -> 'product_ids', '[]'))::uuid);
begin
  if v_id is null or v_kind not in ('story', 'video') then
    raise exception 'contenu invalide' using errcode = '22023';
  end if;
  if v_key is null or v_key not like 'stores/' || v_store || '/contents/%' then
    raise exception 'média invalide' using errcode = '22023';
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
  insert into public.contents (id, store_id, kind, media_key, media_type, caption, expires_at)
  values (v_id, v_store, v_kind, v_key,
          case when v_key like '%.mp4' then 'video' else 'image' end,
          nullif(left(trim(coalesce(p_content ->> 'caption', '')), 200), ''),
          case when v_kind = 'story' then now() + interval '24 hours' end);
  insert into public.content_products (content_id, product_id, sort)
  select v_id, pid, ord - 1 from unnest(v_products) with ordinality as t(pid, ord);
  perform app.emit_event('content_published', v_user, 'vendor', 'vendor',
    (select country_code from public.stores where id = v_store), 'content', v_id::text,
    jsonb_build_object('kind', v_kind, 'products_count', cardinality(v_products)));
  return app.content_json(v_id, v_user);
end
$$;

-- Mes contenus avec statistiques (V-CONT-05).
create or replace function public.my_contents() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.content_json(c.id, null) || jsonb_build_object(
           'view_count', c.view_count, 'click_count', c.click_count,
           'report_count', (select count(*) from public.reports r
                            where r.target_type = 'content' and r.target_id = c.id))
         order by c.created_at desc), '[]'::jsonb)
  from public.contents c
  join public.stores s on s.id = c.store_id and s.owner_id = app.require_user()
  where c.status <> 'removed'
$$;

-- Archiver (V-CONT-06) ; supprimer définitivement ce qui est à soi.
create or replace function public.archive_content(p_content uuid) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  update public.contents c set status = 'archived'
  from public.stores s
  where c.id = p_content and s.id = c.store_id and s.owner_id = app.require_user() and c.status = 'published';
  if not found then
    raise exception 'contenu introuvable' using errcode = 'P0002';
  end if;
end
$$;

create or replace function public.delete_content(p_content uuid) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  delete from public.contents c using public.stores s
  where c.id = p_content and s.id = c.store_id and s.owner_id = app.require_user();
  if not found then
    raise exception 'contenu introuvable' using errcode = 'P0002';
  end if;
end
$$;

-- ------------------------------------------------------------------ modération

-- File (76) : une ligne par cible signalée, avec aperçu.
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
                                 'media_key', c.media_key, 'media_type', c.media_type, 'store_name', s.name,
                                 'tags', coalesce((select jsonb_agg(p.name) from public.content_products cp
                                                   join public.products p on p.id = cp.product_id
                                                   where cp.content_id = c.id), '[]'::jsonb))
                               from public.contents c join public.stores s on s.id = c.store_id
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

-- Garder ou retirer (A-MOD-02..05), raison obligatoire, journalisé.
create or replace function public.admin_moderate(
  p_target_type text,
  p_target_id uuid,
  p_decision text,
  p_reason text
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
begin
  if p_decision not in ('kept', 'removed') then
    raise exception 'décision inconnue' using errcode = '22023';
  end if;
  if v_reason is null then
    raise exception 'reason_required' using errcode = 'P0001';
  end if;
  if p_decision = 'removed' then
    case p_target_type
      when 'content' then update public.contents set status = 'removed' where id = p_target_id;
      when 'product' then update public.products set status = 'removed' where id = p_target_id;
      when 'review' then update public.reviews set status = 'removed' where id = p_target_id;
      else raise exception 'cible inconnue' using errcode = '22023';
    end case;
  end if;
  update public.reports set status = p_decision, decided_by = v_admin, decided_at = now(),
         decision_reason = v_reason
  where target_type = p_target_type and target_id = p_target_id and status = 'open';
  if not found then
    raise exception 'aucun signalement ouvert' using errcode = 'P0002';
  end if;
  perform app.admin_did(v_admin, case p_decision when 'removed' then 'content_removed' else 'content_kept' end,
    p_target_type, p_target_id::text, null, jsonb_build_object('decision', p_decision), v_reason);
end
$$;

-- ------------------------------------------------------------------ référentiel

insert into public.event_names (name, emitted_by, description) values
  ('content_published', 'server', 'Story ou vidéo publiée (type, produits tagués)'),
  ('content_product_clicked', 'server', 'Produit tagué touché dans un contenu'),
  ('content_reported', 'server', 'Signalement (cible, motif)')
on conflict (name) do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function
  app.content_visible(public.contents, timestamptz), app.content_json(uuid, uuid),
  public.content_feed(uuid, text, timestamptz, int, uuid, timestamptz),
  public.content_stories(uuid, timestamptz), public.product_video_count(uuid, timestamptz),
  public.content_viewed(uuid), public.content_clicked(uuid, uuid), public.like_content(uuid, boolean),
  public.report(text, uuid, text, text), public.save_content(jsonb), public.my_contents(),
  public.archive_content(uuid), public.delete_content(uuid), public.admin_reports(text),
  public.admin_moderate(text, uuid, text, text)
from public;

grant execute on function
  public.content_feed(uuid, text, timestamptz, int, uuid, timestamptz),
  public.content_stories(uuid, timestamptz), public.product_video_count(uuid, timestamptz),
  public.content_viewed(uuid), public.content_clicked(uuid, uuid)
to authenticated, anonymous;
grant execute on function
  public.like_content(uuid, boolean), public.report(text, uuid, text, text), public.save_content(jsonb),
  public.my_contents(), public.archive_content(uuid), public.delete_content(uuid),
  public.admin_reports(text), public.admin_moderate(text, uuid, text, text)
to authenticated;
