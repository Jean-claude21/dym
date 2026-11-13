-- Notifications, suite (spec 080) : photo de la commande, rappel de panier.

select plan(5);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '66000000-0000-4000-8000-000000000001'::uuid as tomate,
       '66000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '66200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as order1;
update _t set kodjo_store = tests.open_store(kodjo, 'Ã‰tal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone)
values ((select address from _t), (select awa from _t), 'home', (select be from _t), 'DerriÃ¨re la pharmacie', '+00 00 00 00 01');
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select address from _t),
    'payment_method_id', (select id from public.payment_methods where provider_code = 'cash'
                          and country_code = (select country_code from public.profiles where user_id = (select awa from _t))),
    'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);

select is(app.order_cover_key((select order1 from _t)),
  'stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg',
  'photo du produit principal de la commande');

-- Panier laissé : Awa remet des tomates au panier, puis l'oublie 4 h.
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();
create temporary table _at as select date_trunc('day', now()) + interval '10 hours' as at;
update public.carts set updated_at = (select at from _at) - interval '4 hours'
where user_id = (select awa from _t);
-- La commande précédente date d'avant le panier.
update public.purchases set created_at = (select at from _at) - interval '6 hours'
where user_id = (select awa from _t);

select is(app.remind_carts((select at from _at)), 1, 'un rappel envoyé');
select is(app.remind_carts((select at from _at) + interval '1 hour'), 0, 'pas deux fois');
select is((select params ->> 'items_summary' from public.notifications
           where user_id = (select awa from _t) and kind = 'cart_reminder'), 'Tomates',
  'texte : le produit du panier');
select is(app.remind_carts(date_trunc('day', now()) + interval '2 days 22 hours'), 0,
  'la nuit ou trop tard : rien');

select * from finish();
