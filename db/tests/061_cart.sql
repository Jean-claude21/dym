-- Panier multi-boutiques (spec 009, US1 et US4) : lignes, groupement, frais
-- (maquette 05 : base + supplément par ramassage, gratuité au seuil), problèmes.

select plan(29);

-- Lundi 5 octobre 2026, 10 h à Lomé (UTC+0) : boutiques ouvertes (7 h - 19 h).
create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('esi@example.com') as esi,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       '2026-10-05 20:00:00+00'::timestamptz as evening,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.zones where slug = 'agoe') as agoe,
       (select id from public.categories where slug = 'boissons') as boissons,
       (select id from public.categories where slug = 'tomates') as tomates,
       '11111111-1111-4111-8111-111111111111'::uuid as bissap,
       'b1000000-0000-4000-8000-000000000001'::uuid as bissap_1l,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       null::uuid as esi_store, null::uuid as kodjo_store;
update _t set esi_store = tests.open_store(esi, 'Les jus d''Esi', 'tokoin'),
              kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select on _t to authenticated, anonymous;

create function pg_temp._product(p_store uuid, p_id uuid, p_name text, p_category uuid, p_price bigint,
  p_variants jsonb) returns jsonb language sql as $$
  select jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', p_category, 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || p_store || '/products/' || p_id || '.jpg'),
    'variants', p_variants)
$$;
grant execute on function pg_temp._product(uuid, uuid, text, uuid, bigint, jsonb) to authenticated;

-- Esi livre Bè ; bissap 700 (1 L, stock 3).
select tests.login_as((select esi from _t));
select public.set_store_delivery_zones(array[(select id from public.zones where slug = 'tokoin'), (select be from _t)]);
select public.save_product(pg_temp._product((select esi_store from _t), (select bissap from _t), 'Jus de bissap',
  (select boissons from _t), 700, jsonb_build_array(jsonb_build_object('id', (select bissap_1l from _t),
  'label', '1 L', 'stock_quantity', 3))));
select public.publish_product((select bissap from _t));
-- Kodjo (Bè) : tomates 500 le tas, stock non suivi.
select tests.login_as((select kodjo from _t));
select public.save_product(pg_temp._product((select kodjo_store from _t), (select tomate from _t), 'Tomates fraîches',
  (select tomates from _t), 500, jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t)))));
select public.publish_product((select tomate from _t));

-- Awa, cliente à Bè.
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');

select is(public.my_cart((select null::uuid), '{}', null, (select morning from _t)) ->> 'item_count', '0', 'panier vide');
select lives_ok(format($$select public.cart_add('%s', 2)$$, (select tomate_tas from _t)), 'ajout');
select lives_ok(format($$select public.cart_add('%s')$$, (select tomate_tas from _t)), 'même variante');
select is(public.my_cart() -> 'stores' -> 0 -> 'lines', jsonb_build_array(public.my_cart() -> 'stores' -> 0 -> 'lines' -> 0),
  'une seule ligne');
select is((public.my_cart() -> 'stores' -> 0 -> 'lines' -> 0 ->> 'quantity')::int, 3, 'quantités additionnées');
select lives_ok(format($$select public.cart_add('%s', 5)$$, (select bissap_1l from _t)), 'ajout chez Esi');
select is((public.my_cart() -> 'stores' -> 1 -> 'lines' -> 0 ->> 'quantity')::int, 3, 'plafonné au stock suivi');
select throws_ok(format($$select public.cart_add('%s', 100)$$, (select tomate_tas from _t)), '22023', null,
  'quantité au-delà de 99 refusée');

-- Devis : Kodjo 1 500 (le plus gros sous-total : base 500), Esi 2 100 (supplément 200).
create function pg_temp._cart(p_modes jsonb default '{}', p_at timestamptz default null) returns jsonb
language sql as $$ select public.my_cart(null, p_modes, null, coalesce(p_at, (select morning from _t))) $$;
grant execute on function pg_temp._cart(jsonb, timestamptz) to authenticated;

select is(jsonb_array_length(pg_temp._cart() -> 'stores'), 2, 'deux sous-paniers');
select is(pg_temp._cart() -> 'stores' -> 0 ->> 'name', 'Étal de Kodjo', 'ordre d''ajout');
select is((pg_temp._cart() ->> 'subtotal_minor')::int, 3600, 'sous-total 1 500 + 2 100');
select is((pg_temp._cart() -> 'stores' -> 1 ->> 'delivery_fee_minor')::int, 500,
  'la boutique au plus gros sous-total porte la base');
select is((pg_temp._cart() -> 'stores' -> 0 ->> 'delivery_fee_minor')::int, 200, 'l''autre porte le supplément');
select is((pg_temp._cart() ->> 'total_minor')::int, 4300, 'total');
select is((pg_temp._cart() ->> 'pickup_count')::int, 2, 'deux ramassages');
select is((pg_temp._cart() ->> 'remaining_for_free_minor')::int, 400, 'reste pour la livraison offerte');
select is((pg_temp._cart() ->> 'blocking')::boolean, false, 'rien de bloquant');
select is(pg_temp._cart() -> 'payment_methods' -> 0 ->> 'provider_code', 'cash', 'cash proposé');

-- Seuil atteint : livraison offerte.
select lives_ok(format($$select public.cart_set_quantity('%s', 4)$$, (select tomate_tas from _t)), 'quantité modifiée');
select is((pg_temp._cart() ->> 'delivery_fee_minor')::int, 0, 'livraison offerte au seuil (4 100 ≥ 4 000)');

-- Retrait chez Esi : un seul ramassage, base portée par Kodjo, sous le seuil.
select is((pg_temp._cart(jsonb_build_object((select esi_store from _t), 'pickup')) ->> 'delivery_fee_minor')::int,
  500, 'Esi en retrait : un ramassage, base portée par Kodjo, sous le seuil');
select ok(pg_temp._cart(jsonb_build_object((select esi_store from _t), 'pickup')) -> 'stores' -> 1 -> 'issues'
  ? 'pickup_unavailable', 'retrait non proposé signalé');

-- Problèmes : fermeture, rupture, prix modifié.
select ok(pg_temp._cart('{}', (select evening from _t)) -> 'stores' -> 0 -> 'issues' ? 'closed', 'boutique fermée à 20 h');
select tests.login_as((select kodjo from _t));
select public.set_product_available((select tomate from _t), false);
select public.save_product(pg_temp._product((select kodjo_store from _t), (select tomate from _t), 'Tomates fraîches',
  (select tomates from _t), 600, jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t)))));
select tests.login_as((select awa from _t));
select ok(pg_temp._cart() -> 'stores' -> 0 -> 'lines' -> 0 -> 'issues' ? 'unavailable', 'rupture signalée');
select ok(pg_temp._cart() -> 'stores' -> 0 -> 'lines' -> 0 -> 'issues' ? 'price_changed', 'prix modifié signalé');
select is((pg_temp._cart() -> 'stores' -> 0 -> 'lines' -> 0 ->> 'unit_price_minor')::int, 600, 'prix courant utilisé');
select is((pg_temp._cart() ->> 'blocking')::boolean, true, 'la rupture bloque');

-- Une autre cliente ne voit pas ce panier ; les tables ne sont pas lisibles.
select tests.login_as((select ama from _t));
select is(public.my_cart() ->> 'item_count', '0', 'Ama a son propre panier');
select throws_ok('select * from public.cart_items', '42501', null, 'lignes de panier non lisibles');

select * from finish();
