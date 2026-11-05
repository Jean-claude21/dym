-- 0014 — Litiges (spec 012 : C-ORD-08, C-NOTIF-06, A-LIT-01..06).
-- La cliente signale un problème sur une commande ; cliente, vendeuse et
-- équipe échangent dans le litige ; l'équipe décide (clore, rembourser en
-- partie ou en totalité, avertir la vendeuse). Un remboursement décidé est
-- créé ici et exécuté par la Function (fournisseur de paiement) ou marqué
-- payé en cash par l'équipe (spec admin-ops).

-- ------------------------------------------------------------------ tables

create table public.disputes (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  opened_by uuid not null references neon_auth."user" (id) on delete cascade,
  reason text not null check (reason in (
    'missing_item', 'wrong_item', 'damaged', 'quality', 'not_delivered', 'other')),
  description text not null check (length(trim(description)) between 3 and 500),
  status text not null default 'open' check (status in ('open', 'resolved')),
  resolution text check (resolution in ('no_action', 'partial_refund', 'full_refund')),
  refund_minor bigint check (refund_minor > 0),
  vendor_warned boolean not null default false,
  internal_note text check (length(internal_note) <= 1000),
  resolved_by uuid references neon_auth."user" (id) on delete set null,
  created_at timestamptz not null default clock_timestamp(),
  resolved_at timestamptz,
  check ((status = 'resolved') = (resolution is not null)),
  check ((resolution in ('partial_refund', 'full_refund')) = (refund_minor is not null))
);

-- Un seul litige ouvert par commande.
create unique index disputes_one_open on public.disputes (order_id) where status = 'open';
create index disputes_open on public.disputes (created_at) where status = 'open';

create table public.dispute_messages (
  id uuid primary key default gen_random_uuid(),
  dispute_id uuid not null references public.disputes (id) on delete cascade,
  author_role text not null check (author_role in ('client', 'vendor', 'admin')),
  author_id uuid references neon_auth."user" (id) on delete set null,
  body text not null check (length(trim(body)) between 1 and 1000),
  created_at timestamptz not null default clock_timestamp()
);

create index dispute_messages_dispute on public.dispute_messages (dispute_id, created_at);

-- Remboursements décidés (litige ou annulation par l'équipe).
create table public.refunds (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  dispute_id uuid references public.disputes (id) on delete set null,
  amount_minor bigint not null check (amount_minor > 0),
  currency_code char(3) not null references public.currencies (code),
  method text not null check (method in ('provider', 'cash')),
  status text not null default 'pending' check (status in ('pending', 'succeeded', 'failed')),
  provider_reference text,
  last_error text,
  requested_by uuid references neon_auth."user" (id) on delete set null,
  created_at timestamptz not null default clock_timestamp(),
  completed_at timestamptz
);

create index refunds_pending on public.refunds (created_at) where status = 'pending';

alter table public.disputes enable row level security;
alter table public.dispute_messages enable row level security;
alter table public.refunds enable row level security;
-- Lecture par fonctions seulement (cliente, vendeuse, équipe).

-- ------------------------------------------------------------------ notifications

create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
                              'dispute_message', 'dispute_resolved_vendor')
              then 'vendor' else 'client' end
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('dispute_opened', 'fr', 'Problème signalé', '{customer_first_name} signale un problème sur sa commande.'),
  ('dispute_opened', 'en', 'Problem reported', '{customer_first_name} reported a problem with an order.'),
  ('dispute_message', 'fr', 'Nouveau message', 'Nouveau message sur un signalement.'),
  ('dispute_message', 'en', 'New message', 'New message on a reported problem.'),
  ('dispute_replied', 'fr', 'Réponse à ton signalement', '{author} t''a répondu.'),
  ('dispute_replied', 'en', 'Reply to your report', '{author} replied to you.'),
  ('dispute_resolved', 'fr', 'Signalement traité', 'L''équipe DYM a traité ton signalement.'),
  ('dispute_resolved', 'en', 'Report handled', 'The DYM team handled your report.'),
  ('dispute_resolved_vendor', 'fr', 'Signalement traité', 'L''équipe DYM a traité le signalement d''une commande.'),
  ('dispute_resolved_vendor', 'en', 'Report handled', 'The DYM team handled a reported order.');

