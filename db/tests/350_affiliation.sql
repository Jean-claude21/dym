-- Affiliation des créatrices (spec 039).

select plan(25);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('efua@example.com') as efua,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '35000000-0000-4000-8000-000000000001'::uuid as tomate,
       '35000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '35000000-0000-4000-8000-000000000003'::uuid as gombo,
       '35000000-0000-4000-8000-000000000004'::uuid as gombo_tas,
       '35000000-0000-4000-8000-000000000005'::uuid as piment,
       '35000000-0000-4000-8000-000000000006'::uuid as piment_tas,
       '35100000-0000-4000-8000-000000000001'::uuid as post,
       null::uuid as kodjo_store, null::uuid as order1, null::uuid as order2, null::uuid as order3;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._publish(p_id uuid, p_variant uuid, p_name text, p_price bigint) returns void
language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', (select tomates from _t), 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', 50))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, text, bigint) to authenticated;

create function pg_temp._order(p_buyer uuid) returns uuid language sql as $$
  select (o ->> 'id')::uuid from jsonb_array_elements(
    app.place_order(p_buyer, gen_random_uuid(), jsonb_build_object(
      'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
      'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')),
      (select morning from _t)) -> 'purchase' -> 'orders') o limit 1
$$;

create function pg_temp._deliver(p_order uuid) returns void language sql as $$
  select app.transition_order((select kodjo from _t), p_order, 'accepted', 'pending');
  select app.transition_order((select kodjo from _t), p_order, 'preparing', 'accepted');
  select app.transition_order((select kodjo from _t), p_order, 'ready', 'preparing');
  select app.transition_order((select kodjo from _t), p_order, 'delivered', 'ready');
$$;

-- Vendeuse : taux de la boutique et d'un produit, jamais sous le minimum du pays (300 pb).
select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select pg_temp._publish((select tomate from _t), (select tomate_tas from _t), 'Tomates', 500);
select pg_temp._publish((select gombo from _t), (select gombo_tas from _t), 'Gombo', 300);
select pg_temp._publish((select piment from _t), (select piment_tas from _t), 'Piment', 1000);
select is((public.my_affiliate_rate() ->> 'min_rate_bps')::int, 300, 'minimum du pays');
select throws_ok($$select public.set_affiliate_rate(100)$$, '22023', 'invalid_rate', 'taux sous le minimum refusé');
select is((public.set_affiliate_rate(500) ->> 'affiliate_rate_bps')::int, 500, 'taux de la boutique');
select is((public.set_affiliate_rate(1000, (select piment from _t)) ->> 'affiliate_rate_bps')::int, 1000,
  'taux d''un produit');

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.become_creator('Awa cuisine');
select public.save_creator_content(jsonb_build_object('id', (select post from _t), 'kind', 'post',
  'media_key', 'creators/' || (select awa from _t) || '/contents/' || (select post from _t) || '.jpg',
  'caption', 'Sauce tomate', 'product_ids', jsonb_build_array((select tomate from _t), (select piment from _t))));
select public.register_device('35300000-0000-4000-8000-000000000001');
select throws_ok($$select public.set_affiliate_rate(500)$$, 'P0002', null, 'sans boutique : pas de taux');
-- Son propre contenu ne compte pas.
select public.content_touch((select post from _t), array[(select tomate_tas from _t)]);
select tests.logout();
select is((select count(*)::int from public.affiliate_touches where user_id = (select awa from _t)), 0,
  'pas d''auto-affiliation');

-- Ama : tomates et piment tagués, gombo en ingrédient générique.
select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select public.register_device('35300000-0000-4000-8000-000000000002');
select public.cart_add((select tomate_tas from _t), 2);
select public.cart_add((select piment_tas from _t), 1);
select public.cart_add((select gombo_tas from _t), 1);
select public.content_touch((select post from _t),
  array[(select tomate_tas from _t), (select piment_tas from _t), (select gombo_tas from _t)]);
select throws_ok($$select count(*) from public.affiliate_commissions$$, '42501', null,
  'aucune lecture directe des commissions');
select tests.logout();
select is((select via from public.affiliate_touches where variant_id = (select gombo_tas from _t)), 'ingredient',
  'ingrédient générique reconnu');

-- Ici la vendeuse paie (hors lancement).
update public.countries set affiliate_launch_subsidy = false where code = 'TG';
update _t set order1 = pg_temp._order((select ama from _t));
select is((select array_agg(amount_minor order by amount_minor) from public.affiliate_commissions
           where order_id = (select order1 from _t)), array[9, 50, 100]::bigint[],
  'gombo au minimum (3 % de 300), tomates au taux boutique (5 % de 1 000), piment au taux produit (10 % de 1 000)');
