-- Paiements (spec 010) : moyen en ligne disponible ou non, confirmations
-- signées et idempotentes, montant contrôlé, échec puis réessai ou cash,
-- visibilité des commandes pour la vendeuse.

select plan(41);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('esi@example.com') as esi,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'boissons') as boissons,
       (select id from public.categories where slug = 'tomates') as tomates,
       '11111111-1111-4111-8111-111111111111'::uuid as bissap,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'b1000000-0000-4000-8000-000000000001'::uuid as bissap_1l,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       'a0000000-0000-4000-8000-000000000001'::uuid as home,
       'd0000000-0000-4000-8000-000000000001'::uuid as key1,
       'd0000000-0000-4000-8000-000000000002'::uuid as key2,
       'd0000000-0000-4000-8000-000000000003'::uuid as key3,
       'd0000000-0000-4000-8000-000000000004'::uuid as key4,
       null::uuid as sim, null::uuid as cash,
       null::uuid as esi_store, null::uuid as kodjo_store,
       null::jsonb as p1, null::jsonb as p2, null::uuid as pay2b, null::uuid as kodjo_order;
update _t set esi_store = tests.open_store(esi, 'Les jus d''Esi', 'tokoin'),
              kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select on _t to authenticated, anonymous;

-- Moyen simulé activé pour le pays de test et accepté par les deux boutiques.
insert into public.payment_methods (country_code, provider_code, label, sort, is_active)
values ('TG', 'simulator', '{"fr": "Mobile Money (simulé)"}', 9, true)
on conflict do nothing;
update public.payment_methods set is_active = true where provider_code = 'simulator' and country_code = 'TG';
update _t set sim = (select id from public.payment_methods where provider_code = 'simulator' and country_code = 'TG'),
              cash = (select id from public.payment_methods where provider_code = 'cash' and country_code = 'TG');
insert into public.store_payment_methods (store_id, payment_method_id)
select s, (select sim from _t) from unnest(array[(select esi_store from _t), (select kodjo_store from _t)]) s;

create function pg_temp._product(p_store uuid, p_id uuid, p_variant uuid, p_category uuid, p_price bigint)
returns jsonb language sql as $$
  select jsonb_build_object(
    'id', p_id, 'name', 'Produit', 'category_id', p_category, 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || p_store || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant)))
$$;
grant execute on function pg_temp._product(uuid, uuid, uuid, uuid, bigint) to authenticated;

select tests.login_as((select esi from _t));
select public.set_store_delivery_zones(array[(select id from public.zones where slug = 'tokoin'), (select be from _t)]);
select public.save_product(pg_temp._product((select esi_store from _t), (select bissap from _t), (select bissap_1l from _t),
  (select boissons from _t), 700));
select public.publish_product((select bissap from _t));
select tests.login_as((select kodjo from _t));
select public.save_product(pg_temp._product((select kodjo_store from _t), (select tomate from _t), (select tomate_tas from _t),
  (select tomates from _t), 500));
select public.publish_product((select tomate from _t));

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.save_address(jsonb_build_object('id', (select home from _t), 'kind', 'home', 'zone_id', (select be from _t),
  'landmark', 'Portail bleu', 'phone', '+228 90 00 00 00'));
select public.cart_add((select tomate_tas from _t), 3);
select public.cart_add((select bissap_1l from _t), 2);
select tests.logout();

create function pg_temp._place(p_key uuid, p_providers text[]) returns jsonb language sql as $$
  select app.place_order((select awa from _t), p_key,
    jsonb_build_object('address_id', (select home from _t), 'payment_method_id', (select sim from _t)),
    (select morning from _t), p_providers)
$$;
create function pg_temp._payment(p_purchase jsonb) returns uuid language sql as $$
  select (p_purchase -> 'purchase' -> 'payment' ->> 'id')::uuid
$$;

-- Fournisseur absent du déploiement (production) : refus, rien de créé.
select throws_ok($$select pg_temp._place((select key1 from _t), '{}')$$, 'P0001', 'payment_unavailable',
  'simulateur indisponible : refus');
select is((select count(*)::int from public.purchases), 0, 'aucun achat');

-- Commande en ligne : en attente de paiement, invisible des vendeuses.
update _t set p1 = pg_temp._place((select key1 from _t), '{simulator}');
update _t set kodjo_order = (select id from public.orders where store_id = (select kodjo_store from _t));
select is((select p1 -> 'purchase' ->> 'payment_status' from _t), 'awaiting_payment', 'en attente de paiement');
select is((select p1 -> 'purchase' -> 'payment' ->> 'status' from _t), 'pending', 'tentative en attente');
select is((select (p1 -> 'purchase' -> 'payment' ->> 'amount_minor')::int from _t), 3600, 'montant = total (2 900 + 700)');
select matches((select p1 -> 'purchase' -> 'payment' ->> 'reference' from _t), '^PA-[0-9A-F]{6}$', 'référence courte');

select tests.login_as((select kodjo from _t));
select is((select count(*)::int from public.orders), 0, 'Kodjo ne voit pas la commande non payée');
select is(jsonb_array_length(public.my_store_orders()), 0, 'liste vendeuse vide');
select throws_ok(format($$select public.my_store_order('%s')$$,
  (select kodjo_order from _t)), 'P0002', null, 'détail refusé avant paiement');
select tests.logout();

-- Initiation par la Function.
select is(app.payment_initiated(pg_temp._payment((select p1 from _t)), 'sim_1', 'https://pay.test/1')
  -> 'payment' ->> 'checkout_url', 'https://pay.test/1', 'page de paiement enregistrée');
select is((select count(*)::int from public.events where name = 'payment_initiated'
           and actor_id = (select awa from _t)), 1, 'payment_initiated');

