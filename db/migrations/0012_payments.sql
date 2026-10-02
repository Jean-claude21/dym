-- 0012 — Paiements génériques et fournisseur simulé (spec 010 : C-PAY-01/02/06,
-- V-PAY-01/02/04/05, A-LOG-03).
-- La base décide de l'état de paiement d'un achat et de la visibilité des
-- commandes ; les Functions ne portent que l'appel au fournisseur et la
-- réception des confirmations (webhooks signés, journalisés bruts).

-- Simulateur : fournisseur de test (page de paiement servie par DYM). Aucun
-- moyen par pays n'est créé ici ; la Function ne l'expose jamais en production.
insert into public.payment_providers (code, label, kind) values
  ('simulator', '{"fr": "Mobile Money (simulé)", "en": "Mobile Money (simulated)"}', 'mobile_money');

-- ------------------------------------------------------------------ état de paiement

alter table public.purchases
  add column payment_status text not null default 'cash_on_delivery'
    check (payment_status in ('cash_on_delivery', 'awaiting_payment', 'paid', 'failed'));

-- ------------------------------------------------------------------ paiements

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references public.purchases (id) on delete cascade,
  payment_method_id uuid not null references public.payment_methods (id),
  provider_code text not null references public.payment_providers (code),
  amount_minor bigint not null check (amount_minor > 0),
  currency_code char(3) not null references public.currencies (code),
  status text not null default 'pending'
    check (status in ('pending', 'succeeded', 'failed', 'cancelled')),
  provider_reference text check (length(provider_reference) <= 200),
  checkout_url text check (length(checkout_url) <= 2000),
  last_error text check (length(last_error) <= 500),
  idempotency_key uuid not null,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (purchase_id, idempotency_key)
);

-- Un seul paiement réussi par achat.
create unique index payments_one_success on public.payments (purchase_id) where status = 'succeeded';
create index payments_purchase on public.payments (purchase_id, created_at desc);

create trigger payments_updated_at before update on public.payments
  for each row execute function app.set_updated_at();

-- Confirmations reçues (A-LOG-03) : corps brut, signature, résultat.
create table public.payment_events (
  id bigint generated always as identity primary key,
  provider_code text not null,
  event_id text not null check (length(event_id) between 1 and 200),
  payment_id uuid references public.payments (id) on delete set null,
  signature_valid boolean not null,
  payload jsonb not null,
  outcome text not null check (outcome in ('applied', 'duplicate', 'ignored', 'rejected')),
  detail text,
  received_at timestamptz not null default now()
);

-- Un événement n'est appliqué qu'une fois.
create unique index payment_events_applied_once
  on public.payment_events (provider_code, event_id) where outcome = 'applied';

alter table public.payments enable row level security;
alter table public.payment_events enable row level security;

create policy payments_owner_read on public.payments for select
  to authenticated using (exists (
    select 1 from public.purchases pu
    where pu.id = purchase_id and pu.user_id = app.current_user_id()));

