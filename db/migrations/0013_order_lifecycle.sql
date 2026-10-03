-- 0013 — Cycle de vie des commandes et notifications (spec 011 : V-ORD-01..09,
-- C-ORD-01..04/07, C-NOTIF-01..05/09, C-PROF-03/06).
-- Les transitions sont décidées ici (règles par rôle et par mode), tracées,
-- et créent les notifications ; la Function envoie les push à partir de la
-- file (`notifications.pushed_at`).

-- ------------------------------------------------------------------ statuts

alter table public.orders drop constraint orders_status_check;
alter table public.orders add constraint orders_status_check check (status in (
  'pending', 'accepted', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'refused', 'cancelled'));

alter table public.orders
  add column accepted_at timestamptz,
  add column preparing_at timestamptz,
  add column ready_at timestamptz,
  add column out_for_delivery_at timestamptz,
  add column delivered_at timestamptz,
  add column refused_at timestamptz,
  add column cancelled_at timestamptz,
  add column status_reason text check (status_reason in ('out_of_stock', 'too_busy', 'area_not_served', 'other')),
  add column status_note text check (length(status_note) <= 200),
  add column cancelled_by text check (cancelled_by in ('client', 'vendor', 'admin', 'system')),
  add column cash_collected_at timestamptz,
  add column refund_due boolean not null default false;

grant select (
  accepted_at, preparing_at, ready_at, out_for_delivery_at, delivered_at, refused_at, cancelled_at,
  status_reason, status_note, cancelled_by, cash_collected_at, refund_due
) on public.orders to authenticated;

-- Historique des statuts (chronologie : suivi, vendeuse, admin).
create table public.order_status_events (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders (id) on delete cascade,
  from_status text not null,
  to_status text not null,
  actor_role text not null check (actor_role in ('client', 'vendor', 'admin', 'system')),
  actor_id uuid,
  reason text,
  note text,
  occurred_at timestamptz not null default clock_timestamp()
);

create index order_status_events_order on public.order_status_events (order_id, occurred_at);

alter table public.order_status_events enable row level security;
create policy order_status_events_party_read on public.order_status_events for select
  to authenticated using (app.can_read_order(order_id));
grant select (id, order_id, from_status, to_status, actor_role, reason, occurred_at)
  on public.order_status_events to authenticated;

-- Transitions permises (FR-001).
create or replace function app.order_transition_allowed(
  p_role text, p_fulfillment text, p_from text, p_to text
) returns boolean
language sql immutable
as $$
  select case p_role
    when 'vendor' then
      (p_from, p_to) in (('pending', 'accepted'), ('pending', 'refused'), ('accepted', 'preparing'),
                         ('accepted', 'ready'), ('preparing', 'ready'))
      or (p_fulfillment = 'delivery'
          and (p_from, p_to) in (('ready', 'out_for_delivery'), ('out_for_delivery', 'delivered')))
      or (p_fulfillment = 'pickup' and (p_from, p_to) = ('ready', 'delivered'))
    when 'client' then p_from in ('pending', 'accepted') and p_to = 'cancelled'
    else false
  end
$$;

-- Étapes suivantes permises (gestes affichés par les apps).
create or replace function app.order_next_statuses(p_role text, p_fulfillment text, p_from text)
returns jsonb
language sql immutable
as $$
  select coalesce(jsonb_agg(s order by o), '[]'::jsonb)
  from unnest(array['accepted', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'refused', 'cancelled'])
    with ordinality as t(s, o)
  where app.order_transition_allowed(p_role, p_fulfillment, p_from, s)
$$;

-- Heure de livraison (ou de retrait) estimée.
create or replace function app.order_eta(p_order uuid) returns timestamptz
language sql stable security definer set search_path = ''
as $$
  select coalesce(o.accepted_at, o.created_at)
    + make_interval(mins => s.prep_time_minutes
        + case when o.fulfillment = 'delivery'
               then coalesce((select c.delivery_minutes from public.zones z
                              join public.cities c on c.id = z.city_id
                              where z.id = (pu.address ->> 'zone_id')::uuid), 0)
               else 0 end)
  from public.orders o
  join public.stores s on s.id = o.store_id
  join public.purchases pu on pu.id = o.purchase_id
  where o.id = p_order
$$;

