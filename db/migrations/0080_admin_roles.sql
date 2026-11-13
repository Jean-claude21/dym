-- 0080 — Rôles et permissions des admins (spec 085).
-- Chaque admin a un rôle (super-admin, opérations, support, finance, contenu, analyste) ; un rôle
-- ouvre des permissions « domaine.lecture » ou « domaine.écriture ». Les fonctions admin gardent
-- leur garde unique (`app.require_admin`, `app.assert_admin`) : la garde lit la pile d'appels,
-- trouve la fonction admin appelante et exige la permission que lui attribue
-- `admin_function_permissions`. Une fonction admin sans permission déclarée est réservée au
-- super-admin (sûr par défaut) ; un test vérifie qu'aucune n'est oubliée.
-- Les admins existants (sans rôle enregistré) restent super-admins. Les périmètres de pays (0059)
-- s'ajoutent aux rôles. Toute attribution est journalisée.

create table public.admin_permissions (
  code text primary key check (code ~ '^[a-z_]+\.(read|write)$'),
  area text not null,
  access text not null check (access in ('read', 'write'))
);

create table public.admin_roles (
  code text primary key check (code ~ '^[a-z_]+$'),
  position int not null
);

create table public.admin_role_permissions (
  role_code text not null references public.admin_roles (code) on delete cascade,
  permission_code text not null references public.admin_permissions (code) on delete cascade,
  primary key (role_code, permission_code)
);

create table public.admin_members (
  user_id uuid primary key references neon_auth."user" (id) on delete cascade,
  role_code text not null references public.admin_roles (code),
  granted_by uuid,
  granted_at timestamptz not null default now()
);

create table public.admin_function_permissions (
  function_name text primary key check (function_name ~ '^(public|app)\.[a-z_]+$'),
  permission_code text not null references public.admin_permissions (code)
);

alter table public.admin_invites add column role_code text references public.admin_roles (code);

alter table public.admin_permissions enable row level security;
alter table public.admin_roles enable row level security;
alter table public.admin_role_permissions enable row level security;
alter table public.admin_members enable row level security;
alter table public.admin_function_permissions enable row level security;
revoke all on public.admin_permissions, public.admin_roles, public.admin_role_permissions,
  public.admin_members, public.admin_function_permissions from authenticated, anonymous;

-- ------------------------------------------------------------------ référentiel

insert into public.admin_permissions (code, area, access)
select a || '.' || x, a, x
from unnest(array['dashboard', 'orders', 'disputes', 'stores', 'clients', 'finance', 'catalog',
                  'geography', 'content', 'support', 'risk', 'system', 'admins']) a,
     unnest(array['read', 'write']) x;

insert into public.admin_roles (code, position) values
  ('super_admin', 1), ('operations', 2), ('support', 3), ('finance', 4), ('content', 5), ('analyst', 6);

insert into public.admin_role_permissions (role_code, permission_code)
select 'super_admin', code from public.admin_permissions;
insert into public.admin_role_permissions (role_code, permission_code)
select r, p from (values
  ('operations', 'dashboard.read'), ('operations', 'orders.read'), ('operations', 'orders.write'),
  ('operations', 'disputes.read'), ('operations', 'disputes.write'), ('operations', 'stores.read'),
  ('operations', 'stores.write'), ('operations', 'clients.read'), ('operations', 'geography.read'),
  ('operations', 'catalog.read'), ('operations', 'support.read'), ('operations', 'support.write'),
  ('operations', 'risk.read'),
  ('support', 'dashboard.read'), ('support', 'orders.read'), ('support', 'disputes.read'),
  ('support', 'disputes.write'), ('support', 'stores.read'), ('support', 'clients.read'),
  ('support', 'support.read'), ('support', 'support.write'),
  ('finance', 'dashboard.read'), ('finance', 'orders.read'), ('finance', 'disputes.read'),
  ('finance', 'stores.read'), ('finance', 'clients.read'), ('finance', 'finance.read'),
  ('finance', 'finance.write'), ('finance', 'risk.read'), ('finance', 'risk.write'),
  ('content', 'dashboard.read'), ('content', 'stores.read'), ('content', 'catalog.read'),
  ('content', 'catalog.write'), ('content', 'content.read'), ('content', 'content.write')
) v(r, p);
-- Analyste : tout lire, sauf la liste des admins ; rien modifier.
insert into public.admin_role_permissions (role_code, permission_code)
select 'analyst', code from public.admin_permissions where access = 'read' and area <> 'admins';