grant select (
  id, purchase_id, payment_method_id, provider_code, amount_minor, currency_code, status,
  checkout_url, created_at, updated_at, completed_at
) on public.payments to authenticated;
-- payment_events : interne (aucun droit pour les rôles de l'API).

-- Référence courte affichée (cliente, vendeuse, support).
create or replace function app.payment_reference(p_payment uuid) returns text
language sql immutable
as $$
  select 'PA-' || upper(substr(replace(p_payment::text, '-', ''), 1, 6))
$$;

-- ------------------------------------------------------------------ visibilité

-- Commande visible par sa cliente ; par la propriétaire de la boutique
-- seulement si l'achat est payé ou en cash (jamais en attente de paiement).
create or replace function app.can_read_order(p_order uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    join public.stores s on s.id = o.store_id
    where o.id = p_order
      and (app.current_user_id() = pu.user_id
        or (app.current_user_id() = s.owner_id
            and pu.payment_status in ('cash_on_delivery', 'paid')))
  )
$$;

-- ------------------------------------------------------------------ commande

-- Achat : état de paiement et tentative courante en plus.
create or replace function app.purchase_json(p_purchase uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', pu.id, 'created_at', pu.created_at,
    'country_code', pu.country_code, 'currency_code', pu.currency_code,
    'payment_method', jsonb_build_object('id', pm.id, 'country_code', pm.country_code,
                                         'provider_code', pm.provider_code,
                                         'operator_code', pm.operator_code, 'label', pm.label),
    'address', pu.address, 'substitution_allowed', pu.substitution_allowed,
    'payment_status', pu.payment_status,
    'payment', (
      select jsonb_build_object(
        'id', pa.id, 'status', pa.status, 'provider_code', pa.provider_code,
        'checkout_url', pa.checkout_url, 'amount_minor', pa.amount_minor,
        'reference', app.payment_reference(pa.id), 'completed_at', pa.completed_at)
      from public.payments pa where pa.purchase_id = pu.id
      order by pa.created_at desc, pa.id limit 1),
    'subtotal_minor', pu.subtotal_minor, 'delivery_fee_minor', pu.delivery_fee_minor,
    'total_minor', pu.total_minor,
    'orders', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', o.id, 'status', o.status, 'fulfillment', o.fulfillment,
        'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin),
        'subtotal_minor', o.subtotal_minor, 'delivery_fee_minor', o.delivery_fee_minor,
        'total_minor', o.total_minor,
        'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
        'items', (select coalesce(jsonb_agg(jsonb_build_object(
                    'product_id', i.product_id, 'variant_id', i.variant_id, 'name', i.product_name,
                    'variant_label', i.variant_label, 'unit_label', i.unit_label,
                    'unit_price_minor', i.unit_price_minor, 'quantity', i.quantity,
                    'amount_minor', i.amount_minor) order by i.product_name), '[]'::jsonb)
                  from public.order_items i where i.order_id = o.id))
        order by o.total_minor desc, o.id), '[]'::jsonb)
      from public.orders o join public.stores s on s.id = o.store_id
      where o.purchase_id = pu.id))
  from public.purchases pu
  join public.payment_methods pm on pm.id = pu.payment_method_id
  where pu.id = p_purchase
$$;

-- Commande : un moyen en ligne crée la première tentative de paiement.
-- [p_online_providers] : fournisseurs disponibles dans ce déploiement (la
-- Function les passe) ; tout autre fournisseur en ligne est refusé.
drop function app.place_order(uuid, uuid, jsonb, timestamptz);

