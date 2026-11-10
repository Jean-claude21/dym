-- 0044 — Fil classé, abonnements et commentaires (spec 037).
-- 1. Abonnements à une créatrice ou à une boutique.
-- 2. Commentaires (300 caractères), signalables et retirables par la modération.
-- 3. Algorithme de valorisation : score = Σ poids × critère (fraîcheur, engagement, abonnement,
--    proximité, affinité de catégorie, produits tagués), poids par pays en données de référence.

create table public.follows (
  follower_id uuid not null references neon_auth."user" (id) on delete cascade,
  creator_id uuid references neon_auth."user" (id) on delete cascade,
  store_id uuid references public.stores (id) on delete cascade,
  created_at timestamptz not null default clock_timestamp(),
  check ((creator_id is null) <> (store_id is null)),
  check (creator_id is distinct from follower_id)
);
create unique index follows_unique on public.follows (follower_id, coalesce(creator_id, store_id));
create index follows_creator on public.follows (creator_id) where creator_id is not null;
create index follows_store on public.follows (store_id) where store_id is not null;
alter table public.follows enable row level security;
revoke all on public.follows from authenticated, anonymous;

create table public.content_comments (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.contents (id) on delete cascade,
  author_id uuid not null references neon_auth."user" (id) on delete cascade,
  body text not null check (length(btrim(body)) between 1 and 300),
  status text not null default 'published' check (status in ('published', 'removed')),
  idempotency_key uuid not null,
  created_at timestamptz not null default clock_timestamp(),
  unique (author_id, idempotency_key)
);
create index content_comments_content on public.content_comments (content_id, created_at desc);
alter table public.content_comments enable row level security;
revoke all on public.content_comments from authenticated, anonymous;

create table public.feed_ranking_rules (
  country_code char(2) references public.countries (code),
  weight_recency integer not null default 40 check (weight_recency between 0 and 100),
  weight_engagement integer not null default 25 check (weight_engagement between 0 and 100),
  weight_followed integer not null default 20 check (weight_followed between 0 and 100),
  weight_local integer not null default 10 check (weight_local between 0 and 100),
  weight_affinity integer not null default 10 check (weight_affinity between 0 and 100),
  weight_shoppable integer not null default 5 check (weight_shoppable between 0 and 100),
  updated_at timestamptz not null default now()
);
create unique index feed_ranking_rules_country on public.feed_ranking_rules (coalesce(country_code, '--'));
alter table public.feed_ranking_rules enable row level security;
revoke all on public.feed_ranking_rules from authenticated, anonymous;
insert into public.feed_ranking_rules (country_code) values (null);

alter table public.reports drop constraint reports_target_type_check;
alter table public.reports add constraint reports_target_type_check
  check (target_type in ('content', 'product', 'review', 'comment'));

create or replace function app.feed_weights(p_country char(2)) returns public.feed_ranking_rules
language sql stable security definer set search_path = ''
as $$
  select r.* from public.feed_ranking_rules r
  where r.country_code = p_country or r.country_code is null
  order by r.country_code nulls last limit 1
$$;

-- La personne suit-elle l'autrice ou la boutique du contenu ?
create or replace function app.follows_content(p_user uuid, p_content public.contents) returns boolean
language sql stable security definer set search_path = ''
as $$
  select p_user is not null and exists (
    select 1 from public.follows f
    where f.follower_id = p_user
      and (f.creator_id = p_content.author_id or f.store_id = p_content.store_id))
$$;

-- Compléments du fil : commentaires, abonnement.
create or replace function app.content_feed_extra(p_content uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'comment_count', (select count(*) from public.content_comments k
                      where k.content_id = c.id and k.status = 'published'),
    'followed', app.follows_content(p_user, c))
  from public.contents c where c.id = p_content
$$;