-- ------------------------------------------------------------------ règles

-- Rôle admin d'un utilisateur explicite (gestes appelés par la Function).
create or replace function app.user_is_admin(p_user uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.user_roles where user_id = p_user and role = 'admin')
$$;

-- Rôle d'un utilisateur dans le litige d'une commande (nul : aucun).
create or replace function app.dispute_role(p_user uuid, p_order uuid) returns text
language sql stable security definer set search_path = ''
as $$
  select case
    when p_user = pu.user_id then 'client'
    when p_user = s.owner_id then 'vendor'
    when app.user_is_admin(p_user) then 'admin'
  end
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.stores s on s.id = o.store_id
  where o.id = p_order
$$;

-- Litige d'une commande : conversation et décision (note interne pour
-- l'équipe seulement).
create or replace function app.dispute_json(p_dispute uuid, p_internal boolean default false) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', d.id, 'order_id', d.order_id, 'reason', d.reason, 'description', d.description,
    'status', d.status, 'resolution', d.resolution, 'refund_minor', d.refund_minor,
    'currency_code', o.currency_code, 'vendor_warned', d.vendor_warned,
    'created_at', d.created_at, 'resolved_at', d.resolved_at,
    'store_name', s.name,
    'messages', (select coalesce(jsonb_agg(jsonb_build_object(
                   'id', m.id, 'author_role', m.author_role, 'body', m.body, 'created_at', m.created_at)
                   order by m.created_at, m.id), '[]'::jsonb)
                 from public.dispute_messages m where m.dispute_id = d.id))
  || case when p_internal then jsonb_build_object(
       'internal_note', d.internal_note,
       'customer_first_name', (select first_name from public.profiles where user_id = d.opened_by),
       'refunds', (select coalesce(jsonb_agg(jsonb_build_object(
                     'id', r.id, 'amount_minor', r.amount_minor, 'method', r.method, 'status', r.status,
                     'created_at', r.created_at, 'completed_at', r.completed_at) order by r.created_at), '[]'::jsonb)
                   from public.refunds r where r.dispute_id = d.id))
     else '{}'::jsonb end
  from public.disputes d
  join public.orders o on o.id = d.order_id
  join public.stores s on s.id = o.store_id
  where d.id = p_dispute
$$;

-- Ouverture par la cliente (Function). Refus (P0001) : dispute_not_allowed,
-- dispute_already_open ; raison inconnue : 22023.
create or replace function app.open_dispute(
  p_user uuid, p_order uuid, p_reason text, p_description text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
  v_owner uuid;
  v_dispute uuid;
  v_country char(2);
begin
  select o.* into v_order from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  where o.id = p_order and pu.user_id = p_user
  for update of o;
  if v_order.id is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  if p_reason is null
     or p_reason not in ('missing_item', 'wrong_item', 'damaged', 'quality', 'not_delivered', 'other') then
    raise exception 'raison inconnue' using errcode = '22023';
  end if;
  if v_order.status not in ('accepted', 'preparing', 'ready', 'out_for_delivery', 'delivered')
     or (v_order.status = 'delivered' and v_order.delivered_at < now() - interval '7 days') then
    raise exception 'dispute_not_allowed' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.disputes where order_id = p_order and status = 'open') then
    raise exception 'dispute_already_open' using errcode = 'P0001';
  end if;

  insert into public.disputes (order_id, opened_by, reason, description)
  values (p_order, p_user, p_reason, trim(p_description))
  returning id into v_dispute;
  insert into public.dispute_messages (dispute_id, author_role, author_id, body)
  values (v_dispute, 'client', p_user, trim(p_description));

  select owner_id into v_owner from public.stores where id = v_order.store_id;
  perform app.notify(v_owner, 'dispute_opened', 'orders', p_order, v_order.purchase_id,
    jsonb_build_object('customer_first_name', (select first_name from public.profiles where user_id = p_user),
                       'reason', p_reason));
  select country_code into v_country from public.purchases where id = v_order.purchase_id;
  perform app.emit_event('dispute_opened', p_user, 'client', 'server', v_country, 'dispute', v_dispute::text,
    jsonb_build_object('reason', p_reason, 'order_status', v_order.status));
  return app.dispute_json(v_dispute);