-- ------------------------------------------------------------------ notifications

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  kind text not null check (kind ~ '^[a-z]+(_[a-z]+)*$'),
  category text not null check (category in ('orders', 'payments', 'messages', 'promotions')),
  order_id uuid references public.orders (id) on delete cascade,
  purchase_id uuid references public.purchases (id) on delete cascade,
  params jsonb not null default '{}'::jsonb check (jsonb_typeof(params) = 'object'),
  read_at timestamptz,
  pushed_at timestamptz,
  push_outcome text check (push_outcome in ('claimed', 'sent', 'skipped', 'failed')),
  created_at timestamptz not null default clock_timestamp()
);

create index notifications_user on public.notifications (user_id, created_at desc);
create index notifications_to_push on public.notifications (created_at) where pushed_at is null;

create table public.notification_preferences (
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  category text not null check (category in ('orders', 'payments', 'messages', 'promotions')),
  push_enabled boolean not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, category)
);

create table public.push_tokens (
  token text primary key check (length(token) between 10 and 4096),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'web')),
  app text not null check (app in ('client', 'vendor', 'admin')),
  updated_at timestamptz not null default now()
);

create index push_tokens_user on public.push_tokens (user_id, app);

alter table public.notifications enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.push_tokens enable row level security;

create policy notifications_owner_read on public.notifications for select
  to authenticated using (user_id = app.current_user_id());
grant select (id, user_id, kind, category, order_id, purchase_id, params, read_at, created_at)
  on public.notifications to authenticated;
-- Préférences et téléphones : par fonctions seulement.

-- Types destinés à l'app vendeuse (les autres vont à l'app cliente).
create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client') then 'vendor' else 'client' end
$$;

-- Push autorisé (par défaut : oui, sauf les bons plans).
create or replace function app.push_allowed(p_user uuid, p_category text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    (select push_enabled from public.notification_preferences where user_id = p_user and category = p_category),
    p_category <> 'promotions')
$$;

create or replace function app.notify(
  p_user uuid,
  p_kind text,
  p_category text,
  p_order uuid default null,
  p_purchase uuid default null,
  p_params jsonb default '{}'::jsonb
) returns void
language sql security definer set search_path = ''
as $$
  insert into public.notifications (user_id, kind, category, order_id, purchase_id, params)
  values (p_user, p_kind, p_category, p_order, p_purchase, coalesce(p_params, '{}'::jsonb))
$$;

-- Nouvelle commande visible pour la propriétaire de la boutique.
create or replace function app.notify_new_order(p_order uuid) returns void
language sql security definer set search_path = ''
as $$
  select app.notify(s.owner_id, 'new_order', 'orders', o.id, o.purchase_id,
    jsonb_build_object('customer_first_name', pr.first_name, 'total_minor', o.total_minor,
                       'currency_code', o.currency_code, 'fulfillment', o.fulfillment,
                       'payment_status', pu.payment_status))
  from public.orders o
  join public.stores s on s.id = o.store_id
  join public.purchases pu on pu.id = o.purchase_id
  left join public.profiles pr on pr.user_id = pu.user_id
  where o.id = p_order
$$;

-- Commande cash créée : visible tout de suite.
create or replace function app.on_order_created() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if (select payment_status from public.purchases where id = new.purchase_id) = 'cash_on_delivery' then
    perform app.notify_new_order(new.id);
  end if;
  return new;
end
$$;

create trigger orders_notify_created after insert on public.orders
  for each row execute function app.on_order_created();

-- Paiement : la cliente est prévenue ; les vendeuses voient la commande.
create or replace function app.on_payment_status_changed() returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_order uuid;
begin
  if new.payment_status = 'paid' then
    perform app.notify(new.user_id, 'payment_succeeded', 'payments', null, new.id,
      jsonb_build_object('total_minor', new.total_minor, 'currency_code', new.currency_code));
  elsif new.payment_status = 'failed' then
    perform app.notify(new.user_id, 'payment_failed', 'payments', null, new.id,
      jsonb_build_object('total_minor', new.total_minor, 'currency_code', new.currency_code));
  end if;
  if new.payment_status = 'paid'
     or (new.payment_status = 'cash_on_delivery' and old.payment_status in ('awaiting_payment', 'failed')) then
    for v_order in select id from public.orders where purchase_id = new.id loop
      perform app.notify_new_order(v_order);
    end loop;
  end if;
  return new;
end
$$;

create trigger purchases_notify_payment after update of payment_status on public.purchases
  for each row when (old.payment_status is distinct from new.payment_status)
  execute function app.on_payment_status_changed();

-- ------------------------------------------------------------------ transitions

