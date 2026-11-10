-- 0041 — Remplacement validé par photo et garantie fraîcheur (spec 034).
-- 1. La vendeuse propose, photo à l'appui, un autre produit de sa boutique pour une ligne (même
--    quantité, même prix) ; la cliente accepte (la ligne change) ou refuse (montant rendu).
-- 2. Garantie fraîcheur : dans le délai du pays après livraison, une ligne signalée avec photo est
--    rendue tout de suite, dans la limite mensuelle du pays.
-- Tout montant rendu passe au grand livre : solde de la boutique → wallet de la cliente. Les totaux
-- des commandes ne changent pas.

alter table public.countries
  add column freshness_claim_hours smallint not null default 24 check (freshness_claim_hours between 1 and 168),
  add column freshness_claims_per_month smallint not null default 3 check (freshness_claims_per_month between 0 and 50);

create table public.order_adjustments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  kind text not null check (kind in ('substitution', 'freshness')),
  -- Ligne visée : sa variante d'origine (unique dans une commande).
  variant_id uuid not null references public.product_variants (id),
  item_name text not null,
  -- Remplacement proposé.
  proposed_variant_id uuid references public.product_variants (id),
  proposed_name text,
  photo_key text not null check (photo_key ~ '^orders/[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|webp)$'),
  note text check (note is null or length(note) <= 200),
  status text not null check (status in ('pending', 'accepted', 'refused', 'credited')),
  credited_minor bigint not null default 0 check (credited_minor >= 0),
  created_by uuid references neon_auth."user" (id) on delete set null,
  created_at timestamptz not null default clock_timestamp(),
  decided_at timestamptz,
  check ((kind = 'substitution') = (proposed_variant_id is not null))
);
create index order_adjustments_order on public.order_adjustments (order_id, created_at);
-- Une seule proposition en attente et un seul remboursement par ligne.
create unique index order_adjustments_pending on public.order_adjustments (order_id, variant_id)
  where status = 'pending';
create unique index order_adjustments_credit on public.order_adjustments (order_id, variant_id)
  where credited_minor > 0;
alter table public.order_adjustments enable row level security;
revoke all on public.order_adjustments from authenticated, anonymous;

alter table public.ledger_transactions drop constraint ledger_transactions_kind_check;
alter table public.ledger_transactions add constraint ledger_transactions_kind_check check (kind in (
  'payment_received', 'order_settled', 'cash_commission', 'refund_paid',
  'wallet_topup', 'wallet_transfer', 'cashback', 'space_contribution', 'space_payout',
  'order_credit'          -- montant d'une ligne rendu (remplacement refusé, fraîcheur)
));

-- Partie de la commande : 'client', 'vendor' ou nul.
create or replace function app.order_party(p_user uuid, p_order uuid) returns text
language sql stable security definer set search_path = ''
as $$
  select case
    when exists (select 1 from public.orders o join public.purchases pu on pu.id = o.purchase_id
                 where o.id = p_order and pu.user_id = p_user) then 'client'
    when exists (select 1 from public.orders o join public.stores s on s.id = o.store_id
                 where o.id = p_order and s.owner_id = p_user) then 'vendor' end
$$;

-- Rend le montant d'une ligne : boutique → wallet de la cliente (idempotent par ajustement).
create or replace function app.credit_order_line(p_adjustment uuid) returns bigint
language plpgsql security definer set search_path = ''
as $fn$
declare
  v record;
begin
  select a.id, a.order_id, o.store_id, o.currency_code, pu.user_id, i.amount_minor
  into v
  from public.order_adjustments a
  join public.orders o on o.id = a.order_id
  join public.purchases pu on pu.id = o.purchase_id
  join public.order_items i on i.order_id = a.order_id
    and i.variant_id = a.variant_id
  where a.id = p_adjustment;
  if v.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  perform app.ledger_post('order_credit', 'order-credit:' || p_adjustment, v.currency_code,
    jsonb_build_array(
      jsonb_build_object('account', app.ledger_account('store_balance', v.currency_code, v.store_id),
                         'amount', v.amount_minor),
      jsonb_build_object('account', app.ledger_user_account('user_wallet', v.currency_code, v.user_id),
                         'amount', -v.amount_minor)),
    p_order => v.order_id, p_user => v.user_id);
  update public.order_adjustments set credited_minor = v.amount_minor where id = p_adjustment;
  return v.amount_minor;
