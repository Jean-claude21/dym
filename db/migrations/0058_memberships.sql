-- 0058 — DYM+, vendeuse Pro, visibilité sponsorisée (spec 052, VISION §3 « Différence »).
-- Des formules par pays (données de référence, modifiables par l'équipe) : public visé, prix,
-- durée, avantages. Payées depuis le wallet, au grand livre (compte des abonnements de DYM) ;
-- un nouvel achat prolonge la formule en cours. Avantages lus en base :
-- - `delivery_refund` (cliente) : frais de livraison rendus au wallet à la livraison (financés
--   par DYM ; le livreur garde ses frais) ;
-- - `cashback_bonus_bps` (cliente) : cashback en plus sur le sous-total livré ;
-- - `commission_discount_bps` (boutique) : commission réduite sur les commandes ;
-- - `sponsored` (boutique) : « À la une » de l'accueil des quartiers qu'elle livre, signalée.

alter table public.ledger_accounts drop constraint ledger_accounts_kind_check;
alter table public.ledger_accounts add constraint ledger_accounts_kind_check check (kind in (
  'platform_commission', 'provider_clearing', 'customer_escrow', 'store_balance',
  'user_wallet', 'user_pocket', 'platform_promotions', 'space_pocket',
  'courier_cash', 'platform_cash',
  'platform_subscriptions'   -- formules payées (DYM+, Pro, visibilité)
));

alter table public.ledger_transactions drop constraint ledger_transactions_kind_check;
alter table public.ledger_transactions add constraint ledger_transactions_kind_check check (kind in (
  'payment_received', 'order_settled', 'cash_commission', 'refund_paid',
  'wallet_topup', 'wallet_transfer', 'cashback', 'space_contribution', 'space_payout', 'order_credit',
  'affiliate_commission', 'courier_fee', 'courier_cash', 'courier_cash_remitted', 'cash_topup',
  'wallet_withdrawal', 'store_payout', 'qr_payment',
  'membership',       -- achat d'une formule, du wallet vers DYM
  'member_benefit'    -- avantage d'une formule versé au wallet (financé par DYM)
));

create table public.membership_plans (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries (code),
  code text not null check (code ~ '^[a-z0-9_]{2,40}$'),
  audience text not null check (audience in ('client', 'vendor')),
  name jsonb not null,
  description jsonb,
  price_minor bigint not null check (price_minor > 0),
  currency_code char(3) not null references public.currencies (code),
  period_days integer not null check (period_days between 1 and 366),
  benefits jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  sort smallint not null default 0,
  created_at timestamptz not null default now(),
  unique (country_code, code)
);
alter table public.membership_plans enable row level security;
revoke all on public.membership_plans from authenticated, anonymous;

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.membership_plans (id),
  user_id uuid references neon_auth."user" (id) on delete cascade,
  store_id uuid references public.stores (id) on delete cascade,
  paid_by uuid not null references neon_auth."user" (id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null check (ends_at > starts_at),
  idempotency_key uuid not null unique,
  created_at timestamptz not null default clock_timestamp(),
  check ((user_id is null) <> (store_id is null))
);
create index memberships_user on public.memberships (user_id, ends_at) where user_id is not null;
create index memberships_store on public.memberships (store_id, ends_at) where store_id is not null;
alter table public.memberships enable row level security;
revoke all on public.memberships from authenticated, anonymous;

-- Formules de départ du Togo (données de référence ; prix à valider par le porteur produit).
insert into public.membership_plans (country_code, code, audience, name, description, price_minor, currency_code,
  period_days, benefits, sort)
select c.code, v.code, v.audience, v.name, v.description, v.price, c.currency_code, v.days, v.benefits, v.sort
from public.countries c,
  (values
    ('dym_plus', 'client', '{"fr": "DYM+", "en": "DYM+"}'::jsonb,
     '{"fr": "Livraison remboursée et cashback en plus", "en": "Delivery refunded and extra cashback"}'::jsonb,
     1500::bigint, 30, '{"delivery_refund": true, "cashback_bonus_bps": 200}'::jsonb, 1),
    ('vendor_pro', 'vendor', '{"fr": "Vendeuse Pro", "en": "Pro seller"}'::jsonb,
     '{"fr": "Commission réduite de moitié", "en": "Commission cut by half"}'::jsonb,
     3000::bigint, 30, '{"commission_discount_bps": 5000}'::jsonb, 1),
    ('featured_week', 'vendor', '{"fr": "À la une, 7 jours", "en": "Featured, 7 days"}'::jsonb,
     '{"fr": "Ta boutique en tête de l''accueil de tes quartiers", "en": "Your store at the top of your areas'' home"}'::jsonb,
     1000::bigint, 7, '{"sponsored": true}'::jsonb, 2)
  ) as v(code, audience, name, description, price, days, benefits, sort)
where c.code = 'TG'
on conflict do nothing;

-- Avantage booléen en cours (cliente [p_user] ou boutique [p_store]).
create or replace function app.member_flag(p_user uuid, p_store uuid, p_key text, p_at timestamptz default now())
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m join public.membership_plans pl on pl.id = m.plan_id
    where ((p_user is not null and m.user_id = p_user) or (p_store is not null and m.store_id = p_store))
      and m.starts_at <= p_at and m.ends_at > p_at
      and coalesce((pl.benefits ->> p_key)::boolean, false))