select ok((select bool_and(paid_by = 'store') from public.affiliate_commissions where order_id = (select order1 from _t)),
  'payées par la vendeuse');

select tests.login_as((select awa from _t));
select is((public.my_commissions() ->> 'pending_minor')::bigint, 159::bigint, 'en attente pour la créatrice');
select tests.login_as((select ama from _t));
select is(jsonb_array_length(public.my_commissions() -> 'items'), 0, 'la cliente ne voit rien');
select tests.logout();

-- Livrée : due à la fin du délai de réclamation (24 h), pas avant.
select pg_temp._deliver((select order1 from _t));
select is(app.settle_affiliate_commissions(now() + interval '1 hour'), 0, 'rien avant la fin du délai');
select is(app.settle_affiliate_commissions(now() + interval '25 hours'), 3, 'versées après le délai');
select is(app.settle_affiliate_commissions(now() + interval '26 hours'), 0, 'versées une seule fois');
select tests.login_as((select awa from _t));
select is((public.my_wallet() ->> 'balance_minor')::bigint, 159::bigint, 'commissions sur le wallet');
select tests.logout();
select is((select (-sum(e.amount_minor))::bigint from public.ledger_entries e
           join public.ledger_accounts a on a.id = e.account_id
           join public.ledger_transactions t on t.id = e.transaction_id
           where a.kind = 'store_balance' and a.store_id = (select kodjo_store from _t)
             and t.kind = 'affiliate_commission'), -159::bigint, 'prises sur le solde de la boutique');
select is((select count(*)::int from public.notifications where kind = 'commission_paid'
           and user_id = (select awa from _t)), 3, 'créatrice prévenue');

-- Refusée : annulée.
select tests.login_as((select ama from _t));
select public.cart_add((select tomate_tas from _t), 1);
select public.content_touch((select post from _t), array[(select tomate_tas from _t)]);
select tests.logout();
update _t set order2 = pg_temp._order((select ama from _t));
select app.transition_order((select kodjo from _t), (select order2 from _t), 'refused', 'pending', 'too_busy');
select is((select cancel_reason from public.affiliate_commissions where order_id = (select order2 from _t)),
  'not_delivered', 'commande refusée : commission annulée');

-- Remboursée avant l'échéance : annulée, rien versé.
select tests.login_as((select ama from _t));
select public.cart_add((select tomate_tas from _t), 1);
select public.content_touch((select post from _t), array[(select tomate_tas from _t)]);
select tests.logout();
update _t set order3 = pg_temp._order((select ama from _t));
select pg_temp._deliver((select order3 from _t));
insert into public.refunds (order_id, amount_minor, currency_code, method)
values ((select order3 from _t), 500, 'XOF', 'cash');
select app.settle_affiliate_commissions(now() + interval '25 hours');
select is((select cancel_reason from public.affiliate_commissions where order_id = (select order3 from _t)),
  'refunded', 'remboursée : commission annulée');

-- Antifraude : même appareil que la créatrice.
select tests.login_as((select efua from _t));
select public.complete_profile('Efua', (select be from _t), 'client');
select public.register_device('35300000-0000-4000-8000-000000000001');
select public.cart_add((select tomate_tas from _t), 1);
select public.content_touch((select post from _t), array[(select tomate_tas from _t)]);
select tests.logout();
update _t set order1 = pg_temp._order((select efua from _t));
select is((select count(*)::int from public.affiliate_commissions where order_id = (select order1 from _t)),
  0, 'même appareil que la créatrice : aucune commission');

-- Antifraude : même foyer (téléphone ou coordonnées d'une adresse de la créatrice).
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone, latitude, longitude)
values (gen_random_uuid(), (select awa from _t), 'home', (select be from _t), 'Près du marché',
        '+228 90 00 00 01', 6.130000, 1.220000);
select ok(app.affiliate_same_household((select awa from _t), '{"phone": "+22890000001"}'), 'même téléphone');
select ok(app.affiliate_same_household((select awa from _t),
  '{"phone": "+22891111111", "latitude": 6.13020, "longitude": 1.22010}'), 'à quelques mètres');
select ok(not app.affiliate_same_household((select awa from _t),
  '{"phone": "+22891111111", "latitude": 6.14, "longitude": 1.23}'), 'autre foyer');

select is((select sum(amount_minor)::bigint from public.ledger_entries), 0::bigint, 'grand livre équilibré');

select * from finish();
