-- Nouvelle commande chez la vendeuse (spec 075) : heure limite de réponse.

select plan(4);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '63000000-0000-4000-8000-000000000001'::uuid as tomate,
       '63000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '63200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as order1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
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
values ((select address from _t), (select awa from _t), 'home', (select be from _t), 'Derrière la pharmacie', '+00 00 00 00 01');
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select address from _t),
    'payment_method_id', (select id from public.payment_methods where provider_code = 'cash'
                          and country_code = (select country_code from public.profiles where user_id = (select awa from _t))),
    'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);

create temporary table _want as
select o.created_at + make_interval(mins => c.order_auto_refuse_minutes) as respond_by
from public.orders o
join public.purchases pu on pu.id = o.purchase_id
join public.countries c on c.code = pu.country_code
where o.id = (select order1 from _t);
grant select on _want to authenticated;

select tests.login_as((select kodjo from _t));
select is((public.my_store_order((select order1 from _t)) ->> 'respond_by')::timestamptz,
  (select respond_by from _want), 'heure limite = création + délai du pays');
select ok((public.my_store_orders('new') -> 0 ->> 'respond_by') is not null, 'heure limite dans la liste');

select tests.logout();
select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');
select tests.login_as((select kodjo from _t));
select is(public.my_store_order((select order1 from _t)) -> 'respond_by', 'null'::jsonb,
  'acceptée : plus de compte à rebours');
select is(public.my_store_orders('active') -> 0 -> 'respond_by', 'null'::jsonb,
  'liste : plus de compte à rebours');

select * from finish();