-- Commande vue par la cliente ('client') ou par sa vendeuse ('vendor').
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
    'substitution_allowed', pu.substitution_allowed)
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.payment_methods pm on pm.id = pu.payment_method_id
  join public.stores s on s.id = o.store_id
  join public.zones z on z.id = s.zone_id
  where o.id = p_order
$$;

-- Transition d'une commande par sa vendeuse ou sa cliente (Function).
-- [p_expected] : statut vu par l'app (refus `status_changed` s'il a changé).
-- Refus (P0001) : status_changed, transition_not_allowed, reason_required ;
-- commande invisible ou d'autrui : P0002.
create or replace function app.transition_order(
  p_user uuid,
  p_order uuid,
  p_to text,
  p_expected text,
  p_reason text default null,
  p_note text default null
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
  v_purchase public.purchases;
  v_owner uuid;
  v_store_name text;
  v_role text;
  v_country char(2);
  v_event text;
begin
  select * into v_order from public.orders where id = p_order for update;
  if v_order.id is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  select * into v_purchase from public.purchases where id = v_order.purchase_id;
  select owner_id, name into v_owner, v_store_name from public.stores where id = v_order.store_id;
  v_role := case
    when p_user = v_owner and v_purchase.payment_status in ('cash_on_delivery', 'paid') then 'vendor'
    when p_user = v_purchase.user_id then 'client'
  end;
  if v_role is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  if p_expected is distinct from v_order.status then
    raise exception 'status_changed' using errcode = 'P0001';
  end if;
  if not app.order_transition_allowed(v_role, v_order.fulfillment, v_order.status, p_to) then
    raise exception 'transition_not_allowed' using errcode = 'P0001';
  end if;
  if p_to = 'refused'
     and (p_reason is null or p_reason not in ('out_of_stock', 'too_busy', 'area_not_served', 'other')) then
    raise exception 'reason_required' using errcode = 'P0001';
  end if;

  update public.orders set
    status = p_to,
    accepted_at = case when p_to = 'accepted' then now() else accepted_at end,
    preparing_at = case when p_to = 'preparing' then now() else preparing_at end,
    ready_at = case when p_to = 'ready' then now() else ready_at end,
    out_for_delivery_at = case when p_to = 'out_for_delivery' then now() else out_for_delivery_at end,
    delivered_at = case when p_to = 'delivered' then now() else delivered_at end,
    refused_at = case when p_to = 'refused' then now() else refused_at end,
    cancelled_at = case when p_to = 'cancelled' then now() else cancelled_at end,
    status_reason = case when p_to = 'refused' then p_reason else status_reason end,
    status_note = case when p_to in ('refused', 'cancelled') then left(nullif(trim(p_note), ''), 200)
                       else status_note end,
    cancelled_by = case when p_to = 'cancelled' then v_role else cancelled_by end,
    refund_due = refund_due or (p_to in ('refused', 'cancelled') and v_purchase.payment_status = 'paid')
  where id = p_order;

  insert into public.order_status_events (order_id, from_status, to_status, actor_role, actor_id, reason, note)
  values (p_order, v_order.status, p_to, v_role, p_user,
          case when p_to = 'refused' then p_reason end, left(nullif(trim(p_note), ''), 200));

  -- Refus ou annulation : le stock suivi est rendu.
  if p_to in ('refused', 'cancelled') then
    update public.product_variants v
    set stock_quantity = v.stock_quantity + i.quantity
    from public.order_items i
    where i.order_id = p_order and i.variant_id = v.id and v.stock_quantity is not null;
  end if;

  -- Notifications.
  if v_role = 'vendor' then
    perform app.notify(v_purchase.user_id, 'order_' || p_to, 'orders', p_order, v_purchase.id,
      jsonb_build_object('store_name', v_store_name, 'fulfillment', v_order.fulfillment,
                         'reason', case when p_to = 'refused' then p_reason end,
                         'eta_at', case when p_to = 'accepted' then app.order_eta(p_order) end));
  else
    perform app.notify(v_owner, 'order_cancelled_by_client', 'orders', p_order, v_purchase.id,
      jsonb_build_object('total_minor', v_order.total_minor, 'currency_code', v_order.currency_code));
  end if;

  -- Événements (sans donnée personnelle).
  v_country := v_purchase.country_code;
  perform app.emit_event('order_status_changed', p_user, v_role, 'server', v_country,
    'order', p_order::text,
    jsonb_build_object('from', v_order.status, 'to', p_to, 'fulfillment', v_order.fulfillment));
  v_event := case p_to
    when 'accepted' then 'order_accepted'
    when 'refused' then 'order_rejected'
    when 'delivered' then 'order_delivered'
    when 'cancelled' then 'order_cancelled'
  end;
  if v_event is not null then
    perform app.emit_event(v_event, p_user, v_role, 'server', v_country, 'order', p_order::text,
      jsonb_build_object('fulfillment', v_order.fulfillment, 'reason', p_reason,
                         'minutes_since_created',
                         round(extract(epoch from now() - v_order.created_at) / 60)::int));
  end if;

  return app.order_json(p_order, v_role);
end
$$;

-- Encaissement du cash par la vendeuse (commande livrée, une fois).
-- Refus (P0001) : not_cash, not_delivered.
create or replace function app.confirm_cash(p_user uuid, p_order uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
begin
  select o.* into v_order from public.orders o
  join public.stores s on s.id = o.store_id
  where o.id = p_order and s.owner_id = p_user
  for update of o;
  if v_order.id is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  if (select payment_status from public.purchases where id = v_order.purchase_id) <> 'cash_on_delivery' then
    raise exception 'not_cash' using errcode = 'P0001';
  end if;
  if v_order.status <> 'delivered' then
    raise exception 'not_delivered' using errcode = 'P0001';
  end if;
  if v_order.cash_collected_at is null then
    update public.orders set cash_collected_at = now() where id = p_order;
  end if;
  return app.order_json(p_order, 'vendor');
end
$$;

-- ------------------------------------------------------------------ lectures

-- Mes commandes (cliente), les plus récentes d'abord.
create or replace function public.my_orders(p_limit int default 50) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', o.id, 'purchase_id', o.purchase_id, 'status', o.status, 'fulfillment', o.fulfillment,
    'created_at', o.created_at, 'delivered_at', o.delivered_at,
    'eta_at', case when o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
                   then app.order_eta(o.id) end,
    'currency_code', o.currency_code, 'total_minor', o.total_minor,
    'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
    'payment_status', pu.payment_status,
    'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin))
    order by o.created_at desc, o.id), '[]'::jsonb)
  from (select * from public.orders o
        where exists (select 1 from public.purchases p where p.id = o.purchase_id and p.user_id = app.require_user())
        order by o.created_at desc, o.id
        limit least(greatest(coalesce(p_limit, 50), 1), 200)) o
  join public.purchases pu on pu.id = o.purchase_id
  join public.stores s on s.id = o.store_id
