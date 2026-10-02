-- Garde de sécurité (constitution V) : échoue dès qu'une migration expose une
-- table sans RLS, ou donne un droit d'écriture à `anonymous`.

select plan(3);

select is_empty(
  $$
    select c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p')
      and not c.relrowsecurity
  $$,
  'toute table de public a RLS activé'
);

select is_empty(
  $$
    select table_name || ' : ' || privilege_type
    from information_schema.role_table_grants
    where grantee = 'anonymous'
      and table_schema = 'public'
      and privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
  $$,
  'anonymous n''écrit dans aucune table'
);

select is_empty(
  $$
    select c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p')
      and c.relrowsecurity
      and not exists (select 1 from pg_policy p where p.polrelid = c.oid)
      and (has_table_privilege('authenticated', c.oid, 'SELECT')
        or has_table_privilege('anonymous', c.oid, 'SELECT'))
  $$,
  'toute table exposée a au moins une politique'
);

select * from finish();
