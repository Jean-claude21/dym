-- Commande (spec 009, US3 et US4) : un achat, une commande par boutique,
-- montants du devis, idempotence, refus, lecture limitée.

select plan(30);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('esi@example.com') as esi,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       '2026-10-05 20:00:00+00'::timestamptz as evening,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'boissons') as boissons,
       (select id from public.categories where slug = 'tomates') as tomates,
       (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash') as cash,
       (select id from public.payment_methods where country_code = 'TG' and operator_code = 'tmoney') as tmoney,
       '11111111-1111-4111-8111-111111111111'::uuid as bissap,
       'b1000000-0000-4000-8000-000000000001'::uuid as bissap_1l,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       'a0000000-0000-4000-8000-000000000001'::uuid as home,
       'd0000000-0000-4000-8000-000000000001'::uuid as key1,
       'd0000000-0000-4000-8000-000000000002'::uuid as key2,
       null::uuid as esi_store, null::uuid as kodjo_store, null::jsonb as result;
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

select tests.login_as((select esi from _t));
select public.set_store_delivery_zones(array[(select id from public.zones where slug = 'tokoin'), (select be from _t)]);
select public.update_store('{"offers_pickup": true}');
select public.save_product(pg_temp._product((select esi_store from _t), (select bissap from _t), 'Jus de bissap',
  (select boissons from _t), 700, jsonb_build_array(jsonb_build_object('id', (select bissap_1l from _t),
  'label', '1 L', 'stock_quantity', 5))));
select public.publish_product((select bissap from _t));
select tests.login_as((select kodjo from _t));
select public.save_product(pg_temp._product((select kodjo_store from _t), (select tomate from _t), 'Tomates fraîches',
  (select tomates from _t), 500, jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t)))));
select public.publish_product((select tomate from _t));

-- Panier d'Awa : 3 tas (1 500) chez Kodjo, 2 bissap (1 400) chez Esi.
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 3);
select public.cart_add((select bissap_1l from _t), 2);
select tests.logout();

-- La Function appelle app.place_order avec l'utilisatrice du jeton.
create function pg_temp._place(p_key uuid, p_request jsonb, p_at timestamptz default null) returns jsonb
language sql as $$
  select app.place_order((select awa from _t), p_key, p_request, coalesce(p_at, (select morning from _t)))
$$;
create function pg_temp._request(p_extra jsonb default '{}') returns jsonb language sql as $$
  select jsonb_build_object('address_id', (select home from _t), 'payment_method_id', (select cash from _t),
    'substitution_allowed', false) || p_extra
$$;

select throws_ok($$select pg_temp._place((select key1 from _t), pg_temp._request())$$,
  'P0001', 'address_required', 'adresse obligatoire pour une livraison');

select tests.login_as((select awa from _t));
select public.save_address(jsonb_build_object('id', (select home from _t), 'kind', 'home', 'zone_id', (select be from _t),
  'landmark', 'Portail bleu après la pharmacie', 'phone', '+228 90 00 00 00'));
select tests.logout();

select throws_ok($$select pg_temp._place((select key1 from _t), pg_temp._request('{"payment_method_id": null}'))$$,
  'P0001', 'payment_not_accepted', 'moyen de paiement obligatoire');
select throws_ok($$select pg_temp._place((select key1 from _t), pg_temp._request(), (select evening from _t))$$,
  'P0001', 'cart_blocked', 'boutiques fermées : refus');
select throws_ok($$select pg_temp._place((select key1 from _t), pg_temp._request('{"expected_total_minor": 100}'))$$,
  'P0001', 'total_changed', 'total différent de celui affiché : refus');

-- Mobile Money actif et accepté, mais pas encore construit.
update public.payment_methods set is_active = true where id = (select tmoney from _t);
insert into public.store_payment_methods (store_id, payment_method_id)
select s, (select tmoney from _t) from unnest(array[(select esi_store from _t), (select kodjo_store from _t)]) s;
select throws_ok(format($$select pg_temp._place((select key1 from _t), pg_temp._request('{"payment_method_id": "%s"}'))$$,
  (select tmoney from _t)), 'P0001', 'payment_unavailable', 'Mobile Money pas encore disponible');