insert into public.admin_function_permissions (function_name, permission_code) values
  ('public.admin_dashboard', 'dashboard.read'), ('public.admin_overview', 'dashboard.read'),
  ('public.admin_exchanges', 'dashboard.read'), ('public.ops_live', 'dashboard.read'),
  ('public.ops_countries', 'dashboard.read'),
  ('public.admin_orders', 'orders.read'), ('public.admin_order', 'orders.read'),
  ('public.admin_dispatch', 'orders.read'),
  ('app.admin_cancel_order', 'orders.write'), ('app.admin_force_status', 'orders.write'),
  ('app.admin_assign_courier', 'orders.write'),
  ('public.admin_disputes', 'disputes.read'), ('public.admin_dispute', 'disputes.read'),
  ('public.admin_stores', 'stores.read'), ('public.admin_store', 'stores.read'),
  ('public.admin_vendor_view', 'stores.read'),
  ('public.admin_update_store', 'stores.write'), ('app.admin_set_store_status', 'stores.write'),
  ('app.admin_delete_vendor', 'stores.write'),
  ('public.admin_clients', 'clients.read'), ('public.admin_client', 'clients.read'),
  ('public.admin_refunds', 'finance.read'), ('public.admin_pending_payments', 'finance.read'),
  ('public.admin_ledger_check', 'finance.read'), ('public.admin_revenue', 'finance.read'),
  ('app.refund_claim', 'finance.write'), ('app.refund_mark_cash', 'finance.write'),
  ('app.refund_result', 'finance.write'), ('public.admin_confirm_courier_cash', 'finance.write'),
  ('public.admin_categories', 'catalog.read'), ('public.admin_pricing', 'catalog.read'),
  ('public.admin_payment_methods', 'catalog.read'),
  ('public.admin_save_category', 'catalog.write'), ('public.admin_set_commission', 'catalog.write'),
  ('public.admin_set_delivery_fee', 'catalog.write'),
  ('public.admin_save_payment_method', 'catalog.write'),
  ('public.admin_save_membership_plan', 'catalog.write'),
  ('public.admin_countries', 'dashboard.read'), ('public.admin_geography', 'geography.read'),
  ('public.admin_coverage', 'geography.read'),
  ('public.admin_save_city', 'geography.write'), ('public.admin_save_zone', 'geography.write'),
  ('public.admin_set_country_active', 'geography.write'),
  ('public.admin_reports', 'content.read'), ('public.admin_search_settings', 'content.read'),
  ('public.admin_moderate', 'content.write'), ('public.admin_set_feed_ranking', 'content.write'),
  ('public.admin_set_ranking', 'content.write'), ('public.admin_set_synonym', 'content.write'),
  ('public.admin_set_feed_weights', 'content.write'),
  ('public.admin_tickets', 'support.read'), ('app.support_draft_context', 'support.read'),
  ('public.admin_close_ticket', 'support.write'), ('app.admin_reply_ticket', 'support.write'),
  ('public.admin_fraud_signals', 'risk.read'), ('public.admin_decide_fraud_signal', 'risk.write'),
  ('public.admin_feature_flags', 'system.read'), ('public.admin_ai_health', 'system.read'),
  ('public.admin_ops_settings', 'system.read'), ('public.admin_audit', 'system.read'),
  ('public.admin_set_feature_flag', 'system.write'), ('public.admin_set_ops_thresholds', 'system.write'),
  ('public.admin_admins', 'admins.read'),
  ('public.admin_invite_admin', 'admins.write'), ('public.admin_remove_admin', 'admins.write'),
  ('public.admin_set_scope', 'admins.write'), ('public.admin_set_role', 'admins.write'),
  ('public.admin_me', 'dashboard.read');

-- ------------------------------------------------------------------ garde

-- Rôle d'un admin : celui enregistré, sinon super-admin (admins d'avant les rôles).
create or replace function app.admin_role(p_user uuid) returns text
language sql stable security definer set search_path = ''
as $$
  select coalesce((select role_code from public.admin_members where user_id = p_user), 'super_admin')
$$;

create or replace function app.admin_has(p_user uuid, p_permission text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.admin_role_permissions
    where role_code = app.admin_role(p_user) and permission_code = p_permission)
$$;

