-- 0031 — Wallet et poches (spec 025), écrits dans le grand livre (0030).
-- Le wallet est un moyen de paiement « wallet » réglé en base à la commande : aucun service externe.
-- Poches illimitées à nom libre. Recharge simulée tant que le feature flag
-- `wallet_simulated_topup` est actif (à couper avant la production finale). Cashback configurable
-- par pays (aucune règle : aucun cashback).

-- ------------------------------------------------------------------ comptes du grand livre

create table public.wallet_pockets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 40),
  currency_code char(3) not null references public.currencies (code),
  goal_minor bigint check (goal_minor > 0),
  round_up_minor bigint check (round_up_minor > 0),
  reserved_for text check (reserved_for in ('preorder')),
  archived_at timestamptz,
  created_at timestamptz not null default now()
);
create index wallet_pockets_user on public.wallet_pockets (user_id) where archived_at is null;
alter table public.wallet_pockets enable row level security;
create policy wallet_pockets_own_read on public.wallet_pockets for select
  to authenticated using (user_id = app.current_user_id());
grant select on public.wallet_pockets to authenticated;

alter table public.ledger_accounts
  add column user_id uuid references neon_auth."user" (id) on delete restrict,
  add column pocket_id uuid references public.wallet_pockets (id) on delete restrict;
alter table public.ledger_accounts drop constraint ledger_accounts_kind_check;
alter table public.ledger_accounts add constraint ledger_accounts_kind_check check (kind in (
  'platform_commission', 'provider_clearing', 'customer_escrow', 'store_balance',
  'user_wallet',          -- solde principal d'une personne
  'user_pocket',          -- une poche
  'platform_promotions'   -- cashback financé par DYM
));
alter table public.ledger_accounts drop constraint ledger_accounts_check;
alter table public.ledger_accounts add constraint ledger_accounts_owner_check check (
  (kind = 'store_balance') = (store_id is not null)
  and (kind in ('user_wallet', 'user_pocket')) = (user_id is not null)
  and (kind = 'user_pocket') = (pocket_id is not null));
drop index public.ledger_accounts_unique;
create unique index ledger_accounts_unique on public.ledger_accounts (
  kind,
  coalesce(store_id, '00000000-0000-0000-0000-000000000000'),
  coalesce(user_id, '00000000-0000-0000-0000-000000000000'),
  coalesce(pocket_id, '00000000-0000-0000-0000-000000000000'),
  currency_code);

alter table public.ledger_transactions drop constraint ledger_transactions_kind_check;
alter table public.ledger_transactions add constraint ledger_transactions_kind_check check (kind in (
  'payment_received', 'order_settled', 'cash_commission', 'refund_paid',
  'wallet_topup', 'wallet_transfer', 'cashback'));
alter table public.ledger_transactions add column user_id uuid references neon_auth."user" (id) on delete restrict;
create index ledger_transactions_user on public.ledger_transactions (user_id);

-- ledger_post reçoit la personne concernée (écritures immuables : renseignée à la création).
drop function app.ledger_post(text, text, char, jsonb, uuid, uuid, uuid, uuid);
create function app.ledger_post(
  p_kind text, p_key text, p_currency char(3), p_entries jsonb,
  p_purchase uuid default null, p_order uuid default null,
  p_payment uuid default null, p_refund uuid default null, p_user uuid default null
) returns uuid
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_id uuid;
begin
  select id into v_id from public.ledger_transactions where idempotency_key = p_key;
  if v_id is not null then
    return v_id;
  end if;
  if not exists (select 1 from jsonb_array_elements(p_entries) e where (e ->> 'amount')::bigint <> 0) then
    return null;
  end if;
  insert into public.ledger_transactions (
    kind, idempotency_key, currency_code, purchase_id, order_id, payment_id, refund_id, user_id)
  values (p_kind, p_key, p_currency, p_purchase, p_order, p_payment, p_refund, p_user)
  returning id into v_id;
  insert into public.ledger_entries (transaction_id, account_id, amount_minor)
  select v_id, (e ->> 'account')::uuid, (e ->> 'amount')::bigint
  from jsonb_array_elements(p_entries) e
  where (e ->> 'amount')::bigint <> 0;
  return v_id;
end
$fn$;

create or replace function app.ledger_user_account(
  p_kind text, p_currency char(3), p_user uuid, p_pocket uuid default null)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_id uuid;
