-- 0046 — Affiliation des créatrices (spec 039, VISION §3 « Affiliation »).
-- 1. Taux : par produit, sinon celui de la boutique, jamais sous le minimum du pays ; un
--    ingrédient générique (« Tout pour la faire ») est payé au minimum du pays.
-- 2. Attribution : dernier contenu de créatrice par lequel la variante est entrée au panier,
--    article par article, dans un délai réglable par pays (7 jours par défaut).
-- 3. En attente à la commande ; due à la livraison + délai de réclamation fraîcheur ; versée par
--    une tâche planifiée sur le wallet ; annulée si la commande n'est pas livrée ou si la cliente
--    est remboursée avant l'échéance.
-- 4. Payeur : la vendeuse (solde de la boutique) ; DYM pendant le lancement (réglage du pays).
-- 5. Antifraude : ni ses propres achats, ni la même adresse, ni le même appareil.

alter table public.countries
  add column affiliate_min_rate_bps integer not null default 300
    check (affiliate_min_rate_bps between 0 and 3000),
  add column affiliate_window_days smallint not null default 7
    check (affiliate_window_days between 1 and 30),
  add column affiliate_launch_subsidy boolean not null default true;

alter table public.stores add column affiliate_rate_bps integer
  check (affiliate_rate_bps is null or affiliate_rate_bps between 0 and 3000);
alter table public.products add column affiliate_rate_bps integer
  check (affiliate_rate_bps is null or affiliate_rate_bps between 0 and 3000);

-- Appareils vus par compte : identifiant d'installation aléatoire, jamais un identifiant matériel.
create table public.user_devices (
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  install_id uuid not null,
  seen_at timestamptz not null default clock_timestamp(),
  primary key (user_id, install_id)
);
create index user_devices_install on public.user_devices (install_id);
alter table public.user_devices enable row level security;
revoke all on public.user_devices from authenticated, anonymous;

-- Dernier contenu par lequel la personne a ajouté une variante au panier.
create table public.affiliate_touches (
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  content_id uuid not null references public.contents (id) on delete cascade,
  -- Produit tagué par la créatrice, ou ingrédient générique relié à une vendeuse.
  via text not null check (via in ('tagged', 'ingredient')),
  touched_at timestamptz not null default clock_timestamp(),
  primary key (user_id, variant_id)
);
alter table public.affiliate_touches enable row level security;
revoke all on public.affiliate_touches from authenticated, anonymous;

