-- Rôles et permissions des admins (spec 085) : garde commune par permission, rôles par défaut,
-- changement de rôle réservé et journalisé, aucune fonction admin oubliée.

select plan(17);

create temporary table _t as
select tests.create_user('chef@example.com') as chef,
       tests.create_user('ana@example.com') as ana,
       tests.create_user('sam@example.com') as sam,
       tests.create_user('fin@example.com') as fin,
       tests.create_user('nouvel@example.com') as nouvel;
insert into public.user_roles (user_id, role)
select u, 'admin' from _t, unnest(array[chef, ana, sam, fin]) u;
insert into public.admin_members (user_id, role_code)
select ana, 'analyst' from _t union all select sam, 'support' from _t union all select fin, 'finance' from _t;
grant select, update on _t to authenticated, anonymous;

-- Aucune fonction gardée par l'admin sans permission déclarée.
select is((
  select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname in ('public', 'app')
    and (p.prosrc like '%require_admin()%' or p.prosrc like '%assert_admin(%' or p.prosrc like '%require_ops(%')
    and p.proname not in ('require_admin', 'assert_admin', 'require_ops')
    and not exists (select 1 from public.admin_function_permissions f
                    where f.function_name = n.nspname || '.' || p.proname)), 0,
  'chaque fonction admin a sa permission');

-- Admin d'avant les rôles : super-admin.
select tests.login_as((select chef from _t));
select is(public.admin_me() ->> 'role', 'super_admin', 'admin sans rôle enregistré : super-admin');
select lives_ok($$select public.admin_set_commission('TG', null, 1000)$$, 'super-admin : réglage du prix');

-- Analyste : tout lire, ne rien modifier, pas la liste des admins.
select tests.login_as((select ana from _t));
select is(public.admin_me() ->> 'role', 'analyst', 'rôle analyste');
select ok(not (public.admin_me() -> 'permissions') ? 'admins.read', 'analyste : pas la liste des admins');
select lives_ok($$select public.admin_orders('all')$$, 'analyste : lit les commandes');
select throws_ok($$select public.admin_set_commission('TG', null, 900)$$, '42501', 'permission_denied',
  'analyste : ne modifie pas les prix');
select throws_ok($$select public.admin_admins()$$, '42501', 'permission_denied', 'analyste : pas les admins');

-- Support : commandes et tickets, pas les finances.
select tests.login_as((select sam from _t));
select lives_ok($$select public.admin_tickets()$$, 'support : tickets');
select throws_ok($$select public.admin_refunds()$$, '42501', 'permission_denied', 'support : pas les remboursements');

-- Finance : remboursements.
select tests.login_as((select fin from _t));
select lives_ok($$select public.admin_refunds()$$, 'finance : remboursements');

-- Rôles : réservés au super-admin, jamais le sien, journalisés.
select tests.login_as((select fin from _t));
select throws_ok($$select public.admin_set_role('ana@example.com', 'finance')$$, '42501', 'permission_denied',
  'finance : ne change pas les rôles');
select tests.login_as((select chef from _t));
select throws_ok($$select public.admin_set_role('chef@example.com', 'analyst')$$, 'P0001', 'own_role',
  'pas son propre rôle');
select is((select a ->> 'role' from jsonb_array_elements(public.admin_set_role('ana@example.com', 'content')) a
           where a ->> 'email' = 'ana@example.com'), 'content', 'rôle changé');
select tests.logout();
select is((select count(*)::int from public.audit_log where action = 'admin_role_set'), 1, 'changement journalisé');

-- Invitation avec un rôle : appliqué quand l'invitée devient admin.
select tests.login_as((select chef from _t));
select public.admin_invite_admin('nouvel@example.com', 'support');
select public.admin_invite_admin('plus@example.com', 'finance');
select tests.logout();
select is(app.admin_role((select nouvel from _t)), 'support', 'compte existant : rôle de l''invitation');
-- Compte créé après l'invitation : rôle appliqué quand il devient admin (connexion).
insert into public.user_roles (user_id, role) values (tests.create_user('plus@example.com'), 'admin');
select is(app.admin_role((select id from neon_auth."user" where email = 'plus@example.com')), 'finance',
  'nouveau compte : rôle de l''invitation appliqué');

select * from finish();