begin
  select id into v_id from public.ledger_accounts
  where kind = p_kind and currency_code = p_currency and user_id = p_user
    and pocket_id is not distinct from p_pocket;
  if v_id is null then
    insert into public.ledger_accounts (kind, user_id, pocket_id, currency_code)
    values (p_kind, p_user, p_pocket, p_currency)
    on conflict do nothing
    returning id into v_id;
    if v_id is null then
      select id into v_id from public.ledger_accounts
      where kind = p_kind and currency_code = p_currency and user_id = p_user
        and pocket_id is not distinct from p_pocket;
    end if;
  end if;
  return v_id;
end
$$;

-- Solde d'un compte (positif : argent détenu par la personne).
create or replace function app.ledger_balance(p_account uuid) returns bigint
language sql stable security definer set search_path = ''
as $$
  select coalesce(-sum(amount_minor), 0)::bigint from public.ledger_entries where account_id = p_account
$$;

-- Devise de la personne : celle du pays de son profil.
create or replace function app.user_currency(p_user uuid) returns char(3)
language sql stable security definer set search_path = ''
as $$
  select c.currency_code from public.profiles p
  join public.countries c on c.code = p.country_code
  where p.user_id = p_user
$$;

-- ------------------------------------------------------------------ référentiel

alter table public.payment_providers drop constraint payment_providers_kind_check;
alter table public.payment_providers add constraint payment_providers_kind_check
  check (kind in ('cash', 'mobile_money', 'card', 'digital', 'wallet'));
insert into public.payment_providers (code, label, kind) values
  ('wallet', '{"fr": "Wallet DYM", "en": "DYM Wallet"}', 'wallet')
on conflict (code) do nothing;
insert into public.payment_methods (country_code, provider_code, operator_code, label, sort, is_active)
select c.code, 'wallet', null, '{"fr": "Wallet DYM", "en": "DYM Wallet"}', 10, true
from public.countries c
where not exists (select 1 from public.payment_methods m
                  where m.country_code = c.code and m.provider_code = 'wallet');

create table public.cashback_rules (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries (code),
  rate_bps integer not null check (rate_bps between 0 and 10000),
  valid_from timestamptz not null default now(),
  valid_to timestamptz,
  created_at timestamptz not null default now()
);
alter table public.cashback_rules enable row level security;
create policy cashback_rules_read on public.cashback_rules for select to authenticated, anonymous using (true);
grant select on public.cashback_rules to authenticated, anonymous;

insert into public.feature_flags (key, country_code, is_enabled, description)
select 'wallet_simulated_topup', null, true,
       'Recharge simulée du wallet (tests) ; à couper avant la production finale'
where not exists (select 1 from public.feature_flags where key = 'wallet_simulated_topup');

insert into public.event_names (name, emitted_by, description) values
  ('wallet_topped_up', 'server', 'Recharge du wallet (montant, fournisseur)'),
  ('wallet_payment_succeeded', 'server', 'Commande payée avec le wallet'),
  ('pocket_created', 'server', 'Poche créée (objectif, arrondi)')
on conflict do nothing;

-- Toute boutique accepte le wallet : rail interne de DYM, réglé comme un paiement en ligne.
create or replace function app.ensure_wallet_accepted() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  -- Sa propre insertion ne le relance pas.
  if pg_trigger_depth() > 1 then
    return null;
  end if;
  insert into public.store_payment_methods (store_id, payment_method_id)
  select s.id, m.id
  from public.stores s
  join public.payment_methods m on m.country_code = s.country_code and m.provider_code = 'wallet'
  where s.country_code is not null
  on conflict do nothing;
  return null;
end
$$;
create trigger store_payment_methods_wallet after insert on public.store_payment_methods
  for each statement execute function app.ensure_wallet_accepted();
create trigger stores_wallet after insert or update of country_code on public.stores
  for each statement execute function app.ensure_wallet_accepted();
insert into public.store_payment_methods (store_id, payment_method_id)
select s.id, m.id from public.stores s
join public.payment_methods m on m.country_code = s.country_code and m.provider_code = 'wallet'
on conflict do nothing;

-- ------------------------------------------------------------------ grand livre : wallet

