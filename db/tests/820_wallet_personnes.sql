-- Avoir DYM entre personnes (spec 100) : code personnel, envoyer, demander, recharger un proche,
-- argent de poche et plafond parental, jamais de retrait de l'avoir reçu.

select plan(16);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('mia@example.com') as mia,
       tests.create_user('yao@example.com') as yao,
       (select id from public.zones where slug = 'be') as be,
       null::text as h_awa, null::text as h_mia, null::text as h_yao, null::uuid as req;
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
update _t set h_awa = public.my_wallet_handle() ->> 'handle';
select tests.login_as((select mia from _t));
select public.complete_profile('Mia', (select be from _t), 'client');
update _t set h_mia = public.my_wallet_handle() ->> 'handle';
select tests.login_as((select yao from _t));
select public.complete_profile('Yao', (select be from _t), 'client');
update _t set h_yao = public.my_wallet_handle() ->> 'handle';

select ok((select h_awa from _t) ~ '^[A-Z0-9]{8}$', 'code personnel à 8 caractères');

-- Awa recharge (simulé) puis envoie 2 000 à Mia par son code (QR).
select tests.login_as((select awa from _t));
select public.wallet_topup_simulated(5000, gen_random_uuid());
select is(public.wallet_recipient((select h_mia from _t)) ->> 'first_name', 'Mia', 'prénom du destinataire seul');
select is((public.wallet_send('DYM-P2P:' || (select h_mia from _t), 2000, 'Pour le marché', gen_random_uuid())
           ->> 'balance_minor')::int, 3000, 'envoi : solde d''Awa');
select throws_ok(format($$select public.wallet_send('%s', 9999, null, gen_random_uuid())$$, (select h_mia from _t)),
  'P0001', 'wallet_insufficient', 'solde insuffisant refusé');
select throws_ok($$select public.wallet_send('INCONNU1', 100, null, gen_random_uuid())$$,
  'P0002', 'recipient_unknown', 'code inconnu');
select tests.login_as((select mia from _t));
select is((public.my_wallet() ->> 'balance_minor')::int, 2000, 'Mia reçoit 2 000');
select is(public.my_p2p() -> 'transfers' -> 0 ->> 'other_name', 'Awa', 'historique : prénom de l''autre');

-- L'avoir reçu ne se retire jamais.
select throws_ok($$select public.wallet_withdraw_simulated(1000, gen_random_uuid())$$,
  'P0001', 'p2p_not_withdrawable', 'avoir reçu non retirable');

-- Mia demande 500 à Awa ; Awa paie.
update _t set req = (public.wallet_request((select h_awa from _t), 500, 'Mon panier', null) ->> 'id')::uuid;
select tests.login_as((select awa from _t));
select is(public.my_p2p() -> 'requests' -> 0 ->> 'to_pay', 'true', 'Awa voit la demande à payer');
select is(public.wallet_answer_request((select req from _t), true, gen_random_uuid()) ->> 'status', 'paid',
  'demande payée');
select throws_ok(format($$select public.wallet_answer_request('%s', true, gen_random_uuid())$$, (select req from _t)),
  'P0001', 'request_closed', 'une demande ne se paie qu''une fois');

-- Awa recharge le wallet de Yao (simulé).
select ok((public.wallet_topup_for((select h_yao from _t), 1000, gen_random_uuid()) ->> 'ok')::boolean,
  'recharge pour un proche');

-- Famille : Awa invite Yao, Yao accepte ; plafond de 300 par jour, argent de poche de 200.
select public.family_invite((select h_yao from _t));
select tests.login_as((select yao from _t));
select public.family_accept((select awa from _t));
select tests.login_as((select awa from _t));
select is(public.family_set_rules((select yao from _t), 200, 7, 300) -> 'children' -> 0 ->> 'status', 'active',
  'règles posées sur un lien actif');
select is((public.my_family() -> 'children' -> 0 ->> 'balance_minor')::int, 1000, 'vue parentale : solde de Yao');
select tests.login_as((select yao from _t));
select throws_ok(format($$select public.wallet_send('%s', 400, null, gen_random_uuid())$$, (select h_mia from _t)),
  'P0001', 'child_daily_limit', 'plafond du jour dépassé');
select tests.logout();
select is(app.pay_allowances(now() + interval '1 minute'), 1, 'argent de poche versé par le cron');

select * from finish();