-- Fil classé : « pour toi » (score), « abonnements » (suivis, par date), catégorie facultative.
create or replace function public.content_feed_ranked(
  p_zone uuid default null,
  p_tab text default 'for_you',
  p_category text default null,
  p_offset int default 0,
  p_limit int default 10,
  p_at timestamptz default now()
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.current_user_id();
  v_country char(2) := coalesce(app.zone_country(p_zone),
    (select country_code from public.profiles where user_id = app.current_user_id()));
  w public.feed_ranking_rules := app.feed_weights(v_country);
begin
  if p_tab not in ('for_you', 'following') then
    raise exception 'onglet inconnu' using errcode = '22023';
  end if;
  return coalesce((
    select jsonb_agg(app.content_json(x.id, v_user) || app.content_feed_extra(x.id, v_user)
                     order by case when p_tab = 'following' then 0 else x.score end desc, x.created_at desc, x.id)
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
        and (p_tab = 'for_you' or app.follows_content(v_user, c))) y
      -- Abonnements : par date ; « pour toi » : par score.
      order by case when p_tab = 'following' then 0 else y.score end desc, y.created_at desc, y.id
      offset greatest(coalesce(p_offset, 0), 0)
      limit greatest(1, least(coalesce(p_limit, 10), 20))) x), '[]'::jsonb);
end
$fn$;

-- ------------------------------------------------------------------ abonnements

-- S'abonner (`creator` ou `store`) ou se désabonner ; renvoie l'état final.
create or replace function public.follow(p_kind text, p_id uuid, p_on boolean) returns boolean
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if p_kind not in ('creator', 'store') then raise exception 'invalid_kind' using errcode = '22023'; end if;
  if p_kind = 'creator' and not exists (select 1 from public.creator_profiles where user_id = p_id) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if p_kind = 'store' and not exists (select 1 from public.stores where id = p_id and status = 'active') then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if p_kind = 'creator' and p_id = v_user then raise exception 'self_follow' using errcode = '22023'; end if;
  if p_on then
    insert into public.follows (follower_id, creator_id, store_id)
    values (v_user, case when p_kind = 'creator' then p_id end, case when p_kind = 'store' then p_id end)
    on conflict do nothing;
    if found then
      perform app.emit_event('follow_added', v_user, 'client', 'server',
        (select country_code from public.profiles where user_id = v_user), p_kind, p_id::text,
        jsonb_build_object('kind', p_kind));
    end if;
  else
    delete from public.follows where follower_id = v_user and coalesce(creator_id, store_id) = p_id;
  end if;
  return p_on;
end
$fn$;

-- ------------------------------------------------------------------ commentaires

create or replace function public.content_comments_list(p_content uuid, p_before timestamptz default null)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', k.id, 'body', k.body, 'created_at', k.created_at,
      'author_name', coalesce((select cr.display_name from public.creator_profiles cr where cr.user_id = k.author_id),
                              (select p.first_name from public.profiles p where p.user_id = k.author_id), '?'),
      'mine', k.author_id = app.current_user_id())
    order by k.created_at desc), '[]'::jsonb)
  from (select * from public.content_comments k
        where k.content_id = p_content and k.status = 'published'
          and (p_before is null or k.created_at < p_before)
          and exists (select 1 from public.contents c where c.id = k.content_id and app.content_visible(c, now()))
        order by k.created_at desc limit 50) k
$$;

