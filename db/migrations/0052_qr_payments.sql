-- 0052 — Paiement et encaissement par QR (spec 046).
-- La vendeuse crée une demande de paiement (montant, 10 minutes) : un QR et un code à 6 chiffres.
-- La cliente scanne ou tape le code, voit la boutique et le montant, paie depuis son wallet.
-- Grand livre : wallet de la cliente → solde de la boutique (commission du pays, 0 par défaut).
-- La vente apparaît dans « Ma caisse » (moyen « DYM »).

alter table public.countries add column qr_commission_bps integer not null default 0
  check (qr_commission_bps between 0 and 1000);

alter table public.store_sales drop constraint store_sales_method_check;
alter table public.store_sales add constraint store_sales_method_check
  check (method in ('cash', 'mobile_money', 'other', 'dym'));

alter table public.ledger_transactions drop constraint ledger_transactions_kind_check;
alter table public.ledger_transactions add constraint ledger_transactions_kind_check check (kind in (
  'payment_received', 'order_settled', 'cash_commission', 'refund_paid',
  'wallet_topup', 'wallet_transfer', 'cashback', 'space_contribution', 'space_payout', 'order_credit',
  'affiliate_commission', 'courier_fee', 'courier_cash', 'courier_cash_remitted', 'cash_topup',
  'wallet_withdrawal', 'store_payout',
  'qr_payment'            -- paiement par QR, du wallet vers la boutique
));

create table public.payment_requests (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  code char(6) not null check (code ~ '^[0-9]{6}$'),
  amount_minor bigint not null check (amount_minor > 0 and amount_minor <= 100000000),
  currency_code char(3) not null references public.currencies (code),
  label text check (label is null or length(label) <= 80),
  status text not null default 'open' check (status in ('open', 'paid', 'cancelled')),
  expires_at timestamptz not null,
  paid_by uuid references neon_auth."user" (id) on delete set null,
  paid_at timestamptz,
  idempotency_key uuid not null,
  -- Clé du paiement de la cliente (un seul paiement par envoi).
  pay_key uuid unique,
  created_at timestamptz not null default clock_timestamp(),
  unique (store_id, idempotency_key)
);
-- Un code n'est ouvert qu'une fois à la fois.
create unique index payment_requests_open_code on public.payment_requests (code) where status = 'open';
alter table public.payment_requests enable row level security;
revoke all on public.payment_requests from authenticated, anonymous;

