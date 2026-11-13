-- Conversation en contexte (spec 070) : « vu » et commande en cours.

select plan(7);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '58000000-0000-4000-8000-000000000001'::uuid as tomate,
       '58000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '58200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as conv, null::uuid as order1;
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
select tests.logout();
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone)
values ((select address from _t), (select awa from _t), 'home', (select be from _t), 'Derrière la pharmacie', '+00 00 00 00 01');

update _t set conv = (app.start_conversation(awa, kodjo_store) ->> 'id')::uuid;
select app.send_message((select awa from _t), (select conv from _t), 'text', 'Bonjour', null, null, gen_random_uuid());

select is((select props ->> 'kind' from public.events where name = 'chat_message_sent'
           and entity_id = (select id::text from public.messages where conversation_id = (select conv from _t) limit 1)),
  'text', 'message mesuré côté serveur');

select tests.login_as((select awa from _t));
select is(public.conversation((select conv from _t)) -> 'peer_read_at', 'null'::jsonb,
  'pas encore lu par la vendeuse');
select is(public.conversation((select conv from _t)) -> 'active_order', 'null'::jsonb,
  'aucune commande en cours');

select tests.login_as((select kodjo from _t));
select ok(public.conversation((select conv from _t)) ->> 'peer_read_at' is not null,
  'la vendeuse voit quand la cliente a lu');

select tests.login_as((select awa from _t));
select ok(public.conversation((select conv from _t)) ->> 'peer_read_at' is not null,
  'lu par la vendeuse après ouverture');
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select address from _t),
    'payment_method_id', (select id from public.payment_methods where provider_code = 'cash' limit 1),
    'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);

select tests.login_as((select kodjo from _t));
select is(public.conversation((select conv from _t)) -> 'active_order' ->> 'id', (select order1 from _t)::text,
  'commande en cours en tête du fil');
select tests.logout();
select app.transition_order((select kodjo from _t), (select order1 from _t), 'refused', 'pending', 'too_busy');
select tests.login_as((select kodjo from _t));
select is(public.conversation((select conv from _t)) -> 'active_order', 'null'::jsonb,
  'commande refusée : plus de bandeau');

select * from finish();
