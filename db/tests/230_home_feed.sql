-- Fil personnel de l'accueil (spec 027).

select plan(8);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       null::uuid as kodjo_store, null::uuid as order1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 10))));
select public.publish_product((select tomate from _t));

-- Visiteuse : nouveautés, ni commande ni populaires.
select tests.login_anonymous();
select is(public.home_feed((select be from _t)) -> 'last_order', 'null'::jsonb, 'visiteuse : pas de dernière commande');
select is(public.home_feed((select be from _t)) -> 'fresh' -> 0 ->> 'id', (select tomate from _t)::text,
  'nouveautés : produit publié récemment');
select is(jsonb_array_length(public.home_feed((select be from _t)) -> 'popular'), 0, 'aucune commande : aucun populaire');

-- Awa commande 2 tas, livrés.
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'preparing', 'accepted');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'ready', 'preparing');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'delivered', 'ready');

select tests.login_as((select awa from _t));
select is(public.home_feed((select be from _t)) -> 'last_order' ->> 'order_id', (select order1 from _t)::text,
  'Awa : sa dernière commande livrée');
select is((public.home_feed((select be from _t)) -> 'last_order' ->> 'item_count')::int, 2, 'avec ses 2 articles');
select is(public.home_feed((select be from _t)) -> 'popular' -> 0 ->> 'id', (select tomate from _t)::text,
  'populaires : produit commandé');

select tests.login_as((select ama from _t));
select is(public.home_feed((select be from _t)) -> 'last_order', 'null'::jsonb, 'Ama ne voit pas la commande d''Awa');

-- Rupture : retiré du fil.
select tests.logout();
update public.product_variants set stock_quantity = 0 where id = (select tomate_tas from _t);
select is(jsonb_array_length(public.home_feed((select be from _t)) -> 'popular'), 0, 'rupture : retiré des populaires');

select * from finish();