end
$fn$;

-- Ajustements visibles des deux parties.
create or replace function app.order_adjustments_json(p_order uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', a.id, 'kind', a.kind, 'variant_id', a.variant_id, 'item_name', a.item_name,
      'proposed_variant_id', a.proposed_variant_id, 'proposed_name', a.proposed_name,
      'photo_key', a.photo_key, 'note', a.note, 'status', a.status,
      'credited_minor', a.credited_minor, 'created_at', a.created_at, 'decided_at', a.decided_at)
    order by a.created_at), '[]'::jsonb)
  from public.order_adjustments a where a.order_id = p_order
$$;

-- Clés des photos d'une commande, pour l'une de ses parties (Function : liens signés).
create or replace function app.order_photo_keys(p_user uuid, p_order uuid) returns text[]
language sql stable security definer set search_path = ''
as $$
  select coalesce(array_agg(a.photo_key order by a.created_at), '{}')
  from public.order_adjustments a
  where a.order_id = p_order and app.order_party(p_user, p_order) is not null
$$;

-- ------------------------------------------------------------------ remplacement

create or replace function public.propose_substitution(
  p_order uuid, p_variant uuid, p_proposed_variant uuid, p_photo_key text, p_note text default null
) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_order record;
  v_item public.order_items;
  v_proposed record;
  v_id uuid;
begin
  select o.id, o.status, o.store_id, pu.user_id as client, pu.substitution_allowed, pu.country_code
  into v_order
  from public.orders o join public.purchases pu on pu.id = o.purchase_id where o.id = p_order;
  if v_order.id is null or app.order_party(v_user, p_order) is distinct from 'vendor' then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if v_order.status not in ('accepted', 'preparing') then
    raise exception 'order_not_in_progress' using errcode = '22023';
  end if;
  if not v_order.substitution_allowed then raise exception 'substitution_not_allowed' using errcode = '22023'; end if;
  select * into v_item from public.order_items where order_id = p_order and variant_id = p_variant;
  if v_item.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  select v.id, p.name, v.label into v_proposed
  from public.product_variants v join public.products p on p.id = v.product_id
  where v.id = p_proposed_variant and p.store_id = v_order.store_id and p.status = 'published';
  if v_proposed.id is null or p_proposed_variant = p_variant then
    raise exception 'invalid_substitute' using errcode = '22023';
  end if;
  if p_photo_key is null or p_photo_key !~ ('^orders/' || p_order || '/') then
    raise exception 'photo_required' using errcode = '22023';
  end if;
  insert into public.order_adjustments (order_id, kind, variant_id, item_name, proposed_variant_id,
    proposed_name, photo_key, note, status, created_by)
  values (p_order, 'substitution', p_variant, v_item.product_name, v_proposed.id,
    v_proposed.name || coalesce(' · ' || v_proposed.label, ''), p_photo_key,
    nullif(left(btrim(coalesce(p_note, '')), 200), ''), 'pending', v_user)
  returning id into v_id;
  perform app.notify(v_order.client, 'substitution_proposed', 'orders', p_order, null,
    jsonb_build_object('item_name', v_item.product_name, 'proposed_name', v_proposed.name));
  perform app.emit_event('substitution_proposed', v_user, 'vendor', 'server', v_order.country_code,
    'order', p_order::text, '{}'::jsonb);
  return app.order_adjustments_json(p_order);
end
$fn$;

-- Réponse de la cliente : acceptée (la ligne change, même prix) ou refusée (montant rendu).
create or replace function public.answer_substitution(p_adjustment uuid, p_accept boolean) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_adj public.order_adjustments;
  v_order record;
  v_variant record;
