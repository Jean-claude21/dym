-- Espaces partagés (spec 031) : membres et rôles, panier commun, validation, budget, isolation.

select plan(23);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kofi@example.com') as kofi,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '27000000-0000-4000-8000-000000000001'::uuid as tomate,
       '27000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       null::uuid as kodjo_store, null::uuid as space, null::text as code;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));

select tests.login_as((select kofi from _t));
select public.complete_profile('Kofi', (select be from _t), 'client');
select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');

-- Awa crée « Maison » avec un budget de 3 000.
update _t set space = (public.create_space(' Maison ', 3000) ->> 'id')::uuid;
update _t set code = public.space_detail((select space from _t)) ->> 'join_code';
select is(public.space_detail((select space from _t)) ->> 'my_role', 'payer', 'la créatrice valide et paie');
select is(public.my_spaces() -> 0 ->> 'name', 'Maison', 'espace listé, nom nettoyé');
select throws_ok($$select public.create_space('X', 0)$$, '22023', 'invalid_budget', 'budget nul refusé');

-- Kofi rejoint avec le code (minuscules acceptées) et remplit.
select tests.login_as((select kofi from _t));
select throws_ok($$select public.join_space('ZZZZZZZZ')$$, 'P0002', 'unknown_code', 'code inconnu refusé');
select is(public.join_space(lower((select code from _t))) ->> 'my_role', 'member', 'Kofi rejoint comme membre');
select throws_ok(format($$select public.send_cart_to_space('%s')$$, (select space from _t)), '22023', 'cart_empty',
  'panier vide refusé');
select public.cart_add((select tomate_tas from _t), 4);
select is((public.send_cart_to_space((select space from _t)) ->> 'total_minor')::bigint, 2000::bigint,
  'panier envoyé, chiffré par la base');
select is((public.my_cart() ->> 'item_count')::int, 0, 'panier de Kofi vidé');
select is(public.space_detail((select space from _t)) -> 'items' -> 0 ->> 'added_by', 'Kofi', 'qui a ajouté');
select throws_ok(format($$select public.validate_space('%s')$$, (select space from _t)), '42501', 'not_payer',
  'un membre ne valide pas');
select throws_ok(format($$select public.set_space_role('%s', '%s', 'payer')$$, (select space from _t),
  (select kofi from _t)), '42501', 'not_allowed', 'seule la responsable change les rôles');

-- Isolation : Ama ne voit rien.
select tests.login_as((select ama from _t));
select is(jsonb_array_length(public.my_spaces()), 0, 'Ama ne voit pas l''espace');
select is((select count(*)::int from public.spaces) + (select count(*)::int from public.space_items), 0,
  'lecture directe filtrée (RLS)');
select throws_ok(format($$select public.space_detail('%s')$$, (select space from _t)), 'P0002', null,
  'détail refusé');
select throws_ok(format($$select public.set_space_item('%s', '%s', 1)$$, (select space from _t),
  (select tomate_tas from _t)), 'P0002', null, 'modification refusée');

-- Budget : 6 tas (3 000) passent, 8 tas non.
select tests.login_as((select awa from _t));
select public.set_space_item((select space from _t), (select tomate_tas from _t), 8);
select throws_ok(format($$select public.validate_space('%s')$$, (select space from _t)), '22023',
  'budget_exceeded', 'dépassement du budget refusé');
select public.set_space_item((select space from _t), (select tomate_tas from _t), 6);
create temporary table _v as select public.validate_space((select space from _t)) as r;
select is((select (r ->> 'added')::int from _v), 1, 'validation : article passé au panier d''Awa');
select is((public.my_cart() ->> 'item_count')::int, 6, 'quantités reprises');
select is((public.space_detail((select space from _t)) ->> 'spent_month_minor')::bigint, 3000::bigint,
  'dépensé du mois');
select is(jsonb_array_length(public.space_detail((select space from _t)) -> 'items'), 0, 'panier commun vidé');
select tests.logout();
select is((select count(*)::int from public.notifications where kind = 'space_validated'
           and user_id = (select kofi from _t)), 1, 'Kofi prévenu');

-- Rôles et départ : la responsable ne quitte pas ; Kofi quitte.
select tests.login_as((select awa from _t));
select throws_ok(format($$select public.remove_space_member('%s', '%s')$$, (select space from _t),
  (select awa from _t)), '22023', 'owner_cannot_leave', 'la responsable ne quitte pas');
select tests.login_as((select kofi from _t));
select public.remove_space_member((select space from _t), (select kofi from _t));
select tests.logout();
select is((select count(*)::int from public.space_members where space_id = (select space from _t)), 1, 'Kofi a quitté');

select * from finish();
