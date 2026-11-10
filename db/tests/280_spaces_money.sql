-- Argent des espaces (spec 032) : poche commune, versements, financement, suppression.

select plan(16);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kofi@example.com') as kofi,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '28000000-0000-4000-8000-000000000001'::uuid as tomate,
       '28000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       null::uuid as kodjo_store, null::uuid as space, null::text as code;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));

select tests.login_as((select kofi from _t));
select public.complete_profile('Kofi', (select be from _t), 'client');
select public.wallet_topup_simulated(5000, '28100000-0000-4000-8000-000000000001');
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
update _t set space = (public.create_space('Maison') ->> 'id')::uuid;
update _t set code = public.space_detail((select space from _t)) ->> 'join_code';
select tests.login_as((select kofi from _t));
select public.join_space((select code from _t));

-- Versements : wallet → poche, idempotents, refus.
select is((public.space_contribute((select space from _t), 2000, '28200000-0000-4000-8000-000000000001')
           ->> 'pocket_balance_minor')::bigint, 2000::bigint, 'versement : la poche monte');
select is((public.space_contribute((select space from _t), 2000, '28200000-0000-4000-8000-000000000001')
           ->> 'pocket_balance_minor')::bigint, 2000::bigint, 'même clé : compté une fois');
select is((public.my_wallet() ->> 'balance_minor')::bigint, 3000::bigint, 'le wallet baisse d''autant');
select throws_ok($$select public.space_contribute((select space from _t), 9000, gen_random_uuid())$$,
  'P0001', 'wallet_insufficient', 'solde insuffisant refusé');
select throws_ok($$select public.space_contribute((select space from _t), 0, gen_random_uuid())$$,
  'P0001', 'wallet_amount_invalid', 'montant nul refusé');
select is((select (m ->> 'contributed_month_minor')::bigint from jsonb_array_elements(
           public.space_detail((select space from _t)) -> 'members') m where (m ->> 'is_me')::boolean),
  2000::bigint, 'part de chacun ce mois');
select is((select movement ->> 'kind' from jsonb_array_elements(public.my_wallet() -> 'movements') movement limit 1),
  'space_contribution', 'mouvement visible dans le wallet');

-- Kofi remplit 6 tas (3 000) : la poche (2 000) ne suffit pas.
select public.cart_add((select tomate_tas from _t), 6);
select public.send_cart_to_space((select space from _t));
select tests.login_as((select awa from _t));
select throws_ok(format($$select public.validate_space('%s', true)$$, (select space from _t)), '22023',
  'space_pocket_insufficient', 'poche insuffisante : refusé');
select is(jsonb_array_length(public.space_detail((select space from _t)) -> 'items'), 1, 'rien n''a bougé');

-- 4 tas (2 000) : financés par la poche, virés sur le wallet d'Awa.
select public.set_space_item((select space from _t), (select tomate_tas from _t), 4);
select is((public.validate_space((select space from _t), true) ->> 'funded_minor')::bigint, 2000::bigint,
  'validation financée par la poche');
select is((public.my_wallet() ->> 'balance_minor')::bigint, 2000::bigint, 'montant sur le wallet d''Awa');
select is((public.space_detail((select space from _t)) ->> 'pocket_balance_minor')::bigint, 0::bigint, 'poche vidée');
select tests.logout();
select is((select sum(amount_minor)::bigint from public.ledger_entries), 0::bigint, 'grand livre équilibré');

-- Un membre ne finance pas ; suppression refusée tant que la poche n'est pas vide.
select tests.login_as((select kofi from _t));
select public.space_contribute((select space from _t), 500, '28200000-0000-4000-8000-000000000002');
select public.cart_add((select tomate_tas from _t), 1);
select public.send_cart_to_space((select space from _t));
select throws_ok(format($$select public.validate_space('%s', true)$$, (select space from _t)), '42501', 'not_payer',
  'un membre ne finance pas');
select tests.login_as((select awa from _t));
select throws_ok(format($$select public.delete_space('%s')$$, (select space from _t)), '22023', 'space_balance',
  'suppression refusée : poche non vide');
select tests.logout();
select ok('space_balance' = any(app.account_deletion_blockers((select awa from _t))),
  'suppression du compte refusée : poche non vide');

select * from finish();