-- Confirmations.
create function pg_temp._event(p_event text, p_payment uuid, p_outcome text, p_amount bigint,
  p_signed boolean default true) returns text language sql as $$
  select app.apply_payment_event('simulator', p_event, jsonb_build_object('event', p_event),
    p_signed, p_payment, p_outcome, p_amount, 'XOF')
$$;
select is(pg_temp._event('e0', pg_temp._payment((select p1 from _t)), 'succeeded', 3600, false), 'rejected',
  'signature invalide : refusée');
select is(pg_temp._event('e1', pg_temp._payment((select p1 from _t)), 'succeeded', 100), 'ignored',
  'montant différent : ignoré');
select is((select status from public.payments where id = pg_temp._payment((select p1 from _t))), 'pending',
  'toujours en attente');
select is(pg_temp._event('e2', pg_temp._payment((select p1 from _t)), 'succeeded', 3600), 'applied', 'réussite appliquée');
select is(pg_temp._event('e2', pg_temp._payment((select p1 from _t)), 'succeeded', 3600), 'duplicate', 'rejeu : sans effet');
select is(pg_temp._event('e3', pg_temp._payment((select p1 from _t)), 'failed', 3600), 'duplicate',
  'échec après réussite : sans effet');
select is((select payment_status from public.purchases where id = (select (p1 -> 'purchase' ->> 'id')::uuid from _t)),
  'paid', 'achat payé');
select is((select count(*)::int from public.payment_events where payment_id = pg_temp._payment((select p1 from _t))), 5,
  'chaque confirmation est journalisée');
select is((select count(*)::int from public.events where name = 'payment_succeeded'
           and actor_id = (select awa from _t)), 1, 'payment_succeeded une fois');
select throws_ok(format($$select app.retry_payment('%s', '%s', '%s', null, '{simulator}')$$,
  (select awa from _t), (select p1 -> 'purchase' ->> 'id' from _t), (select key2 from _t)),
  'P0001', 'already_paid', 'réessai après réussite refusé');

-- La vendeuse voit la commande payée et le détail du paiement.
select tests.login_as((select kodjo from _t));
select is(jsonb_array_length(public.my_store_orders()), 1, 'Kodjo voit la commande payée');
select is(public.my_store_orders() -> 0 ->> 'payment_status', 'paid', 'badge paiement confirmé');
select is(public.my_store_orders() -> 0 ->> 'customer_first_name', 'Awa', 'prénom de la cliente');
select is(public.my_store_order((select kodjo_order from _t)) -> 'payment' ->> 'status', 'succeeded',
  'détail : paiement réussi');
select is(public.my_store_order((select kodjo_order from _t)) -> 'delivery' ->> 'landmark', 'Portail bleu',
  'détail : repère de livraison');
select ok(not (public.my_store_order((select kodjo_order from _t))::text ~* 'example\.com'),
  'jamais l''email de la cliente');

-- Deuxième achat : échec, réessai, échec à l'initiation, puis cash.
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
update _t set p2 = pg_temp._place((select key2 from _t), '{simulator}');
select is(pg_temp._event('f1', pg_temp._payment((select p2 from _t)), 'failed', 0), 'applied', 'échec appliqué');
select is((select payment_status from public.purchases where id = (select (p2 -> 'purchase' ->> 'id')::uuid from _t)),
  'failed', 'achat en échec');
update _t set pay2b = (app.retry_payment((select awa from _t), (select (p2 -> 'purchase' ->> 'id')::uuid from _t),
  (select key3 from _t), null, '{simulator}') ->> 'payment_id')::uuid;
select is((select status from public.payments where id = (select pay2b from _t)), 'pending', 'nouvelle tentative');
select is(app.retry_payment((select awa from _t), (select (p2 -> 'purchase' ->> 'id')::uuid from _t),
  (select key3 from _t), null, '{simulator}') ->> 'replayed', 'true', 'réessai rejoué : même tentative');
select is((select count(*)::int from public.payments where purchase_id = (select (p2 -> 'purchase' ->> 'id')::uuid from _t)),
  2, 'l''ancienne tentative reste journalisée');
select is(app.payment_initiation_failed((select pay2b from _t), 'délai dépassé') ->> 'payment_status', 'failed',
  'fournisseur injoignable : échec');
select throws_ok(format($$select app.retry_payment('%s', '%s', '%s', '%s', '{simulator}')$$,
  (select awa from _t), (select p2 -> 'purchase' ->> 'id' from _t), (select key4 from _t), (select cash from _t)),
  'P0001', 'payment_not_accepted', 'réessai en cash : passer par le cash');
select is(app.switch_to_cash((select awa from _t), (select (p2 -> 'purchase' ->> 'id')::uuid from _t)) ->> 'payment_status',
  'cash_on_delivery', 'passage au cash');
select is(pg_temp._event('f9', (select pay2b from _t), 'succeeded', 500), 'duplicate',
  'confirmation tardive d''une tentative close : sans effet');

select tests.login_as((select kodjo from _t));
select is(jsonb_array_length(public.my_store_orders()), 2, 'la commande cash apparaît aussi');
select ok(public.my_store_orders() @> '[{"payment_status": "cash_on_delivery"}]', 'badge cash');

-- Lecture des paiements : la cliente seulement ; journal interne.
select tests.login_as((select awa from _t));
select is((select count(*)::int from public.payments), 3, 'Awa lit ses tentatives');
select tests.login_as((select ama from _t));
select is((select count(*)::int from public.payments), 0, 'Ama ne lit rien');
select throws_ok('select * from public.payment_events', '42501', null, 'journal des confirmations interne');

select * from finish();