begin
  select * into v_adj from public.order_adjustments where id = p_adjustment and kind = 'substitution' for update;
  if v_adj.id is null or app.order_party(v_user, v_adj.order_id) is distinct from 'client' then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if v_adj.status <> 'pending' then raise exception 'already_answered' using errcode = '22023'; end if;
  select o.status, s.owner_id, pu.country_code into v_order
  from public.orders o join public.stores s on s.id = o.store_id
  join public.purchases pu on pu.id = o.purchase_id where o.id = v_adj.order_id;
  if v_order.status not in ('accepted', 'preparing', 'ready') then
    raise exception 'order_not_in_progress' using errcode = '22023';
  end if;
  if p_accept then
    select v.id, v.product_id, v.label, p.name into v_variant
    from public.product_variants v join public.products p on p.id = v.product_id
    where v.id = v_adj.proposed_variant_id;
    update public.order_items set variant_id = v_variant.id, product_id = v_variant.product_id,
      product_name = v_variant.name, variant_label = v_variant.label
    where order_id = v_adj.order_id and variant_id = v_adj.variant_id;
    update public.order_adjustments set status = 'accepted', decided_at = clock_timestamp() where id = v_adj.id;
  else
    update public.order_adjustments set status = 'refused', decided_at = clock_timestamp() where id = v_adj.id;
    perform app.credit_order_line(v_adj.id);
  end if;
  perform app.notify(v_order.owner_id, 'substitution_answered', 'orders', v_adj.order_id, null,
    jsonb_build_object('item_name', v_adj.item_name, 'accepted', p_accept));
  perform app.emit_event('substitution_answered', v_user, 'client', 'server', v_order.country_code,
    'order', v_adj.order_id::text, jsonb_build_object('accepted', p_accept));
  return app.order_adjustments_json(v_adj.order_id);
end
$fn$;

-- ------------------------------------------------------------------ fraîcheur

create or replace function public.claim_freshness(
  p_order uuid, p_variant uuid, p_photo_key text, p_note text default null
) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_order record;
  v_item public.order_items;
  v_id uuid;
  v_amount bigint;
  v_used int;
begin
  select o.id, o.status, o.delivered_at, s.owner_id, c.code as country, c.timezone,
         c.freshness_claim_hours, c.freshness_claims_per_month
  into v_order
  from public.orders o join public.stores s on s.id = o.store_id
  join public.purchases pu on pu.id = o.purchase_id
  join public.countries c on c.code = pu.country_code
  where o.id = p_order;
  if v_order.id is null or app.order_party(v_user, p_order) is distinct from 'client' then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if v_order.status <> 'delivered' or v_order.delivered_at is null
     or now() > v_order.delivered_at + make_interval(hours => v_order.freshness_claim_hours) then
    raise exception 'claim_window_closed' using errcode = '22023';
  end if;
  select * into v_item from public.order_items where order_id = p_order and variant_id = p_variant;
  if v_item.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if exists (select 1 from public.order_adjustments where order_id = p_order and variant_id = p_variant
             and credited_minor > 0) then
    raise exception 'already_credited' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtext('freshness:' || v_user));
  select count(*) into v_used
  from public.order_adjustments a
  join public.orders o on o.id = a.order_id
  join public.purchases pu on pu.id = o.purchase_id
  where a.kind = 'freshness' and pu.user_id = v_user
    and date_trunc('month', a.created_at at time zone v_order.timezone)
        = date_trunc('month', now() at time zone v_order.timezone);
  if v_used >= v_order.freshness_claims_per_month then
    raise exception 'claim_limit_reached' using errcode = '22023';
  end if;
  if p_photo_key is null or p_photo_key !~ ('^orders/' || p_order || '/') then
    raise exception 'photo_required' using errcode = '22023';
  end if;
  insert into public.order_adjustments (order_id, kind, variant_id, item_name, photo_key, note, status, created_by)
  values (p_order, 'freshness', p_variant, v_item.product_name, p_photo_key,
    nullif(left(btrim(coalesce(p_note, '')), 200), ''), 'credited', v_user)
  returning id into v_id;
  v_amount := app.credit_order_line(v_id);
  perform app.notify(v_order.owner_id, 'freshness_claimed', 'orders', p_order, null,
    jsonb_build_object('item_name', v_item.product_name));
  perform app.emit_event('freshness_claimed', v_user, 'client', 'server', v_order.country,
    'order', p_order::text, jsonb_build_object('amount_minor', v_amount));
  return app.order_adjustments_json(p_order);
end
$fn$;

