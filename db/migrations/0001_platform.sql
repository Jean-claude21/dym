-- 0001 — Socle commun (spec 003).
-- Schéma interne, identité courante, horodatage, droits de la Data API.

-- Fonctions internes : jamais exposées par la Data API (seul `public` l'est).
create schema if not exists app;

revoke all on schema app from public;
grant usage on schema app to authenticated, anonymous;

-- Utilisateur courant en uuid (NULL pour une requête anonyme).
create or replace function app.current_user_id() returns uuid
language sql stable
as $$
  select auth.uid()
$$;

grant execute on function app.current_user_id() to authenticated, anonymous;

-- Trigger : `updated_at = now()` à chaque mise à jour.
create or replace function app.set_updated_at() returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end
$$;

-- Droits de la Data API : rien n'est accordé par défaut. L'option « Grant public
-- schema access » de Neon donne SELECT/INSERT/UPDATE/DELETE sur toute nouvelle
-- table ; on le retire pour que chaque table accorde explicitement ses droits,
-- après activation de RLS (garde : db/tests/000_security_guard.sql).
grant usage on schema public to authenticated, anonymous;
alter default privileges in schema public
  revoke all on tables from authenticated, anonymous;
alter default privileges in schema public
  revoke all on sequences from authenticated, anonymous;
-- Fonctions : PostgreSQL accorde EXECUTE à PUBLIC au niveau global (un retrait
-- par schéma serait sans effet). Chaque fonction exposée accorde son droit.
alter default privileges revoke execute on functions from public;
