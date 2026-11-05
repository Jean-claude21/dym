-- 0005 — Profils et rôles (spec 005 : C-AUTH, V-AUTH, C-PROF-09, A-AUTH).
-- Le profil et les rôles sont décidés en SQL : le pays découle du quartier,
-- le rôle de l'app déclarée ; admin et livreur ne sont donnés que par un admin.

create table public.profiles (
  user_id uuid primary key references neon_auth."user" (id) on delete cascade,
  first_name text not null check (length(trim(first_name)) between 1 and 40),
  country_code char(2) not null references public.countries (code),
  zone_id uuid references public.zones (id),
  locale text not null default 'fr' check (locale ~ '^[a-z]{2}$'),
  avatar_key text check (avatar_key is null or length(avatar_key) <= 200),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_updated_at before update on public.profiles
  for each row execute function app.set_updated_at();

create table public.user_roles (
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  role text not null check (role in ('client', 'vendor', 'admin', 'courier')),
  granted_at timestamptz not null default now(),
  granted_by uuid,
  primary key (user_id, role)
);

-- ------------------------------------------------------------------ rôles

create or replace function app.has_role(p_role text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = app.current_user_id() and role = p_role
  )
$$;

create or replace function app.is_admin() returns boolean
language sql stable security definer set search_path = ''
as $$
  select app.has_role('admin')
$$;

grant execute on function app.has_role(text), app.is_admin() to authenticated, anonymous;

-- Attribution d'un rôle par un admin (ou par le propriétaire de la base, pour
-- le premier admin). Toujours auditée.
create or replace function app.grant_role(p_user uuid, p_role text, p_reason text default null)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := app.current_user_id();
begin
  if v_actor is not null and not app.is_admin() then
    raise exception 'rôle réservé aux admins' using errcode = '42501';
  end if;
  insert into public.user_roles (user_id, role, granted_by)
  values (p_user, p_role, v_actor)
  on conflict (user_id, role) do nothing;
  perform app.audit(v_actor, 'role_granted', 'user', p_user::text, null,
    jsonb_build_object('role', p_role), p_reason);
end
$$;

create or replace function app.revoke_role(p_user uuid, p_role text, p_reason text default null)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := app.current_user_id();
begin
  if v_actor is not null and not app.is_admin() then
    raise exception 'rôle réservé aux admins' using errcode = '42501';
  end if;
  delete from public.user_roles where user_id = p_user and role = p_role;
  perform app.audit(v_actor, 'role_revoked', 'user', p_user::text,
    jsonb_build_object('role', p_role), null, p_reason);
end
$$;

-- ------------------------------------------------------------------ RLS

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;

create policy profiles_own_read on public.profiles for select
  to authenticated using (user_id = app.current_user_id() or app.is_admin());

create policy profiles_own_update on public.profiles for update
  to authenticated
  using (user_id = app.current_user_id())
  with check (user_id = app.current_user_id());

create policy user_roles_own_read on public.user_roles for select
  to authenticated using (user_id = app.current_user_id() or app.is_admin());

-- Lecture ; mise à jour limitée aux colonnes libres (le pays suit le quartier
-- via complete_profile, la photo arrive avec le stockage).
grant select on public.profiles to authenticated;
grant update (first_name, locale) on public.profiles to authenticated;
grant select on public.user_roles to authenticated;

-- ------------------------------------------------------------------ fonctions exposées

-- Moi : profil et rôles de l'utilisateur connecté (profil absent = à compléter).
create or replace function public.me() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'user_id', app.current_user_id(),
    'profile', (
      select to_jsonb(p) - 'created_at' - 'updated_at'
      from public.profiles p where p.user_id = app.current_user_id()
    ),
    'roles', coalesce((
      select jsonb_agg(r.role order by r.role)
      from public.user_roles r where r.user_id = app.current_user_id()
    ), '[]'::jsonb)
  )
  where app.current_user_id() is not null
$$;

