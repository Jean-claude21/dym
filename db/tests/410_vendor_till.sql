-- Caisse de la vendeuse (spec 045).

select plan(17);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('efua@example.com') as efua,
       '41000000-0000-4000-8000-000000000001'::uuid as tomate,
       '41000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       null::uuid as kodjo_store, null::uuid as sale;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select id from public.categories where slug = 'tomates'),
  'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 10))));
select public.publish_product((select tomate from _t));

-- Lecture d'une vente dictée : montant selon les décimales de la devise, produit reconnu.
select is((public.till_parse('3 tas de tomates 1 500 F') ->> 'amount_minor')::bigint, 1500::bigint, 'montant lu');
select is(public.till_parse('3 tas de tomates 1 500 F') ->> 'label', '3 tas de tomates', 'libellé');
select is((public.till_parse('3 tas de tomates 1500') ->> 'quantity')::int, 3, 'quantité lue');
select is(public.till_parse('3 tas de tomates 1500') ->> 'variant_id', (select tomate_tas from _t)::text, 'produit reconnu');
select is(public.till_parse('piment') ->> 'amount_minor', null, 'sans montant : à compléter');

-- Vente hors app : une fois par clé, stock décompté, comptée dans la caisse du jour.
select is((public.record_till_sale('3 tas de tomates', 1500, 'cash', '41100000-0000-4000-8000-000000000001',
  (select tomate_tas from _t), 3) ->> 'today_off_app_minor')::bigint, 1500::bigint, 'vente enregistrée');
select is((public.record_till_sale('3 tas de tomates', 1500, 'cash', '41100000-0000-4000-8000-000000000001',
  (select tomate_tas from _t), 3) ->> 'today_off_app_count')::int, 1, 'même clé : une seule vente');
select public.record_till_sale('Gombo', 700, 'mobile_money', gen_random_uuid());
select is((public.my_till() -> 'today_by_method' ->> 'mobile_money')::bigint, 700::bigint, 'par moyen');
select throws_ok($$select public.record_till_sale('x', 0, 'cash', gen_random_uuid())$$, '22023', 'invalid_amount', 'montant nul refusé');
select throws_ok($$select public.record_till_sale('x', 100, 'troc', gen_random_uuid())$$, '22023', 'invalid_method', 'moyen inconnu refusé');
select tests.logout();
select is((select stock_quantity from public.product_variants where id = (select tomate_tas from _t)), 7, 'stock décompté');

-- Annulation : stock rendu, plus comptée.
update _t set sale = (select id from public.store_sales where idempotency_key = '41100000-0000-4000-8000-000000000001');
select tests.login_as((select kodjo from _t));
select is((public.void_till_sale((select sale from _t)) ->> 'today_off_app_minor')::bigint, 700::bigint, 'vente annulée');
select tests.logout();
select is((select stock_quantity from public.product_variants where id = (select tomate_tas from _t)), 10, 'stock rendu');

-- Une autre vendeuse ne voit ni n'annule rien.
select tests.login_as((select efua from _t));
select throws_ok($$select public.my_till()$$, 'P0002', null, 'sans boutique : pas de caisse');
select throws_ok(format($$select public.void_till_sale('%s')$$, (select sale from _t)), 'P0002', null, 'vente d''autrui');

-- Versement : jamais plus que le solde.
select tests.login_as((select kodjo from _t));
select throws_ok($$select public.store_payout_simulated(100, gen_random_uuid())$$, 'P0001', 'balance_insufficient',
  'solde nul : versement refusé');
select tests.logout();
select app.ledger_post('payment_received', 'test-till', 'XOF', jsonb_build_array(
  jsonb_build_object('account', app.ledger_account('provider_clearing', 'XOF'), 'amount', 2000),
  jsonb_build_object('account', app.ledger_account('store_balance', 'XOF', (select kodjo_store from _t)), 'amount', -2000)));
select tests.login_as((select kodjo from _t));
select is((public.store_payout_simulated(1500, gen_random_uuid()) ->> 'balance_minor')::bigint, 500::bigint,
  'versement effectué');
select tests.logout();

select * from finish();
