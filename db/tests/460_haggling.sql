-- Marchandage dans la limite de la vendeuse (spec 050).

select plan(19);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('awa@example.com') as awa,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       '46000000-0000-4000-8000-000000000001'::uuid as igname,
       '46000000-0000-4000-8000-000000000002'::uuid as igname_tas,
       '46000000-0000-4000-8000-000000000003'::uuid as piment,
       '46000000-0000-4000-8000-000000000004'::uuid as piment_tas,
       null::uuid as kodjo_store, null::jsonb as counter, null::uuid as order1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._publish(p_id uuid, p_variant uuid, p_name text, p_price bigint) returns void
language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', (select id from public.categories where slug = 'tomates'),
    'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', 20))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, text, bigint) to authenticated;

create function pg_temp._line_price() returns bigint
language sql as $$
  select (public.my_cart() -> 'stores' -> 0 -> 'lines' -> 0 ->> 'unit_price_minor')::bigint
$$;
grant execute on function pg_temp._line_price() to authenticated;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select pg_temp._publish((select igname from _t), (select igname_tas from _t), 'Igname', 1000);
select pg_temp._publish((select piment from _t), (select piment_tas from _t), 'Piment', 200);
select tests.logout();

-- Pas de limite : pas de marchandage.
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select is(public.product_page((select igname from _t)) ->> 'can_haggle', 'false', 'fiche : marchandage fermé');
select throws_ok(format($$select public.propose_haggle('%s', 2, 900)$$, (select igname_tas from _t)), 'P0001',
  'haggle_off', 'refusé sans limite');

-- La vendeuse fixe 10 % pour la boutique et « jamais » pour le piment.
select tests.login_as((select kodjo from _t));
select throws_ok($$select public.set_haggle_limit(80)$$, '22023', 'invalid_percent', 'limite hors bornes');
select is((public.set_haggle_limit(10) ->> 'store_percent')::int, 10, 'limite de la boutique');
select is(public.set_haggle_limit(0, (select piment from _t)) -> 'products' -> 1 ->> 'percent', '0',
  'piment : jamais');
select throws_ok(format($$select public.propose_haggle('%s', 1, 900)$$, (select igname_tas from _t)), 'P0001',
  'own_store', 'pas sur sa propre boutique');

select tests.login_as((select awa from _t));
select is(public.product_page((select igname from _t)) ->> 'can_haggle', 'true', 'fiche : marchandage ouvert');
select ok(not public.product_page((select igname from _t))::text like '%haggle_max%', 'limite jamais montrée');
select is(public.product_page((select piment from _t)) ->> 'can_haggle', 'false', 'produit exclu');
select throws_ok(format($$select public.propose_haggle('%s', 2, 1000)$$, (select igname_tas from _t)), 'P0001',
  'offer_not_lower', 'offre au prix : refusée');

-- Au-dessus du plancher (900) : conclu, au panier à 950.
select is(public.propose_haggle((select igname_tas from _t), 2, 950) ->> 'status', 'accepted', 'marché conclu');
select is(pg_temp._line_price(), 950::bigint, 'panier au prix conclu');
select public.cart_set_quantity((select igname_tas from _t), 3);
select is(pg_temp._line_price(), 1000::bigint, 'au-delà de la quantité : prix du jour');
select public.cart_set_quantity((select igname_tas from _t), 2);

-- Sous le plancher : contre-prix au milieu (900), accepté.
update _t set counter = public.propose_haggle((select igname_tas from _t), 2, 800);
select is((select counter ->> 'price_minor' from _t), '900', 'contre-prix de la vendeuse');
select is(public.accept_haggle((select (counter ->> 'id')::uuid from _t)) ->> 'status', 'accepted', 'contre-prix accepté');
select is(pg_temp._line_price(), 900::bigint, 'panier au meilleur prix conclu');
select public.propose_haggle((select igname_tas from _t), 2, 990);
select throws_ok(format($$select public.propose_haggle('%s', 2, 950)$$, (select igname_tas from _t)), 'P0001',
  'too_many_attempts', '3 propositions par jour');
select tests.logout();

-- La commande prend le prix conclu et le consomme.
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
select is((select subtotal_minor from public.orders where id = (select order1 from _t)), 1800::bigint,
  'commande au prix conclu');
select is((select status from public.haggles where id = (select (counter ->> 'id')::uuid from _t)), 'used', 'prix conclu consommé');

select * from finish();
