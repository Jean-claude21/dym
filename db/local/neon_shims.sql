-- Imitation locale de ce que Neon fournit (Data API + Neon Auth).
-- NE JAMAIS appliquer sur Neon : ces objets y existent déjà, gérés par Neon.
-- Appliqué par `dym-db local start` et par la CI (`--neon-shims`).
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

-- Utilisateurs de Neon Auth (Managed Better Auth).
create schema if not exists neon_auth;

create table if not exists neon_auth."user" (
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