$$;

create or replace function public.my_order(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.orders o join public.purchases p on p.id = o.purchase_id
                 where o.id = p_id and p.user_id = app.require_user()) then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  return app.order_json(p_id, 'client') || jsonb_build_object(
    'address', (select p.address from public.purchases p join public.orders o on o.purchase_id = p.id
                where o.id = p_id));
end
$$;

-- Commandes de ma boutique : 'new' (en attente), 'active' (en cours),
-- 'done' (terminées), nul (toutes). Payées ou en cash seulement.
drop function public.my_store_orders(int);
create or replace function public.my_store_orders(p_scope text default null, p_limit int default 50)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.store_order_json(o.id, false)
    || jsonb_build_object('eta_at', case when o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
                                         then app.order_eta(o.id) end)
    order by o.created_at desc, o.id), '[]'::jsonb)
  from (
    select o.id, o.created_at, o.status from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    where o.store_id = app.own_store_id()
      and pu.payment_status in ('cash_on_delivery', 'paid')
      and (p_scope is null
        or (p_scope = 'new' and o.status = 'pending')
        or (p_scope = 'active' and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery'))
        or (p_scope = 'done' and o.status in ('delivered', 'refused', 'cancelled')))
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
  return app.store_order_json(p_id, true)
    || (app.order_json(p_id, 'vendor') - 'store' - 'items' - 'payment_method' - 'substitution_allowed');
end
$$;

-- ------------------------------------------------------------------ centre de notifications

create or replace function public.my_notifications(p_limit int default 50) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', n.id, 'kind', n.kind, 'category', n.category, 'order_id', n.order_id,
    'purchase_id', n.purchase_id, 'params', n.params, 'read_at', n.read_at, 'created_at', n.created_at)
    order by n.created_at desc, n.id), '[]'::jsonb)
  from (select * from public.notifications
        where user_id = app.require_user()
        order by created_at desc, id
        limit least(greatest(coalesce(p_limit, 50), 1), 200)) n
$$;

create or replace function public.unread_notifications_count() returns int
language sql stable security definer set search_path = ''
as $$
  select count(*)::int from public.notifications where user_id = app.require_user() and read_at is null
$$;

