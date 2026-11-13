-- 0081 — Analytics et MCP admin (spec 086).
-- 1. Schéma `analytics` : vues d'analyse sans donnée personnelle (ni nom, ni email, ni téléphone,
--    ni adresse ; les personnes sont comptées, jamais listées). Rôle `analytics_reader` en lecture
--    seule sur ce schéma : un outil de graphiques (Looker Studio, Metabase) s'y branche par un
--    utilisateur de connexion qui en hérite, créé hors dépôt.
-- 2. Clés MCP personnelles des admins : le serveur MCP des Functions agit avec les droits du
--    propriétaire de la clé (rôle, pays). Seule l'empreinte SHA-256 est gardée ; la clé n'est
--    montrée qu'une fois.

create schema if not exists analytics;
revoke all on schema analytics from public;

-- Commandes par jour, pays et devise (montants en unités mineures, jamais mélangés).
create view analytics.daily_orders as
select date_trunc('day', o.created_at)::date as day,
       p.country_code, o.currency_code,
       count(*) as orders,
       count(*) filter (where o.status = 'delivered') as delivered,
       count(*) filter (where o.status in ('cancelled', 'refused')) as cancelled_or_refused,
       coalesce(sum(o.total_minor) filter (where o.status = 'delivered'), 0) as gmv_minor,
       coalesce(sum(o.commission_minor) filter (where o.status = 'delivered'), 0) as commission_minor,
       count(distinct p.user_id) as buyers
from public.orders o
join public.purchases p on p.id = o.purchase_id
group by 1, 2, 3;

-- Événements par jour (nom, app, pays) : volumes et personnes distinctes.
create view analytics.daily_events as
select date_trunc('day', e.occurred_at)::date as day, e.country_code, e.app, e.name,
       count(*) as events, count(distinct e.actor_id) as actors
from public.events e
group by 1, 2, 3, 4;

-- Parcours d'achat par jour et pays : personnes distinctes à chaque étape.
create view analytics.daily_funnel as
select date_trunc('day', e.occurred_at)::date as day, e.country_code,
       count(distinct e.actor_id) filter (where e.name = 'product_viewed') as viewed,
       count(distinct e.actor_id) filter (where e.name = 'cart_item_added') as added_to_cart,
       count(distinct e.actor_id) filter (where e.name = 'checkout_started') as checkout,
       count(distinct e.actor_id) filter (where e.name = 'order_created') as ordered,
       count(distinct e.actor_id) filter (where e.name = 'order_delivered') as delivered
from public.events e
where e.name in ('product_viewed', 'cart_item_added', 'checkout_started', 'order_created', 'order_delivered')
group by 1, 2;

-- Inscriptions par jour, pays et app.
create view analytics.daily_signups as
select date_trunc('day', e.occurred_at)::date as day, e.country_code, e.app, count(*) as signups
from public.events e
where e.name = 'user_signed_up'
group by 1, 2, 3;

-- Boutiques : activité des 30 derniers jours (informations publiques de la boutique seulement).
create view analytics.stores_activity as
select s.id as store_id, s.name as store_name, s.country_code, s.currency_code, s.origin, s.status,
       z.city_id, s.created_at::date as created_on,
       count(o.id) filter (where o.created_at > now() - interval '30 days') as orders_30d,
       count(o.id) filter (where o.created_at > now() - interval '30 days' and o.status = 'delivered')
         as delivered_30d,
       coalesce(sum(o.total_minor) filter (where o.created_at > now() - interval '30 days'
                                           and o.status = 'delivered'), 0) as gmv_30d_minor,
       max(o.created_at)::date as last_order_on
from public.stores s
left join public.zones z on z.id = s.zone_id
left join public.orders o on o.store_id = s.id
group by s.id, z.city_id;

-- Rétention des acheteuses : semaine de la première commande × semaines écoulées.
create view analytics.buyer_retention_weekly as
with buys as (
  select p.user_id, p.country_code, date_trunc('week', o.created_at)::date as week
  from public.orders o join public.purchases p on p.id = o.purchase_id
  where o.status = 'delivered'
  group by 1, 2, 3
), firsts as (
  select user_id, min(week) as cohort from buys group by 1
)
select f.cohort as cohort_week, b.country_code,
       ((b.week - f.cohort) / 7) as weeks_since, count(distinct b.user_id) as buyers
from buys b join firsts f on f.user_id = b.user_id
group by 1, 2, 3;

-- Délais de préparation et de livraison (minutes) par jour et pays.
create view analytics.daily_delivery_times as
select date_trunc('day', o.created_at)::date as day, p.country_code,
       count(*) filter (where o.delivered_at is not null) as delivered,
       round(avg(extract(epoch from o.accepted_at - o.created_at) / 60)
             filter (where o.accepted_at is not null)) as avg_accept_min,
       round(avg(extract(epoch from o.ready_at - o.accepted_at) / 60)
             filter (where o.ready_at is not null)) as avg_prep_min,
       round(avg(extract(epoch from o.delivered_at - o.created_at) / 60)
             filter (where o.delivered_at is not null)) as avg_total_min
from public.orders o join public.purchases p on p.id = o.purchase_id
group by 1, 2;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'analytics_reader') then
    create role analytics_reader nologin;
  end if;
end
$$;
grant usage on schema analytics to analytics_reader;
grant select on all tables in schema analytics to analytics_reader;

-- ------------------------------------------------------------------ permissions

