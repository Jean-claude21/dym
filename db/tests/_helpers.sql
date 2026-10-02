-- Aides de test, chargées par `dym-db test` au début de chaque transaction de
-- test (annulée ensuite) : rien ne persiste, y compris sur une branche Neon.

create schema tests;

-- Crée un utilisateur Neon Auth et renvoie son identifiant.
create function tests.create_user(p_email text) returns uuid
language sql
as $$
  insert into neon_auth."user" (name, email, "emailVerified")
  values (split_part(p_email, '@', 1), p_email, true)
  returning id
$$;

-- Agit comme la Data API pour un utilisateur connecté.
create function tests.login_as(p_user uuid) returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end
$$;

-- Agit comme la Data API sans jeton.
create function tests.login_anonymous() returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims', '', true);
  execute 'set local role anonymous';
end
$$;

-- Revient au rôle propriétaire (préparation des données).
create function tests.logout() returns void
language plpgsql
as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end
$$;

grant usage on schema tests to authenticated, anonymous;
grant execute on all functions in schema tests to authenticated, anonymous;
