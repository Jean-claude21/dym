-- App livreur : inscription, missions, acceptation (spec 041).

select plan(23);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('kofi@example.com') as kofi,
       tests.create_user('yao@example.com') as yao,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.zones where slug = 'tokoin') as tokoin,
       (select id from public.categories where slug = 'tomates') as tomates,
       '37000000-0000-4000-8000-000000000001'::uuid as tomate,
       '37000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '37200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as order1, null::uuid as order2;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));

-- Inscription : profil requis, zones du pays, rôle livreur.
select tests.login_as((select kofi from _t));
select throws_ok($$select public.become_courier('Kofi', '+228 90 11 22 33', 'moto', array[(select be from _t)])$$,
  '22023', 'profile_required', 'profil DYM requis');
select public.complete_profile('Kofi', (select be from _t), 'delivery');
select ok(not ((public.me() -> 'roles') ? 'courier'), 'pas encore livreur');
select throws_ok($$select public.become_courier('Kofi', '123', 'moto', array[(select be from _t)])$$,
  '22023', 'invalid_phone', 'téléphone invalide');
select throws_ok($$select public.become_courier('Kofi', '+228 90 11 22 33', 'avion', array[(select be from _t)])$$,
  '22023', 'invalid_vehicle', 'moyen inconnu');
select throws_ok($$select public.become_courier('Kofi', '+228 90 11 22 33', 'moto', array[]::uuid[])$$,
  '22023', 'invalid_zones', 'au moins une zone');
select is(public.become_courier('Kofi', '+228 90 11 22 33', 'moto', array[(select be from _t)]) ->> 'vehicle',
  'moto', 'livreur inscrit');
select ok((public.me() -> 'roles') ? 'courier', 'rôle livreur');
select is(public.my_courier_profile() ->> 'is_online', 'false', 'hors ligne au départ');
select is(jsonb_array_length(public.available_missions()), 0, 'hors ligne : aucune mission');
select is(public.set_courier_online(true) ->> 'is_online', 'true', 'en ligne');

-- Commande à livrer d'Awa (Tokoin) chez Kodjo (Bè).
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select tokoin from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone)
values ((select address from _t), (select awa from _t), 'home', (select tokoin from _t), 'Derrière la pharmacie', '+228 91 00 00 01');
insert into public.store_delivery_zones (store_id, zone_id)
values ((select kodjo_store from _t), (select tokoin from _t)) on conflict do nothing;
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select address from _t),
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);

select tests.login_as((select kofi from _t));
select is(jsonb_array_length(public.available_missions()), 0, 'commande pas encore acceptée par la boutique');
select tests.logout();
select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');
select is((select count(*)::int from public.notifications where kind = 'mission_available'
           and user_id = (select kofi from _t)), 1, 'livreur en ligne prévenu');

select tests.login_as((select kofi from _t));
select is(jsonb_array_length(public.available_missions()), 1, 'mission proposée (boutique dans sa zone)');
select is(public.available_missions() -> 0 -> 'customer' ->> 'phone', null, 'téléphone caché avant acceptation');

-- Un autre livreur hors zone ne la voit pas.
select tests.login_as((select yao from _t));
select public.complete_profile('Yao', (select be from _t), 'delivery');
select public.become_courier('Yao', '+228 92 00 00 00', 'bike', array[(select id from public.zones where slug = 'agoe')]);
select public.set_courier_online(true);
select is(jsonb_array_length(public.available_missions()), 0, 'hors zone : rien');

-- Acceptation : coordonnées révélées, une seule fois.
select tests.login_as((select kofi from _t));
select is(public.accept_mission((select order1 from _t)) -> 'customer' ->> 'phone', '+228 91 00 00 01',
  'coordonnées de la cliente après acceptation');
select throws_ok(format($$select public.accept_mission('%s')$$, (select order1 from _t)), 'P0001', 'mission_taken',
  'déjà prise');
select is(jsonb_array_length(public.my_missions()), 1, 'dans mes courses');

-- Gestes : récupérer seulement une commande prête, puis livrer.
select throws_ok(format($$select public.courier_transition('%s', 'out_for_delivery', 'accepted')$$, (select order1 from _t)),
  'P0001', 'transition_not_allowed', 'pas encore prête');
select tests.logout();
select app.transition_order((select kodjo from _t), (select order1 from _t), 'ready', 'accepted');
alter table _t add column code text;
update _t set code = (select handover_code from public.orders where id = (select order1 from _t));
select tests.login_as((select kofi from _t));
select is(public.courier_transition((select order1 from _t), 'out_for_delivery', 'ready') ->> 'status',
  'out_for_delivery', 'récupérée');
select throws_ok(format($$select public.release_mission('%s')$$, (select order1 from _t)), 'P0002', null,
  'plus de retour après retrait');
-- Remise par le code de la cliente (spec 042).
select is(public.courier_deliver((select order1 from _t),
  (select code from _t)) -> 'mission' ->> 'status',
  'delivered', 'livrée par le livreur');
select tests.logout();
select is((select actor_role from public.order_status_events where order_id = (select order1 from _t)
           and to_status = 'delivered'), 'courier', 'trace : livreur');

select * from finish();
