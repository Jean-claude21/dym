-- Tournées, code de remise, consignes de conservation (spec 042).

select plan(16);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('efua@example.com') as efua,
       tests.create_user('kofi@example.com') as kofi,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       '38000000-0000-4000-8000-000000000001'::uuid as tomate,
       '38000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '38000000-0000-4000-8000-000000000003'::uuid as huile,
       '38000000-0000-4000-8000-000000000004'::uuid as huile_v,
       '38200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as efua_store, null::uuid as purchase,
       null::uuid as order_k, null::uuid as order_e, null::text as code;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be'),
              efua_store = tests.open_store(efua, 'Huiles d''Efua', 'be');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._publish(p_id uuid, p_variant uuid, p_store uuid, p_name text, p_category text, p_price bigint)
returns void language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', (select id from public.categories where slug = p_category),
    'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || p_store || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', 50))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, uuid, text, text, bigint) to authenticated;

select tests.login_as((select kodjo from _t));
select pg_temp._publish((select tomate from _t), (select tomate_tas from _t), (select kodjo_store from _t),
  'Tomates', 'tomates', 500);
select tests.login_as((select efua from _t));
select pg_temp._publish((select huile from _t), (select huile_v from _t), (select efua_store from _t),
  'Huile rouge', 'huiles-condiments', 1500);
-- Consigne propre au produit.
select is(public.set_product_storage((select huile from _t), 'ambient') ->> 'storage', 'ambient', 'consigne du produit');
select throws_ok(format($$select public.set_product_storage('%s', 'chaud')$$, (select huile from _t)),
  '22023', 'invalid_storage', 'consigne inconnue');
select tests.login_as((select kodjo from _t));
select throws_ok(format($$select public.set_product_storage('%s', 'cool')$$, (select huile from _t)),
  'P0002', null, 'produit d''une autre boutique');

-- Livreur en ligne à Bè.
select tests.login_as((select kofi from _t));
select public.complete_profile('Kofi', (select be from _t), 'delivery');
select public.become_courier('Kofi', '+228 90 11 22 33', 'moto', array[(select be from _t)]);
select public.set_courier_online(true);

-- Awa commande chez deux boutiques, un seul achat.
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);
select public.cart_add((select huile_v from _t), 1);
select tests.logout();
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone)
values ((select address from _t), (select awa from _t), 'home', (select be from _t), 'Près du marché', '+228 91 00 00 01');
update _t set purchase = (app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select address from _t),
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'delivery', (select efua_store from _t), 'delivery')),
    (select morning from _t)) -> 'purchase' ->> 'id')::uuid;
update _t set order_k = (select id from public.orders where purchase_id = (select purchase from _t) and store_id = (select kodjo_store from _t)),
              order_e = (select id from public.orders where purchase_id = (select purchase from _t) and store_id = (select efua_store from _t));
select app.transition_order((select kodjo from _t), (select order_k from _t), 'accepted', 'pending');
select app.transition_order((select efua from _t), (select order_e from _t), 'accepted', 'pending');

-- Missions : tournée de deux boutiques, consignes affichées.
select tests.login_as((select kofi from _t));
select is((public.available_missions() -> 0 ->> 'run_size')::int, 2, 'tournée de deux boutiques');
select ok((select bool_or(m -> 'storage' ? 'fragile') from jsonb_array_elements(public.available_missions()) m),
  'tomates : fragile (rayon)');
select ok((select bool_or(m -> 'storage' ? 'ambient') from jsonb_array_elements(public.available_missions()) m),
  'huile : ambiante (produit)');
select public.accept_mission((select order_k from _t));
select is(jsonb_array_length(public.my_missions()), 2, 'la tournée entière est prise');
select is(jsonb_array_length(public.available_missions()), 0, 'plus rien à prendre');
select tests.logout();
select is((select count(*)::int from public.order_couriers where courier_id = (select kofi from _t)), 2,
  'deux commandes confiées');
select ok((select bool_and(handover_code ~ '^[0-9]{4}$') from public.orders where purchase_id = (select purchase from _t)),
  'codes de remise tirés');

-- La cliente voit son code ; le livreur doit le saisir.
select tests.login_as((select awa from _t));
update _t set code = public.my_handover_code((select order_k from _t));
select ok((select code is not null from _t), 'code visible par la cliente');
select tests.logout();
select app.transition_order((select kodjo from _t), (select order_k from _t), 'ready', 'accepted');
select tests.login_as((select kofi from _t));
select tests.pickup((select order_k from _t));
select throws_ok(format($$select public.courier_transition('%s', 'delivered', 'out_for_delivery')$$, (select order_k from _t)),
  'P0001', 'code_required', 'livrée sans code refusée');
select is(public.courier_deliver((select order_k from _t), 'xxxx') ->> 'ok', 'false', 'mauvais code');
select is((public.courier_deliver((select order_k from _t), (select code from _t)) -> 'mission' ->> 'status'),
  'delivered', 'bon code : livrée');
select tests.login_as((select awa from _t));
select is(public.my_handover_code((select order_k from _t)), null, 'code retiré après livraison');

-- Cinq erreurs : bloqué.
select tests.logout();
update public.orders set handover_attempts = 5 where id = (select order_e from _t);
select tests.login_as((select kofi from _t));
select throws_ok(format($$select public.courier_deliver('%s', '0000')$$, (select order_e from _t)),
  'P0001', 'code_locked', 'trop d''essais : l''équipe prend le relais');

select * from finish();
