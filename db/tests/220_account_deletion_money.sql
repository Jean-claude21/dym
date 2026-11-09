-- Suppression de compte et argent (migration 0033).

select plan(4);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       (select id from public.zones where slug = 'be') as be;
grant select on _t to authenticated, anonymous;

select is(
  (select count(*)::int from pg_constraint
   where contype = 'f' and conrelid = 'public.ledger_transactions'::regclass
     and conname <> 'ledger_transactions_currency_code_fkey'),
  0, 'grand livre : aucune référence bloquante');

-- Argent restant : refus explicite.
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.wallet_topup_simulated(500, 'e0000000-0000-4000-8000-00000000000a');
select throws_ok('select public.delete_my_account()', 'P0001', 'suppression impossible : wallet_balance',
  'wallet non vide : suppression refusée');

-- Wallet vide (mais grand livre non vide) : suppression possible.
select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select public.wallet_topup_simulated(300, 'e0000000-0000-4000-8000-00000000000b');
select public.create_pocket('Fête');
select public.wallet_transfer(null, (select id from public.wallet_pockets where user_id = (select ama from _t)),
  300, 'e0000000-0000-4000-8000-00000000000c');
select public.archive_pocket((select id from public.wallet_pockets where user_id = (select ama from _t)));
select tests.logout();
-- Le solde est rendu au wallet par l'archivage ; on le vide comme un paiement le ferait.
select app.ledger_post('wallet_transfer', 'test-vidage', 'XOF', jsonb_build_array(
  jsonb_build_object('account', app.ledger_user_account('user_wallet', 'XOF', (select ama from _t)), 'amount', 300),
  jsonb_build_object('account', app.ledger_account('provider_clearing', 'XOF'), 'amount', -300)));
select tests.login_as((select ama from _t));
select lives_ok('select public.delete_my_account()', 'wallet vide : suppression acceptée');
select tests.logout();
select is((select count(*)::int from neon_auth."user" where id = (select ama from _t)), 0,
  'compte supprimé, écritures gardées');

select * from finish();
