-- 0051 — Caisse de la vendeuse (spec 045, VISION §3 « Vendeuse » : caisse en app et hors app, à
-- la voix ; « Ma caisse » : gains et versements).
-- 1. Ventes hors app : libellé, montant, moyen (cash, mobile money, autre), produit facultatif
--    (stock suivi décompté) ; saisies à la main ou dictées (transcription existante, lecture du
--    montant en base selon les décimales de la devise) ; annulables le jour même.
-- 2. « Ma caisse » : ventes du jour en app et hors app, par moyen ; solde chez DYM ; versements.
-- 3. Versement du solde vers le fournisseur : simulé tant que le versement réel n'est pas branché
--    (flag `store_simulated_payout`, décision 0015).

create table public.store_sales (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  label text not null check (length(btrim(label)) between 1 and 120),
  variant_id uuid references public.product_variants (id) on delete set null,
  quantity smallint not null default 1 check (quantity between 1 and 999),
  amount_minor bigint not null check (amount_minor > 0 and amount_minor <= 100000000),
  currency_code char(3) not null references public.currencies (code),
  method text not null check (method in ('cash', 'mobile_money', 'other')),
  idempotency_key uuid not null,
  sold_at timestamptz not null default clock_timestamp(),
  voided_at timestamptz,
  created_by uuid references neon_auth."user" (id) on delete set null,
  unique (store_id, idempotency_key)
);
create index store_sales_store on public.store_sales (store_id, sold_at desc);
alter table public.store_sales enable row level security;
revoke all on public.store_sales from authenticated, anonymous;

alter table public.ledger_transactions drop constraint ledger_transactions_kind_check;
alter table public.ledger_transactions add constraint ledger_transactions_kind_check check (kind in (
  'payment_received', 'order_settled', 'cash_commission', 'refund_paid',
  'wallet_topup', 'wallet_transfer', 'cashback', 'space_contribution', 'space_payout', 'order_credit',
  'affiliate_commission', 'courier_fee', 'courier_cash', 'courier_cash_remitted', 'cash_topup',
  'wallet_withdrawal',
  'store_payout'          -- versement du solde de la boutique vers le fournisseur
));

insert into public.feature_flags (key, country_code, is_enabled, description)
select 'store_simulated_payout', null, true,
  'Versement du solde des boutiques simulé (aucun versement réel) — à couper avant la production finale'
where not exists (select 1 from public.feature_flags where key = 'store_simulated_payout');

-- Texte dicté ou tapé (« 3 tas de tomates 1500 ») : dernier nombre = montant en unités
-- principales, le reste = libellé ; produit de la boutique reconnu par son nom.
create or replace function public.till_parse(p_text text) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_store uuid := app.own_store_id();
  v_text text := btrim(regexp_replace(coalesce(p_text, ''), '\s+', ' ', 'g'));
  v_number text;
  v_units smallint;
  v_amount bigint;
  v_label text;
  v_quantity int;
  v_variant uuid;
begin
  if v_store is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  select cu.minor_units into v_units from public.stores s join public.currencies cu on cu.code = s.currency_code
  where s.id = v_store;
  -- Dernier nombre (« 1 500 », « 1500 », « 12,50 »), suivi ou non de la monnaie.
  v_number := (regexp_match(v_text, '([0-9][0-9 .]*(?:,[0-9]{1,3})?)\s*(?:fcfa|francs?|cfa|f|ghs|cedis?)?\.?$', 'i'))[1];
  if v_number is not null then
    v_label := btrim(regexp_replace(v_text, '([0-9][0-9 .]*(?:,[0-9]{1,3})?)\s*(?:fcfa|francs?|cfa|f|ghs|cedis?)?\.?$', '', 'i'));
    v_number := regexp_replace(btrim(v_number), '[ .]', '', 'g');
    v_amount := round(replace(v_number, ',', '.')::numeric * power(10, v_units))::bigint;
  else
    v_label := v_text;
  end if;
  v_quantity := coalesce((regexp_match(v_label, '^([0-9]{1,3})\s'))[1]::int, 1);
  select v.id into v_variant
  from public.products p join public.product_variants v on v.product_id = p.id
  where p.store_id = v_store and p.status = 'published' and length(p.name) >= 3
    and lower(v_label) like '%' || lower(p.name) || '%'
  order by length(p.name) desc, v.sort limit 1;
  return jsonb_build_object('label', nullif(v_label, ''), 'amount_minor', v_amount,
    'quantity', least(greatest(v_quantity, 1), 999), 'variant_id', v_variant);
