-- Livreurs relancés, alerte « prête », refus automatique (spec 066).

select plan(17);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('kofi@example.com') as kofi,
       tests.create_user('yao@example.com') as yao,
       tests.create_user('admin@example.com') as admin,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.zones where slug = 'tokoin') as tokoin,
       (select id from public.categories where slug = 'tomates') as tomates,
       '55000000-0000-4000-8000-000000000001'::uuid as tomate,
       '55000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '55200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as order1, null::uuid as order2;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));

-- Deux livreurs en ligne de Lomé, dans d'autres quartiers que la boutique et la cliente.
select tests.login_as((select kofi from _t));
select public.complete_profile('Kofi', (select be from _t), 'delivery');
select public.become_courier('Kofi', '+228 90 11 22 33', 'moto', array[(select id from public.zones where slug = 'agoe')]);
select public.set_courier_online(true);
select tests.login_as((select yao from _t));
select public.complete_profile('Yao', (select be from _t), 'delivery');
select public.become_courier('Yao', '+228 92 00 00 00', 'bike', array[(select id from public.zones where slug = 'hedzranawoe')]);
select public.set_courier_online(true);

-- Commande d'Awa (Tokoin) chez Kodjo (Bè).
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select tokoin from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone)
values ((select address from _t), (select awa from _t), 'home', (select tokoin from _t), 'Derrière la pharmacie', '+228 91 00 00 01');
insert into public.store_delivery_zones (store_id, zone_id)
values ((select kodjo_store from _t), (select tokoin from _t)) on conflict do nothing;

create function pg_temp._order() returns uuid language sql as $$
  select (o ->> 'id')::uuid from jsonb_array_elements(
    app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
      'address_id', (select address from _t),
      'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
      'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
      (select morning from _t)) -> 'purchase' -> 'orders') o limit 1
$$;
update _t set order1 = pg_temp._order();

create function pg_temp._missions(p_user uuid) returns int language sql as $$
  select count(*)::int from public.notifications where kind = 'mission_available' and user_id = p_user
$$;

-- Acceptation : aucun livreur des quartiers de la boutique ou de la cliente.
select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');
select is(pg_temp._missions((select kofi from _t)) + pg_temp._missions((select yao from _t)), 0,
  'personne dans les quartiers de la boutique ou de la cliente');
select ok(exists (select 1 from public.order_dispatch where order_id = (select order1 from _t)),
  'alerte enregistrée');

select is(app.run_dispatch_watch(now() + interval '2 minutes') ->> 'relaunched', '0',
  'avant le délai de relance : rien');
select is(app.run_dispatch_watch(now() + interval '6 minutes') ->> 'relaunched', '1',
  'première relance après 5 minutes');
select is(pg_temp._missions((select kofi from _t)), 0, 'première relance : mêmes quartiers');
select is(app.run_dispatch_watch(now() + interval '12 minutes') ->> 'relaunched', '1',
  'deuxième relance');
select is(pg_temp._missions((select kofi from _t)) + pg_temp._missions((select yao from _t)), 2,
  'deuxième relance : toute la ville de la boutique');

select tests.login_as((select kofi from _t));
select is(jsonb_array_length(public.available_missions()), 1, 'course visible après élargissement');
select lives_ok(format($$select public.accept_mission(%L)$$, (select order1 from _t)), 'Kofi prend la course');
select tests.logout();

-- Commande prête : le livreur assigné est prévenu.
select app.transition_order((select kodjo from _t), (select order1 from _t), 'ready', 'accepted');
select is((select count(*)::int from public.notifications where kind = 'order_ready_pickup'
           and user_id = (select kofi from _t)), 1, 'livreur prévenu : commande prête');

-- Commande sans réponse : refus automatique après 20 minutes.
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
update _t set order2 = pg_temp._order();
select is(app.run_dispatch_watch(now() + interval '12 minutes') ->> 'refused', '0', 'avant 20 minutes : rien');
select is(app.run_dispatch_watch(now() + interval '25 minutes') ->> 'refused', '1', 'refus automatique');
select is((select status || '/' || status_reason from public.orders where id = (select order2 from _t)),
  'refused/no_response', 'motif : pas de réponse');
select is((select actor_role from public.order_status_events where order_id = (select order2 from _t)
           and to_status = 'refused'), 'system', 'acteur : système');
select is((select count(*)::int from public.notifications where kind = 'order_auto_refused'
           and user_id = (select kodjo from _t)), 1, 'vendeuse prévenue');

-- Statistiques et réglages de l'équipe.
select tests.login_as((select admin from _t));
select is(public.admin_dispatch('day', now() + interval '30 minutes') - 'couriers_active' - 'couriers_online'
          - 'waiting' - 'median_accept_minutes',
  '{"relaunches": 2, "widened": 1, "auto_refused": 1, "ready_alerts": 1}'::jsonb,
  'tableau de bord : relances, élargissements, refus automatiques, alertes « prête »');
select is(public.admin_set_ops_thresholds('TG', '{"auto_refuse": 30, "relaunch_max": 2}')
          -> 'thresholds' ->> 'auto_refuse', '30', 'délai de refus réglé par pays');

select * from finish();
