-- Événements en direct (spec 067) : destinataires, lecture par personne,
-- aucun accès par la Data API, ménage.

select plan(10);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('mallory@example.com') as mallory,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '56000000-0000-4000-8000-000000000001'::uuid as tomate,
       '56000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '56200000-0000-4000-8000-000000000001'::uuid as address,
       '56300000-0000-4000-8000-000000000001'::uuid as conv,
       null::uuid as kodjo_store, null::uuid as order1, 0::bigint as start;
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
update _t set start = app.live_last_id();

-- Message : la cliente et la vendeuse reçoivent l'événement.
insert into public.conversations (id, store_id, client_id)
values ((select conv from _t), (select kodjo_store from _t), (select awa from _t));
insert into public.messages (conversation_id, author_id, author_role, kind, body, idempotency_key)
values ((select conv from _t), (select awa from _t), 'client', 'text', 'Bonjour', gen_random_uuid());
select is((select count(*)::int from public.live_events where kind = 'message' and id > (select start from _t)
           and user_id in ((select awa from _t), (select kodjo from _t))), 2,
  'message : cliente et vendeuse prévenues');
select is((select count(*)::int from public.live_events where user_id = (select mallory from _t)), 0,
  'personne d''autre');

-- Commande : nouvelle commande (notification) puis statut.
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone)
values ((select address from _t), (select awa from _t), 'home', (select be from _t), 'Derrière la pharmacie', '+228 91 00 00 01');
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select address from _t),
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
select ok(exists (select 1 from public.live_events where user_id = (select kodjo from _t) and kind = 'notification'
                  and payload ->> 'kind' = 'new_order'),
  'vendeuse : nouvelle commande en direct');

select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');
select is((select count(*)::int from public.live_events where kind = 'order_status' and entity_id = (select order1 from _t)
           and payload ->> 'status' = 'accepted'), 2,
  'statut : cliente et vendeuse (pas encore de livreur)');

-- Lecture par la passerelle : seulement les personnes connectées, après le curseur.
select is((select count(*)::int from app.live_events_since(array[(select awa from _t)], (select start from _t))),
          (select count(*)::int from public.live_events where user_id = (select awa from _t) and id > (select start from _t)),
  'lecture limitée à la personne');
select is((select count(*)::int from app.live_events_since(array[(select mallory from _t)], 0)), 0,
  'rien pour une autre personne');
select is((select count(*)::int from app.live_events_since(array[(select awa from _t)], app.live_last_id())), 0,
  'rien après le dernier curseur');

-- Aucun accès par la Data API.
select tests.login_as((select awa from _t));
select throws_ok('select * from public.live_events', '42501', null, 'table non exposée');
select tests.logout();

-- Ménage après 24 h.
update public.live_events set created_at = now() - interval '2 days' where user_id = (select awa from _t);
select ok(app.prune_live_events() >= 1, 'événements de plus de 24 h supprimés');
select is((select count(*)::int from public.live_events where user_id = (select awa from _t)), 0, 'plus rien d''ancien');

select * from finish();
