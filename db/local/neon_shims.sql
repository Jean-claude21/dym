-- Imitation locale de ce que Neon fournit (Data API + Neon Auth).
-- NE JAMAIS appliquer sur une branche Neon où Neon Auth et la Data API sont actifs (staging,
-- production) : ces objets y existent déjà. Appliqué par `dym-db local start`, par la CI et sur
-- une branche de test jetable créée depuis `main` vide (`--neon-shims`).
-- Référence : specs/003-foundation/research.md (R1).

-- Rôles de la Data API.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'anonymous') then
    create role anonymous nologin;
  end if;
  -- Les tests endossent ces rôles ; sur Neon, l'utilisateur n'est pas superutilisateur.
  execute format('grant authenticated, anonymous to %I', current_user);
end
$$;

-- Identité de la requête : la Data API expose les claims du JWT.
create schema if not exists auth;

create or replace function auth.user_id() returns text
language sql stable
as $$
  select nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
$$;

create or replace function auth.uid() returns uuid
language sql stable
as $$
  select case
    when auth.user_id() ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      then auth.user_id()::uuid
  end
$$;

grant usage on schema auth to authenticated, anonymous;
grant execute on function auth.user_id(), auth.uid() to authenticated, anonymous;

-- Utilisateurs de Neon Auth (Managed Better Auth). Sur une branche Neon où Neon Auth est actif
-- (branche jetable créée depuis `main`), la table existe et le schéma n'est pas modifiable :
-- rien n'est créé.
do $shim$
begin
  if to_regclass('neon_auth."user"') is not null then
    return;
  end if;
  create schema if not exists neon_auth;
  create table neon_auth."user" (
    id uuid primary key default gen_random_uuid(),
    name text not null default '',
    email text not null unique,
    "emailVerified" boolean not null default false,
    image text,
    "createdAt" timestamptz not null default now(),
    "updatedAt" timestamptz not null default now(),
    role text,
    banned boolean,
    "banReason" text,
    "banExpires" timestamptz
  );
end
$shim$;
