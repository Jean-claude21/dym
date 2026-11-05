-- Identité sur Neon (décision 0013, validée sur la branche staging) :
-- - la Data API vérifie le JWT de Neon Auth puis pose ses claims dans
--   `request.jwt.claims` ;
-- - `auth.uid()` (pg_session_jwt) refuse de s'exécuter dans une fonction
--   SECURITY DEFINER, et les rôles `authenticated`/`anonymous` n'ont pas
--   l'usage du schéma `auth`.
-- L'identité est donc lue dans `request.jwt.claims`, que seule la Data API
-- pose (les Functions se connectent en propriétaire et passent un identifiant
-- explicite aux fonctions `app.*`).

create or replace function app.current_user_id() returns uuid
language sql stable set search_path = ''
as $$
  select case
    when sub ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then sub::uuid
  end
  from (
    select nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub' as sub
  ) claims
$$;

grant execute on function app.current_user_id() to authenticated, anonymous;
