-- Achat de gros groupé (spec 049).

select plan(14);

create temporary table _t as
select tests.create_user('yao@example.com') as yao,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('efua@example.com') as efua,
       '45000000-0000-4000-8000-000000000001'::uuid as riz,
       '45000000-0000-4000-8000-000000000002'::uuid as riz_sac,
       null::uuid as yao_store, null::uuid as offer;
update _t set yao_store = tests.open_store(yao, 'Grossiste Yao', 'be');
select tests.open_store((select kodjo from _t), 'Étal de Kodjo', 'be');
select tests.open_store((select efua from _t), 'Huiles d''Efua', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select yao from _t));
select public.save_product(jsonb_build_object(
  'id', (select riz from _t), 'name', 'Riz 25 kg', 'category_id', (select id from public.categories where slug = 'cereales-farines'),
  'price_minor', 18000,
  'photo_keys', jsonb_build_array('stores/' || (select yao_store from _t) || '/products/' || (select riz from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select riz_sac from _t)))));
select public.publish_product((select riz from _t));
select throws_ok(format($$select public.create_wholesale_offer('%s', 15000, 20)$$, (select riz from _t)),
  '42501', 'not_wholesaler', 'grossistes seulement');
select is(public.set_wholesaler(true) ->> 'is_wholesaler', 'true', 'devenue grossiste');
update _t set offer = (public.create_wholesale_offer((select riz from _t), 15000, 20, 7, 'Livré au marché') ->> 'id')::uuid;
select throws_ok(format($$select public.commit_wholesale('%s', 5)$$, (select offer from _t)), 'P0001', 'own_offer',
  'pas d''engagement sur sa propre offre');
select throws_ok(format($$select public.decide_wholesale_offer('%s', true)$$, (select offer from _t)), 'P0001',
  'minimum_not_reached', 'confirmation avant le minimum refusée');

-- Les vendeuses s'engagent ; la jauge monte.
select tests.login_as((select kodjo from _t));
select is(jsonb_array_length(public.wholesale_board() -> 'open'), 1, 'offre visible des vendeuses du pays');
select is((public.commit_wholesale((select offer from _t), 12) ->> 'committed')::int, 12, 'engagement');
select is((public.commit_wholesale((select offer from _t), 8) ->> 'my_quantity')::int, 8, 'quantité modifiée');
select is(public.wholesale_board() -> 'open' -> 0 ->> 'commitments', null, 'les engagements des autres restent privés');
select tests.login_as((select efua from _t));
select is((public.commit_wholesale((select offer from _t), 12) ->> 'committed')::int, 20, 'minimum atteint');

-- La grossiste voit qui achète, confirme ; les acheteuses sont prévenues.
select tests.login_as((select yao from _t));
select is(jsonb_array_length(public.wholesale_board() -> 'mine' -> 0 -> 'commitments'), 2, 'acheteuses visibles');
select is(public.decide_wholesale_offer((select offer from _t), true) ->> 'status', 'confirmed', 'offre confirmée');
select tests.logout();
select is((select count(*)::int from public.notifications where kind = 'wholesale_confirmed'), 2, 'acheteuses prévenues');
select is(app.notification_app('wholesale_confirmed'), 'vendor', 'vers l''app vendeuse');

select tests.login_as((select kodjo from _t));
select throws_ok(format($$select public.commit_wholesale('%s', 3)$$, (select offer from _t)), 'P0001', 'offer_closed',
  'offre close');
select tests.logout();

select * from finish();