create or replace function public.add_comment(p_content uuid, p_body text, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_body text := btrim(coalesce(p_body, ''));
  v_id uuid;
begin
  if p_key is null or length(v_body) not between 1 and 300 then
    raise exception 'invalid_comment' using errcode = '22023';
  end if;
  if not exists (select 1 from public.contents c where c.id = p_content and app.content_visible(c, now())) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  insert into public.content_comments (content_id, author_id, body, idempotency_key)
  values (p_content, v_user, v_body, p_key)
  on conflict (author_id, idempotency_key) do nothing
  returning id into v_id;
  if v_id is not null then
    perform app.emit_event('comment_added', v_user, 'client', 'server',
      (select country_code from public.profiles where user_id = v_user), 'content', p_content::text, '{}'::jsonb);
  end if;
  return public.content_comments_list(p_content);
end
$fn$;

create or replace function public.delete_comment(p_comment uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
begin
  delete from public.content_comments where id = p_comment and author_id = app.require_user();
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
end
$fn$;

-- ------------------------------------------------------------------ admin

create or replace function public.admin_set_feed_ranking(p_country char(2), p_weights jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_admin uuid := app.require_admin();
  v_before jsonb;
  v_base public.feed_ranking_rules := app.feed_weights(p_country);
begin
  select to_jsonb(r) into v_before from public.feed_ranking_rules r where r.country_code is not distinct from p_country;
  delete from public.feed_ranking_rules where country_code is not distinct from p_country;
  insert into public.feed_ranking_rules (country_code, weight_recency, weight_engagement, weight_followed,
                                         weight_local, weight_affinity, weight_shoppable)
  values (p_country,
    coalesce((p_weights ->> 'weight_recency')::int, v_base.weight_recency),
    coalesce((p_weights ->> 'weight_engagement')::int, v_base.weight_engagement),
    coalesce((p_weights ->> 'weight_followed')::int, v_base.weight_followed),
    coalesce((p_weights ->> 'weight_local')::int, v_base.weight_local),
    coalesce((p_weights ->> 'weight_affinity')::int, v_base.weight_affinity),
    coalesce((p_weights ->> 'weight_shoppable')::int, v_base.weight_shoppable));
  perform app.admin_did(v_admin, 'feed_ranking_set', 'feed_ranking_rules', coalesce(p_country, '*'),
    v_before, p_weights, null, p_country);
  return to_jsonb(app.feed_weights(p_country));
end
$fn$;

insert into public.event_names (name, emitted_by, description) values
  ('follow_added', 'server', 'Abonnement à une créatrice ou une boutique'),
  ('comment_added', 'server', 'Commentaire publié sur un contenu')
on conflict do nothing;

-- Signalement (0022) : commentaires.
create or replace function public.report(p_target_type text, p_target_id uuid, p_reason text, p_note text default null)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_found boolean;
begin
  if p_target_type not in ('content', 'product', 'review', 'comment') then
    raise exception 'cible inconnue' using errcode = '22023';
  end if;
  if p_reason not in ('misleading', 'offensive', 'forbidden', 'spam', 'other') then
    raise exception 'motif inconnu' using errcode = '22023';
  end if;
  select case p_target_type
    when 'content' then exists (select 1 from public.contents where id = p_target_id)
    when 'product' then exists (select 1 from public.products where id = p_target_id)
    when 'comment' then exists (select 1 from public.content_comments where id = p_target_id)
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

-- Modération (0022) : commentaires.
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
      when 'comment' then update public.content_comments set status = 'removed' where id = p_target_id;
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

-- File de modération (0043) : aperçu des commentaires.
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
          when 'comment' then (select jsonb_build_object('title', k.body, 'kind', 'comment',
                                 'store_name', coalesce((select cr.display_name from public.creator_profiles cr
                                                         where cr.user_id = k.author_id),
                                                        (select p.first_name from public.profiles p
                                                         where p.user_id = k.author_id)))
                               from public.content_comments k where k.id = r.target_id)
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

revoke all on function app.feed_weights(char), app.follows_content(uuid, public.contents),
  app.content_feed_extra(uuid, uuid), public.content_feed_ranked(uuid, text, text, int, int, timestamptz),
  public.follow(text, uuid, boolean), public.content_comments_list(uuid, timestamptz),
  public.add_comment(uuid, text, uuid), public.delete_comment(uuid), public.admin_set_feed_ranking(char, jsonb)
  from public;
grant execute on function public.content_feed_ranked(uuid, text, text, int, int, timestamptz),
  public.content_comments_list(uuid, timestamptz) to authenticated, anonymous;
grant execute on function public.follow(text, uuid, boolean), public.add_comment(uuid, text, uuid),
  public.delete_comment(uuid), public.admin_set_feed_ranking(char, jsonb) to authenticated;