$$;

-- Avantage chiffré en cours (le plus fort).
create or replace function app.member_bps(p_user uuid, p_store uuid, p_key text, p_at timestamptz default now())
returns integer
language sql stable security definer set search_path = ''
as $$
  select least(10000, greatest(0, coalesce(max((pl.benefits ->> p_key)::integer), 0)))
  from public.memberships m join public.membership_plans pl on pl.id = m.plan_id
  where ((p_user is not null and m.user_id = p_user) or (p_store is not null and m.store_id = p_store))
    and m.starts_at <= p_at and m.ends_at > p_at
$$;

-- Formules proposées à la cliente ou à la boutique, avec la fin de celles en cours.
create or replace function public.membership_offer(p_audience text) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_store public.stores;
  v_country char(2);
begin
  if p_audience = 'vendor' then
    select * into v_store from public.stores where id = app.own_store_id();
    v_country := v_store.country_code;
  elsif p_audience = 'client' then
    v_country := (select country_code from public.profiles where user_id = v_user);
  else
    raise exception 'invalid_audience' using errcode = '22023';
  end if;
  return jsonb_build_object(
    'currency_code', app.user_currency(v_user),
    'wallet_balance_minor', coalesce(app.ledger_balance(
      (select id from public.ledger_accounts where kind = 'user_wallet' and user_id = v_user
         and currency_code = app.user_currency(v_user))), 0),
    'plans', coalesce((select jsonb_agg(jsonb_build_object(
        'id', pl.id, 'code', pl.code, 'name', pl.name, 'description', pl.description,
        'price_minor', pl.price_minor, 'currency_code', pl.currency_code, 'period_days', pl.period_days,
        'benefits', pl.benefits,
        'active_until', (select max(m.ends_at) from public.memberships m where m.plan_id = pl.id
          and m.ends_at > now()
          and (case when p_audience = 'vendor' then m.store_id = v_store.id else m.user_id = v_user end)))
        order by pl.sort, pl.code)
      from public.membership_plans pl
      where pl.country_code = v_country and pl.audience = p_audience and pl.is_active), '[]'::jsonb));
end
$fn$;