create or replace function app.place_order(
  p_user uuid,
  p_key uuid,
  p_request jsonb,
  p_at timestamptz default now(),
  p_online_providers text[] default '{}'
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_existing uuid;
  v_cart public.carts;
  v_address public.customer_addresses;
  v_zone uuid;
  v_method public.payment_methods;
  v_quote jsonb;
  v_purchase uuid;
  v_order uuid;
  v_store jsonb;
  v_line jsonb;
  v_commission bigint;
  v_expected bigint := (p_request ->> 'expected_total_minor')::bigint;
begin
  if p_user is null or p_key is null then
    raise exception 'utilisateur et clé obligatoires' using errcode = '22023';
  end if;
  select id into v_existing from public.purchases where user_id = p_user and idempotency_key = p_key;
  if v_existing is not null then
    return jsonb_build_object('replayed', true, 'purchase', app.purchase_json(v_existing));
  end if;

  select * into v_cart from public.carts where user_id = p_user for update;
  -- Une demande concurrente avec la même clé a pu finir pendant l'attente.
  select id into v_existing from public.purchases where user_id = p_user and idempotency_key = p_key;
  if v_existing is not null then
    return jsonb_build_object('replayed', true, 'purchase', app.purchase_json(v_existing));
  end if;
  if v_cart.id is null or not exists (select 1 from public.cart_items where cart_id = v_cart.id) then
    raise exception 'cart_empty' using errcode = 'P0001';
  end if;
  -- Stocks verrouillés avant le devis : il reste vrai jusqu'à la fin.
  perform 1 from public.product_variants v
  join public.cart_items ci on ci.variant_id = v.id
  where ci.cart_id = v_cart.id
  for update of v;

  if p_request ->> 'address_id' is not null then
    v_address := app.delivery_address(p_user, (p_request ->> 'address_id')::uuid, v_cart.country_code);
  end if;
  v_zone := v_address.zone_id;
  select * into v_method from public.payment_methods where id = (p_request ->> 'payment_method_id')::uuid;
  v_quote := app.cart_quote(v_cart.id, v_zone, coalesce(p_request -> 'modes', '{}'::jsonb), v_method.id, p_at);

  if v_address.id is null and exists (
    select 1 from jsonb_array_elements(v_quote -> 'stores') s where s ->> 'fulfillment' = 'delivery'
  ) then
    raise exception 'address_required' using errcode = 'P0001';
  end if;
  if v_method.id is null or not exists (
    select 1 from jsonb_array_elements(v_quote -> 'payment_methods') m where (m ->> 'id')::uuid = v_method.id
  ) then
    raise exception 'payment_not_accepted' using errcode = 'P0001';
  end if;
  if (v_quote ->> 'blocking')::boolean then
    raise exception 'cart_blocked' using errcode = 'P0001';
  end if;
  -- Moyen en ligne : seulement si son fournisseur est disponible ici.
  if v_method.provider_code <> 'cash'
     and not v_method.provider_code = any(coalesce(p_online_providers, '{}')) then
    raise exception 'payment_unavailable' using errcode = 'P0001';
  end if;
  if v_expected is not null and v_expected <> (v_quote ->> 'total_minor')::bigint then
    raise exception 'total_changed' using errcode = 'P0001';
  end if;

  insert into public.purchases (
    user_id, idempotency_key, country_code, currency_code, payment_method_id, address,
    substitution_allowed, subtotal_minor, delivery_fee_minor, total_minor, payment_status)
  values (
    p_user, p_key, v_cart.country_code, v_cart.currency_code, v_method.id,
    case when v_address.id is null then null else (
      select jsonb_build_object(
        'id', v_address.id, 'kind', v_address.kind, 'label', v_address.label,
        'zone_id', z.id, 'zone_name', z.name, 'city_name', c.name,
        'landmark', v_address.landmark, 'phone', v_address.phone,
        'latitude', v_address.latitude, 'longitude', v_address.longitude)
      from public.zones z join public.cities c on c.id = z.city_id where z.id = v_address.zone_id)
    end,
    coalesce((p_request ->> 'substitution_allowed')::boolean, true),
    (v_quote ->> 'subtotal_minor')::bigint, (v_quote ->> 'delivery_fee_minor')::bigint,
    (v_quote ->> 'total_minor')::bigint,
    case when v_method.provider_code = 'cash' then 'cash_on_delivery' else 'awaiting_payment' end)
  returning id into v_purchase;

  -- Moyen en ligne : première tentative, que la Function initie ensuite.
  if v_method.provider_code <> 'cash' then
    insert into public.payments (
      purchase_id, payment_method_id, provider_code, amount_minor, currency_code, idempotency_key)
    values (
      v_purchase, v_method.id, v_method.provider_code, (v_quote ->> 'total_minor')::bigint,
      v_cart.currency_code, p_key);
  end if;

  for v_store in select * from jsonb_array_elements(v_quote -> 'stores') loop
    select coalesce(sum(floor((l ->> 'amount_minor')::bigint
             * app.commission_rate(v_cart.country_code, (l ->> 'category_id')::uuid) / 10000.0)), 0)
    into v_commission
    from jsonb_array_elements(v_store -> 'lines') l;

    insert into public.orders (
      purchase_id, store_id, fulfillment, currency_code,
      subtotal_minor, delivery_fee_minor, total_minor, commission_minor)
    values (
      v_purchase, (v_store ->> 'id')::uuid, v_store ->> 'fulfillment', v_cart.currency_code,
      (v_store ->> 'subtotal_minor')::bigint, (v_store ->> 'delivery_fee_minor')::bigint,
      (v_store ->> 'subtotal_minor')::bigint + (v_store ->> 'delivery_fee_minor')::bigint,
      v_commission)
    returning id into v_order;

    for v_line in select * from jsonb_array_elements(v_store -> 'lines') loop
      insert into public.order_items (
        order_id, product_id, variant_id, product_name, variant_label, unit_label,
        unit_price_minor, quantity, amount_minor)
      values (
        v_order, (v_line ->> 'product_id')::uuid, (v_line ->> 'variant_id')::uuid,
        v_line ->> 'name', v_line ->> 'variant_label', v_line -> 'unit_label',
        (v_line ->> 'unit_price_minor')::bigint, (v_line ->> 'quantity')::smallint,
        (v_line ->> 'amount_minor')::bigint);
      update public.product_variants
      set stock_quantity = stock_quantity - (v_line ->> 'quantity')::int
      where id = (v_line ->> 'variant_id')::uuid and stock_quantity is not null;
    end loop;
  end loop;

  delete from public.cart_items where cart_id = v_cart.id;
  update public.carts set updated_at = now() where id = v_cart.id;

  perform app.emit_event(
    'order_created', p_user, 'client', 'server', v_cart.country_code, 'purchase', v_purchase::text,
    jsonb_build_object(
      'stores_count', jsonb_array_length(v_quote -> 'stores'),
      'items_count', (v_quote ->> 'item_count')::int,
      'delivery_count', (v_quote ->> 'pickup_count')::int,
      'payment_provider', v_method.provider_code));

  return jsonb_build_object('replayed', false, 'purchase', app.purchase_json(v_purchase));
end
$$;

-- ------------------------------------------------------------------ cycle du paiement

-- Achat recalculé à partir de ses paiements (jamais le cash, déjà décidé).
create or replace function app.refresh_payment_status(p_purchase uuid) returns void
language sql security definer set search_path = ''
as $$
  update public.purchases pu set payment_status = case
      when exists (select 1 from public.payments p where p.purchase_id = pu.id and p.status = 'succeeded')
        then 'paid'
      when exists (select 1 from public.payments p where p.purchase_id = pu.id and p.status = 'pending')
        then 'awaiting_payment'
      else 'failed'
    end
  where pu.id = p_purchase and pu.payment_status <> 'cash_on_delivery'
$$;

-- Le fournisseur a accepté la création : référence et page de paiement.
create or replace function app.payment_initiated(
  p_payment uuid,
  p_reference text,
  p_checkout_url text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_payment public.payments;
  v_country char(2);
  v_user uuid;
begin
  update public.payments
  set provider_reference = p_reference, checkout_url = p_checkout_url
  where id = p_payment and status = 'pending'
  returning * into v_payment;
  if v_payment.id is null then
    raise exception 'paiement introuvable ou terminé' using errcode = 'P0002';
  end if;
  select country_code, user_id into v_country, v_user from public.purchases where id = v_payment.purchase_id;
  perform app.emit_event('payment_initiated', v_user, 'client', 'server', v_country,
    'payment', v_payment.id::text, jsonb_build_object('provider_code', v_payment.provider_code));
  return app.purchase_json(v_payment.purchase_id);
end
$$;

-- Le fournisseur a refusé ou n'a pas répondu à la création.
create or replace function app.payment_initiation_failed(p_payment uuid, p_error text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_payment public.payments;
  v_country char(2);
  v_user uuid;
begin
  update public.payments
  set status = 'failed', last_error = left(p_error, 500), completed_at = now()
  where id = p_payment and status = 'pending'
  returning * into v_payment;
  if v_payment.id is null then
    raise exception 'paiement introuvable ou terminé' using errcode = 'P0002';
  end if;
  perform app.refresh_payment_status(v_payment.purchase_id);
  select country_code, user_id into v_country, v_user from public.purchases where id = v_payment.purchase_id;
  perform app.emit_event('payment_failed', v_user, 'client', 'server', v_country,
    'payment', v_payment.id::text,
    jsonb_build_object('provider_code', v_payment.provider_code, 'reason', 'initiation'));
  return app.purchase_json(v_payment.purchase_id);
end
$$;

-- Confirmation d'un fournisseur (webhook), déjà vérifiée par la Function :
-- journalisée brute, appliquée une fois, montant contrôlé. Renvoie le
-- résultat : applied, duplicate, ignored ou rejected.
create or replace function app.apply_payment_event(
  p_provider text,
  p_event_id text,
  p_payload jsonb,
  p_signature_valid boolean,
  p_payment uuid,
  p_outcome text,
  p_amount_minor bigint,
  p_currency char(3)
) returns text
language plpgsql security definer set search_path = ''
as $$
declare
  v_payment public.payments;
  v_outcome text;
  v_detail text;
  v_country char(2);
  v_user uuid;
  v_stores int;
begin
  if not coalesce(p_signature_valid, false) then
    v_outcome := 'rejected';
    v_detail := 'signature invalide';
  elsif exists (select 1 from public.payment_events
                where provider_code = p_provider and event_id = p_event_id and outcome = 'applied') then
    v_outcome := 'duplicate';
  elsif p_outcome not in ('succeeded', 'failed', 'cancelled') then
    v_outcome := 'ignored';
    v_detail := 'issue inconnue';
  else
    select * into v_payment from public.payments where id = p_payment for update;
    if v_payment.id is null or v_payment.provider_code <> p_provider then
      v_outcome := 'ignored';
      v_detail := 'paiement inconnu';
    elsif v_payment.status <> 'pending' then
      v_outcome := 'duplicate';
      v_detail := 'paiement déjà ' || v_payment.status;
    elsif p_outcome = 'succeeded'
          and (p_amount_minor is distinct from v_payment.amount_minor
               or p_currency is distinct from v_payment.currency_code) then
      v_outcome := 'ignored';
      v_detail := 'montant ou devise différents';
    else
      update public.payments set status = p_outcome, completed_at = now()
      where id = v_payment.id;
      perform app.refresh_payment_status(v_payment.purchase_id);
      select country_code, user_id into v_country, v_user from public.purchases where id = v_payment.purchase_id;
      select count(*) into v_stores from public.orders where purchase_id = v_payment.purchase_id;
      if p_outcome = 'succeeded' then
        perform app.emit_event('payment_succeeded', v_user, 'client', 'server', v_country,
          'payment', v_payment.id::text,
          jsonb_build_object('provider_code', p_provider, 'stores_count', v_stores));
      else
        perform app.emit_event('payment_failed', v_user, 'client', 'server', v_country,
          'payment', v_payment.id::text,
          jsonb_build_object('provider_code', p_provider, 'reason', p_outcome));
      end if;
      v_outcome := 'applied';
    end if;
  end if;

  insert into public.payment_events (
    provider_code, event_id, payment_id, signature_valid, payload, outcome, detail)
  values (
    p_provider, coalesce(nullif(p_event_id, ''), 'sans-identifiant'),
    case when exists (select 1 from public.payments where id = p_payment) then p_payment end,
    coalesce(p_signature_valid, false), coalesce(p_payload, '{}'::jsonb), v_outcome, v_detail);
  return v_outcome;
end
$$;

-- Moyen en ligne accepté par toutes les boutiques d'un achat.
create or replace function app.purchase_accepts(p_purchase uuid, p_method uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.payment_methods pm
    join public.purchases pu on pu.id = p_purchase and pu.country_code = pm.country_code
    where pm.id = p_method and pm.is_active)
  and not exists (
    select 1 from public.orders o
    where o.purchase_id = p_purchase
      and not exists (select 1 from public.store_payment_methods spm
                      where spm.store_id = o.store_id and spm.payment_method_id = p_method))
$$;

-- Nouvelle tentative (même montant). Une clé déjà vue rend la même tentative.
-- Refus (P0001) : already_paid, not_online, payment_not_accepted,
-- payment_unavailable.
create or replace function app.retry_payment(
  p_user uuid,
  p_purchase uuid,
  p_key uuid,
  p_method uuid default null,
  p_online_providers text[] default '{}'
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_purchase public.purchases;
  v_method public.payment_methods;
  v_payment uuid;
begin
  select * into v_purchase from public.purchases where id = p_purchase and user_id = p_user for update;
  if v_purchase.id is null then
    raise exception 'achat introuvable' using errcode = 'P0002';
  end if;
  select id into v_payment from public.payments where purchase_id = p_purchase and idempotency_key = p_key;
  if v_payment is not null then
    return jsonb_build_object('replayed', true, 'payment_id', v_payment,
                              'purchase', app.purchase_json(p_purchase));
  end if;
  if v_purchase.payment_status = 'paid' then
    raise exception 'already_paid' using errcode = 'P0001';
  end if;
  if v_purchase.payment_status = 'cash_on_delivery' then
    raise exception 'not_online' using errcode = 'P0001';
  end if;
  select * into v_method from public.payment_methods
  where id = coalesce(p_method, v_purchase.payment_method_id);
  if v_method.id is null or v_method.provider_code = 'cash'
     or not app.purchase_accepts(p_purchase, v_method.id) then
    raise exception 'payment_not_accepted' using errcode = 'P0001';
  end if;
  if not v_method.provider_code = any(coalesce(p_online_providers, '{}')) then
    raise exception 'payment_unavailable' using errcode = 'P0001';
  end if;

  -- Une page abandonnée ne doit plus pouvoir confirmer.
  update public.payments set status = 'cancelled', completed_at = now()
  where purchase_id = p_purchase and status = 'pending';
  insert into public.payments (
    purchase_id, payment_method_id, provider_code, amount_minor, currency_code, idempotency_key)
  values (
    p_purchase, v_method.id, v_method.provider_code, v_purchase.total_minor,
    v_purchase.currency_code, p_key)
  returning id into v_payment;
  update public.purchases set payment_method_id = v_method.id, payment_status = 'awaiting_payment'
  where id = p_purchase;
  return jsonb_build_object('replayed', false, 'payment_id', v_payment,
                            'purchase', app.purchase_json(p_purchase));
end
$$;

-- Passage au paiement à la livraison après un échec ou un abandon.
-- Refus (P0001) : already_paid, cash_not_accepted.
create or replace function app.switch_to_cash(p_user uuid, p_purchase uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_purchase public.purchases;
  v_cash uuid;
begin
  select * into v_purchase from public.purchases where id = p_purchase and user_id = p_user for update;
  if v_purchase.id is null then
    raise exception 'achat introuvable' using errcode = 'P0002';
  end if;
  if v_purchase.payment_status = 'paid' then
    raise exception 'already_paid' using errcode = 'P0001';
  end if;
  if v_purchase.payment_status = 'cash_on_delivery' then
    return app.purchase_json(p_purchase);
  end if;
  select pm.id into v_cash from public.payment_methods pm
  where pm.country_code = v_purchase.country_code and pm.provider_code = 'cash' and pm.is_active
  limit 1;
  if v_cash is null or not app.purchase_accepts(p_purchase, v_cash) then
    raise exception 'cash_not_accepted' using errcode = 'P0001';
  end if;
  update public.payments set status = 'cancelled', completed_at = now()
  where purchase_id = p_purchase and status = 'pending';
  update public.purchases set payment_method_id = v_cash, payment_status = 'cash_on_delivery'
  where id = p_purchase;
  return app.purchase_json(p_purchase);
end
$$;

-- ------------------------------------------------------------------ vendeuse

-- Ligne de liste d'une commande pour la vendeuse (prénom et quartier de la
-- cliente seulement).
create or replace function app.store_order_json(p_order uuid, p_detail boolean) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id, 'created_at', o.created_at, 'status', o.status, 'fulfillment', o.fulfillment,
    'currency_code', o.currency_code,
    'subtotal_minor', o.subtotal_minor, 'delivery_fee_minor', o.delivery_fee_minor,
    'total_minor', o.total_minor,
    'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
    'customer_first_name', pr.first_name,
    'zone_name', case when o.fulfillment = 'delivery' then pu.address ->> 'zone_name' end,
    'payment_status', pu.payment_status,
    'payment_method', jsonb_build_object('id', pm.id, 'country_code', pm.country_code,
                                         'provider_code', pm.provider_code,
                                         'operator_code', pm.operator_code, 'label', pm.label),
    'substitution_allowed', pu.substitution_allowed)
  || case when not p_detail then '{}'::jsonb else jsonb_build_object(
    'items', (select coalesce(jsonb_agg(jsonb_build_object(
                'product_id', i.product_id, 'variant_id', i.variant_id, 'name', i.product_name,
                'variant_label', i.variant_label, 'unit_label', i.unit_label,
                'unit_price_minor', i.unit_price_minor, 'quantity', i.quantity,
                'amount_minor', i.amount_minor) order by i.product_name), '[]'::jsonb)
              from public.order_items i where i.order_id = o.id),
    'delivery', case when o.fulfillment = 'delivery' then jsonb_build_object(
                  'zone_name', pu.address ->> 'zone_name', 'city_name', pu.address ->> 'city_name',
                  'landmark', pu.address ->> 'landmark', 'phone', pu.address ->> 'phone',
                  'latitude', pu.address -> 'latitude', 'longitude', pu.address -> 'longitude') end,
    'payment', (select jsonb_build_object(
                  'status', pa.status, 'provider_code', pa.provider_code,
                  'amount_minor', pa.amount_minor, 'completed_at', pa.completed_at,
                  'reference', app.payment_reference(pa.id))
                from public.payments pa where pa.purchase_id = pu.id and pa.status = 'succeeded'))
  end
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.payment_methods pm on pm.id = pu.payment_method_id
  left join public.profiles pr on pr.user_id = pu.user_id
  where o.id = p_order
$$;

-- Commandes de ma boutique, payées ou en cash, les plus récentes d'abord.
create or replace function public.my_store_orders(p_limit int default 50) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.store_order_json(o.id, false) order by o.created_at desc, o.id), '[]'::jsonb)
  from (
    select o.id, o.created_at from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    where o.store_id = app.own_store_id()
      and pu.payment_status in ('cash_on_delivery', 'paid')
    order by o.created_at desc, o.id
    limit least(greatest(coalesce(p_limit, 50), 1), 200)
  ) o
$$;

create or replace function public.my_store_order(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.orders o join public.purchases pu on pu.id = o.purchase_id
    where o.id = p_id and o.store_id = app.own_store_id()
      and pu.payment_status in ('cash_on_delivery', 'paid')
  ) then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  return app.store_order_json(p_id, true);
end
$$;

-- ------------------------------------------------------------------ droits

revoke all on function
  app.place_order(uuid, uuid, jsonb, timestamptz, text[]), app.payment_initiated(uuid, text, text),
  app.payment_initiation_failed(uuid, text),
  app.apply_payment_event(text, text, jsonb, boolean, uuid, text, bigint, char),
  app.retry_payment(uuid, uuid, uuid, uuid, text[]), app.switch_to_cash(uuid, uuid),
  public.my_store_orders(int), public.my_store_order(uuid)
from public;

grant execute on function public.my_store_orders(int), public.my_store_order(uuid) to authenticated;
