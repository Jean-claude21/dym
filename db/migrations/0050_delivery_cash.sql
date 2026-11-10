-- 0050 — Cash et gains du livreur (spec 043, VISION §3 « Livreur » : gains en direct, retrait
-- immédiat, gestion du cash ; « Recharge … cash auprès d'un livreur »).
-- 1. Gains : livrée et payée en ligne, les frais de livraison passent du solde de la boutique au
--    wallet du livreur. Payée en cash, le livreur garde ses frais en main.
-- 2. Circuit du cash : le livreur encaisse la cliente ; il doit à chaque boutique le prix des
--    articles (compte `courier_cash` par livreur et boutique) ; la boutique confirme l'avoir reçu.
-- 3. Point de recharge : la cliente montre un code ; le livreur prend son cash et crédite son
--    wallet ; il le doit à DYM (compte `courier_cash` sans boutique), remis à l'équipe.
-- 4. Retrait du wallet vers le fournisseur (simulé tant que le versement réel n'est pas branché,
--    décision 0015).

alter table public.ledger_accounts drop constraint ledger_accounts_kind_check;
alter table public.ledger_accounts add constraint ledger_accounts_kind_check check (kind in (
  'platform_commission', 'provider_clearing', 'customer_escrow', 'store_balance',
  'user_wallet', 'user_pocket', 'platform_promotions', 'space_pocket',
  'courier_cash',         -- cash détenu par un livreur, dû à une boutique (ou à DYM)
  'platform_cash'         -- cash remis à l'équipe DYM
));
alter table public.ledger_accounts drop constraint ledger_accounts_owner_check;
alter table public.ledger_accounts add constraint ledger_accounts_owner_check check (
  ((kind = 'store_balance' and store_id is not null and user_id is null)
   or (kind = 'courier_cash' and user_id is not null)
   or (kind in ('user_wallet', 'user_pocket') and user_id is not null and store_id is null)
   or (kind not in ('store_balance', 'courier_cash', 'user_wallet', 'user_pocket')
       and user_id is null and store_id is null))
  and (kind = 'user_pocket') = (pocket_id is not null)
  and (kind = 'space_pocket') = (space_id is not null));

alter table public.ledger_transactions drop constraint ledger_transactions_kind_check;
alter table public.ledger_transactions add constraint ledger_transactions_kind_check check (kind in (
  'payment_received', 'order_settled', 'cash_commission', 'refund_paid',
  'wallet_topup', 'wallet_transfer', 'cashback', 'space_contribution', 'space_payout', 'order_credit',
  'affiliate_commission',
  'courier_fee',          -- frais de livraison versés au livreur
  'courier_cash',         -- cash encaissé par le livreur pour une boutique
  'courier_cash_remitted',-- cash remis par le livreur (boutique ou équipe)
  'cash_topup',           -- recharge du wallet en cash auprès d'un livreur
  'wallet_withdrawal'     -- retrait du wallet vers le fournisseur
));

-- Codes de recharge en cash (montrés par la cliente, valables 15 minutes, une fois).
create table public.cash_topup_codes (
  code char(6) primary key check (code ~ '^[0-9]{6}$'),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default clock_timestamp()
);
create index cash_topup_codes_user on public.cash_topup_codes (user_id);
alter table public.cash_topup_codes enable row level security;
revoke all on public.cash_topup_codes from authenticated, anonymous;

insert into public.feature_flags (key, country_code, is_enabled, description)
select 'wallet_simulated_withdrawal', null, true,
  'Retrait du wallet simulé (aucun versement réel) — à couper avant la production finale'
where not exists (select 1 from public.feature_flags where key = 'wallet_simulated_withdrawal');

-- Compte cash d'un livreur (dû à une boutique, ou à DYM si la boutique est nulle).
create or replace function app.courier_cash_account(p_user uuid, p_store uuid, p_currency char(3)) returns uuid
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_id uuid;
begin
  select id into v_id from public.ledger_accounts
  where kind = 'courier_cash' and user_id = p_user and store_id is not distinct from p_store
    and currency_code = p_currency;
  if v_id is null then
    insert into public.ledger_accounts (kind, user_id, store_id, currency_code)
    values ('courier_cash', p_user, p_store, p_currency)
    on conflict do nothing returning id into v_id;
    if v_id is null then
      select id into v_id from public.ledger_accounts
      where kind = 'courier_cash' and user_id = p_user and store_id is not distinct from p_store
        and currency_code = p_currency;
    end if;
  end if;
  return v_id;
end
$fn$;

-- ------------------------------------------------------------------ livraison : gains et cash

-- Livrée par un livreur DYM : frais au wallet (payée en ligne) ou cash encaissé (paiement à la
-- livraison : la commission et le cashback suivent le circuit cash existant).
create or replace function app.courier_money_on_order() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_courier uuid;
  v_payment text;
begin
  if new.status <> 'delivered' or old.status is not distinct from 'delivered' then return null; end if;
  select courier_id into v_courier from public.order_couriers where order_id = new.id;
  if v_courier is null then return null; end if;
  select payment_status into v_payment from public.purchases where id = new.purchase_id;
  if v_payment = 'paid' and new.delivery_fee_minor > 0 then
    perform app.ledger_post('courier_fee', 'courier-fee:' || new.id, new.currency_code, jsonb_build_array(
      jsonb_build_object('account', app.ledger_account('store_balance', new.currency_code, new.store_id),
                         'amount', new.delivery_fee_minor),
      jsonb_build_object('account', app.ledger_user_account('user_wallet', new.currency_code, v_courier),
                         'amount', -new.delivery_fee_minor)),
      p_order => new.id, p_user => v_courier);
  elsif v_payment = 'cash_on_delivery' then
    -- Le livreur a le cash : il doit le prix des articles à la boutique et garde ses frais.
    perform app.ledger_post('courier_cash', 'courier-cash:' || new.id, new.currency_code, jsonb_build_array(
      jsonb_build_object('account', app.courier_cash_account(v_courier, new.store_id, new.currency_code),
                         'amount', new.subtotal_minor),
      jsonb_build_object('account', app.ledger_account('store_balance', new.currency_code, new.store_id),
                         'amount', -new.subtotal_minor)),
      p_order => new.id, p_user => v_courier);
    update public.orders set cash_collected_at = coalesce(cash_collected_at, now()) where id = new.id;
  end if;
  perform app.emit_event('courier_earned', v_courier, 'courier', 'server',
    (select country_code from public.purchases where id = new.purchase_id), 'order', new.id::text,
    jsonb_build_object('fee_minor', new.delivery_fee_minor, 'cash', v_payment = 'cash_on_delivery'));
  return null;
end
$fn$;
create trigger orders_courier_money after update of status on public.orders
  for each row execute function app.courier_money_on_order();

-- Gains et cash du livreur : aujourd'hui, wallet, cash à remettre par boutique (et à DYM).
create or replace function public.courier_earnings() returns jsonb
language sql stable security definer set search_path = ''
as $$
  with me as (select app.current_user_id() as id),
  today as (
    select o.* from public.orders o
    join public.order_couriers oc on oc.order_id = o.id
    join public.purchases pu on pu.id = o.purchase_id
    join public.countries c on c.code = pu.country_code
    where oc.courier_id = (select id from me) and o.status = 'delivered'
      and (o.delivered_at at time zone c.timezone)::date = (now() at time zone c.timezone)::date)
  select jsonb_build_object(
    'today_count', (select count(*) from today),
    'today_fees_minor', coalesce((select sum(delivery_fee_minor) from today), 0),
    'wallet_minor', coalesce((select -sum(e.amount_minor) from public.ledger_entries e
                              join public.ledger_accounts a on a.id = e.account_id
                              where a.kind = 'user_wallet' and a.user_id = (select id from me)), 0),
    'cash', coalesce((select jsonb_agg(jsonb_build_object(
        'store_id', a.store_id,
        'store_name', (select s.name from public.stores s where s.id = a.store_id),
        'amount_minor', app.ledger_balance(a.id) * -1) order by a.store_id nulls last)
      from public.ledger_accounts a
      where a.kind = 'courier_cash' and a.user_id = (select id from me) and app.ledger_balance(a.id) <> 0),
      '[]'::jsonb))
$$;

-- Boutique : cash que lui doivent les livreurs.
create or replace function public.store_courier_cash() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'courier_id', a.user_id,
      'courier_name', (select c.display_name from public.courier_profiles c where c.user_id = a.user_id),
      'amount_minor', -app.ledger_balance(a.id)) order by a.user_id), '[]'::jsonb)
  from public.ledger_accounts a
  where a.kind = 'courier_cash' and a.store_id = app.own_store_id() and app.ledger_balance(a.id) <> 0