-- Vendeuse : notifications du remplacement et de la fraîcheur vers son app.
create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor', 'review_received', 'support_replied_vendor', 'low_stock',
    'substitution_answered', 'freshness_claimed')
    then 'vendor' else 'client' end
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('substitution_proposed', 'fr', 'Un remplacement est proposé', '{item_name} manque : la vendeuse propose {proposed_name}. Regarde la photo.'),
  ('substitution_proposed', 'en', 'A replacement is proposed', '{item_name} is missing: the seller suggests {proposed_name}. See the photo.'),
  ('substitution_answered', 'fr', 'Réponse au remplacement', 'La cliente a répondu pour {item_name}.'),
  ('substitution_answered', 'en', 'Replacement answered', 'The customer answered for {item_name}.'),
  ('freshness_claimed', 'fr', 'Garantie fraîcheur', '{item_name} a été signalé pas frais et remboursé.'),
  ('freshness_claimed', 'en', 'Freshness guarantee', '{item_name} was reported not fresh and refunded.')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('substitution_proposed', 'server', 'Remplacement proposé par la vendeuse'),
  ('substitution_answered', 'server', 'Remplacement accepté ou refusé par la cliente'),
  ('freshness_claimed', 'server', 'Garantie fraîcheur : ligne remboursée (montant)')
on conflict do nothing;

-- Détail de commande (0040) : ajustements (remplacements, fraîcheur).
create or replace function app.order_json(p_order uuid, p_role text) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id, 'purchase_id', o.purchase_id, 'status', o.status, 'fulfillment', o.fulfillment,
    'created_at', o.created_at, 'accepted_at', o.accepted_at, 'preparing_at', o.preparing_at,
    'ready_at', o.ready_at, 'out_for_delivery_at', o.out_for_delivery_at,
    'delivered_at', o.delivered_at, 'refused_at', o.refused_at, 'cancelled_at', o.cancelled_at,
    'status_reason', o.status_reason, 'status_note', o.status_note, 'cancelled_by', o.cancelled_by,
    'cash_collected_at', o.cash_collected_at, 'refund_due', o.refund_due,
    'eta_at', case when o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
                   then app.order_eta(o.id) end,
    'scheduled_start', o.scheduled_start, 'scheduled_end', o.scheduled_end,
    'currency_code', o.currency_code, 'subtotal_minor', o.subtotal_minor,
    'delivery_fee_minor', o.delivery_fee_minor, 'total_minor', o.total_minor,
    'payment_status', pu.payment_status,
    'payment_method', jsonb_build_object('id', pm.id, 'country_code', pm.country_code,
                                         'provider_code', pm.provider_code,
                                         'operator_code', pm.operator_code, 'label', pm.label),
    'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin, 'zone_name', z.name),
    'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
    'items', (select coalesce(jsonb_agg(jsonb_build_object(
                'product_id', i.product_id, 'variant_id', i.variant_id, 'name', i.product_name,
                'variant_label', i.variant_label, 'unit_label', i.unit_label,
                'unit_price_minor', i.unit_price_minor, 'quantity', i.quantity,
                'amount_minor', i.amount_minor) order by i.product_name), '[]'::jsonb)
              from public.order_items i where i.order_id = o.id),
    'history', (select coalesce(jsonb_agg(jsonb_build_object(
                  'to_status', e.to_status, 'actor_role', e.actor_role, 'occurred_at', e.occurred_at)
                  order by e.occurred_at, e.id), '[]'::jsonb)
                from public.order_status_events e where e.order_id = o.id),
    'next_statuses', app.order_next_statuses(p_role, o.fulfillment, o.status),
    'substitution_allowed', pu.substitution_allowed,
    'adjustments', app.order_adjustments_json(o.id))
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.payment_methods pm on pm.id = pu.payment_method_id
  join public.stores s on s.id = o.store_id
  join public.zones z on z.id = s.zone_id
  where o.id = p_order
$$;

-- ------------------------------------------------------------------ droits

revoke all on function app.order_party(uuid, uuid), app.credit_order_line(uuid),
  app.order_adjustments_json(uuid), app.order_photo_keys(uuid, uuid),
  public.propose_substitution(uuid, uuid, uuid, text, text), public.answer_substitution(uuid, boolean),
  public.claim_freshness(uuid, uuid, text, text) from public;
grant execute on function public.propose_substitution(uuid, uuid, uuid, text, text),
  public.answer_substitution(uuid, boolean), public.claim_freshness(uuid, uuid, text, text)
  to authenticated;