-- Permission exigée par la fonction admin appelante (pile d'appels) ; inconnue : super-admin.
create or replace function app.admin_required_permission(p_context text) returns text
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_name text;
  v_permission text;
begin
  for v_name in
    select m[1] from regexp_matches(p_context, 'function ((?:public|app)\.[a-z_]+)\(', 'g') as m
  loop
    select permission_code into v_permission from public.admin_function_permissions
    where function_name = v_name;
    if v_permission is not null then return v_permission; end if;
  end loop;
  return null;
end
$$;

create or replace function app.admin_check(p_user uuid, p_context text) returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_permission text := app.admin_required_permission(p_context);
begin
  if v_permission is null then
    if app.admin_role(p_user) <> 'super_admin' then
      raise exception 'permission_denied' using errcode = '42501';
    end if;
  elsif not app.admin_has(p_user, v_permission) then
    raise exception 'permission_denied' using errcode = '42501', detail = v_permission;
  end if;
end
$$;

create or replace function app.require_admin() returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_context text;
begin
  if not app.is_admin() then
    raise exception 'rôle admin requis' using errcode = '42501';
  end if;
  get diagnostics v_context = pg_context;
  perform app.admin_check(v_user, v_context);
  return v_user;
end
$$;

create or replace function app.assert_admin(p_user uuid) returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_context text;
begin
  if p_user is null or not app.user_is_admin(p_user) then
    raise exception 'rôle admin requis' using errcode = '42501';
  end if;
  get diagnostics v_context = pg_context;
  perform app.admin_check(p_user, v_context);
end
$$;

-- ------------------------------------------------------------------ fonctions admin

-- Ce que l'admin connecté peut faire (menu de l'app admin).
create or replace function public.admin_me() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
begin
  return jsonb_build_object(
    'role', app.admin_role(v_admin),
    'permissions', coalesce((
      select jsonb_agg(permission_code order by permission_code) from public.admin_role_permissions
      where role_code = app.admin_role(v_admin)), '[]'::jsonb),
    'roles', (select jsonb_agg(code order by position) from public.admin_roles));
end
$$;

