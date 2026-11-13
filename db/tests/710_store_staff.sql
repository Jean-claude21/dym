-- Personnel des boutiques et succursales (spec 087) : rôles, garde commune, invitations, boutique
-- active, propriétaire seule pour l'argent, les réglages et l'équipe.

select plan(19);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kofi@example.com') as kofi,
       tests.create_user('sena@example.com') as sena,
       tests.create_user('awa@example.com') as awa,
       null::uuid as store, null::uuid as branch, null::uuid as conv, null::uuid as zoe;
update _t set store = tests.open_store(kodjo, 'Super Frais', 'be');
grant select, update on _t to authenticated, anonymous;

-- La propriétaire invite : comptes existants ajoutés tout de suite, sinon invitation.
select tests.login_as((select kodjo from _t));
select public.invite_store_staff('ama@example.com', 'preparer');
select public.invite_store_staff('kofi@example.com', 'manager');
select public.invite_store_staff('sena@example.com', 'cashier');
select is(jsonb_array_length(public.invite_store_staff('zoe@example.com', 'cashier')), 4, 'équipe de quatre');
select is((select x ->> 'status' from jsonb_array_elements(public.my_store_staff()) x
           where x ->> 'email' = 'zoe@example.com'), 'invited', 'compte inexistant : invitation');
select throws_ok($$select public.invite_store_staff('kodjo@example.com', 'manager')$$, 'P0001', 'own_store',
  'pas soi-même');

-- Préparatrice : commandes et chat, pas le catalogue ni l'argent.
select tests.login_as((select ama from _t));
select is(public.my_store() ->> 'staff_role', 'preparer', 'elle voit la boutique avec son rôle');
select ok(public.my_store() -> 'staff_permissions' ? 'orders', 'permission commandes');
select lives_ok($$select public.my_store_orders('active', 20)$$, 'préparatrice : commandes');
select throws_ok($$select public.save_product('{"name": "Tomate"}'::jsonb)$$, '42501', 'permission_denied',
  'préparatrice : pas le catalogue');
select throws_ok($$select public.my_store_balance()$$, 'P0002', null, 'préparatrice : pas l''argent');

-- Gérante : catalogue, pas les réglages ni l'équipe.
select tests.login_as((select kofi from _t));
select lives_ok($$select public.my_products()$$, 'gérante : catalogue');
select throws_ok($$select public.set_store_hours('[]'::jsonb)$$, '42501', 'permission_denied',
  'gérante : pas les horaires');
select throws_ok($$select public.invite_store_staff('x@example.com', 'manager')$$, '42501', 'permission_denied',
  'gérante : pas l''équipe');

-- Caissière : caisse, pas le chat.
select tests.login_as((select sena from _t));
select lives_ok($$select public.my_till()$$, 'caissière : caisse');
select tests.logout();
update _t set conv = (app.start_conversation((select awa from _t), (select store from _t)) ->> 'id')::uuid;
select is(app.conversation_role((select sena from _t), (select conv from _t)), null, 'caissière : pas le chat');
select is(app.conversation_role((select ama from _t), (select conv from _t)), 'vendor',
  'préparatrice : répond au chat de la boutique');

-- Invitation acceptée à la première visite ; succursale et boutique active.
update _t set zoe = tests.create_user('zoe@example.com');
update _t set branch = tests.open_store(zoe, 'Super Frais Bè', 'be');
select tests.login_as((select zoe from _t));
select is(jsonb_array_length(public.my_stores()), 2, 'sa boutique et celle où elle est caissière');
select is((public.set_active_store((select store from _t)) -> 0 ->> 'name'), 'Super Frais',
  'boutique active : la succursale choisie');
select is(public.my_store() ->> 'staff_role', 'cashier', 'rôle de la boutique active');

-- Lecture de la pile : fonctions PL/pgSQL et SQL simple.
select tests.logout();
select is(array(select app.context_functions(
  E'PL/pgSQL function app.own_store_id() line 15 at RAISE
SQL function "my_store_orders" during startup')),
  array['app.own_store_id', 'public.my_store_orders', 'app.my_store_orders'], 'pile lue dans l''ordre');

-- Retrait : plus d'accès.
select tests.login_as((select kodjo from _t));
select public.remove_store_staff('ama@example.com');
select tests.login_as((select ama from _t));
select is(public.my_store(), null, 'retirée : plus de boutique');

select * from finish();
