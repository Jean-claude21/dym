-- 0030 — Grand livre à double écriture (spec 024).
-- Chaque mouvement d'argent est une transaction équilibrée (somme des écritures nulle, une devise),
-- identifiée par une clé unique. Montant positif = débit. Écritures immuables ; écriture seulement
-- par les fonctions ci-dessous, jamais depuis une app.

-- ------------------------------------------------------------------ tables

create table public.ledger_accounts (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in (
    'platform_commission',  -- revenus de commission de DYM
    'provider_clearing',    -- argent chez les fournisseurs de paiement
    'customer_escrow',      -- argent des clientes détenu par DYM jusqu'à la livraison
    'store_balance'         -- ce que DYM doit à une boutique (négatif : ce qu'elle doit)
  )),
  store_id uuid references public.stores (id) on delete restrict,
  currency_code char(3) not null references public.currencies (code),
  created_at timestamptz not null default now(),
  check ((kind = 'store_balance') = (store_id is not null))
);
create unique index ledger_accounts_unique
  on public.ledger_accounts (kind, coalesce(store_id, '00000000-0000-0000-0000-000000000000'), currency_code);

create table public.ledger_transactions (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in (
    'payment_received', 'order_settled', 'cash_commission', 'refund_paid')),
  idempotency_key text not null unique,
  currency_code char(3) not null references public.currencies (code),
  purchase_id uuid references public.purchases (id) on delete restrict,
  order_id uuid references public.orders (id) on delete restrict,
  payment_id uuid references public.payments (id) on delete restrict,
  refund_id uuid references public.refunds (id) on delete restrict,
  occurred_at timestamptz not null default now()
);
create index ledger_transactions_purchase on public.ledger_transactions (purchase_id);
create index ledger_transactions_order on public.ledger_transactions (order_id);

create table public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.ledger_transactions (id) on delete restrict,
  account_id uuid not null references public.ledger_accounts (id) on delete restrict,
  amount_minor bigint not null check (amount_minor <> 0)
);
create index ledger_entries_account on public.ledger_entries (account_id);
create index ledger_entries_transaction on public.ledger_entries (transaction_id);

-- Lecture seulement par les fonctions : RLS sans politique, aucun droit direct.
alter table public.ledger_accounts enable row level security;
alter table public.ledger_transactions enable row level security;
alter table public.ledger_entries enable row level security;
revoke all on public.ledger_accounts, public.ledger_transactions, public.ledger_entries
  from authenticated, anonymous;

-- Immuable.
create or replace function app.ledger_immutable() returns trigger
language plpgsql as $$
begin
  raise exception 'ledger_immutable' using errcode = 'P0001';
end
$$;
create trigger ledger_entries_immutable before update or delete on public.ledger_entries
  for each row execute function app.ledger_immutable();
create trigger ledger_transactions_immutable before update or delete on public.ledger_transactions
  for each row execute function app.ledger_immutable();

-- Équilibre et devise, vérifiés en fin de transaction SQL.
create or replace function app.ledger_check_balanced() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if (select coalesce(sum(amount_minor), 0) from public.ledger_entries
      where transaction_id = new.transaction_id) <> 0 then
    raise exception 'ledger_unbalanced' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.ledger_entries e
    join public.ledger_accounts a on a.id = e.account_id
    join public.ledger_transactions t on t.id = e.transaction_id
    where e.transaction_id = new.transaction_id and a.currency_code <> t.currency_code) then
    raise exception 'ledger_currency_mismatch' using errcode = 'P0001';
  end if;
  return null;
end
$$;
create constraint trigger ledger_entries_balanced after insert on public.ledger_entries
  deferrable initially deferred for each row execute function app.ledger_check_balanced();

-- ------------------------------------------------------------------ écriture

create or replace function app.ledger_account(p_kind text, p_currency char(3), p_store uuid default null)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_id uuid;
begin
  select id into v_id from public.ledger_accounts
  where kind = p_kind and currency_code = p_currency and store_id is not distinct from p_store;
  if v_id is null then
    insert into public.ledger_accounts (kind, store_id, currency_code)
    values (p_kind, p_store, p_currency)
    on conflict do nothing
    returning id into v_id;
    if v_id is null then
      select id into v_id from public.ledger_accounts
      where kind = p_kind and currency_code = p_currency and store_id is not distinct from p_store;
    end if;
  end if;
  return v_id;
