-- Wallet et poches (spec 025) : recharge simulée, poches, transferts, paiement d'une commande,
-- arrondi, cashback, isolement, équilibre du grand livre.

select plan(20);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       null::uuid as kodjo_store, null::uuid as pocket, null::uuid as order1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 700,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));
select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');

-- Recharge simulée.
select is((public.my_wallet() ->> 'balance_minor')::bigint, 0::bigint, 'wallet vide au départ');
select is((public.wallet_topup_simulated(5000, 'e0000000-0000-4000-8000-000000000001') ->> 'balance_minor')::bigint,
  5000::bigint, 'recharge de 5 000');
select is((public.wallet_topup_simulated(5000, 'e0000000-0000-4000-8000-000000000001') ->> 'balance_minor')::bigint,
  5000::bigint, 'rejeu de la recharge : aucun doublon');
select throws_ok($$select public.wallet_topup_simulated(0, gen_random_uuid())$$,
  'P0001', 'wallet_amount_invalid', 'montant nul refusé');
select tests.logout();
update public.feature_flags set is_enabled = false where key = 'wallet_simulated_topup';
select tests.login_as((select awa from _t));
select throws_ok($$select public.wallet_topup_simulated(100, gen_random_uuid())$$,
  'P0001', 'feature_disabled', 'recharge simulée coupée : refusée');
select tests.logout();
update public.feature_flags set is_enabled = true where key = 'wallet_simulated_topup';

-- Poches.
select tests.login_as((select awa from _t));
update _t set pocket = (public.create_pocket('Tabaski', 50000, 500) -> 'pockets' -> 0 ->> 'id')::uuid;
select is(jsonb_array_length(public.my_wallet() -> 'pockets'), 1, 'poche créée');
select is((public.wallet_transfer(null, (select pocket from _t), 1000, gen_random_uuid()) -> 'pockets' -> 0
           ->> 'balance_minor')::bigint, 1000::bigint, 'transfert vers la poche');
select is((public.my_wallet() ->> 'balance_minor')::bigint, 4000::bigint, 'wallet après transfert');
select throws_ok(format($$select public.wallet_transfer('%s', null, 2000, gen_random_uuid())$$, (select pocket from _t)),
  'P0001', 'wallet_insufficient', 'poche insuffisante : refusé');

-- Isolement.
select tests.login_as((select ama from _t));
select is((select count(*)::int from public.wallet_pockets), 0, 'Ama ne voit pas les poches d''Awa');
select throws_ok(format($$select public.wallet_transfer('%s', null, 10, gen_random_uuid())$$, (select pocket from _t)),
  'P0002', null, 'Ama ne vide pas la poche d''Awa');
select throws_ok($$select count(*) from public.ledger_entries$$, '42501', null, 'aucune lecture directe du grand livre');

-- Paiement d'une commande avec le wallet (retrait, 700) : réglée tout de suite, arrondi de 300.
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'wallet'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')),
    (select morning from _t), '{wallet}') -> 'purchase' -> 'orders') o limit 1);
select is((select payment_status from public.purchases where user_id = (select awa from _t)), 'paid',
  'commande payée avec le wallet');
select tests.login_as((select awa from _t));
select is((public.my_wallet() ->> 'balance_minor')::bigint, 3000::bigint, 'wallet : 4 000 − 700 − arrondi 300');
select is((public.my_wallet() -> 'pockets' -> 0 ->> 'balance_minor')::bigint, 1300::bigint, 'poche : arrondi reçu');

-- Solde insuffisant : commande refusée.
select public.cart_add((select tomate_tas from _t), 9);
select tests.logout();
select throws_ok($$select app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'wallet'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')),
    (select morning from _t), '{wallet}')$$, 'P0001', 'wallet_insufficient', 'wallet insuffisant : commande refusée');

-- Cashback de 10 % à la livraison.
insert into public.cashback_rules (country_code, rate_bps) values ('TG', 1000);
select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'preparing', 'accepted');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'ready', 'preparing');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'delivered', 'ready');
select tests.login_as((select awa from _t));
select is((public.my_wallet() ->> 'balance_minor')::bigint, 3070::bigint, 'cashback de 70 crédité');

-- Archivage : le solde revient au wallet.
select is((public.archive_pocket((select pocket from _t)) ->> 'balance_minor')::bigint, 4370::bigint,
  'poche archivée : solde rendu');
select is(jsonb_array_length(public.my_wallet() -> 'pockets'), 0, 'poche archivée retirée');
select tests.logout();

select is((select count(*)::int from (select transaction_id from public.ledger_entries group by 1
           having sum(amount_minor) <> 0) x), 0, 'grand livre équilibré');

select * from finish();