-- Changer le rôle d'un admin (super-admin seulement, pas le sien) ; journalisé.
create or replace function public.admin_set_role(p_email text, p_role text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_email text := lower(trim(coalesce(p_email, '')));
  v_user uuid;
  v_before text;
begin
  if not exists (select 1 from public.admin_roles where code = p_role) then
    raise exception 'role_unknown' using errcode = '22023';
  end if;
  select u.id into v_user from neon_auth."user" u
  join public.user_roles r on r.user_id = u.id and r.role = 'admin'
  where lower(u.email) = v_email;
  if v_user is null then
    if exists (select 1 from public.admin_invites where email = v_email) then
      update public.admin_invites set role_code = p_role where email = v_email;
      perform app.audit(v_admin, 'admin_role_set', 'email', v_email, null,
        jsonb_build_object('role', p_role), 'invitation');
      return public.admin_admins();
    end if;
    raise exception 'admin_not_found' using errcode = 'P0002';
  end if;
  if v_user = v_admin then raise exception 'own_role' using errcode = 'P0001'; end if;
  v_before := app.admin_role(v_user);
  insert into public.admin_members (user_id, role_code, granted_by) values (v_user, p_role, v_admin)
  on conflict (user_id) do update set role_code = excluded.role_code, granted_by = excluded.granted_by,
    granted_at = now();
  perform app.audit(v_admin, 'admin_role_set', 'user', v_user::text,
    jsonb_build_object('role', v_before), jsonb_build_object('role', p_role), null);
  return public.admin_admins();
end
$$;

-- Invitation avec un rôle (par défaut le plus restreint : analyste).
create or replace function public.admin_invite_admin(p_email text, p_role text default 'analyst')
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_email text := lower(trim(coalesce(p_email, '')));
  v_user uuid;
begin
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'email invalide' using errcode = '22023';
  end if;
  if not exists (select 1 from public.admin_roles where code = p_role) then
    raise exception 'role_unknown' using errcode = '22023';
  end if;
  insert into public.admin_invites (email, source, invited_by, role_code)
  values (v_email, 'admin', v_admin, p_role)
  on conflict (email) do update set role_code = excluded.role_code;
  perform app.audit(v_admin, 'admin_invited', 'email', v_email, null,
    jsonb_build_object('role', p_role), null);
  select u.id into v_user from neon_auth."user" u
  where lower(u.email) = v_email and u."emailVerified";
  if v_user is not null then
    insert into public.user_roles (user_id, role, granted_by)
    values (v_user, 'admin', v_admin)
    on conflict (user_id, role) do nothing;
    insert into public.admin_members (user_id, role_code, granted_by) values (v_user, p_role, v_admin)
    on conflict (user_id) do nothing;
    perform app.audit(v_admin, 'role_granted', 'user', v_user::text, null,
      jsonb_build_object('role', 'admin', 'admin_role', p_role), 'invitation admin');
  end if;
  return public.admin_admins();
end
$$;
drop function if exists public.admin_invite_admin(text);

-- Rôle de l'invitation appliqué quand l'invité devient admin (connexion à l'app admin).
create or replace function app.admin_member_from_invite() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.role = 'admin' then
    insert into public.admin_members (user_id, role_code, granted_by)
    select new.user_id, i.role_code, i.invited_by
    from public.admin_invites i join neon_auth."user" u on lower(u.email) = i.email
    where u.id = new.user_id and i.role_code is not null
    on conflict (user_id) do nothing;
  end if;
  return new;
end
$$;
create trigger user_roles_admin_member after insert on public.user_roles
  for each row execute function app.admin_member_from_invite();

-- Liste des admins avec leur rôle.
create or replace function public.admin_admins() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return coalesce((
    select jsonb_agg(row_to_json(a)::jsonb order by a.status, a.email)
    from (
      select lower(u.email) as email, u.id as user_id, p.first_name,
        coalesce(i.source, 'admin') as source,
        'active' as status, r.granted_at as since, u.id = app.current_user_id() as is_me,
        app.admin_role(u.id) as role
      from public.user_roles r
      join neon_auth."user" u on u.id = r.user_id
      left join public.profiles p on p.user_id = u.id
      left join public.admin_invites i on i.email = lower(u.email)
      where r.role = 'admin'
      union all
      select i.email, null, null, i.source, 'invited', i.created_at, false,
        coalesce(i.role_code, 'super_admin')
      from public.admin_invites i
      where not exists (
        select 1 from neon_auth."user" u
        join public.user_roles r on r.user_id = u.id and r.role = 'admin'
        where lower(u.email) = i.email)
    ) a), '[]'::jsonb);
end
$$;

-- ------------------------------------------------------------------ gardes alignées
-- Ces trois fonctions vérifiaient l'admin à part : elles passent par la garde commune.

CREATE OR REPLACE FUNCTION public.admin_dispute(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  perform app.require_admin();
  if not exists (select 1 from public.disputes where id = p_id) then
    raise exception 'litige introuvable' using errcode = 'P0002';
  end if;
  return app.dispute_json(p_id, true) || jsonb_build_object(
    'order', app.order_json((select order_id from public.disputes where id = p_id), 'admin'));
end
$function$

;
CREATE OR REPLACE FUNCTION public.admin_disputes(p_status text DEFAULT 'open'::text, p_limit integer DEFAULT 100)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  perform app.require_admin();
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', d.id, 'order_id', d.order_id, 'reason', d.reason, 'status', d.status,
      'resolution', d.resolution, 'created_at', d.created_at, 'resolved_at', d.resolved_at,
      'store_name', s.name,
      'customer_first_name', (select first_name from public.profiles where user_id = d.opened_by),
      'order_total_minor', o.total_minor, 'currency_code', o.currency_code,
      'message_count', (select count(*) from public.dispute_messages m where m.dispute_id = d.id),
      'last_message_at', (select max(created_at) from public.dispute_messages m where m.dispute_id = d.id))
      order by d.created_at), '[]'::jsonb)
    from (select * from public.disputes
          where p_status is null or status = p_status
          order by created_at
          limit least(greatest(coalesce(p_limit, 100), 1), 500)) d
    join public.orders o on o.id = d.order_id
    join public.stores s on s.id = o.store_id);
end
$function$

;
CREATE OR REPLACE FUNCTION public.admin_ledger_check()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  perform app.require_admin();
  return coalesce((
    select jsonb_agg(jsonb_build_object('purchase_id', purchase_id, 'escrow_minor', escrow))
    from (
      select t.purchase_id, -sum(e.amount_minor) as escrow
      from public.ledger_entries e
      join public.ledger_accounts a on a.id = e.account_id and a.kind = 'customer_escrow'
      join public.ledger_transactions t on t.id = e.transaction_id
      where t.purchase_id is not null
      group by t.purchase_id
      having -sum(e.amount_minor) < 0) x), '[]'::jsonb);
end
$function$

;

-- ------------------------------------------------------------------ droits

revoke all on function app.admin_role(uuid), app.admin_has(uuid, text), app.admin_required_permission(text),
  app.admin_check(uuid, text), app.admin_member_from_invite(),
  public.admin_me(), public.admin_set_role(text, text), public.admin_invite_admin(text, text) from public;
grant execute on function public.admin_me(), public.admin_set_role(text, text),
  public.admin_invite_admin(text, text) to authenticated;