create table public.affiliate_commissions (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  order_item_id uuid not null unique references public.order_items (id) on delete cascade,
  content_id uuid references public.contents (id) on delete set null,
  creator_id uuid not null references neon_auth."user" (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  via text not null check (via in ('tagged', 'ingredient')),
  rate_bps integer not null check (rate_bps between 0 and 3000),
  base_minor bigint not null check (base_minor >= 0),
  amount_minor bigint not null check (amount_minor > 0),
  currency_code char(3) not null references public.currencies (code),
  paid_by text not null check (paid_by in ('store', 'platform')),
  status text not null default 'pending' check (status in ('pending', 'paid', 'cancelled')),
  cancel_reason text check (cancel_reason in ('not_delivered', 'refunded', 'credited')),
  -- Échéance : livraison + délai de réclamation ; null tant que la commande n'est pas livrée.
  due_at timestamptz,
  created_at timestamptz not null default clock_timestamp(),
  settled_at timestamptz,
  check ((status = 'cancelled') = (cancel_reason is not null))
);
create index affiliate_commissions_creator on public.affiliate_commissions (creator_id, created_at desc);
create index affiliate_commissions_order on public.affiliate_commissions (order_id);
create index affiliate_commissions_due on public.affiliate_commissions (due_at) where status = 'pending';
alter table public.affiliate_commissions enable row level security;
revoke all on public.affiliate_commissions from authenticated, anonymous;

alter table public.ledger_transactions drop constraint ledger_transactions_kind_check;
alter table public.ledger_transactions add constraint ledger_transactions_kind_check check (kind in (
  'payment_received', 'order_settled', 'cash_commission', 'refund_paid',
  'wallet_topup', 'wallet_transfer', 'cashback', 'space_contribution', 'space_payout', 'order_credit',
  'affiliate_commission'  -- commission versée à une créatrice
));

-- ------------------------------------------------------------------ appareils et attribution

-- L'app déclare son identifiant d'installation (aléatoire) pour le compte connecté.
create or replace function public.register_device(p_install uuid) returns void
language sql security definer set search_path = ''
as $$
  insert into public.user_devices (user_id, install_id)
  values (app.require_user(), p_install)
  on conflict (user_id, install_id) do update set seen_at = clock_timestamp()
$$;

-- Ajout au panier depuis un contenu (fil, story, « Tout pour la faire ») : le dernier contenu de
-- créatrice qui a amené chaque variante est gardé. Ni son propre contenu ni celui d'une boutique.
create or replace function public.content_touch(p_content uuid, p_variants uuid[]) returns void
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if coalesce(array_length(p_variants, 1), 0) > 30 then
    raise exception 'invalid_items' using errcode = '22023';
  end if;
  if not exists (select 1 from public.contents c where c.id = p_content and c.author_id is not null
                 and c.author_id <> v_user and app.content_visible(c, now())) then
    return;
  end if;
  insert into public.affiliate_touches (user_id, variant_id, content_id, via)
  select v_user, v.id, p_content,
         case when exists (select 1 from public.content_products cp
                           where cp.content_id = p_content and cp.product_id = v.product_id)
              then 'tagged' else 'ingredient' end
  from public.product_variants v where v.id = any (p_variants)
  on conflict (user_id, variant_id) do update
    set content_id = excluded.content_id, via = excluded.via, touched_at = clock_timestamp();
end
$fn$;

-- Même foyer : même téléphone ou mêmes coordonnées (≈ 50 m) qu'une adresse de la créatrice.
create or replace function app.affiliate_same_household(p_creator uuid, p_address jsonb) returns boolean
language sql stable security definer set search_path = ''
as $$
  select p_address is not null and exists (
    select 1 from public.customer_addresses a
    where a.user_id = p_creator
      and (regexp_replace(a.phone, '[^0-9]', '', 'g') = regexp_replace(coalesce(p_address ->> 'phone', ''), '[^0-9]', '', 'g')
           or (a.latitude is not null and p_address ->> 'latitude' is not null
               and abs(a.latitude - (p_address ->> 'latitude')::numeric) < 0.0005
               and abs(a.longitude - (p_address ->> 'longitude')::numeric) < 0.0005)))
$$;

-- Commission d'une ligne commandée, si un contenu de créatrice l'a amenée dans le délai.
create or replace function app.affiliate_on_order_item() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_order record;
  v_touch record;
  v_rate integer;
  v_amount bigint;
begin
  select o.id, o.store_id, o.currency_code, pu.user_id, pu.country_code, pu.address,
         s.affiliate_rate_bps as store_rate, p.affiliate_rate_bps as product_rate,
         c.affiliate_min_rate_bps, c.affiliate_window_days, c.affiliate_launch_subsidy
  into v_order
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.stores s on s.id = o.store_id
  join public.products p on p.id = new.product_id
  join public.countries c on c.code = pu.country_code
  where o.id = new.order_id;
  select t.content_id, t.via, ct.author_id into v_touch
  from public.affiliate_touches t join public.contents ct on ct.id = t.content_id
  where t.user_id = v_order.user_id and t.variant_id = new.variant_id
    and t.touched_at > now() - make_interval(days => v_order.affiliate_window_days)
    and ct.author_id is not null and ct.author_id <> v_order.user_id;
  if v_touch.content_id is null then return null; end if;
  -- Antifraude : même appareil ou même foyer que la créatrice.
  if exists (select 1 from public.user_devices b join public.user_devices cr on cr.install_id = b.install_id
             where b.user_id = v_order.user_id and cr.user_id = v_touch.author_id)
     or app.affiliate_same_household(v_touch.author_id, v_order.address) then
    return null;
  end if;
  v_rate := case when v_touch.via = 'tagged'
                 then greatest(coalesce(v_order.product_rate, v_order.store_rate, 0), v_order.affiliate_min_rate_bps)
                 else v_order.affiliate_min_rate_bps end;
  v_amount := (new.amount_minor * v_rate) / 10000;
  if v_amount <= 0 then return null; end if;
  insert into public.affiliate_commissions (order_id, order_item_id, content_id, creator_id, store_id, via,
    rate_bps, base_minor, amount_minor, currency_code, paid_by)
  values (new.order_id, new.id, v_touch.content_id, v_touch.author_id, v_order.store_id, v_touch.via,
    v_rate, new.amount_minor, v_amount, v_order.currency_code,
    case when v_order.affiliate_launch_subsidy then 'platform' else 'store' end)
  on conflict (order_item_id) do nothing;
  perform app.emit_event('commission_earned', v_touch.author_id, 'client', 'server', v_order.country_code,
    'order', new.order_id::text, jsonb_build_object('amount_minor', v_amount, 'rate_bps', v_rate, 'via', v_touch.via));
  return null;
end
$fn$;
create trigger order_items_affiliate after insert on public.order_items
  for each row execute function app.affiliate_on_order_item();

-- Livrée : échéance fixée (fin du délai de réclamation) ; refusée ou annulée : commissions annulées.
create or replace function app.affiliate_on_order() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
begin
  if new.status = 'delivered' and old.status is distinct from 'delivered' then
    update public.affiliate_commissions a
    set due_at = coalesce(new.delivered_at, now()) + make_interval(hours => c.freshness_claim_hours)
    from public.purchases pu join public.countries c on c.code = pu.country_code
    where a.order_id = new.id and a.status = 'pending' and pu.id = new.purchase_id;
  elsif new.status in ('refused', 'cancelled') and old.status is distinct from new.status then
    update public.affiliate_commissions
    set status = 'cancelled', cancel_reason = 'not_delivered', settled_at = clock_timestamp()
    where order_id = new.id and status = 'pending';
  end if;
  return null;
end
$fn$;
create trigger orders_affiliate after update of status on public.orders
  for each row execute function app.affiliate_on_order();

-- Tâche planifiée : commissions arrivées à échéance. Remboursée ou ligne rendue : annulée ;
-- sinon versée au grand livre (une fois par commission) sur le wallet de la créatrice.
create or replace function app.settle_affiliate_commissions(p_at timestamptz default now()) returns integer
language plpgsql security definer set search_path = ''
as $fn$
declare
  v record;
  v_paid integer := 0;
begin
  for v in
    select a.*, i.variant_id from public.affiliate_commissions a
    join public.order_items i on i.id = a.order_item_id
    where a.status = 'pending' and a.due_at is not null and a.due_at <= p_at
    order by a.due_at
    for update of a skip locked
  loop
    if exists (select 1 from public.refunds r where r.order_id = v.order_id and r.status <> 'failed') then
      update public.affiliate_commissions set status = 'cancelled', cancel_reason = 'refunded',
        settled_at = clock_timestamp() where id = v.id;
      continue;
    end if;
    if exists (select 1 from public.order_adjustments j where j.order_id = v.order_id
               and j.variant_id = v.variant_id and j.credited_minor > 0) then
      update public.affiliate_commissions set status = 'cancelled', cancel_reason = 'credited',
        settled_at = clock_timestamp() where id = v.id;
      continue;
    end if;
    perform app.ledger_post('affiliate_commission', 'affiliate:' || v.id, v.currency_code,
      jsonb_build_array(
        jsonb_build_object('account',
          case when v.paid_by = 'platform' then app.ledger_account('platform_promotions', v.currency_code)
               else app.ledger_account('store_balance', v.currency_code, v.store_id) end,
          'amount', v.amount_minor),
        jsonb_build_object('account', app.ledger_user_account('user_wallet', v.currency_code, v.creator_id),
          'amount', -v.amount_minor)),
      p_order => v.order_id, p_user => v.creator_id);
    update public.affiliate_commissions set status = 'paid', settled_at = clock_timestamp() where id = v.id;
    perform app.notify(v.creator_id, 'commission_paid', 'payments', null, null,
      jsonb_build_object('amount_minor', v.amount_minor, 'currency_code', v.currency_code));
    perform app.emit_event('commission_paid', v.creator_id, 'client', 'server',
      (select country_code from public.profiles where user_id = v.creator_id), 'order', v.order_id::text,
      jsonb_build_object('amount_minor', v.amount_minor, 'paid_by', v.paid_by));
    v_paid := v_paid + 1;
  end loop;
  return v_paid;
end
$fn$;

-- ------------------------------------------------------------------ tableaux de bord et réglages

-- Créatrice : totaux et dernières commissions.
create or replace function public.my_commissions() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'pending_minor', coalesce((select sum(amount_minor) from public.affiliate_commissions
                               where creator_id = app.current_user_id() and status = 'pending'), 0),
    'paid_minor', coalesce((select sum(amount_minor) from public.affiliate_commissions
                            where creator_id = app.current_user_id() and status = 'paid'), 0),
    'items', coalesce((select jsonb_agg(jsonb_build_object(
        'id', a.id, 'status', a.status, 'cancel_reason', a.cancel_reason, 'via', a.via,
        'amount_minor', a.amount_minor, 'rate_bps', a.rate_bps,
        'created_at', a.created_at, 'due_at', a.due_at, 'settled_at', a.settled_at,
        'product_name', (select i.product_name from public.order_items i where i.id = a.order_item_id),
        'content_caption', (select c.caption from public.contents c where c.id = a.content_id))
      order by a.created_at desc)
      from (select * from public.affiliate_commissions where creator_id = app.current_user_id()
            order by created_at desc limit 50) a), '[]'::jsonb))