-- Marque lues [p_ids] (nul : toutes). Renvoie le nombre de non-lues restant.
create or replace function public.mark_notifications_read(p_ids uuid[] default null) returns int
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  update public.notifications set read_at = now()
  where user_id = v_user and read_at is null and (p_ids is null or id = any(p_ids));
  return public.unread_notifications_count();
end
$$;

create or replace function public.my_notification_preferences() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_agg(jsonb_build_object('category', c, 'push_enabled', app.push_allowed(app.require_user(), c))
                   order by o)
  from unnest(array['orders', 'payments', 'messages', 'promotions']) with ordinality as t(c, o)
$$;

create or replace function public.set_notification_preference(p_category text, p_enabled boolean)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
begin
  if p_category not in ('orders', 'payments', 'messages', 'promotions') or p_enabled is null then
    raise exception 'catégorie inconnue' using errcode = '22023';
  end if;
  insert into public.notification_preferences (user_id, category, push_enabled)
  values (app.require_user(), p_category, p_enabled)
  on conflict (user_id, category) do update set push_enabled = excluded.push_enabled, updated_at = now();
  return public.my_notification_preferences();
end
$$;

-- Téléphone enregistré pour le push (le jeton suit la personne connectée).
create or replace function public.register_push_token(p_token text, p_platform text, p_app text)
returns void
language sql security definer set search_path = ''
as $$
  insert into public.push_tokens (token, user_id, platform, app)
  values (p_token, app.require_user(), p_platform, p_app)
  on conflict (token) do update set user_id = excluded.user_id, platform = excluded.platform,
    app = excluded.app, updated_at = now()
$$;

create or replace function public.unregister_push_token(p_token text) returns void
language sql security definer set search_path = ''
as $$
  delete from public.push_tokens where token = p_token and user_id = app.require_user()
$$;

-- ------------------------------------------------------------------ file de push (Function)

-- Réserve les notifications à envoyer (jamais deux fois), avec les jetons de
-- l'app destinataire et l'autorisation de la catégorie.
create or replace function app.claim_pushes(p_limit int default 50) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_rows jsonb;
begin
  with claimed as (
    update public.notifications n set pushed_at = now(), push_outcome = 'claimed'
    where n.id in (
      select id from public.notifications
      where pushed_at is null and created_at > now() - interval '1 day'
      order by created_at
      limit least(greatest(coalesce(p_limit, 50), 1), 500)
      for update skip locked)
    returning n.*
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', c.id, 'kind', c.kind, 'category', c.category, 'order_id', c.order_id,
    'purchase_id', c.purchase_id, 'params', c.params,
    'locale', coalesce((select locale from public.profiles where user_id = c.user_id), 'fr'),
    'allowed', app.push_allowed(c.user_id, c.category),
    'tokens', coalesce((select jsonb_agg(t.token) from public.push_tokens t
                        where t.user_id = c.user_id and t.app = app.notification_app(c.kind)), '[]'::jsonb))),
    '[]'::jsonb)
  into v_rows
  from claimed c;
  return v_rows;
end
$$;

create or replace function app.push_result(p_ids uuid[], p_outcome text) returns void
language sql security definer set search_path = ''
as $$
  update public.notifications set push_outcome = p_outcome
  where id = any(p_ids) and p_outcome in ('sent', 'skipped', 'failed')
$$;

-- Jetons refusés par le fournisseur (téléphone désinstallé).
create or replace function app.drop_push_tokens(p_tokens text[]) returns void
language sql security definer set search_path = ''
as $$
  delete from public.push_tokens where token = any(p_tokens)
$$;

-- ------------------------------------------------------------------ droits

revoke all on function
  app.transition_order(uuid, uuid, text, text, text, text), app.confirm_cash(uuid, uuid),
  app.claim_pushes(int), app.push_result(uuid[], text), app.drop_push_tokens(text[]),
  public.my_orders(int), public.my_order(uuid), public.my_store_orders(text, int),
  public.my_notifications(int), public.unread_notifications_count(),
  public.mark_notifications_read(uuid[]), public.my_notification_preferences(),
  public.set_notification_preference(text, boolean), public.register_push_token(text, text, text),
  public.unregister_push_token(text)
from public;

grant execute on function
  public.my_orders(int), public.my_order(uuid), public.my_store_orders(text, int),
  public.my_notifications(int), public.unread_notifications_count(),
  public.mark_notifications_read(uuid[]), public.my_notification_preferences(),
  public.set_notification_preference(text, boolean), public.register_push_token(text, text, text),
  public.unregister_push_token(text)
to authenticated;
