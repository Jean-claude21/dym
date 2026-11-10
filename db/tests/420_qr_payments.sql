-- Paiement et encaissement par QR (spec 046).

select plan(16);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('awa@example.com') as awa,
       (select id from public.zones where slug = 'be') as be,
       null::uuid as kodjo_store, null::uuid as req, null::text as code;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;
update public.countries set qr_commission_bps = 100 where code = 'TG';

-- Vendeuse : demande de 2 000, une par clé.
select tests.login_as((select kodjo from _t));
select throws_ok($$select public.create_payment_request(0, gen_random_uuid())$$, '22023', 'invalid_amount', 'montant nul refusé');
update _t set req = (public.create_payment_request(2000, '42100000-0000-4000-8000-000000000001', 'Tomates') ->> 'id')::uuid;
select is(public.create_payment_request(2000, '42100000-0000-4000-8000-000000000001') ->> 'id', (select req from _t)::text,
  'même clé : même demande');
update _t set code = public.my_payment_request((select req from _t)) ->> 'code';
select ok((select code ~ '^[0-9]{6}$' from _t), 'code à 6 chiffres');
select is(public.my_payment_request((select req from _t)) ->> 'qr', 'DYM-PAY:' || (select code from _t), 'contenu du QR');
select throws_ok(format($$select public.pay_payment_request('%s', gen_random_uuid())$$, (select code from _t)),
  'P0001', 'own_store', 'la vendeuse ne se paie pas elle-même');

-- Cliente : aperçu, solde insuffisant, puis paiement.
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select is(public.payment_request_preview('DYM-PAY:' || (select code from _t)) ->> 'store_name', 'Étal de Kodjo', 'aperçu par QR');
select is(public.payment_request_preview((select code from _t)) ->> 'code', null, 'le code ne revient pas à la cliente');
select throws_ok($$select public.payment_request_preview('000000')$$, 'P0001', 'invalid_code', 'code inconnu');
select throws_ok(format($$select public.pay_payment_request('%s', gen_random_uuid())$$, (select code from _t)),
  'P0001', 'wallet_insufficient', 'wallet vide');
select public.wallet_topup_simulated(5000, gen_random_uuid());
select is(public.pay_payment_request((select code from _t), '42200000-0000-4000-8000-000000000001') ->> 'status', 'paid', 'payé');
select is(public.pay_payment_request((select code from _t), '42200000-0000-4000-8000-000000000001') ->> 'status', 'paid',
  'même clé : pas de second paiement');
select is((public.my_wallet() ->> 'balance_minor')::bigint, 3000::bigint, 'wallet débité une fois');
select throws_ok(format($$select public.pay_payment_request('%s', gen_random_uuid())$$, (select code from _t)),
  'P0001', 'invalid_code', 'demande déjà payée');

-- Vendeuse : payée, dans la caisse, solde net de la commission (1 %).
select tests.login_as((select kodjo from _t));
select is(public.my_payment_request((select req from _t)) ->> 'status', 'paid', 'la vendeuse voit « payé »');
select is((public.my_till() -> 'today_by_method' ->> 'dym')::bigint, 2000::bigint, 'vente dans la caisse');
select is((public.my_till() ->> 'balance_minor')::bigint, 1980::bigint, 'solde net de la commission');
select tests.logout();

select * from finish();
