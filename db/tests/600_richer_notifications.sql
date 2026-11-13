-- Notifications plus utiles (spec 072) : montant et articles, nuit calme.

select plan(12);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '60000000-0000-4000-8000-000000000001'::uuid as tomate,
       '60000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '60000000-0000-4000-8000-000000000003'::uuid as piment,
       '60000000-0000-4000-8000-000000000004'::uuid as piment_tas,
       '60200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as order1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

-- Montants.
select is(app.format_money(3500, 'XOF'), '3' || U&'\202F' || '500' || U&'\00A0' || 'F CFA',
  'franc CFA : groupes de trois, symbole après');
select is(app.format_money(350050, 'GHS'), 'GH₵3,500.50', 'cedi : symbole avant, deux décimales');
select is(app.format_money(500, 'XOF'), '500' || U&'\00A0' || 'F CFA', 'petit montant');

-- Commande de deux articles.
select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));
select public.save_product(jsonb_build_object(
  'id', (select piment from _t), 'name', 'Piment', 'category_id', (select tomates from _t), 'price_minor', 200,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select piment from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select piment_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select piment from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);
select public.cart_add((select piment_tas from _t), 1);
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

select is((select app.notification_params(user_id, order_id, params) ->> 'items_summary' from public.notifications
           where user_id = (select kodjo from _t) and kind = 'new_order'),
  'Tomates et 1 autre article', 'résumé : article principal et le reste');
select ok((select app.notification_params(user_id, order_id, params) ->> 'total' from public.notifications
           where user_id = (select kodjo from _t) and kind = 'new_order') like '%F CFA',
  'total lisible');
select is((select app.render_notification('new_order', 'fr', app.notification_params(user_id, order_id, params)) ->> 'body'
           from public.notifications
           where user_id = (select kodjo from _t) and kind = 'new_order'),
  'Awa : Tomates et 1 autre article. Réponds vite.', 'texte de la vendeuse complet');
select ok((select app.render_notification('new_order', 'fr', app.notification_params(user_id, order_id, params)) ->> 'title'
           from public.notifications
           where user_id = (select kodjo from _t) and kind = 'new_order') not like '%{%',
  'aucun paramètre oublié dans le titre');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');
select ok((select app.render_notification(kind, 'fr', app.notification_params(user_id, order_id, params)) ->> 'body'
           from public.notifications
           where user_id = (select awa from _t) and kind = 'order_accepted') like 'Étal de Kodjo a accepté ta commande de %F CFA.',
  'la cliente voit le montant accepté');

-- Nuit calme.
select tests.login_as((select awa from _t));
select is(jsonb_array_length(public.my_notification_preferences())::int, 5, 'cinq réglages'::text);
select public.set_notification_preference('quiet_night', true);
select tests.logout();
select ok(app.quiet_blocks((select awa from _t), 'messages', '2026-10-05 23:30:00+00'),
  'la nuit : messages retenus');
select ok(not app.quiet_blocks((select awa from _t), 'orders', '2026-10-05 23:30:00+00'),
  'la nuit : commandes toujours envoyées');
select ok(not app.quiet_blocks((select awa from _t), 'messages', '2026-10-05 12:00:00+00'),
  'le jour : messages envoyés');

select * from finish();