-- Paiement reçu : depuis le wallet de la cliente, ou depuis le fournisseur.
create or replace function app.ledger_payment_received(p_payment uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  p public.payments;
  v_user uuid;
  v_from uuid;
begin
  select * into p from public.payments where id = p_payment and status = 'succeeded';
  if p.id is null then return; end if;
  select user_id into v_user from public.purchases where id = p.purchase_id;
  v_from := case when p.provider_code = 'wallet'
    then app.ledger_user_account('user_wallet', p.currency_code, v_user)
    else app.ledger_account('provider_clearing', p.currency_code) end;
  perform app.ledger_post('payment_received', 'payment:' || p.id, p.currency_code, jsonb_build_array(
    jsonb_build_object('account', v_from, 'amount', p.amount_minor),
    jsonb_build_object('account', app.ledger_account('customer_escrow', p.currency_code), 'amount', -p.amount_minor)),
    p_purchase => p.purchase_id, p_payment => p.id);
end
$$;

-- Remboursement : rendu au wallet si le paiement venait du wallet.
create or replace function app.ledger_refund_paid(p_refund uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  r public.refunds;
  o public.orders;
  v_payment public.payments;
  v_from uuid;
  v_to uuid;
begin
  select * into r from public.refunds where id = p_refund and status = 'succeeded' and method = 'provider';
  if r.id is null then return; end if;
  select * into o from public.orders where id = r.order_id;
  select * into v_payment from public.payments where purchase_id = o.purchase_id and status = 'succeeded';
  v_from := case
    when exists (select 1 from public.ledger_transactions where idempotency_key = 'settled:' || o.id)
      then app.ledger_account('store_balance', r.currency_code, o.store_id)
    else app.ledger_account('customer_escrow', r.currency_code)
  end;
  v_to := case when v_payment.provider_code = 'wallet'
    then app.ledger_user_account('user_wallet', r.currency_code,
                                 (select user_id from public.purchases where id = o.purchase_id))
    else app.ledger_account('provider_clearing', r.currency_code) end;
  perform app.ledger_post('refund_paid', 'refund:' || r.id, r.currency_code, jsonb_build_array(
    jsonb_build_object('account', v_from, 'amount', r.amount_minor),
    jsonb_build_object('account', v_to, 'amount', -r.amount_minor)),
    p_purchase => o.purchase_id, p_order => o.id, p_refund => r.id);
end
$$;

-- Cashback : crédité au wallet quand la commande est réglée (en ligne) ou encaissée (cash).
create or replace function app.ledger_cashback(p_order uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  o public.orders;
  v_user uuid;
  v_country char(2);
  v_rate integer;
  v_amount bigint;
begin
  select * into o from public.orders where id = p_order;
  select pu.user_id, pu.country_code into v_user, v_country from public.purchases pu where pu.id = o.purchase_id;
  select rate_bps into v_rate from public.cashback_rules
  where country_code = v_country and valid_from <= now() and (valid_to is null or valid_to > now())
  order by valid_from desc limit 1;
  v_amount := floor(o.subtotal_minor * coalesce(v_rate, 0) / 10000.0);
  if v_amount <= 0 then return; end if;
  perform app.ledger_post('cashback', 'cashback:' || o.id, o.currency_code, jsonb_build_array(
    jsonb_build_object('account', app.ledger_account('platform_promotions', o.currency_code), 'amount', v_amount),
    jsonb_build_object('account', app.ledger_user_account('user_wallet', o.currency_code, v_user), 'amount', -v_amount)),
    p_purchase => o.purchase_id, p_order => o.id);
end
$$;

create or replace function app.ledger_on_order() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.status = 'delivered' and old.status is distinct from 'delivered' then
    perform app.ledger_order_settled(new.id);
    if exists (select 1 from public.purchases where id = new.purchase_id and payment_status = 'paid') then
      perform app.ledger_cashback(new.id);
    end if;
  end if;
  if new.cash_collected_at is not null and old.cash_collected_at is null then
    perform app.ledger_cash_commission(new.id);
    perform app.ledger_cashback(new.id);
  end if;
  return null;
end
$$;

-- ------------------------------------------------------------------ paiement par wallet

-- Un paiement « wallet » est réglé dès sa création, dans la transaction de la commande :
-- solde insuffisant = commande refusée. Puis arrondis vers les poches qui le demandent.
create or replace function app.wallet_settle_payment() returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid;
  v_country char(2);
  v_wallet uuid;
  v_pocket record;
  v_round bigint;
begin
  if new.provider_code <> 'wallet' or new.status <> 'pending' then
    return null;
  end if;
  select user_id, country_code into v_user, v_country from public.purchases where id = new.purchase_id;
  perform pg_advisory_xact_lock(hashtext('wallet:' || v_user));
  v_wallet := app.ledger_user_account('user_wallet', new.currency_code, v_user);
  if app.ledger_balance(v_wallet) < new.amount_minor then
    raise exception 'wallet_insufficient' using errcode = 'P0001';
  end if;
  perform app.apply_payment_event('wallet', 'wallet:' || new.id, '{}'::jsonb, true, new.id, 'succeeded',
                                  new.amount_minor, new.currency_code);
  perform app.emit_event('wallet_payment_succeeded', v_user, 'client', 'server', v_country,
                         'payment', new.id::text, jsonb_build_object('amount_minor', new.amount_minor));
  for v_pocket in
    select id, round_up_minor from public.wallet_pockets
    where user_id = v_user and currency_code = new.currency_code
      and archived_at is null and round_up_minor is not null
    order by created_at
  loop
    v_round := (v_pocket.round_up_minor - new.amount_minor % v_pocket.round_up_minor) % v_pocket.round_up_minor;
    if v_round > 0 and app.ledger_balance(v_wallet) >= v_round then
      perform app.ledger_post('wallet_transfer', 'roundup:' || new.id || ':' || v_pocket.id, new.currency_code,
        jsonb_build_array(
          jsonb_build_object('account', v_wallet, 'amount', v_round),
          jsonb_build_object('account', app.ledger_user_account('user_pocket', new.currency_code, v_user, v_pocket.id),
                             'amount', -v_round)),
        p_payment => new.id);
    end if;
  end loop;
  return null;
end
$$;
create trigger payments_wallet after insert on public.payments
  for each row execute function app.wallet_settle_payment();

-- ------------------------------------------------------------------ actions de la personne

-- Recharge simulée (tests) : refusée si le flag est coupé pour le pays.
create or replace function public.wallet_topup_simulated(p_amount_minor bigint, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_country char(2);
  v_currency char(3);
begin
  if v_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  select country_code into v_country from public.profiles where user_id = v_user;
  v_currency := app.user_currency(v_user);
  if v_currency is null then
    raise exception 'profil incomplet' using errcode = 'P0002';
  end if;
  if not app.feature_enabled('wallet_simulated_topup', v_country) then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  if p_amount_minor is null or p_amount_minor <= 0 or p_amount_minor > 100000000 then
    raise exception 'wallet_amount_invalid' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.ledger_transactions where idempotency_key = 'topup:' || p_key) then
    perform app.ledger_post('wallet_topup', 'topup:' || p_key, v_currency, jsonb_build_array(
      jsonb_build_object('account', app.ledger_account('provider_clearing', v_currency), 'amount', p_amount_minor),
      jsonb_build_object('account', app.ledger_user_account('user_wallet', v_currency, v_user), 'amount', -p_amount_minor)),
      p_user => v_user);
    perform app.emit_event('wallet_topped_up', v_user, 'client', 'server', v_country, null, null,
                           jsonb_build_object('amount_minor', p_amount_minor, 'provider', 'simulator'));
  end if;
  return public.my_wallet();
end
$$;

create or replace function public.create_pocket(
  p_name text, p_goal_minor bigint default null, p_round_up_minor bigint default null,
  p_reserved_for text default null) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_currency char(3);
  v_id uuid;
begin
  if v_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  v_currency := app.user_currency(v_user);
  if v_currency is null then
    raise exception 'profil incomplet' using errcode = 'P0002';
  end if;
  if (select count(*) from public.wallet_pockets where user_id = v_user and archived_at is null) >= 50 then
    raise exception 'pocket_limit' using errcode = 'P0001';
  end if;
  insert into public.wallet_pockets (user_id, name, currency_code, goal_minor, round_up_minor, reserved_for)
  values (v_user, btrim(p_name), v_currency, p_goal_minor, p_round_up_minor, p_reserved_for)
  returning id into v_id;
  perform app.emit_event('pocket_created', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'pocket', v_id::text,
    jsonb_build_object('has_goal', p_goal_minor is not null, 'round_up', p_round_up_minor is not null));
  return public.my_wallet();
end
$$;

create or replace function public.update_pocket(
  p_pocket uuid, p_name text, p_goal_minor bigint default null, p_round_up_minor bigint default null)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
begin
  update public.wallet_pockets
  set name = btrim(p_name), goal_minor = p_goal_minor, round_up_minor = p_round_up_minor
  where id = p_pocket and user_id = app.current_user_id() and archived_at is null;
  if not found then
    raise exception 'poche introuvable' using errcode = 'P0002';
  end if;
  return public.my_wallet();
end
$$;

-- Déplace de l'argent entre le wallet (null) et une poche, ou entre deux poches.
create or replace function public.wallet_transfer(
  p_from_pocket uuid, p_to_pocket uuid, p_amount_minor bigint, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_currency char(3);
  v_from uuid;
  v_to uuid;
begin
  if v_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  v_currency := app.user_currency(v_user);
  if p_amount_minor is null or p_amount_minor <= 0 or p_from_pocket is not distinct from p_to_pocket then
    raise exception 'wallet_amount_invalid' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from unnest(array[p_from_pocket, p_to_pocket]) x(id)
    where x.id is not null and not exists (
      select 1 from public.wallet_pockets p
      where p.id = x.id and p.user_id = v_user and p.archived_at is null and p.currency_code = v_currency)) then
    raise exception 'poche introuvable' using errcode = 'P0002';
  end if;
  perform pg_advisory_xact_lock(hashtext('wallet:' || v_user));
  v_from := case when p_from_pocket is null then app.ledger_user_account('user_wallet', v_currency, v_user)
                 else app.ledger_user_account('user_pocket', v_currency, v_user, p_from_pocket) end;
  v_to := case when p_to_pocket is null then app.ledger_user_account('user_wallet', v_currency, v_user)
               else app.ledger_user_account('user_pocket', v_currency, v_user, p_to_pocket) end;
  if not exists (select 1 from public.ledger_transactions where idempotency_key = 'transfer:' || p_key) then
    if app.ledger_balance(v_from) < p_amount_minor then
      raise exception 'wallet_insufficient' using errcode = 'P0001';
    end if;
    perform app.ledger_post('wallet_transfer', 'transfer:' || p_key, v_currency, jsonb_build_array(
      jsonb_build_object('account', v_from, 'amount', p_amount_minor),
      jsonb_build_object('account', v_to, 'amount', -p_amount_minor)),
      p_user => v_user);
  end if;
  return public.my_wallet();
end
$$;

-- Archive une poche ; son solde revient au wallet.
create or replace function public.archive_pocket(p_pocket uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_pocket public.wallet_pockets;
  v_balance bigint;
begin
  select * into v_pocket from public.wallet_pockets
  where id = p_pocket and user_id = v_user and archived_at is null;
  if v_pocket.id is null then
    raise exception 'poche introuvable' using errcode = 'P0002';
  end if;
  perform pg_advisory_xact_lock(hashtext('wallet:' || v_user));
  v_balance := app.ledger_balance(app.ledger_user_account('user_pocket', v_pocket.currency_code, v_user, v_pocket.id));
  if v_balance > 0 then
    perform app.ledger_post('wallet_transfer', 'archive:' || v_pocket.id, v_pocket.currency_code, jsonb_build_array(
      jsonb_build_object('account', app.ledger_user_account('user_pocket', v_pocket.currency_code, v_user, v_pocket.id),
                         'amount', v_balance),
      jsonb_build_object('account', app.ledger_user_account('user_wallet', v_pocket.currency_code, v_user),
                         'amount', -v_balance)));
  end if;
  update public.wallet_pockets set archived_at = now() where id = v_pocket.id;
  return public.my_wallet();
end
$$;

-- Mon wallet : solde, poches et 30 derniers mouvements.
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
          'id', e.id, 'kind', t.kind, 'pocket_id', a.pocket_id, 'order_id', t.order_id,
          'amount_minor', -e.amount_minor, 'occurred_at', t.occurred_at) as m
        from public.ledger_entries e
        join public.ledger_accounts a on a.id = e.account_id
        join public.ledger_transactions t on t.id = e.transaction_id
        where a.user_id = v_user and a.currency_code = v_currency
        order by t.occurred_at desc
        limit 30) x), '[]'::jsonb));
end
$$;

revoke all on function
  public.wallet_topup_simulated(bigint, uuid), public.create_pocket(text, bigint, bigint, text),
  public.update_pocket(uuid, text, bigint, bigint), public.wallet_transfer(uuid, uuid, bigint, uuid),
  public.archive_pocket(uuid), public.my_wallet()
from public;
grant execute on function
  public.wallet_topup_simulated(bigint, uuid), public.create_pocket(text, bigint, bigint, text),
  public.update_pocket(uuid, text, bigint, bigint), public.wallet_transfer(uuid, uuid, bigint, uuid),
  public.archive_pocket(uuid), public.my_wallet()
to authenticated;
