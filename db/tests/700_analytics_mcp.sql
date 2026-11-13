-- Analytics (vues sans donnée personnelle, lecteur en lecture seule) et clés MCP (spec 086).

select plan(13);

create temporary table _t as
select tests.create_user('chef@example.com') as chef,
       tests.create_user('ana@example.com') as ana,
       null::text as key, null::uuid as key_id;
insert into public.user_roles (user_id, role) select u, 'admin' from _t, unnest(array[chef, ana]) u;
insert into public.admin_members (user_id, role_code) select ana, 'analyst' from _t;
grant select, update on _t to authenticated, anonymous;

-- Aucune colonne personnelle dans les vues d'analyse.
select is((select count(*)::int from information_schema.columns
           where table_schema = 'analytics'
             and column_name in ('email', 'phone', 'first_name', 'address', 'user_id', 'actor_id',
                                 'owner_id', 'client_id', 'courier_id')), 0,
  'aucune colonne personnelle dans analytics');
select ok((select count(*) from information_schema.views where table_schema = 'analytics') >= 7,
  'vues d''analyse publiées');

-- Lecteur : analytics seulement.
select ok(has_table_privilege('analytics_reader', 'analytics.daily_orders', 'select'),
  'lecteur : commandes du jour');
select ok(has_table_privilege('analytics_reader', 'analytics.daily_funnel', 'select'),
  'lecteur : parcours d''achat');
select ok(not has_table_privilege('analytics_reader', 'public.profiles', 'select')
          and not has_schema_privilege('analytics_reader', 'public', 'create'),
  'lecteur : ni les profils ni l''écriture');

-- Clés MCP : créées par le super-admin, montrées une fois, empreinte seule gardée.
select tests.login_as((select chef from _t));
update _t set key = public.admin_create_mcp_key('Claude') ->> 'key';
update _t set key_id = (public.admin_mcp_keys() -> 0 ->> 'id')::uuid;
select ok((select key from _t) like 'dym_mcp_%' and length((select key from _t)) = 72, 'clé de 64 caractères aléatoires');
select is(public.admin_mcp_keys() -> 0 ->> 'key', null, 'la liste ne montre jamais la clé');
select tests.logout();
select is((select count(*)::int from public.admin_mcp_keys where key_hash = (select key from _t)), 0,
  'la clé n''est pas stockée en clair');
select is(app.mcp_key_user((select key from _t)), (select chef from _t), 'clé valide : son propriétaire');
select is(app.mcp_key_user('dym_mcp_faux'), null, 'clé inconnue refusée');

-- Fonctions offertes au MCP selon le rôle.
select ok(not app.mcp_admin_functions((select ana from _t)) @> '[{"name": "admin_set_commission"}]',
  'analyste : pas de réglage des prix par le MCP');

select tests.login_as((select ana from _t));
select throws_ok($$select public.admin_create_mcp_key('test')$$, '42501', 'permission_denied',
  'analyste : ne crée pas de clé');
select tests.login_as((select chef from _t));
select public.admin_revoke_mcp_key((select key_id from _t));
select tests.logout();
select is(app.mcp_key_user((select key from _t)), null, 'clé révoquée refusée');

select * from finish();
