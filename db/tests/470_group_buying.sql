-- Achat groupé entre voisins, départ groupé (spec 051).

select plan(16);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('awa@example.com') as awa,
       tests.create_user('efua@example.com') as efua,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       '47000000-0000-4000-8000-000000000001'::uuid as igname,
       '47000000-0000-4000-8000-000000000002'::uuid as igname_tas,
       null::uuid as kodjo_store, null::uuid as offer, null::uuid as order1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._line_price() returns bigint
language sql as $$
  select (public.my_cart() -> 'stores' -> 0 -> 'lines' -> 0 ->> 'unit_price_minor')::bigint
$$;
grant execute on function pg_temp._line_price() to authenticated;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select public.save_product(jsonb_build_object(
  'id', (select igname from _t), 'name', 'Igname', 'category_id', (select id from public.categories where slug = 'tomates'),
  'price_minor', 1000,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select igname from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select igname_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select igname from _t));
select throws_ok(format($$select public.create_group_offer('%s', 1000, 5)$$, (select igname from _t)), '22023',
  'invalid_amount', 'prix de groupe au moins égal au prix : refusé');
update _t set offer = (public.create_group_offer((select igname from _t), 800, 5, 3, 200) ->> 'id')::uuid;
select is(jsonb_array_length(public.my_group_offers()), 1, 'offre ouverte');
select throws_ok(format($$select public.join_group_offer('%s', 2)$$, (select offer from _t)), 'P0001', 'own_store',
  'pas dans son propre groupe');

-- Les voisines s'inscrivent ; le groupe se débloque au minimum.
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select is(jsonb_array_length(public.group_offers_near()), 1, 'offre visible dans le quartier');
select is(public.join_group_offer((select offer from _t), 2) ->> 'reached', 'false', 'inscrite, pas encore débloqué');
select tests.login_as((select efua from _t));
select public.complete_profile('Efua', (select be from _t), 'client');
select is(public.join_group_offer((select offer from _t), 3) ->> 'reached', 'true', 'minimum atteint : débloqué');
select tests.logout();
select is((select count(*)::int from public.notifications where kind = 'group_unlocked'), 2, 'membres prévenues');

-- Prix de groupe et frais partagés au panier.
select tests.login_as((select awa from _t));
select throws_ok(format($$select public.join_group_offer('%s', 1)$$, (select offer from _t)), 'P0001', 'group_locked',
  'débloqué : pas de baisse');
select public.cart_add((select igname_tas from _t), 2);
select is(pg_temp._line_price(), 800::bigint, 'prix de groupe');
select public.cart_set_quantity((select igname_tas from _t), 3);
select is(pg_temp._line_price(), 1000::bigint, 'au-delà de sa quantité : prix du jour');
select public.cart_set_quantity((select igname_tas from _t), 2);
select tests.logout();
select is(app.cart_store_fee((select id from public.carts where user_id = (select awa from _t)), (select kodjo_store from _t)),
  200::bigint, 'livraison partagée : frais des membres');

update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
select is((select subtotal_minor from public.orders where id = (select order1 from _t)), 1600::bigint,
  'commande au prix de groupe');
select is((select order_id from public.group_members where user_id = (select awa from _t)), (select order1 from _t),
  'avantage consommé');
select is(app.cart_line_price((select id from public.carts where user_id = (select awa from _t)), (select igname_tas from _t), 1),
  1000::bigint, 'ensuite : prix du jour');

-- Annulation : les membres sont prévenues.
select tests.login_as((select kodjo from _t));
select is(public.cancel_group_offer((select offer from _t)) ->> 'status', 'cancelled', 'offre annulée');
select tests.logout();
select is((select count(*)::int from public.notifications where kind = 'group_cancelled'), 2, 'annulation annoncée');

select * from finish();