$$;

-- Vendeuse : taux de sa boutique (nul : minimum du pays), puis d'un produit (nul : boutique).
create or replace function public.set_affiliate_rate(p_rate_bps integer, p_product uuid default null)
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store uuid := app.own_store_id();
  v_min integer;
begin
  if v_store is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  select c.affiliate_min_rate_bps into v_min from public.stores s join public.countries c on c.code = s.country_code
  where s.id = v_store;
  if p_rate_bps is not null and (p_rate_bps < v_min or p_rate_bps > 3000) then
    raise exception 'invalid_rate' using errcode = '22023';
  end if;
  if p_product is null then
    update public.stores set affiliate_rate_bps = p_rate_bps where id = v_store;
  else
    update public.products set affiliate_rate_bps = p_rate_bps where id = p_product and store_id = v_store;
    if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  end if;
  return public.my_affiliate_rate(p_product);
end
$fn$;

create or replace function public.my_affiliate_rate(p_product uuid default null) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('affiliate_rate_bps',
           case when p_product is null then s.affiliate_rate_bps
                else (select p.affiliate_rate_bps from public.products p
                      where p.id = p_product and p.store_id = s.id) end,
           'store_rate_bps', s.affiliate_rate_bps,
           'min_rate_bps', c.affiliate_min_rate_bps)
  from public.stores s join public.countries c on c.code = s.country_code
  where s.id = app.own_store_id()
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('commission_paid', 'fr', 'Commission reçue', 'Un achat fait grâce à ton contenu a été livré : ta commission est sur ton wallet.'),
  ('commission_paid', 'en', 'Commission received', 'A purchase made thanks to your content was delivered: your commission is in your wallet.')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('commission_earned', 'server', 'Commission d''affiliation en attente (montant, taux, origine)'),
  ('commission_paid', 'server', 'Commission d''affiliation versée (montant, payeur)')
on conflict do nothing;

revoke all on function public.register_device(uuid), public.content_touch(uuid, uuid[]),
  app.affiliate_same_household(uuid, jsonb), app.affiliate_on_order_item(), app.affiliate_on_order(),
  app.settle_affiliate_commissions(timestamptz), public.my_commissions(),
  public.set_affiliate_rate(integer, uuid), public.my_affiliate_rate(uuid) from public;
grant execute on function public.register_device(uuid), public.content_touch(uuid, uuid[]),
  public.my_commissions(), public.set_affiliate_rate(integer, uuid), public.my_affiliate_rate(uuid)
  to authenticated;