-- Complète (ou met à jour) le profil et donne le rôle de l'app. Rejouable.
create or replace function public.complete_profile(
  p_first_name text,
  p_zone_id uuid,
  p_app text,
  p_locale text default 'fr'
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_country char(2);
  v_created boolean;
  v_role text;
begin
  if v_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  v_role := case p_app when 'client' then 'client' when 'vendor' then 'vendor' end;
  if v_role is null then
    raise exception 'app inconnue : %', p_app using errcode = '22023';
  end if;
  if length(trim(coalesce(p_first_name, ''))) not between 1 and 40 then
    raise exception 'prénom : 1 à 40 caractères' using errcode = '22023';
  end if;

  -- Le quartier doit être visible (actif, ville et pays actifs) ; il fixe le pays.
  select c.country_code into v_country
  from public.zones z
  join public.cities c on c.id = z.city_id
  where z.id = p_zone_id and z.is_active and app.city_is_visible(c.id);
  if v_country is null then
    raise exception 'quartier inconnu ou inactif' using errcode = '22023';
  end if;

  insert into public.profiles (user_id, first_name, country_code, zone_id, locale)
  values (v_user, trim(p_first_name), v_country, p_zone_id, coalesce(p_locale, 'fr'))
  on conflict (user_id) do update
    set first_name = excluded.first_name,
        country_code = excluded.country_code,
        zone_id = excluded.zone_id,
        locale = excluded.locale
  returning (xmax = 0) into v_created;

  insert into public.user_roles (user_id, role) values (v_user, v_role)
  on conflict (user_id, role) do nothing;

  if v_created then
    perform app.emit_event('user_signed_up', v_user, v_role, p_app, v_country, 'user',
      v_user::text, jsonb_build_object('role', v_role));
  end if;

  return public.me();
end
$$;

-- Connexion réussie : événement, et audit pour l'admin.
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

-- Obstacles à la suppression (complétée par les specs de commande).
create or replace function app.account_deletion_blockers(p_user uuid) returns text[]
language sql stable
as $$
  select array[]::text[]
$$;

-- Suppression du compte par sa propriétaire : données personnelles effacées
-- (utilisateur, profil, rôles, sessions en cascade), trace pseudonyme gardée.
create or replace function public.delete_my_account() returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_blockers text[];
  v_country char(2);
  v_roles jsonb;
begin
  if v_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  if not exists (select 1 from neon_auth."user" where id = v_user) then
    return; -- déjà supprimé
  end if;
  v_blockers := app.account_deletion_blockers(v_user);
  if cardinality(v_blockers) > 0 then
    raise exception 'suppression impossible : %', array_to_string(v_blockers, ', ')
      using errcode = 'P0001';
  end if;

  select country_code into v_country from public.profiles where user_id = v_user;
  select coalesce(jsonb_agg(role order by role), '[]'::jsonb) into v_roles
  from public.user_roles where user_id = v_user;

  perform app.audit(v_user, 'account_deleted', 'user', v_user::text,
    jsonb_build_object('roles', v_roles), null, 'demande de la personne');
  perform app.emit_event('account_deleted', v_user, 'authenticated', 'server', v_country,
    'user', v_user::text, jsonb_build_object('roles', v_roles));

  delete from neon_auth."user" where id = v_user;
end
$$;

insert into public.event_names (name, emitted_by, description) values
  ('account_deleted', 'server', 'Compte supprimé par sa propriétaire');

revoke all on function
  public.me(), public.complete_profile(text, uuid, text, text),
  public.record_sign_in(text), public.delete_my_account()
  from public;
grant execute on function
  public.me(), public.complete_profile(text, uuid, text, text),
  public.record_sign_in(text), public.delete_my_account()
  to authenticated;

-- Les fonctions vérifient elles-mêmes le rôle admin ; l'admin les appellera
-- par des fonctions publiques ajoutées avec la spec admin-ops.
grant execute on function app.grant_role(uuid, text, text), app.revoke_role(uuid, text, text)
  to authenticated;
