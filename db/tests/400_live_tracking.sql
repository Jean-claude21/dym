-- Suivi en direct, score, bonus, zones (spec 044).

select plan(17);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('kofi@example.com') as kofi,
       tests.create_user('ama@example.com') as ama,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       '40000000-0000-4000-8000-000000000001'::uuid as tomate,
       '40000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '40200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as order1, null::uuid as order2, null::text as code;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select id from public.categories where slug = 'tomates'),
  'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));

select tests.login_as((select kofi from _t));
select public.complete_profile('Kofi', (select be from _t), 'delivery');
select public.become_courier('Kofi', '+228 90 11 22 33', 'moto', array[(select be from _t)]);
select throws_ok($$select public.report_position(6.13, 1.22)$$, 'P0001', 'not_online', 'hors ligne : position refusée');
select public.set_courier_online(true);

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);
select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone, latitude, longitude)
values ((select address from _t), (select awa from _t), 'home', (select be from _t), 'Près du marché',
        '+228 91 00 00 01', 6.130000, 1.220000);
update public.countries set courier_bonus_threshold = 2, courier_bonus_minor = 300 where code = 'TG';

update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select address from _t),
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
-- Seconde commande de la zone : profil seul, sans adresse enregistrée à reprendre.
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone)
values ('40200000-0000-4000-8000-000000000002', (select ama from _t), 'home', (select be from _t), 'Face école', '+228 91 00 00 02');
update _t set order2 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select ama from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', '40200000-0000-4000-8000-000000000002',
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');
select app.transition_order((select kodjo from _t), (select order2 from _t), 'accepted', 'pending');

-- Zone en forte demande : deux commandes attendent.
select tests.login_as((select kofi from _t));
select is(public.zone_demand() -> 0 ->> 'high', 'true', 'zone en forte demande');
select is((public.zone_demand() -> 0 ->> 'bonus_minor')::bigint, 300::bigint, 'bonus annoncé');
select public.accept_mission((select order1 from _t));
select tests.logout();
select is((select bonus_minor from public.order_couriers where order_id = (select order1 from _t)), 300::bigint,
  'bonus fixé à l''acceptation');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'ready', 'accepted');
update _t set code = (select handover_code from public.orders where id = (select order1 from _t));

-- Pas de suivi avant le départ.
select tests.login_as((select awa from _t));
select is(public.order_live((select order1 from _t)), null, 'pas de suivi avant le retrait');

select tests.login_as((select kofi from _t));
select public.courier_transition((select order1 from _t), 'out_for_delivery', 'ready');
select public.report_position(6.139000, 1.220000);
select throws_ok($$select public.report_position(95, 1.22)$$, '22023', 'invalid_position', 'position invalide');

-- La cliente voit la distance (≈ 1 km) et l'heure d'arrivée ; une autre personne, rien.
select tests.login_as((select awa from _t));
select ok((public.order_live((select order1 from _t)) ->> 'distance_m')::int between 950 and 1050, 'distance calculée');
select ok((public.order_live((select order1 from _t)) ->> 'eta_at')::timestamptz > now(), 'heure d''arrivée');
select is(public.order_live((select order1 from _t)) ->> 'simulated', 'false', 'position réelle');
select tests.login_as((select ama from _t));
select is(public.order_live((select order1 from _t)), null, 'suivi réservé à la cliente');

-- Livrée : bonus au wallet ; note unique, score du livreur.
select tests.login_as((select kofi from _t));
select public.courier_deliver((select order1 from _t), (select code from _t));
select is((public.my_wallet() ->> 'balance_minor')::bigint, 300::bigint, 'bonus sur le wallet');
select tests.login_as((select awa from _t));
select throws_ok(format($$select public.rate_courier('%s', 6)$$, (select order1 from _t)), '22023', 'invalid_rating', 'note invalide');
select is(public.order_courier_rating((select order1 from _t)) ->> 'courier_name', 'Kofi', 'livreur à noter');
select is((public.rate_courier((select order1 from _t), 4) ->> 'rating')::int, 4, 'remise notée');
select is((public.order_courier_rating((select order1 from _t)) ->> 'rating')::int, 4, 'note relue');
select throws_ok(format($$select public.rate_courier('%s', 5)$$, (select order1 from _t)), 'P0002', null, 'une seule note');
select tests.login_as((select kofi from _t));
select is((public.my_courier_profile() ->> 'score')::numeric, 4.0, 'score du livreur');
select tests.logout();

select * from finish();
