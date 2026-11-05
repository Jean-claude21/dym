-- 0025 — Admins par défaut et invitations (remplace la partie admin de la décision 0007).
-- La liste ADMIN_EMAILS (variable d'environnement lue par `dym-db admins`) alimente
-- admin_invites (source 'env'). Un compte qui se connecte à l'app admin avec un email
-- vérifié présent dans admin_invites reçoit le rôle admin. Un admin peut inviter
-- d'autres emails (source 'admin') ou retirer un admin invité ; jamais le dernier admin.

create table public.admin_invites (
  email text primary key check (email = lower(trim(email)) and email ~ '^[^@\s]+@[^@\s]+$'),
  source text not null check (source in ('env', 'admin')),
  invited_by uuid references neon_auth."user" (id) on delete set null,
  created_at timestamptz not null default now()
);

-- Aucune lecture directe : seulement par les fonctions ci-dessous.
alter table public.admin_invites enable row level security;
revoke all on public.admin_invites from authenticated, anonymous;

-- Rôle admin si l'email vérifié du compte est invité. Vrai si le compte est admin.
create or replace function app.claim_admin_invite(p_user uuid) returns boolean
language plpgsql security definer set search_path = ''
as $$
declare
  v_email text;
begin
  if p_user is null then
    return false;
  end if;
  if exists (select 1 from public.user_roles where user_id = p_user and role = 'admin') then
    return true;
  end if;
  select lower(u.email) into v_email
  from neon_auth."user" u
  where u.id = p_user and u."emailVerified";
  if v_email is null
     or not exists (select 1 from public.admin_invites where email = v_email) then
    return false;
  end if;
  insert into public.user_roles (user_id, role, granted_by)
  values (p_user, 'admin', null)
  on conflict (user_id, role) do nothing;
  perform app.audit(p_user, 'role_granted', 'user', p_user::text, null,
    jsonb_build_object('role', 'admin', 'via', 'admin_invite'), 'invitation admin');
  return true;
end
$$;

-- Connexion : l'invitation admin est honorée avant le contrôle d'accès.
create or replace function public.record_sign_in(p_app text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_country char(2);
begin
  if v_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  if p_app not in ('client', 'vendor', 'admin', 'delivery') then
    raise exception 'app inconnue : %', p_app using errcode = '22023';
  end if;
  if p_app = 'admin' then
    perform app.claim_admin_invite(v_user);
  end if;
  if p_app = 'admin' and not app.is_admin() then
    raise exception 'accès réservé aux admins' using errcode = '42501';
  end if;
  select country_code into v_country from public.profiles where user_id = v_user;
  perform app.emit_event('user_signed_in', v_user, 'authenticated', p_app, v_country,
    'user', v_user::text, '{}'::jsonb);
  if p_app = 'admin' then
    perform app.audit(v_user, 'admin_signed_in', 'user', v_user::text, null, null, null);
  end if;
  return public.me();
end
$$;

-- Liste des admins actifs et des invitations en attente.
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
        'active' as status, r.granted_at as since
      from public.user_roles r
      join neon_auth."user" u on u.id = r.user_id
      left join public.profiles p on p.user_id = u.id
      left join public.admin_invites i on i.email = lower(u.email)
      where r.role = 'admin'
      union all
      select i.email, null, null, i.source, 'invited', i.created_at
      from public.admin_invites i
      where not exists (
        select 1 from neon_auth."user" u
        join public.user_roles r on r.user_id = u.id and r.role = 'admin'
        where lower(u.email) = i.email)
    ) a), '[]'::jsonb);
end
$$;