select is((select count(*)::int from public.purchases), 0, 'aucun achat après les refus');

-- Commande : sous-total 2 900, frais 500 (Kodjo, base) + 200 (Esi), total 3 600.
update _t set result = pg_temp._place((select key1 from _t), pg_temp._request('{"expected_total_minor": 3600}'));
select is((select result ->> 'replayed' from _t), 'false', 'achat créé');
select is((select count(*)::int from public.purchases), 1, 'un achat');
select is((select count(*)::int from public.orders), 2, 'une commande par boutique');
select is((select result -> 'purchase' ->> 'total_minor' from _t)::int, 3600, 'total du devis');
select is((select delivery_fee_minor::int from public.orders where store_id = (select kodjo_store from _t)), 500,
  'Kodjo porte la base');
select is((select total_minor::int from public.orders where store_id = (select esi_store from _t)), 1600,
  'Esi : 1 400 + 200');
select is((select status from public.orders limit 1), 'pending', 'en attente d''acceptation');
select is((select product_name || ' ' || variant_label from public.order_items
           where variant_id = (select bissap_1l from _t)), 'Jus de bissap 1 L', 'ligne figée');
select is((select stock_quantity from public.product_variants where id = (select bissap_1l from _t)), 3,
  'stock suivi décrémenté');
select is((select count(*)::int from public.cart_items), 0, 'panier vidé');
select is((select address ->> 'landmark' from public.purchases), 'Portail bleu après la pharmacie', 'adresse copiée');
select is((select substitution_allowed from public.purchases), false, 'préférence de remplacement');
select is((select (props ->> 'stores_count')::int from public.events where name = 'order_created'
           and actor_id = (select awa from _t)), 2, 'order_created avec stores_count');
select ok((select commission_minor >= 0 from public.orders limit 1), 'commission figée');

-- Rejeu : même clé, même achat.
select is(pg_temp._place((select key1 from _t), pg_temp._request()) ->> 'replayed', 'true', 'rejeu reconnu');
select is((select count(*)::int from public.purchases), 1, 'toujours un seul achat');
select is(pg_temp._place((select key1 from _t), pg_temp._request()) -> 'purchase' ->> 'id',
  (select result -> 'purchase' ->> 'id' from _t), 'même achat rendu');
select throws_ok($$select pg_temp._place((select key2 from _t), pg_temp._request())$$,
  'P0001', 'cart_empty', 'nouvelle clé, panier vide : refus');

-- Retrait chez Esi : aucun frais pour cette commande.
select tests.login_as((select awa from _t));
select public.cart_add((select bissap_1l from _t), 1);
select tests.logout();
select is(pg_temp._place((select key2 from _t), pg_temp._request(jsonb_build_object('modes',
  jsonb_build_object((select esi_store from _t), 'pickup')))) -> 'purchase' ->> 'delivery_fee_minor', '0',
  'retrait : aucun frais de livraison');

-- Lecture : la cliente, la vendeuse de la boutique seulement.
select tests.login_as((select awa from _t));
select is(public.my_purchase((select (result -> 'purchase' ->> 'id')::uuid from _t)) ->> 'total_minor', '3600',
  'Awa lit son achat');
select throws_ok('select commission_minor from public.orders', '42501', null, 'commission non servie');
select tests.login_as((select kodjo from _t));
select is((select count(*)::int from public.orders), 1, 'Kodjo voit seulement la commande de sa boutique');
select is((select count(*)::int from public.purchases), 0, 'Kodjo ne lit pas l''achat');
select tests.login_as((select ama from _t));
select throws_ok(format($$select public.my_purchase('%s')$$, (select result -> 'purchase' ->> 'id' from _t)),
  'P0002', null, 'Ama ne lit pas l''achat d''Awa');

select * from finish();