insert into public.admin_permissions (code, area, access) values
  ('analytics.read', 'analytics', 'read'), ('mcp.write', 'mcp', 'write')
on conflict do nothing;
insert into public.admin_role_permissions (role_code, permission_code) values
  ('super_admin', 'analytics.read'), ('super_admin', 'mcp.write'),
  ('analyst', 'analytics.read'), ('finance', 'analytics.read'), ('operations', 'analytics.read')
on conflict do nothing;

-- ------------------------------------------------------------------ clés MCP

create table public.admin_mcp_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 60),
  key_hash text not null unique,
  key_hint text not null,
  created_at timestamptz not null default now(),
  last_used_at timestamptz,
  revoked_at timestamptz
);
alter table public.admin_mcp_keys enable row level security;
revoke all on public.admin_mcp_keys from authenticated, anonymous;

create or replace function app.mcp_key_json(k public.admin_mcp_keys) returns jsonb
language sql stable set search_path = ''
as $$
  select jsonb_build_object('id', k.id, 'name', k.name, 'hint', k.key_hint,
    'created_at', k.created_at, 'last_used_at', k.last_used_at, 'revoked', k.revoked_at is not null)
$$;

-- Mes clés (jamais la clé elle-même).
create or replace function public.admin_mcp_keys() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
begin
  return coalesce((select jsonb_agg(app.mcp_key_json(k) order by k.created_at desc)
                   from public.admin_mcp_keys k where k.user_id = v_admin), '[]'::jsonb);
end
$$;

-- Nouvelle clé : renvoyée une seule fois, seule l'empreinte est gardée.
create or replace function public.admin_create_mcp_key(p_name text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_key text := 'dym_mcp_' || replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  v_row public.admin_mcp_keys;
begin
  if (select count(*) from public.admin_mcp_keys where user_id = v_admin and revoked_at is null) >= 5 then
    raise exception 'mcp_key_limit' using errcode = 'P0001';
  end if;
  insert into public.admin_mcp_keys (user_id, name, key_hash, key_hint)
  values (v_admin, trim(p_name), encode(sha256(convert_to(v_key, 'UTF8')), 'hex'), right(v_key, 4))
  returning * into v_row;
  perform app.audit(v_admin, 'mcp_key_created', 'mcp_key', v_row.id::text, null,
    jsonb_build_object('name', v_row.name), null);
  return app.mcp_key_json(v_row) || jsonb_build_object('key', v_key);
end
$$;

create or replace function public.admin_revoke_mcp_key(p_id uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
begin
  update public.admin_mcp_keys set revoked_at = now()
  where id = p_id and user_id = v_admin and revoked_at is null;
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  perform app.audit(v_admin, 'mcp_key_revoked', 'mcp_key', p_id::text, null, null, null);
  return public.admin_mcp_keys();
end
$$;

-- Propriétaire d'une clé valide (Function MCP) : admin encore admin, clé non révoquée.
create or replace function app.mcp_key_user(p_key text) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_key public.admin_mcp_keys;
begin
  select * into v_key from public.admin_mcp_keys
  where key_hash = encode(sha256(convert_to(coalesce(p_key, ''), 'UTF8')), 'hex') and revoked_at is null;
  if v_key.id is null or not app.user_is_admin(v_key.user_id)
     or not app.admin_has(v_key.user_id, 'mcp.write') then
    return null;
  end if;
  update public.admin_mcp_keys set last_used_at = now() where id = v_key.id;
  return v_key.user_id;
end
$$;

-- Fonctions admin appelables par le MCP pour cet admin : nom, arguments, permission, écriture.
create or replace function app.mcp_admin_functions(p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'name', p.proname,
    'permission', f.permission_code,
    'writes', ap.access = 'write',
    'args', coalesce((
      select jsonb_agg(jsonb_build_object('name', a.name, 'type', format_type(a.type, null),
        'required', a.ord <= p.pronargs - p.pronargdefaults) order by a.ord)
      from unnest(p.proargnames, p.proargtypes::oid[]) with ordinality a(name, type, ord)
      where a.name is not null), '[]'::jsonb)
  ) order by p.proname), '[]'::jsonb)
  from public.admin_function_permissions f
  join pg_proc p on p.oid = to_regproc(f.function_name)
  join public.admin_permissions ap on ap.code = f.permission_code
  where f.function_name like 'public.%'
    and app.admin_has(p_user, f.permission_code)
$$;

-- Gestion des clés : chacun voit les siennes ; créer et révoquer exige `mcp.write` (super-admin).
insert into public.admin_function_permissions (function_name, permission_code) values
  ('public.admin_mcp_keys', 'dashboard.read'), ('public.admin_create_mcp_key', 'mcp.write'),
  ('public.admin_revoke_mcp_key', 'mcp.write')
on conflict do nothing;

revoke all on function app.mcp_key_json(public.admin_mcp_keys), app.mcp_key_user(text),
  app.mcp_admin_functions(uuid), public.admin_mcp_keys(), public.admin_create_mcp_key(text),
  public.admin_revoke_mcp_key(uuid) from public;
grant execute on function public.admin_mcp_keys(), public.admin_create_mcp_key(text),
  public.admin_revoke_mcp_key(uuid) to authenticated;

-- Le propriétaire de la base (Functions) lit l'analytics sous le rôle lecteur : il en devient
-- membre (PostgreSQL 16 ne le fait plus à la création du rôle).
do $$
begin
  execute format('grant analytics_reader to %I', current_user);
end
$$;
