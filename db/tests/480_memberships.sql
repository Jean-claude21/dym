-- DYM+, vendeuse Pro, visibilité sponsorisée (spec 052).

select plan(14);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('awa@example.com') as awa,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       '48000000-0000-4000-8000-000000000001'::uuid as igname,
       '48000000-0000-4000-8000-000000000002'::uuid as igname_tas,
       null::uuid as kodjo_store, null::uuid as order1, null::uuid as plus_plan, null::uuid as pro_plan,
       null::uuid as featured_plan;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
update _t set plus_plan = (select id from public.membership_plans where country_code = 'TG' and code = 'dym_plus'),
              pro_plan = (select id from public.membership_plans where country_code = 'TG' and code = 'vendor_pro'),
              featured_plan = (select id from public.membership_plans where country_code = 'TG' and code = 'featured_week');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._go(p_order uuid, p_to text) returns jsonb
language sql as $$
  select app.transition_order((select kodjo from _t), p_order, p_to, (select status from public.orders where id = p_order))
$$;

-- La vendeuse prend Pro et « À la une » depuis son wallet.
select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select public.save_product(jsonb_build_object(
  'id', (select igname from _t), 'name', 'Igname', 'category_id', (select id from public.categories where slug = 'tomates'),
  'price_minor', 10000,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select igname from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select igname_tas from _t), 'stock_quantity', 20))));
select public.publish_product((select igname from _t));
select is(jsonb_array_length(public.membership_offer('vendor') -> 'plans'), 2, 'formules de la boutique');
select throws_ok(format($$select public.subscribe_plan('%s', gen_random_uuid())$$, (select pro_plan from _t)), 'P0001',
  'wallet_insufficient', 'wallet vide : refusé');
select public.wallet_topup_simulated(10000, gen_random_uuid());
select ok(public.subscribe_plan((select pro_plan from _t), 'e1000000-0000-4000-8000-000000000001')
  -> 'plans' -> 0 ->> 'active_until' is not null, 'Pro active');
select is((public.subscribe_plan((select pro_plan from _t), 'e1000000-0000-4000-8000-000000000001')
  ->> 'wallet_balance_minor')::bigint, 7000::bigint, 'rejeu : payé une seule fois');
select public.subscribe_plan((select featured_plan from _t), gen_random_uuid());
select tests.logout();
select is((select count(*)::int from public.ledger_transactions where kind = 'membership'), 2, 'au grand livre');

-- La cliente voit la boutique « À la une » et prend DYM+ (prolongée par un second achat).
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select is(public.discover_stores((select be from _t)) -> 'sponsored' -> 0 ->> 'name', 'Étal de Kodjo', 'à la une');
select is(jsonb_array_length(public.membership_offer('client') -> 'plans'), 1, 'formule cliente');
select throws_ok($$select public.membership_offer('admin')$$, '22023', 'invalid_audience', 'public inconnu');
select public.wallet_topup_simulated(5000, gen_random_uuid());
select public.subscribe_plan((select plus_plan from _t), gen_random_uuid());
select ok((public.subscribe_plan((select plus_plan from _t), gen_random_uuid()) -> 'plans' -> 0 ->> 'active_until')::timestamptz
  > now() + interval '59 days', 'prolongée de 30 jours');
select is((public.membership_offer('client') ->> 'wallet_balance_minor')::bigint, 2000::bigint, 'deux mois payés');
select public.cart_add((select igname_tas from _t), 1);
select tests.logout();

-- Commande : commission Pro réduite de moitié ; à la livraison, cashback DYM+ en plus.
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
select is((select commission_minor from public.orders where id = (select order1 from _t)),
  (select r - r / 2 from (select app.commission_rate('TG', (select id from public.categories where slug = 'tomates'))::bigint
                           as r) x),
  'commission Pro réduite de moitié');
select pg_temp._go((select order1 from _t), 'accepted');
select pg_temp._go((select order1 from _t), 'ready');
select pg_temp._go((select order1 from _t), 'delivered');
select is((select (-sum(e.amount_minor))::bigint from public.ledger_entries e join public.ledger_transactions t on t.id = e.transaction_id
           join public.ledger_accounts a on a.id = e.account_id
           where t.kind = 'member_benefit' and a.kind = 'user_wallet'), 200::bigint, 'cashback DYM+ : 2 % de 10 000');
select is((select count(*)::int from public.ledger_transactions where kind = 'member_benefit'), 1, 'versé une fois');
select is(app.member_flag((select awa from _t), null, 'delivery_refund'), true, 'livraison remboursée active');

select * from finish();