-- Achat (ou prolongation) d'une formule depuis le wallet. Rejeu de la même clé : sans effet.
create or replace function public.subscribe_plan(p_plan uuid, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_plan public.membership_plans;
  v_store public.stores;
  v_wallet uuid;
  v_start timestamptz;
  v_country char(2);
begin
  select * into v_plan from public.membership_plans where id = p_plan and is_active;
  if v_plan.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if p_key is null then raise exception 'invalid_key' using errcode = '22023'; end if;
  if exists (select 1 from public.memberships where idempotency_key = p_key and paid_by = v_user) then
    return public.membership_offer(v_plan.audience);
  end if;
  if v_plan.audience = 'vendor' then
    select * into v_store from public.stores where id = app.own_store_id();
    v_country := v_store.country_code;
  else
    v_country := (select country_code from public.profiles where user_id = v_user);
  end if;
  if v_country is distinct from v_plan.country_code
     or app.user_currency(v_user) is distinct from v_plan.currency_code then
    raise exception 'other_country' using errcode = 'P0001';
  end if;
  v_wallet := app.ledger_user_account('user_wallet', v_plan.currency_code, v_user);
  perform 1 from public.ledger_accounts where id = v_wallet for update;
  if app.ledger_balance(v_wallet) < v_plan.price_minor then
    raise exception 'wallet_insufficient' using errcode = 'P0001';
  end if;
  select greatest(now(), coalesce(max(m.ends_at), now())) into v_start
  from public.memberships m
  where m.plan_id = v_plan.id
    and (case when v_store.id is not null then m.store_id = v_store.id else m.user_id = v_user end);
  perform app.ledger_post('membership', 'membership:' || p_key, v_plan.currency_code, jsonb_build_array(
    jsonb_build_object('account', v_wallet, 'amount', v_plan.price_minor),
    jsonb_build_object('account', app.ledger_account('platform_subscriptions', v_plan.currency_code),
                       'amount', -v_plan.price_minor)),
    p_user => v_user);
  insert into public.memberships (plan_id, user_id, store_id, paid_by, starts_at, ends_at, idempotency_key)
  values (v_plan.id, case when v_store.id is null then v_user end, v_store.id, v_user, v_start,
          v_start + make_interval(days => v_plan.period_days), p_key);
  perform app.emit_event('membership_started', v_user, v_plan.audience, 'server', v_plan.country_code,
    case when v_store.id is null then 'user' else 'store' end, coalesce(v_store.id, v_user)::text,
    jsonb_build_object('plan_code', v_plan.code, 'renewal', v_start > now()));
  return public.membership_offer(v_plan.audience);
end
$fn$;

-- Boutique Pro : commission réduite à la création de la commande.
create or replace function app.member_commission() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_bps integer := app.member_bps(null, new.store_id, 'commission_discount_bps');
begin
  if v_bps > 0 and new.commission_minor > 0 then
    new.commission_minor := new.commission_minor - floor(new.commission_minor * v_bps / 10000.0)::bigint;
  end if;
  return new;
end
$fn$;
create trigger orders_member_commission before insert on public.orders
for each row execute function app.member_commission();

-- Cliente DYM+ au moment de l'achat : à la livraison, frais rendus et cashback en plus au wallet.
create or replace function app.member_benefits_on_order() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid;
  v_at timestamptz;
  v_amount bigint := 0;
begin
  if new.status <> 'delivered' or old.status = 'delivered' then return null; end if;
  select pu.user_id, pu.created_at into v_user, v_at from public.purchases pu where pu.id = new.purchase_id;
  if app.member_flag(v_user, null, 'delivery_refund', v_at) then
    v_amount := v_amount + new.delivery_fee_minor;
  end if;
  v_amount := v_amount + floor(new.subtotal_minor * app.member_bps(v_user, null, 'cashback_bonus_bps', v_at) / 10000.0)::bigint;
  if v_amount <= 0 then return null; end if;
  perform app.ledger_post('member_benefit', 'member-benefit:' || new.id, new.currency_code, jsonb_build_array(
    jsonb_build_object('account', app.ledger_account('platform_promotions', new.currency_code), 'amount', v_amount),
    jsonb_build_object('account', app.ledger_user_account('user_wallet', new.currency_code, v_user), 'amount', -v_amount)),
    p_purchase => new.purchase_id, p_order => new.id);
  perform app.emit_event('member_benefit_paid', v_user, 'client', 'server',
    (select country_code from public.purchases where id = new.purchase_id), 'order', new.id::text,
    jsonb_build_object('amount_minor', v_amount));
  return null;
end
$fn$;
create trigger orders_member_benefits after update of status on public.orders
for each row execute function app.member_benefits_on_order();

insert into public.event_names (name, emitted_by, description) values
  ('membership_started', 'server', 'Formule achetée ou prolongée (code, prolongation)'),
  ('member_benefit_paid', 'server', 'Avantage DYM+ versé au wallet à la livraison (montant)')
on conflict do nothing;

-- Copie (0008) : la liste « À la une » des boutiques sponsorisées.
create or replace function public.discover_stores(
  p_zone uuid,
  p_limit integer default 20,
  p_at timestamptz default now()
) returns jsonb
language sql stable security definer set search_path = ''
as $$
  with candidates as (
    select s.id, s.name, s.zone_id = p_zone as same_zone,
           app.store_open_at(s.id, p_at) as open_now, s.prep_time_minutes
    from public.stores s
    where s.status = 'active' and app.store_serves(s.id, p_zone)
  )
  select jsonb_build_object(
    'estimate_minutes', (
      select min(cd.prep_time_minutes) + c.delivery_minutes
      from candidates cd, public.zones z join public.cities c on c.id = z.city_id
      where cd.open_now and z.id = p_zone
      group by c.delivery_minutes),
    'stores', coalesce((
      select jsonb_agg(app.store_summary(id, p_at) order by open_now desc, same_zone desc, name)
      from (select * from candidates order by open_now desc, same_zone desc, name
            limit greatest(1, least(p_limit, 50))) t), '[]'::jsonb),
    -- « À la une » (spec 052) : boutiques sponsorisées qui livrent le quartier, signalées comme telles.
    'sponsored', coalesce((
      select jsonb_agg(app.store_summary(cd.id, p_at) order by cd.open_now desc, cd.name)
      from candidates cd where app.member_flag(null, cd.id, 'sponsored', p_at)), '[]'::jsonb)
  )
$$;

revoke all on function app.member_flag(uuid, uuid, text, timestamptz), app.member_bps(uuid, uuid, text, timestamptz),
  public.membership_offer(text), public.subscribe_plan(uuid, uuid), app.member_commission(),
  app.member_benefits_on_order() from public;
grant execute on function public.membership_offer(text), public.subscribe_plan(uuid, uuid) to authenticated;