end
$fn$;

-- Vente hors app enregistrée (une fois par clé) ; stock suivi décompté si produit reconnu.
create or replace function public.record_till_sale(
  p_label text, p_amount_minor bigint, p_method text, p_key uuid,
  p_variant uuid default null, p_quantity int default 1) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store public.stores;
  v_id uuid;
begin
  select * into v_store from public.stores where id = app.own_store_id();
  if v_store.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  select id into v_id from public.store_sales where store_id = v_store.id and idempotency_key = p_key;
  if v_id is not null then return public.my_till(); end if;
  if p_amount_minor is null or p_amount_minor <= 0 or p_amount_minor > 100000000 then
    raise exception 'invalid_amount' using errcode = '22023';
  end if;
  if p_method is null or p_method not in ('cash', 'mobile_money', 'other') then
    raise exception 'invalid_method' using errcode = '22023';
  end if;
  if length(btrim(coalesce(p_label, ''))) = 0 then raise exception 'invalid_label' using errcode = '22023'; end if;
  if p_variant is not null and not exists (
      select 1 from public.product_variants v join public.products p on p.id = v.product_id
      where v.id = p_variant and p.store_id = v_store.id) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  insert into public.store_sales (store_id, label, variant_id, quantity, amount_minor, currency_code, method,
    idempotency_key, created_by)
  values (v_store.id, left(btrim(p_label), 120), p_variant, least(greatest(coalesce(p_quantity, 1), 1), 999),
    p_amount_minor, v_store.currency_code, p_method, p_key, app.current_user_id())
  returning id into v_id;
  if p_variant is not null then
    update public.product_variants set stock_quantity = greatest(stock_quantity - least(greatest(coalesce(p_quantity, 1), 1), 999), 0)
    where id = p_variant and stock_quantity is not null;
  end if;
  perform app.emit_event('till_sale_recorded', app.current_user_id(), 'vendor', 'server', v_store.country_code,
    'store', v_store.id::text, jsonb_build_object('amount_minor', p_amount_minor, 'method', p_method,
      'with_product', p_variant is not null));
  return public.my_till();
end
$fn$;