create or replace function app.payment_request_json(p_id uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('id', r.id, 'code', r.code, 'qr', 'DYM-PAY:' || r.code,
    'amount_minor', r.amount_minor, 'currency_code', r.currency_code, 'label', r.label,
    'status', case when r.status = 'open' and r.expires_at < now() then 'expired' else r.status end,
    'expires_at', r.expires_at, 'paid_at', r.paid_at, 'store_name', s.name)
  from public.payment_requests r join public.stores s on s.id = r.store_id
  where r.id = p_id
$$;

-- Vendeuse : demande de paiement (une par clé), valable 10 minutes.
create or replace function public.create_payment_request(p_amount_minor bigint, p_key uuid, p_label text default null)
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store public.stores;
  v_id uuid;
  v_code text;
begin
  select * into v_store from public.stores where id = app.own_store_id();
  if v_store.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_store.status <> 'active' then raise exception 'store_inactive' using errcode = 'P0001'; end if;
  select id into v_id from public.payment_requests where store_id = v_store.id and idempotency_key = p_key;
  if v_id is not null then return app.payment_request_json(v_id); end if;
  if p_amount_minor is null or p_amount_minor <= 0 or p_amount_minor > 100000000 then
    raise exception 'invalid_amount' using errcode = '22023';
  end if;
  -- Les codes expirés se libèrent.
  update public.payment_requests set status = 'cancelled' where status = 'open' and expires_at < now();
  loop
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    begin
      insert into public.payment_requests (store_id, code, amount_minor, currency_code, label, expires_at, idempotency_key)
      values (v_store.id, v_code, p_amount_minor, v_store.currency_code, nullif(left(btrim(coalesce(p_label, '')), 80), ''),
              now() + interval '10 minutes', p_key)
      returning id into v_id;
      exit;
    exception when unique_violation then
      if exists (select 1 from public.payment_requests where store_id = v_store.id and idempotency_key = p_key) then
        return app.payment_request_json((select id from public.payment_requests
                                         where store_id = v_store.id and idempotency_key = p_key));
      end if;
    end;
  end loop;
  return app.payment_request_json(v_id);
end
$fn$;

-- Vendeuse : état de sa demande (l'écran attend « payé »).
create or replace function public.my_payment_request(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
begin
  if not exists (select 1 from public.payment_requests where id = p_id and store_id = app.own_store_id()) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  return app.payment_request_json(p_id);
end
$fn$;

create or replace function public.cancel_payment_request(p_id uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
begin
  update public.payment_requests set status = 'cancelled'
  where id = p_id and store_id = app.own_store_id() and status = 'open';
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  return app.payment_request_json(p_id);
end
$fn$;

-- Cliente : ce qu'elle va payer (code scanné « DYM-PAY:123456 » ou tapé).
create or replace function app.open_request_id(p_code text) returns uuid
language sql stable security definer set search_path = ''
as $$
  select id from public.payment_requests
  where code = regexp_replace(btrim(coalesce(p_code, '')), '^DYM-PAY:', '', 'i')
    and status = 'open' and expires_at > now()
$$;

create or replace function public.payment_request_preview(p_code text) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_id uuid := app.open_request_id(p_code);
begin
  perform app.require_user();
  if v_id is null then raise exception 'invalid_code' using errcode = 'P0001'; end if;
  return app.payment_request_json(v_id) - 'code' - 'qr';
end
$fn$;

-- Cliente : paiement depuis son wallet, une fois.
create or replace function public.pay_payment_request(p_code text, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_request public.payment_requests;
  v_store public.stores;
  v_wallet uuid;
  v_commission bigint;
begin
  select * into v_request from public.payment_requests where pay_key = p_key and paid_by = v_user;
  if v_request.id is not null then return app.payment_request_json(v_request.id) - 'code' - 'qr'; end if;
  select * into v_request from public.payment_requests where id = app.open_request_id(p_code) for update;
  if v_request.id is null or v_request.status <> 'open' then raise exception 'invalid_code' using errcode = 'P0001'; end if;
  select * into v_store from public.stores where id = v_request.store_id;
  if v_store.owner_id = v_user then raise exception 'own_store' using errcode = 'P0001'; end if;
  if app.user_currency(v_user) is distinct from v_request.currency_code then
    raise exception 'currency_mismatch' using errcode = 'P0001';
  end if;
  v_wallet := app.ledger_user_account('user_wallet', v_request.currency_code, v_user);
  perform 1 from public.ledger_accounts where id = v_wallet for update;
  if app.ledger_balance(v_wallet) < v_request.amount_minor then
    raise exception 'wallet_insufficient' using errcode = 'P0001';
  end if;
  v_commission := (v_request.amount_minor *
    (select qr_commission_bps from public.countries where code = v_store.country_code)) / 10000;
  perform app.ledger_post('qr_payment', 'qr:' || p_key, v_request.currency_code, jsonb_build_array(
    jsonb_build_object('account', v_wallet, 'amount', v_request.amount_minor),
    jsonb_build_object('account', app.ledger_account('store_balance', v_request.currency_code, v_store.id),
                       'amount', -(v_request.amount_minor - v_commission)),
    jsonb_build_object('account', app.ledger_account('platform_commission', v_request.currency_code),
                       'amount', -v_commission)),
    p_user => v_user);
  update public.payment_requests set status = 'paid', paid_by = v_user, paid_at = clock_timestamp(), pay_key = p_key
  where id = v_request.id;
  insert into public.store_sales (store_id, label, amount_minor, currency_code, method, idempotency_key)
  values (v_store.id, coalesce(v_request.label, 'QR ' || v_request.code), v_request.amount_minor,
          v_request.currency_code, 'dym', v_request.id);
  perform app.notify(v_store.owner_id, 'qr_paid', 'payments', null, null,
    jsonb_build_object('amount_minor', v_request.amount_minor, 'currency_code', v_request.currency_code));
  perform app.emit_event('qr_paid', v_user, 'client', 'server', v_store.country_code, 'store', v_store.id::text,
    jsonb_build_object('amount_minor', v_request.amount_minor));
  return app.payment_request_json(v_request.id) - 'code' - 'qr';
end
$fn$;

insert into public.notification_templates (kind, locale, title, body) values
  ('qr_paid', 'fr', 'Paiement reçu', 'Une cliente vient de payer par QR.'),
  ('qr_paid', 'en', 'Payment received', 'A customer just paid by QR.')
on conflict do nothing;

-- Notifications (0048) : paiement QR vers l'app vendeuse, cash confirmé vers l'app livreur.
create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor', 'review_received', 'support_replied_vendor', 'low_stock',
    'substitution_answered', 'freshness_claimed', 'incoming_call_vendor',
    'courier_out_for_delivery', 'courier_delivered', 'qr_paid')
    then 'vendor'
    when p_kind in ('mission_available', 'courier_cash_confirmed') then 'delivery'
    else 'client' end
$$;

insert into public.event_names (name, emitted_by, description) values
  ('qr_paid', 'server', 'Paiement par QR depuis le wallet (montant)')
on conflict do nothing;

revoke all on function app.payment_request_json(uuid), public.create_payment_request(bigint, uuid, text),
  public.my_payment_request(uuid), public.cancel_payment_request(uuid), app.open_request_id(text),
  public.payment_request_preview(text), public.pay_payment_request(text, uuid) from public;
grant execute on function public.create_payment_request(bigint, uuid, text), public.my_payment_request(uuid),
  public.cancel_payment_request(uuid), public.payment_request_preview(text), public.pay_payment_request(text, uuid)
  to authenticated;