end
$$;

-- Message dans un litige ouvert (cliente, vendeuse ou équipe). Refus :
-- dispute_closed (P0001) ; hors du litige : P0002.
create or replace function app.dispute_reply(p_user uuid, p_dispute uuid, p_body text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_dispute public.disputes;
  v_role text;
  v_order public.orders;
  v_client uuid;
  v_owner uuid;
begin
  select * into v_dispute from public.disputes where id = p_dispute for update;
  if v_dispute.id is null then
    raise exception 'litige introuvable' using errcode = 'P0002';
  end if;
  v_role := app.dispute_role(p_user, v_dispute.order_id);
  if v_role is null then
    raise exception 'litige introuvable' using errcode = 'P0002';
  end if;
  if v_dispute.status <> 'open' then
    raise exception 'dispute_closed' using errcode = 'P0001';
  end if;
  insert into public.dispute_messages (dispute_id, author_role, author_id, body)
  values (p_dispute, v_role, p_user, trim(p_body));

  select * into v_order from public.orders where id = v_dispute.order_id;
  select user_id into v_client from public.purchases where id = v_order.purchase_id;
  select owner_id into v_owner from public.stores where id = v_order.store_id;
  if v_role in ('vendor', 'admin') then
    perform app.notify(v_client, 'dispute_replied', 'orders', v_order.id, v_order.purchase_id,
      jsonb_build_object('author', case when v_role = 'vendor'
        then (select name from public.stores where id = v_order.store_id) else 'DYM' end));
  end if;
  if v_role in ('client', 'admin') then
    perform app.notify(v_owner, 'dispute_message', 'orders', v_order.id, v_order.purchase_id, '{}'::jsonb);
  end if;
  return app.dispute_json(p_dispute, v_role = 'admin');
end
$$;

-- Décision de l'équipe (Function, rôle admin). [p_resolution] : no_action,
-- partial_refund (montant obligatoire), full_refund (total de la commande).
-- Refus (P0001) : dispute_closed, refund_amount_invalid ; non admin : 42501.
create or replace function app.resolve_dispute(
  p_admin uuid,
  p_dispute uuid,
  p_resolution text,
  p_refund_minor bigint default null,
  p_internal_note text default null,
  p_warn_vendor boolean default false
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_dispute public.disputes;
  v_order public.orders;
  v_purchase public.purchases;
  v_amount bigint;
  v_owner uuid;
  v_after jsonb;
begin
  if not app.user_is_admin(p_admin) then
    raise exception 'rôle admin requis' using errcode = '42501';
  end if;
  select * into v_dispute from public.disputes where id = p_dispute for update;
  if v_dispute.id is null then
    raise exception 'litige introuvable' using errcode = 'P0002';
  end if;
  if v_dispute.status <> 'open' then
    raise exception 'dispute_closed' using errcode = 'P0001';
  end if;
  if p_resolution is null or p_resolution not in ('no_action', 'partial_refund', 'full_refund') then
    raise exception 'décision inconnue' using errcode = '22023';
  end if;
  select * into v_order from public.orders where id = v_dispute.order_id;
  select * into v_purchase from public.purchases where id = v_order.purchase_id;
  if p_resolution = 'partial_refund'
     and (p_refund_minor is null or p_refund_minor <= 0 or p_refund_minor > v_order.total_minor) then
    raise exception 'refund_amount_invalid' using errcode = 'P0001';
  end if;
  v_amount := case p_resolution
    when 'full_refund' then v_order.total_minor
    when 'partial_refund' then p_refund_minor
  end;

  update public.disputes set
    status = 'resolved', resolution = p_resolution, refund_minor = v_amount,
    internal_note = left(nullif(trim(p_internal_note), ''), 1000),
    vendor_warned = coalesce(p_warn_vendor, false),
    resolved_by = p_admin, resolved_at = now()
  where id = p_dispute;

  if v_amount is not null then
    insert into public.refunds (order_id, dispute_id, amount_minor, currency_code, method, requested_by)
    values (v_order.id, p_dispute, v_amount, v_order.currency_code,
            case when v_purchase.payment_status = 'paid' then 'provider' else 'cash' end, p_admin);
    update public.orders set refund_due = true where id = v_order.id;
  end if;

  v_after := app.dispute_json(p_dispute, true);
  perform app.audit(p_admin, 'dispute_resolved', 'dispute', p_dispute::text,
    jsonb_build_object('status', 'open'), v_after, p_internal_note);
  perform app.notify(v_purchase.user_id, 'dispute_resolved', 'orders', v_order.id, v_purchase.id,
    jsonb_build_object('resolution', p_resolution, 'refund_minor', v_amount,
                       'currency_code', v_order.currency_code));
  select owner_id into v_owner from public.stores where id = v_order.store_id;
  perform app.notify(v_owner, 'dispute_resolved_vendor', 'orders', v_order.id, v_purchase.id,
    jsonb_build_object('resolution', p_resolution, 'vendor_warned', coalesce(p_warn_vendor, false)));
  perform app.emit_event('dispute_resolved', p_admin, 'admin', 'server', v_purchase.country_code,
    'dispute', p_dispute::text,
    jsonb_build_object('resolution', p_resolution, 'refund_minor', v_amount,
                       'vendor_warned', coalesce(p_warn_vendor, false),
                       'hours_open', round(extract(epoch from now() - v_dispute.created_at) / 3600)::int));
  return v_after;
end
$$;

-- ------------------------------------------------------------------ lectures

-- Dernier litige d'une commande (cliente, vendeuse ou équipe) ; nul sinon.
create or replace function public.order_dispute(p_order uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_role text := app.dispute_role(app.require_user(), p_order);
  v_dispute uuid;
begin
  if v_role is null or (v_role = 'vendor' and not app.can_read_order(p_order)) then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  select id into v_dispute from public.disputes where order_id = p_order
  order by created_at desc limit 1;
  return case when v_dispute is null then null else app.dispute_json(v_dispute, v_role = 'admin') end;
end
$$;

-- Litiges pour l'équipe : ouverts (les plus anciens d'abord) ou résolus.
create or replace function public.admin_disputes(p_status text default 'open', p_limit int default 100)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not app.is_admin() then
    raise exception 'rôle admin requis' using errcode = '42501';
  end if;
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', d.id, 'order_id', d.order_id, 'reason', d.reason, 'status', d.status,
      'resolution', d.resolution, 'created_at', d.created_at, 'resolved_at', d.resolved_at,
      'store_name', s.name,
      'customer_first_name', (select first_name from public.profiles where user_id = d.opened_by),
      'order_total_minor', o.total_minor, 'currency_code', o.currency_code,
      'message_count', (select count(*) from public.dispute_messages m where m.dispute_id = d.id),
      'last_message_at', (select max(created_at) from public.dispute_messages m where m.dispute_id = d.id))
      order by d.created_at), '[]'::jsonb)
    from (select * from public.disputes
          where p_status is null or status = p_status
          order by created_at
          limit least(greatest(coalesce(p_limit, 100), 1), 500)) d
    join public.orders o on o.id = d.order_id
    join public.stores s on s.id = o.store_id);
end
$$;

create or replace function public.admin_dispute(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not app.is_admin() then
    raise exception 'rôle admin requis' using errcode = '42501';
  end if;
  if not exists (select 1 from public.disputes where id = p_id) then
    raise exception 'litige introuvable' using errcode = 'P0002';
  end if;
  return app.dispute_json(p_id, true) || jsonb_build_object(
    'order', app.order_json((select order_id from public.disputes where id = p_id), 'admin'));
end
$$;

-- ------------------------------------------------------------------ droits

revoke all on function
  app.open_dispute(uuid, uuid, text, text), app.dispute_reply(uuid, uuid, text),
  app.resolve_dispute(uuid, uuid, text, bigint, text, boolean),
  public.order_dispute(uuid), public.admin_disputes(text, int), public.admin_dispute(uuid)
from public;

grant execute on function
  public.order_dispute(uuid), public.admin_disputes(text, int), public.admin_dispute(uuid)
to authenticated;