-- Annulation le jour même (erreur de saisie) ; le stock décompté revient.
create or replace function public.void_till_sale(p_sale uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_sale public.store_sales;
begin
  update public.store_sales set voided_at = clock_timestamp()
  where id = p_sale and store_id = app.own_store_id() and voided_at is null
    and sold_at > now() - interval '24 hours'
  returning * into v_sale;
  if v_sale.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_sale.variant_id is not null then
    update public.product_variants set stock_quantity = stock_quantity + v_sale.quantity
    where id = v_sale.variant_id and stock_quantity is not null;
  end if;
  return public.my_till();
end
$fn$;

-- « Ma caisse » : jour (fuseau du pays), par moyen ; solde chez DYM ; ventes et versements récents.
create or replace function public.my_till() returns jsonb
language sql stable security definer set search_path = ''
as $$
  with s as (select st.*, c.timezone from public.stores st join public.countries c on c.code = st.country_code
             where st.id = app.own_store_id()),
  day as (select (now() at time zone (select timezone from s))::date as d),
  sales as (select * from public.store_sales where store_id = (select id from s) and voided_at is null
            and (sold_at at time zone (select timezone from s))::date = (select d from day)),
  app_orders as (select o.* from public.orders o where o.store_id = (select id from s) and o.status = 'delivered'
                 and (o.delivered_at at time zone (select timezone from s))::date = (select d from day)),
  balance as (select coalesce((select app.ledger_balance(a.id) from public.ledger_accounts a
                               where a.kind = 'store_balance' and a.store_id = (select id from s)
                                 and a.currency_code = (select currency_code from s)), 0) as b)
  select case when (select id from s) is null then null else jsonb_build_object(
    'currency_code', (select currency_code from s),
    'today_app_minor', coalesce((select sum(subtotal_minor) from app_orders), 0),
    'today_app_count', (select count(*) from app_orders),
    'today_off_app_minor', coalesce((select sum(amount_minor) from sales), 0),
    'today_off_app_count', (select count(*) from sales),
    'today_by_method', coalesce((select jsonb_object_agg(method, total) from
                                  (select method, sum(amount_minor) as total from sales group by method) m), '{}'::jsonb),
    'balance_minor', (select b from balance),
    'simulated_payout', app.feature_enabled('store_simulated_payout', (select country_code from s)),
    'sales', coalesce((select jsonb_agg(jsonb_build_object('id', x.id, 'label', x.label, 'quantity', x.quantity,
        'amount_minor', x.amount_minor, 'method', x.method, 'sold_at', x.sold_at,
        'voided', x.voided_at is not null) order by x.sold_at desc)
      from (select * from public.store_sales where store_id = (select id from s)
            order by sold_at desc limit 30) x), '[]'::jsonb),
    'payouts', coalesce((select jsonb_agg(jsonb_build_object('amount_minor', e.amount_minor, 'at', t.occurred_at)
        order by t.occurred_at desc)
      from public.ledger_transactions t
      join public.ledger_entries e on e.transaction_id = t.id
      join public.ledger_accounts a on a.id = e.account_id and a.kind = 'store_balance' and a.store_id = (select id from s)
      where t.kind = 'store_payout'), '[]'::jsonb))
  end
$$;

-- Versement du solde (simulé) : jamais plus que le solde.
create or replace function public.store_payout_simulated(p_amount_minor bigint, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store public.stores;
  v_account uuid;
begin
  select * into v_store from public.stores where id = app.own_store_id();
  if v_store.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if not app.feature_enabled('store_simulated_payout', v_store.country_code) then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ledger_transactions where idempotency_key = 'store-payout:' || p_key) then
    return public.my_till();
  end if;
  if p_amount_minor is null or p_amount_minor <= 0 then raise exception 'invalid_amount' using errcode = '22023'; end if;
  v_account := app.ledger_account('store_balance', v_store.currency_code, v_store.id);
  perform 1 from public.ledger_accounts where id = v_account for update;
  if app.ledger_balance(v_account) < p_amount_minor then
    raise exception 'balance_insufficient' using errcode = 'P0001';
  end if;
  perform app.ledger_post('store_payout', 'store-payout:' || p_key, v_store.currency_code, jsonb_build_array(
    jsonb_build_object('account', v_account, 'amount', p_amount_minor),
    jsonb_build_object('account', app.ledger_account('provider_clearing', v_store.currency_code),
                       'amount', -p_amount_minor)));
  perform app.emit_event('store_paid_out', app.current_user_id(), 'vendor', 'server', v_store.country_code,
    'store', v_store.id::text, jsonb_build_object('amount_minor', p_amount_minor, 'provider', 'simulator'));
  return public.my_till();
end
$fn$;

insert into public.event_names (name, emitted_by, description) values
  ('till_sale_recorded', 'server', 'Vente hors app enregistrée (montant, moyen, produit reconnu)'),
  ('store_paid_out', 'server', 'Versement du solde de la boutique (montant, fournisseur)')
on conflict do nothing;

revoke all on function public.till_parse(text), public.record_till_sale(text, bigint, text, uuid, uuid, int),
  public.void_till_sale(uuid), public.my_till(), public.store_payout_simulated(bigint, uuid) from public;
grant execute on function public.till_parse(text), public.record_till_sale(text, bigint, text, uuid, uuid, int),
  public.void_till_sale(uuid), public.my_till(), public.store_payout_simulated(bigint, uuid) to authenticated;
