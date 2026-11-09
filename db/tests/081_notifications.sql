-- Notifications (spec 011) : nouvelle commande pour la vendeuse, étapes et
-- paiement pour la cliente, centre, préférences, file de push sans doublon.

select plan(24);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       'a0000000-0000-4000-8000-000000000001'::uuid as home,
       null::uuid as kodjo_store, null::uuid as o1, null::jsonb as p2;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t)))));
select public.publish_product((select tomate from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.save_address(jsonb_build_object('id', (select home from _t), 'kind', 'home', 'zone_id', (select be from _t),
  'landmark', 'Portail bleu', 'phone', '+228 90 00 00 00'));
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();

-- Commande cash : la vendeuse est prévenue tout de suite.
select app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
  'address_id', (select home from _t),
  'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash')),
  (select morning from _t));
update _t set o1 = (select id from public.orders where store_id = (select kodjo_store from _t));
select is((select kind from public.notifications where user_id = (select kodjo from _t)), 'new_order',
  'nouvelle commande pour la vendeuse');
select is((select params ->> 'customer_first_name' from public.notifications where user_id = (select kodjo from _t)),
  'Awa', 'avec le prénom de la cliente');
select is(app.notification_app('new_order'), 'vendor', 'destinée à l''app vendeuse');

-- Étapes : la cliente est prévenue.
select app.transition_order((select kodjo from _t), (select o1 from _t), 'accepted', 'pending');
select app.transition_order((select kodjo from _t), (select o1 from _t), 'preparing', 'accepted');
select is(array(select kind from public.notifications where user_id = (select awa from _t) order by created_at),
  array['order_accepted', 'order_preparing'], 'acceptée, en préparation');
select ok((select params ->> 'eta_at' from public.notifications where user_id = (select awa from _t) and kind = 'order_accepted') is not null,
  'acceptée : avec l''heure estimée');
select is((select params ->> 'store_name' from public.notifications where user_id = (select awa from _t) and kind = 'order_preparing'), 'Étal de Kodjo',
  'avec le nom de la boutique');

-- Paiement en ligne : la vendeuse ne voit la commande qu'une fois payée.
insert into public.payment_methods (country_code, provider_code, label, sort, is_active)
values ('TG', 'simulator', '{"fr": "Simulé"}', 9, true)
on conflict do nothing;
update public.payment_methods set is_active = true where provider_code = 'simulator' and country_code = 'TG';
insert into public.store_payment_methods (store_id, payment_method_id)
select (select kodjo_store from _t), id from public.payment_methods where provider_code = 'simulator' and country_code = 'TG' and operator_code is null;
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
update _t set p2 = app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
  'address_id', (select home from _t),
  'payment_method_id', (select id from public.payment_methods where provider_code = 'simulator' and country_code = 'TG' and operator_code is null)),
  (select morning from _t), '{simulator}');
select is((select count(*)::int from public.notifications where user_id = (select kodjo from _t)), 1,
  'en attente de paiement : rien pour la vendeuse');
select app.apply_payment_event('simulator', 'evt-1', '{}', true,
  (select (p2 -> 'purchase' -> 'payment' ->> 'id')::uuid from _t), 'succeeded',
  (select (p2 -> 'purchase' -> 'payment' ->> 'amount_minor')::bigint from _t), 'XOF');
select is((select count(*)::int from public.notifications where user_id = (select kodjo from _t) and kind = 'new_order'), 2,
  'payée : nouvelle commande pour la vendeuse');
select is((select category from public.notifications where user_id = (select awa from _t) and kind = 'payment_succeeded'),
  'payments', 'paiement confirmé pour la cliente');

-- Centre de notifications.
select tests.login_as((select awa from _t));
select is(public.unread_notifications_count(), 3, '3 non lues');
select is(public.my_notifications() -> 0 ->> 'kind', 'payment_succeeded', 'la plus récente en tête');
select is(public.mark_notifications_read(array[(select id from public.notifications where user_id = (select awa from _t) and kind = 'order_accepted')]), 2,
  'une lue : 2 restantes');
select is(public.mark_notifications_read(), 0, 'tout lire');
select tests.login_as((select ama from _t));
select is(jsonb_array_length(public.my_notifications()), 0, 'Ama ne voit rien');
select is((select count(*)::int from public.notifications), 0, 'table filtrée par la RLS');

-- Préférences et téléphones.
select tests.login_as((select awa from _t));
select is(public.my_notification_preferences() -> 3, '{"category": "promotions", "push_enabled": false}',
  'bons plans coupés par défaut');
select is(public.set_notification_preference('orders', false) -> 0 ->> 'push_enabled', 'false', 'suivi coupé');
select lives_ok($$select public.register_push_token('jeton-de-test-awa-0001', 'android', 'client')$$, 'téléphone enregistré');
select tests.login_as((select kodjo from _t));
select public.register_push_token('jeton-de-test-kodjo-001', 'android', 'vendor');
select tests.logout();

-- File de push : réservée une fois, autorisation et jetons de la bonne app.
create temporary table _c as select app.claim_pushes(100) as rows;
select is((select count(*)::int from _c, jsonb_array_elements(rows)), 5, 'toutes les notifications réservées (2 vendeuse, 3 cliente)');
select is((select jsonb_agg(distinct r -> 'allowed') from _c, jsonb_array_elements(rows) r where r ->> 'kind' like 'order_%'),
  '[false]', 'suivi coupé : push non autorisé');
select is((select r -> 'tokens' from _c, jsonb_array_elements(rows) r where r ->> 'kind' = 'new_order' limit 1),
  '["jeton-de-test-kodjo-001"]', 'nouvelle commande : jeton de l''app vendeuse');
select is(jsonb_array_length(app.claim_pushes(100)), 0, 'jamais réservées deux fois');
select is((select r -> 'text' ->> 'title' from _c, jsonb_array_elements(rows) r where r ->> 'kind' = 'order_preparing'),
  'En préparation', 'texte du push : modèle de la langue');
select is((select r -> 'text' ->> 'body' from _c, jsonb_array_elements(rows) r where r ->> 'kind' = 'order_preparing'),
  'Étal de Kodjo prépare ta commande.', 'variables remplacées');

select * from finish();
