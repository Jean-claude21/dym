-- Cash et gains du livreur (spec 043).

select plan(18);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('kofi@example.com') as kofi,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       '39000000-0000-4000-8000-000000000001'::uuid as tomate,
       '39000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '39200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as order1, null::uuid as order2, null::text as code;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select id from public.categories where slug = 'tomates'),
  'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));

select tests.login_as((select kofi from _t));
select public.complete_profile('Kofi', (select be from _t), 'delivery');
select public.become_courier('Kofi', '+228 90 11 22 33', 'moto', array[(select be from _t)]);
select public.set_courier_online(true);

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.logout();
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone)
values ((select address from _t), (select awa from _t), 'home', (select be from _t), 'Près du marché', '+228 91 00 00 01');

create function pg_temp._order() returns uuid language sql as $$
  select (o ->> 'id')::uuid from jsonb_array_elements(
    app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
      'address_id', (select address from _t),
      'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
      'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
      (select morning from _t)) -> 'purchase' -> 'orders') o limit 1
$$;

create function pg_temp._run(p_order uuid) returns void language plpgsql as $$
declare v_code text;
begin
  perform app.transition_order((select kodjo from _t), p_order, 'accepted', 'pending');
  perform tests.login_as((select kofi from _t));
  perform public.accept_mission(p_order);
  perform tests.logout();
  perform app.transition_order((select kodjo from _t), p_order, 'ready', 'accepted');
  select handover_code into v_code from public.orders where id = p_order;
  perform tests.login_as((select kofi from _t));
  perform tests.pickup(p_order);
  perform public.courier_deliver(p_order, v_code);
  perform tests.logout();
end
$$;

-- Commande en cash (2 × 500) livrée par Kofi : il doit 1 000 à la boutique, garde ses frais.
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();
update _t set order1 = pg_temp._order();
select pg_temp._run((select order1 from _t));
select ok((select cash_collected_at is not null from public.orders where id = (select order1 from _t)),
  'cash encaissé par le livreur');
select tests.login_as((select kofi from _t));
select is((public.courier_earnings() -> 'cash' -> 0 ->> 'amount_minor')::bigint, 1000::bigint,
  'cash dû à la boutique : prix des articles');
select is((public.courier_earnings() ->> 'today_count')::int >= 0, true, 'tableau de bord lisible');
select is((public.courier_earnings() ->> 'wallet_minor')::bigint, 0::bigint, 'cash : rien au wallet');

-- La boutique confirme avoir reçu le cash.
select tests.login_as((select kodjo from _t));
select is((public.store_courier_cash() -> 0 ->> 'amount_minor')::bigint, 1000::bigint, 'la boutique voit le cash dû');
select is(jsonb_array_length(public.confirm_courier_cash((select kofi from _t), gen_random_uuid())), 0,
  'cash confirmé : plus rien dû');
select throws_ok(format($$select public.confirm_courier_cash('%s', gen_random_uuid())$$, (select kofi from _t)),
  'P0001', 'nothing_owed', 'rien à confirmer');
select tests.login_as((select kofi from _t));
select is(jsonb_array_length(public.courier_earnings() -> 'cash'), 0, 'livreur à jour');
select is((select count(*)::int from public.notifications where kind = 'courier_cash_confirmed'
           and user_id = (select kofi from _t)), 1, 'livreur prévenu');

-- Commande payée en ligne : les frais de livraison vont au wallet du livreur.
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
update _t set order2 = pg_temp._order();
update public.purchases set payment_status = 'paid'
where id = (select purchase_id from public.orders where id = (select order2 from _t));
select pg_temp._run((select order2 from _t));
alter table _t add column fee bigint;
update _t set fee = (select delivery_fee_minor from public.orders where id = (select order2 from _t));
select tests.login_as((select kofi from _t));
select is((public.courier_earnings() ->> 'wallet_minor')::bigint, (select fee from _t), 'frais au wallet');

-- Point de recharge : la cliente montre un code, le livreur crédite son wallet.
select tests.login_as((select awa from _t));
update _t set code = public.cash_topup_code() ->> 'code';
select ok((select code ~ '^[0-9]{6}$' from _t), 'code de recharge');
select tests.login_as((select kofi from _t));
select throws_ok($$select public.courier_cash_topup('000000', 2000, gen_random_uuid())$$, 'P0001', 'invalid_code',
  'code inconnu refusé');
select is((public.courier_cash_topup((select code from _t), 2000, gen_random_uuid()) -> 'cash' -> 0 ->> 'amount_minor')::bigint,
  2000::bigint, 'le livreur doit 2 000 à DYM');
select throws_ok(format($$select public.courier_cash_topup('%s', 500, gen_random_uuid())$$, (select code from _t)),
  'P0001', 'invalid_code', 'code utilisé une fois');
select tests.login_as((select awa from _t));
select is((public.my_wallet() ->> 'balance_minor')::bigint, 2000::bigint, 'wallet de la cliente crédité');

-- Retrait simulé : pas plus que le solde.
select throws_ok($$select public.wallet_withdraw_simulated(5000, gen_random_uuid())$$, 'P0001', 'wallet_insufficient',
  'retrait au-delà du solde refusé');
select is((public.wallet_withdraw_simulated(1500, gen_random_uuid()) ->> 'balance_minor')::bigint, 500::bigint,
  'retrait effectué');
select tests.logout();

select is((select sum(amount_minor)::bigint from public.ledger_entries), 0::bigint, 'grand livre équilibré');

select * from finish();