-- Invite un email ; s'il a déjà un compte vérifié, il devient admin tout de suite.
create or replace function public.admin_invite_admin(p_email text) returns jsonb
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
  insert into public.admin_invites (email, source, invited_by)
  values (v_email, 'admin', v_admin)
  on conflict (email) do nothing;
  perform app.audit(v_admin, 'admin_invited', 'email', v_email, null, null, null);
  select u.id into v_user from neon_auth."user" u
  where lower(u.email) = v_email and u."emailVerified";
  if v_user is not null then
    insert into public.user_roles (user_id, role, granted_by)
    values (v_user, 'admin', v_admin)
    on conflict (user_id, role) do nothing;
    perform app.audit(v_admin, 'role_granted', 'user', v_user::text, null,
      jsonb_build_object('role', 'admin'), 'invitation admin');
  end if;
  return public.admin_admins();
end
$$;

-- Retire un admin ou une invitation. Les admins de ADMIN_EMAILS, soi-même et le
-- dernier admin ne peuvent pas être retirés ici.
create or replace function public.admin_remove_admin(p_email text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_email text := lower(trim(coalesce(p_email, '')));
  v_user uuid;
begin
  if exists (select 1 from public.admin_invites where email = v_email and source = 'env') then
    raise exception 'admin par défaut (ADMIN_EMAILS) : à retirer de la configuration'
      using errcode = '42501';
  end if;
  select u.id into v_user from neon_auth."user" u where lower(u.email) = v_email;
  if v_user = v_admin then
    raise exception 'impossible de retirer son propre accès' using errcode = '42501';
  end if;
  if v_user is not null
     and (select count(*) from public.user_roles where role = 'admin') <= 1
     and exists (select 1 from public.user_roles where user_id = v_user and role = 'admin') then
    raise exception 'dernier admin' using errcode = '42501';
  end if;
  delete from public.admin_invites where email = v_email;
  if v_user is not null then
    delete from public.user_roles where user_id = v_user and role = 'admin';
    perform app.audit(v_admin, 'role_revoked', 'user', v_user::text,
      jsonb_build_object('role', 'admin'), null, 'retrait admin');
  end if;
  perform app.audit(v_admin, 'admin_removed', 'email', v_email, null, null, null);
  return public.admin_admins();
end
$$;

-- Synchronise ADMIN_EMAILS (propriétaire de la base seulement, via `dym-db admins`).
create or replace function app.sync_admin_emails(p_emails text[]) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_emails text[] := array(
    select distinct lower(trim(e)) from unnest(coalesce(p_emails, '{}')) e
    where trim(e) <> '');
  v_user uuid;
  v_email text;
begin
  -- Les anciens admins par défaut retirés de la liste perdent le rôle.
  for v_email in
    select email from public.admin_invites where source = 'env' and email <> all (v_emails)
  loop
    delete from public.admin_invites where email = v_email;
    select id into v_user from neon_auth."user" where lower(email) = v_email;
    if v_user is not null then
      delete from public.user_roles where user_id = v_user and role = 'admin';
      perform app.audit(null, 'role_revoked', 'user', v_user::text,
        jsonb_build_object('role', 'admin'), null, 'retiré de ADMIN_EMAILS');
    end if;
  end loop;
  insert into public.admin_invites (email, source)
  select e, 'env' from unnest(v_emails) e
  on conflict (email) do update set source = 'env';
  -- Comptes déjà existants : rôle accordé tout de suite.
  for v_user in
    select u.id from neon_auth."user" u
    where lower(u.email) = any (v_emails) and u."emailVerified"
  loop
    perform app.claim_admin_invite(v_user);
  end loop;
  return to_jsonb(v_emails);
end
$$;

revoke all on function app.claim_admin_invite(uuid), app.sync_admin_emails(text[]) from public;
revoke all on function app.sync_admin_emails(text[]) from authenticated, anonymous;
revoke all on function
  public.admin_admins(), public.admin_invite_admin(text), public.admin_remove_admin(text)
  from public, anonymous;
grant execute on function
  public.admin_admins(), public.admin_invite_admin(text), public.admin_remove_admin(text),
  public.record_sign_in(text)
  to authenticated;