end
$$;

-- Écrit une transaction. p_entries : [{"account": uuid, "amount": bigint}] ; les montants nuls
-- sont ignorés. Rejeu de la même clé : la transaction existante est rendue, rien n'est écrit.
create or replace function app.ledger_post(
  p_kind text, p_key text, p_currency char(3), p_entries jsonb,
  p_purchase uuid default null, p_order uuid default null,
  p_payment uuid default null, p_refund uuid default null
) returns uuid
language plpgsql security definer set search_path = ''
as $$
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
    kind, idempotency_key, currency_code, purchase_id, order_id, payment_id, refund_id)
  values (p_kind, p_key, p_currency, p_purchase, p_order, p_payment, p_refund)
  returning id into v_id;
  insert into public.ledger_entries (transaction_id, account_id, amount_minor)
  select v_id, (e ->> 'account')::uuid, (e ->> 'amount')::bigint
  from jsonb_array_elements(p_entries) e
  where (e ->> 'amount')::bigint <> 0;
  return v_id;
end
$$;

-- ------------------------------------------------------------------ mouvements

-- Paiement en ligne réussi : l'argent arrive chez le fournisseur, détenu pour la cliente.
create or replace function app.ledger_payment_received(p_payment uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  p public.payments;
begin
  select * into p from public.payments where id = p_payment and status = 'succeeded';
  if p.id is null then return; end if;
  perform app.ledger_post('payment_received', 'payment:' || p.id, p.currency_code, jsonb_build_array(
    jsonb_build_object('account', app.ledger_account('provider_clearing', p.currency_code), 'amount', p.amount_minor),
    jsonb_build_object('account', app.ledger_account('customer_escrow', p.currency_code), 'amount', -p.amount_minor)),
    p_purchase => p.purchase_id, p_payment => p.id);
end
$$;

-- Commande payée en ligne et livrée : part boutique et commission.
create or replace function app.ledger_order_settled(p_order uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  o public.orders;
begin
  select o2.* into o from public.orders o2
  join public.purchases pu on pu.id = o2.purchase_id
  where o2.id = p_order and o2.status = 'delivered' and pu.payment_status = 'paid';
  if o.id is null then return; end if;
  perform app.ledger_post('order_settled', 'settled:' || o.id, o.currency_code, jsonb_build_array(
    jsonb_build_object('account', app.ledger_account('customer_escrow', o.currency_code), 'amount', o.total_minor),
    jsonb_build_object('account', app.ledger_account('store_balance', o.currency_code, o.store_id),
                       'amount', -(o.total_minor - o.commission_minor)),
    jsonb_build_object('account', app.ledger_account('platform_commission', o.currency_code),
                       'amount', -o.commission_minor)),
    p_purchase => o.purchase_id, p_order => o.id);
end
$$;

-- Cash encaissé par la vendeuse : elle doit la commission à DYM.
create or replace function app.ledger_cash_commission(p_order uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order and cash_collected_at is not null;
  if o.id is null or o.commission_minor = 0 then return; end if;
  perform app.ledger_post('cash_commission', 'cash:' || o.id, o.currency_code, jsonb_build_array(
    jsonb_build_object('account', app.ledger_account('store_balance', o.currency_code, o.store_id),
                       'amount', o.commission_minor),
    jsonb_build_object('account', app.ledger_account('platform_commission', o.currency_code),
                       'amount', -o.commission_minor)),
    p_purchase => o.purchase_id, p_order => o.id);
end
$$;

-- Remboursement en ligne réussi : avant livraison, depuis l'argent détenu ; après, depuis la
-- boutique. Un remboursement en cash ne passe pas par DYM.
create or replace function app.ledger_refund_paid(p_refund uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  r public.refunds;
  o public.orders;
  v_from uuid;
begin
  select * into r from public.refunds where id = p_refund and status = 'succeeded' and method = 'provider';
  if r.id is null then return; end if;
  select * into o from public.orders where id = r.order_id;
  v_from := case
    when exists (select 1 from public.ledger_transactions where idempotency_key = 'settled:' || o.id)
      then app.ledger_account('store_balance', r.currency_code, o.store_id)
    else app.ledger_account('customer_escrow', r.currency_code)
  end;
  perform app.ledger_post('refund_paid', 'refund:' || r.id, r.currency_code, jsonb_build_array(
    jsonb_build_object('account', v_from, 'amount', r.amount_minor),
    jsonb_build_object('account', app.ledger_account('provider_clearing', r.currency_code), 'amount', -r.amount_minor)),
    p_purchase => o.purchase_id, p_order => o.id, p_refund => r.id);
end
$$;

-- ------------------------------------------------------------------ déclencheurs

create or replace function app.ledger_on_payment() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.status = 'succeeded' and (tg_op = 'INSERT' or old.status is distinct from 'succeeded') then
    perform app.ledger_payment_received(new.id);
  end if;
  return null;
end
$$;
create trigger payments_ledger after insert or update of status on public.payments
  for each row execute function app.ledger_on_payment();

create or replace function app.ledger_on_order() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.status = 'delivered' and old.status is distinct from 'delivered' then
    perform app.ledger_order_settled(new.id);
  end if;
  if new.cash_collected_at is not null and old.cash_collected_at is null then
    perform app.ledger_cash_commission(new.id);
  end if;
  return null;
end
$$;
create trigger orders_ledger after update of status, cash_collected_at on public.orders
  for each row execute function app.ledger_on_order();

create or replace function app.ledger_on_refund() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.status = 'succeeded' and (tg_op = 'INSERT' or old.status is distinct from 'succeeded') then
    perform app.ledger_refund_paid(new.id);
  end if;
  return null;
end
$$;
create trigger refunds_ledger after insert or update of status on public.refunds
  for each row execute function app.ledger_on_refund();

-- ------------------------------------------------------------------ lectures

-- Solde de sa boutique (positif : DYM lui doit) et 20 derniers mouvements.
create or replace function public.my_store_balance() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_store public.stores;
begin
  select * into v_store from public.stores where owner_id = app.current_user_id();
  if v_store.id is null then
    raise exception 'aucune boutique' using errcode = 'P0002';
  end if;
  return jsonb_build_object(
    'currency_code', v_store.currency_code,
    'balance_minor', coalesce((
      select -sum(e.amount_minor) from public.ledger_entries e
      join public.ledger_accounts a on a.id = e.account_id
      where a.kind = 'store_balance' and a.store_id = v_store.id
        and a.currency_code = v_store.currency_code), 0),
    'movements', coalesce((
      select jsonb_agg(m order by m ->> 'occurred_at' desc) from (
        select jsonb_build_object('kind', t.kind, 'order_id', t.order_id,
                                  'amount_minor', -e.amount_minor, 'occurred_at', t.occurred_at) as m
        from public.ledger_entries e
        join public.ledger_accounts a on a.id = e.account_id
        join public.ledger_transactions t on t.id = e.transaction_id
        where a.kind = 'store_balance' and a.store_id = v_store.id
        order by t.occurred_at desc
        limit 20) x), '[]'::jsonb));
end
$$;

-- Contrôle des anomalies (admin) : argent détenu négatif sur un achat.
create or replace function public.admin_ledger_check() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not app.is_admin() then
    raise exception 'accès réservé aux admins' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('purchase_id', purchase_id, 'escrow_minor', escrow))
    from (
      select t.purchase_id, -sum(e.amount_minor) as escrow
      from public.ledger_entries e
      join public.ledger_accounts a on a.id = e.account_id and a.kind = 'customer_escrow'
      join public.ledger_transactions t on t.id = e.transaction_id
      where t.purchase_id is not null
      group by t.purchase_id
      having -sum(e.amount_minor) < 0) x), '[]'::jsonb);
end
$$;

revoke all on function public.my_store_balance(), public.admin_ledger_check() from public;
grant execute on function public.my_store_balance(), public.admin_ledger_check() to authenticated;

-- ------------------------------------------------------------------ reprise de l'historique

do $$
declare
  r record;
begin
  for r in select id from public.payments where status = 'succeeded' order by created_at loop
    perform app.ledger_payment_received(r.id);
  end loop;
  for r in select id from public.orders where status = 'delivered' order by delivered_at nulls first loop
    perform app.ledger_order_settled(r.id);
  end loop;
  for r in select id from public.orders where cash_collected_at is not null order by cash_collected_at loop
    perform app.ledger_cash_commission(r.id);
  end loop;
  for r in select id from public.refunds where status = 'succeeded' order by completed_at nulls first loop
    perform app.ledger_refund_paid(r.id);
  end loop;
end
$$;
