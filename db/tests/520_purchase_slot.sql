-- La confirmation rappelle le créneau (spec 056) : `purchase_json` expose le début et la fin du
-- créneau de chaque commande ; nuls pour « dès que possible ».

select plan(3);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '52000000-0000-4000-8000-000000000001'::uuid as tomate,
       '52000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       null::uuid as kodjo_store,
       (now() at time zone 'Africa/Lome')::date + 1 as tomorrow,
       (select id from public.delivery_windows where country_code = 'TG' and starts_at = '14:00') as afternoon;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select public.set_store_hours((select jsonb_agg(jsonb_build_object('weekday', d, 'opens_at', '06:00',
  'closes_at', '22:00')) from generate_series(1, 7) d));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 20))));
select public.publish_product((select tomate from _t));
select tests.logout();

create function pg_temp._order(p_slot jsonb) returns jsonb language sql as $$
  select app.place_order_scheduled((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup'), 'slot', p_slot),
    (((select tomorrow from _t) - 1) + time '10:00') at time zone 'Africa/Lome', '{}')
$$;

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();

create temporary table _o as select pg_temp._order(jsonb_build_object('date', (select tomorrow from _t),
  'window_id', (select afternoon from _t))) -> 'purchase' -> 'orders' -> 0 as o;
select is((select (o ->> 'scheduled_start')::timestamptz from _o),
  ((select tomorrow from _t) + time '14:00') at time zone 'Africa/Lome', 'confirmation : début du créneau');
select ok((select (o ->> 'scheduled_end')::timestamptz > (o ->> 'scheduled_start')::timestamptz from _o),
  'confirmation : fin du créneau');

select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
create temporary table _asap as select pg_temp._order(null) -> 'purchase' -> 'orders' -> 0 as o;
select ok((select o ? 'scheduled_start' and o -> 'scheduled_start' = 'null'::jsonb from _asap),
  'dès que possible : pas de créneau');

select * from finish();