$$;

-- La boutique confirme avoir reçu du livreur tout le cash dû.
create or replace function public.confirm_courier_cash(p_courier uuid, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store uuid := app.own_store_id();
  v_account record;
  v_owed bigint;
begin
  if v_store is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  select a.id, a.currency_code into v_account from public.ledger_accounts a
  where a.kind = 'courier_cash' and a.user_id = p_courier and a.store_id = v_store;
  v_owed := case when v_account.id is null then 0 else -app.ledger_balance(v_account.id) end;
  if v_owed <= 0 then raise exception 'nothing_owed' using errcode = 'P0001'; end if;
  perform app.ledger_post('courier_cash_remitted', 'remit:' || p_key, v_account.currency_code, jsonb_build_array(
    jsonb_build_object('account', v_account.id, 'amount', -v_owed),
    jsonb_build_object('account', app.ledger_account('store_balance', v_account.currency_code, v_store),
                       'amount', v_owed)),
    p_user => p_courier);
  perform app.notify(p_courier, 'courier_cash_confirmed', 'payments', null, null,
    jsonb_build_object('amount_minor', v_owed, 'currency_code', v_account.currency_code,
                       'store_name', (select name from public.stores where id = v_store)));
  perform app.emit_event('courier_cash_remitted', app.current_user_id(), 'vendor', 'server',
    (select country_code from public.stores where id = v_store), 'store', v_store::text,
    jsonb_build_object('amount_minor', v_owed));
  return public.store_courier_cash();
end
$fn$;

-- ------------------------------------------------------------------ point de recharge

-- Cliente : code à montrer au livreur (un seul actif, 15 minutes).
create or replace function public.cash_topup_code() returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_code text;
begin
  delete from public.cash_topup_codes where user_id = v_user and used_at is null;
  loop
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    begin
      insert into public.cash_topup_codes (code, user_id, expires_at)
      values (v_code, v_user, now() + interval '15 minutes');
      exit;
    exception when unique_violation then
      delete from public.cash_topup_codes where code = v_code and (used_at is not null or expires_at < now());
    end;
  end loop;
  return jsonb_build_object('code', v_code, 'expires_at', now() + interval '15 minutes');
end
$fn$;

-- Livreur : prend le cash de la cliente et crédite son wallet ; il le doit à DYM.
create or replace function public.courier_cash_topup(p_code text, p_amount_minor bigint, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_courier public.courier_profiles;
  v_client uuid;
  v_currency char(3);
begin
  select * into v_courier from public.courier_profiles where user_id = v_user and status = 'active';
  if v_courier.user_id is null then raise exception 'not_courier' using errcode = '42501'; end if;
  if exists (select 1 from public.ledger_transactions where idempotency_key = 'cash-topup:' || p_key) then
    return public.courier_earnings();
  end if;
  if p_amount_minor is null or p_amount_minor <= 0 or p_amount_minor > 100000000 then
    raise exception 'wallet_amount_invalid' using errcode = 'P0001';
  end if;
  update public.cash_topup_codes set used_at = now()
  where code = btrim(coalesce(p_code, '')) and used_at is null and expires_at > now() and user_id <> v_user
  returning user_id into v_client;
  if v_client is null then raise exception 'invalid_code' using errcode = 'P0001'; end if;
  v_currency := app.user_currency(v_client);
  if v_currency is distinct from (select currency_code from public.countries where code = v_courier.country_code) then
    raise exception 'invalid_code' using errcode = 'P0001';
  end if;
  perform app.ledger_post('cash_topup', 'cash-topup:' || p_key, v_currency, jsonb_build_array(
    jsonb_build_object('account', app.courier_cash_account(v_user, null, v_currency), 'amount', p_amount_minor),
    jsonb_build_object('account', app.ledger_user_account('user_wallet', v_currency, v_client),
                       'amount', -p_amount_minor)),
    p_user => v_client);
  perform app.notify(v_client, 'cash_topup_received', 'payments', null, null,
    jsonb_build_object('amount_minor', p_amount_minor, 'currency_code', v_currency));
  perform app.emit_event('wallet_topped_up', v_client, 'client', 'server', v_courier.country_code, null, null,
    jsonb_build_object('amount_minor', p_amount_minor, 'provider', 'courier_cash'));
  return public.courier_earnings();
end
$fn$;

-- Équipe : cash remis par un livreur (recharges). Journalisé.
create or replace function public.admin_confirm_courier_cash(p_courier uuid, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_admin uuid := app.require_user();
  v_account record;
  v_owed bigint;
begin
  perform app.assert_admin(v_admin);
  select a.id, a.currency_code into v_account from public.ledger_accounts a
  where a.kind = 'courier_cash' and a.user_id = p_courier and a.store_id is null;
  v_owed := case when v_account.id is null then 0 else -app.ledger_balance(v_account.id) end;
  if v_owed <= 0 then raise exception 'nothing_owed' using errcode = 'P0001'; end if;
  perform app.ledger_post('courier_cash_remitted', 'remit:' || p_key, v_account.currency_code, jsonb_build_array(
    jsonb_build_object('account', v_account.id, 'amount', -v_owed),
    jsonb_build_object('account', app.ledger_account('platform_cash', v_account.currency_code), 'amount', v_owed)),
    p_user => p_courier);
  perform app.admin_did(v_admin, 'courier_cash_received', 'courier', p_courier::text, null,
    jsonb_build_object('amount_minor', v_owed), null,
    (select country_code from public.courier_profiles where user_id = p_courier));
  return jsonb_build_object('amount_minor', v_owed);
end
$fn$;

-- ------------------------------------------------------------------ retrait

-- Retrait du wallet (simulé : aucun versement réel tant que le flag est actif).
create or replace function public.wallet_withdraw_simulated(p_amount_minor bigint, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_country char(2) := (select country_code from public.profiles where user_id = v_user);
  v_currency char(3) := app.user_currency(v_user);
  v_wallet uuid;
begin
  if v_currency is null then raise exception 'profil incomplet' using errcode = 'P0002'; end if;
  if not app.feature_enabled('wallet_simulated_withdrawal', v_country) then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ledger_transactions where idempotency_key = 'withdraw:' || p_key) then
    return public.my_wallet();
  end if;
  if p_amount_minor is null or p_amount_minor <= 0 then
    raise exception 'wallet_amount_invalid' using errcode = 'P0001';
  end if;
  v_wallet := app.ledger_user_account('user_wallet', v_currency, v_user);
  -- Verrou sur le compte : deux retraits simultanés ne dépassent pas le solde.
  perform 1 from public.ledger_accounts where id = v_wallet for update;
  if app.ledger_balance(v_wallet) < p_amount_minor then
    raise exception 'wallet_insufficient' using errcode = 'P0001';
  end if;
  perform app.ledger_post('wallet_withdrawal', 'withdraw:' || p_key, v_currency, jsonb_build_array(
    jsonb_build_object('account', v_wallet, 'amount', p_amount_minor),
    jsonb_build_object('account', app.ledger_account('provider_clearing', v_currency), 'amount', -p_amount_minor)),
    p_user => v_user);
  perform app.emit_event('wallet_withdrawn', v_user, 'client', 'server', v_country, null, null,
    jsonb_build_object('amount_minor', p_amount_minor, 'provider', 'simulator'));
  return public.my_wallet();
end
$fn$;

insert into public.notification_templates (kind, locale, title, body) values
  ('courier_cash_confirmed', 'fr', 'Cash remis', '{store_name} confirme avoir reçu ton cash.'),
  ('courier_cash_confirmed', 'en', 'Cash handed over', '{store_name} confirms receiving your cash.'),
  ('cash_topup_received', 'fr', 'Wallet rechargé', 'Ta recharge en cash est sur ton wallet.'),
  ('cash_topup_received', 'en', 'Wallet topped up', 'Your cash top-up is in your wallet.')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('courier_earned', 'server', 'Course livrée par un livreur DYM (frais, cash)'),
  ('courier_cash_remitted', 'server', 'Cash du livreur confirmé par la boutique (montant)'),
  ('wallet_withdrawn', 'server', 'Retrait du wallet (montant, fournisseur)')
on conflict do nothing;

-- Suppression du compte (0039) : cash du livreur, courses en cours.
create or replace function app.account_deletion_blockers(p_user uuid) returns text[]
language sql stable security definer set search_path = ''
as $$
  select array_remove(array[
    case when exists (
      select 1 from public.ledger_accounts a
      where a.user_id = p_user and a.kind in ('user_wallet', 'user_pocket')
        and app.ledger_balance(a.id) <> 0) then 'wallet_balance' end,
    case when exists (
      select 1 from public.stores s
      join public.ledger_accounts a on a.store_id = s.id and a.kind = 'store_balance'
      where s.owner_id = p_user and app.ledger_balance(a.id) <> 0) then 'store_balance' end,
    case when exists (
      select 1 from public.orders o
      join public.purchases pu on pu.id = o.purchase_id
      left join public.stores s on s.id = o.store_id
      where (pu.user_id = p_user or s.owner_id = p_user)
        and o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery'))
      then 'orders_in_progress' end,
    case when exists (
      select 1 from public.stores s join public.orders o on o.store_id = s.id
      where s.owner_id = p_user) then 'store_history' end,
    case when exists (
      select 1 from public.spaces sp where sp.owner_id = p_user and app.space_pocket_balance(sp.id) <> 0)
      then 'space_balance' end,
    -- Livreur (spec 043) : cash encore dû, ou course en cours.
    case when exists (
      select 1 from public.ledger_accounts a
      where a.user_id = p_user and a.kind = 'courier_cash' and app.ledger_balance(a.id) <> 0)
      then 'courier_cash' end,
    case when exists (
      select 1 from public.order_couriers oc join public.orders o on o.id = oc.order_id
      where oc.courier_id = p_user and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery'))
      then 'courier_runs' end
  ], null)
$$;

-- Wallet (0032) : retrait simulé signalé.
create or replace function public.my_wallet() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_currency char(3);
  v_wallet uuid;
  v_country char(2);
begin
  if v_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  v_currency := app.user_currency(v_user);
  if v_currency is null then
    raise exception 'profil incomplet' using errcode = 'P0002';
  end if;
  select country_code into v_country from public.profiles where user_id = v_user;
  select id into v_wallet from public.ledger_accounts
  where kind = 'user_wallet' and user_id = v_user and currency_code = v_currency;
  return jsonb_build_object(
    'currency_code', v_currency,
    'balance_minor', case when v_wallet is null then 0 else app.ledger_balance(v_wallet) end,
    'simulated_topup', app.feature_enabled('wallet_simulated_topup', v_country),
    'simulated_withdrawal', app.feature_enabled('wallet_simulated_withdrawal', v_country),
    'pockets', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id, 'name', p.name, 'goal_minor', p.goal_minor, 'round_up_minor', p.round_up_minor,
        'reserved_for', p.reserved_for,
        'balance_minor', coalesce((select app.ledger_balance(a.id) from public.ledger_accounts a
                                   where a.kind = 'user_pocket' and a.pocket_id = p.id), 0))
        order by p.created_at)
      from public.wallet_pockets p
      where p.user_id = v_user and p.archived_at is null and p.currency_code = v_currency), '[]'::jsonb),
    'movements', coalesce((
      select jsonb_agg(m order by (m ->> 'occurred_at') desc) from (
        select jsonb_build_object(
          'id', t.id, 'kind', t.kind, 'order_id', t.order_id, 'occurred_at', t.occurred_at,
          'pocket_id', (select a.pocket_id from public.ledger_entries e
                        join public.ledger_accounts a on a.id = e.account_id
                        where e.transaction_id = t.id and a.kind = 'user_pocket' and a.user_id = v_user
                        limit 1),
          -- Vu du wallet principal ; sinon (poche à poche) vu de la poche d'origine.
          'amount_minor', coalesce(
            (select -sum(e.amount_minor) from public.ledger_entries e
             join public.ledger_accounts a on a.id = e.account_id
             where e.transaction_id = t.id and a.kind = 'user_wallet' and a.user_id = v_user),
            (select -sum(e.amount_minor) from public.ledger_entries e
             join public.ledger_accounts a on a.id = e.account_id
             where e.transaction_id = t.id and a.kind = 'user_pocket' and a.user_id = v_user
               and e.amount_minor > 0))) as m
        from public.ledger_transactions t
        where exists (
          select 1 from public.ledger_entries e
          join public.ledger_accounts a on a.id = e.account_id
          where e.transaction_id = t.id and a.user_id = v_user and a.currency_code = v_currency)
        order by t.occurred_at desc
        limit 30) x), '[]'::jsonb));
end
$$;


revoke all on function app.courier_cash_account(uuid, uuid, char), app.courier_money_on_order(),
  public.courier_earnings(), public.store_courier_cash(), public.confirm_courier_cash(uuid, uuid),
  public.cash_topup_code(), public.courier_cash_topup(text, bigint, uuid),
  public.admin_confirm_courier_cash(uuid, uuid), public.wallet_withdraw_simulated(bigint, uuid) from public;
grant execute on function public.courier_earnings(), public.store_courier_cash(), public.confirm_courier_cash(uuid, uuid),
  public.cash_topup_code(), public.courier_cash_topup(text, bigint, uuid),
  public.admin_confirm_courier_cash(uuid, uuid), public.wallet_withdraw_simulated(bigint, uuid) to authenticated;
