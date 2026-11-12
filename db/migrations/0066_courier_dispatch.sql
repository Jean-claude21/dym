-- 0066 — Livreurs relancés, alerte « prête », refus automatique (spec 066).
-- Aujourd'hui, une seule alerte part à l'acceptation : si personne ne prend la
-- course, rien ne se passe ; le livreur n'est pas prévenu quand la commande est
-- prête ; une commande que la vendeuse ne regarde pas reste en attente.
-- Les délais sont des réglages du pays (Configuration des opérations).

alter table public.countries
  add column order_auto_refuse_minutes smallint not null default 20
    check (order_auto_refuse_minutes between 5 and 240),
  add column courier_relaunch_minutes smallint not null default 5
    check (courier_relaunch_minutes between 1 and 60),
  add column courier_relaunch_max smallint not null default 3
    check (courier_relaunch_max between 0 and 10);

-- Motif « la boutique n'a pas répondu » (refus automatique).
alter table public.orders drop constraint orders_status_reason_check;
alter table public.orders add constraint orders_status_reason_check
  check (status_reason in ('out_of_stock', 'too_busy', 'area_not_served', 'other', 'no_response'));

-- Suivi des alertes envoyées aux livreurs (interne : aucune lecture par la Data API).
create table public.order_dispatch (
  order_id uuid primary key references public.orders (id) on delete cascade,
  notified_at timestamptz not null default now(),
  relaunches smallint not null default 0,
  widened boolean not null default false,
  ready_alerted_at timestamptz
);
alter table public.order_dispatch enable row level security;

-- Quartiers de la ville de la boutique (élargissement).
create or replace function app.store_city_zones(p_store uuid) returns setof uuid
language sql stable security definer set search_path = ''
as $$
  select z2.id from public.stores s
  join public.zones z on z.id = s.zone_id
  join public.zones z2 on z2.city_id = z.city_id and z2.is_active
  where s.id = p_store
$$;

-- Alerte « Nouvelle course » aux livreurs éligibles (20 au plus). Élargie :
-- toute la ville de la boutique. Renvoie le nombre de livreurs prévenus.
create or replace function app.dispatch_couriers(p_order uuid, p_widen boolean default false)
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
  v_zone uuid;
  v_country char(2);
  v_client uuid;
  v_store_zone uuid;
  v_store_name text;
  v_count integer := 0;
  v_courier uuid;
begin
  select * into v_order from public.orders where id = p_order;
  select (pu.address ->> 'zone_id')::uuid, pu.country_code, pu.user_id into v_zone, v_country, v_client
  from public.purchases pu where pu.id = v_order.purchase_id;
  select zone_id, name into v_store_zone, v_store_name from public.stores where id = v_order.store_id;
  for v_courier in
    select c.user_id from public.courier_profiles c
    where c.status = 'active' and c.is_online and c.country_code = v_country and c.user_id <> v_client
      and exists (select 1 from public.courier_zones z where z.user_id = c.user_id
                  and (z.zone_id in (v_zone, v_store_zone)
                       or (p_widen and z.zone_id in (select app.store_city_zones(v_order.store_id)))))
    limit 20
  loop
    perform app.notify(v_courier, 'mission_available', 'orders', null, null,
      jsonb_build_object('store_name', v_store_name));
    v_count := v_count + 1;
  end loop;
  insert into public.order_dispatch (order_id, notified_at, widened)
  values (p_order, now(), p_widen)
  on conflict (order_id) do update set notified_at = now(),
    widened = public.order_dispatch.widened or excluded.widened;
  return v_count;
end
$$;

-- Déclencheur des statuts : course proposée à l'acceptation ; livreur
-- assigné prévenu quand la commande est prête.
create or replace function app.notify_couriers() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_courier uuid;
  v_country char(2);
begin
  if new.fulfillment <> 'delivery' or old.status is not distinct from new.status then
    return null;
  end if;
  if new.status = 'accepted' then
    perform app.dispatch_couriers(new.id, false);
  elsif new.status = 'ready' then
    select courier_id into v_courier from public.order_couriers where order_id = new.id;
    if v_courier is not null then
      perform app.notify(v_courier, 'order_ready_pickup', 'orders', new.id, null,
        jsonb_build_object('store_name', (select name from public.stores where id = new.store_id)));
      insert into public.order_dispatch (order_id, ready_alerted_at) values (new.id, now())
      on conflict (order_id) do update set ready_alerted_at = now();
      select country_code into v_country from public.purchases where id = new.purchase_id;
      perform app.emit_event('courier_ready_alerted', v_courier, 'courier', 'server', v_country,
        'order', new.id::text, '{}'::jsonb);
    end if;
  end if;
  return null;
end
$fn$;

-- Visibilité d'une course : élargie à la ville après la deuxième relance.
create or replace function app.mission_open_for(p_order uuid, p_user uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    join public.stores s on s.id = o.store_id
    join public.courier_profiles c on c.user_id = p_user and c.status = 'active' and c.is_online
    left join public.order_dispatch d on d.order_id = o.id
    where o.id = p_order and o.fulfillment = 'delivery' and o.status in ('accepted', 'preparing', 'ready')
      and pu.country_code = c.country_code and pu.user_id <> p_user and s.owner_id <> p_user
      and not exists (select 1 from public.order_couriers oc where oc.order_id = o.id)
      and exists (select 1 from public.courier_zones z where z.user_id = p_user
                  and (z.zone_id = s.zone_id or z.zone_id = (pu.address ->> 'zone_id')::uuid
                       or (coalesce(d.widened, false)
                           and z.zone_id in (select app.store_city_zones(s.id))))))
$$;

-- Refus automatique d'une commande restée sans réponse : mêmes effets qu'un
-- refus de la vendeuse (stock rendu, remboursement dû si payée), acteur système.
create or replace function app.auto_refuse_order(p_order uuid) returns boolean
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
  v_purchase public.purchases;
  v_owner uuid;
  v_store_name text;
begin
  select * into v_order from public.orders where id = p_order for update;
  if v_order.id is null or v_order.status <> 'pending' then
    return false;
  end if;
  select * into v_purchase from public.purchases where id = v_order.purchase_id;
  select owner_id, name into v_owner, v_store_name from public.stores where id = v_order.store_id;

  update public.orders set
    status = 'refused', refused_at = now(), status_reason = 'no_response',
    refund_due = refund_due or v_purchase.payment_status = 'paid'
  where id = p_order;
  insert into public.order_status_events (order_id, from_status, to_status, actor_role, actor_id, reason)
  values (p_order, 'pending', 'refused', 'system', null, 'no_response');
  update public.product_variants v
  set stock_quantity = v.stock_quantity + i.quantity
  from public.order_items i
  where i.order_id = p_order and i.variant_id = v.id and v.stock_quantity is not null;

  perform app.notify(v_purchase.user_id, 'order_refused', 'orders', p_order, v_purchase.id,
    jsonb_build_object('store_name', v_store_name, 'fulfillment', v_order.fulfillment,
                       'reason', 'no_response'));
  perform app.notify(v_owner, 'order_auto_refused', 'orders', p_order, v_purchase.id,
    jsonb_build_object('total_minor', v_order.total_minor, 'currency_code', v_order.currency_code));

  perform app.emit_event('order_status_changed', null, 'system', 'server', v_purchase.country_code,
    'order', p_order::text,
    jsonb_build_object('from', 'pending', 'to', 'refused', 'fulfillment', v_order.fulfillment));
  perform app.emit_event('order_rejected', null, 'system', 'server', v_purchase.country_code,
    'order', p_order::text,
    jsonb_build_object('fulfillment', v_order.fulfillment, 'reason', 'no_response',
                       'minutes_since_created', round(extract(epoch from now() - v_order.created_at) / 60)::int));
  return true;
end
$$;

-- Surveillance (tâche planifiée, toutes les 5 minutes) : refus automatique
-- des commandes sans réponse, relance des courses sans livreur.
create or replace function app.run_dispatch_watch(p_at timestamptz default now()) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_refused integer := 0;
  v_relaunched integer := 0;
  v_row record;
  v_widen boolean;
  v_notified integer;
begin
  for v_row in
    select o.id from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    join public.countries c on c.code = pu.country_code
    where o.status = 'pending'
      and pu.payment_status in ('cash_on_delivery', 'paid')
      and o.created_at < p_at - make_interval(mins => c.order_auto_refuse_minutes)
    order by o.created_at
    limit 200
  loop
    if app.auto_refuse_order(v_row.id) then v_refused := v_refused + 1; end if;
  end loop;

  for v_row in
    select o.id, d.relaunches, pu.country_code from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    join public.countries c on c.code = pu.country_code
    join public.order_dispatch d on d.order_id = o.id
    where o.fulfillment = 'delivery' and o.status in ('accepted', 'preparing', 'ready')
      and not exists (select 1 from public.order_couriers oc where oc.order_id = o.id)
      and d.relaunches < c.courier_relaunch_max
      and d.notified_at < p_at - make_interval(mins => c.courier_relaunch_minutes)
    order by d.notified_at
    limit 200
    for update of d skip locked
  loop
    -- Première relance : mêmes quartiers ; ensuite, toute la ville.
    v_widen := v_row.relaunches >= 1;
    v_notified := app.dispatch_couriers(v_row.id, v_widen);
    update public.order_dispatch set relaunches = relaunches + 1 where order_id = v_row.id;
    perform app.emit_event('courier_relaunched', null, 'system', 'server', v_row.country_code,
      'order', v_row.id::text,
      jsonb_build_object('relaunch', v_row.relaunches + 1, 'widened', v_widen, 'notified', v_notified));
    v_relaunched := v_relaunched + 1;
  end loop;

  return jsonb_build_object('refused', v_refused, 'relaunched', v_relaunched);
end
$$;

-- Réglages des opérations : délais de livraison automatique avec les seuils.
create or replace function public.admin_ops_settings(p_country char(2)) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_country public.countries;
begin
  perform app.require_ops(p_country);
  select * into v_country from public.countries where code = p_country;
  return jsonb_build_object(
    'country_code', p_country,
    'currency_code', v_country.currency_code,
    'thresholds', jsonb_build_object('pending', v_country.ops_pending_alert_minutes,
      'ready', v_country.ops_ready_alert_minutes, 'transit', v_country.ops_transit_alert_minutes,
      'auto_refuse', v_country.order_auto_refuse_minutes,
      'relaunch', v_country.courier_relaunch_minutes,
      'relaunch_max', v_country.courier_relaunch_max),
    'feed_weights', to_jsonb(app.feed_weights(p_country)) - 'country_code' - 'id' - 'created_at' - 'updated_at',
    'plans', coalesce((select jsonb_agg(to_jsonb(pl) - 'created_at' order by pl.audience, pl.sort, pl.code)
      from public.membership_plans pl where pl.country_code = p_country), '[]'::jsonb),
    'can_manage_scopes', not exists (select 1 from public.admin_scopes where user_id = app.current_user_id()),
    'scopes', coalesce((select jsonb_agg(jsonb_build_object('email', u.email, 'countries',
        (select jsonb_agg(sc.country_code order by sc.country_code) from public.admin_scopes sc where sc.user_id = u.id))
        order by u.email)
      from neon_auth."user" u
      where exists (select 1 from public.admin_scopes sc where sc.user_id = u.id)), '[]'::jsonb));
end
$fn$;

create or replace function public.admin_set_ops_thresholds(p_country char(2), p_values jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_admin uuid := app.require_ops(p_country);
  v_before jsonb;
begin
  select jsonb_build_object('pending', ops_pending_alert_minutes, 'ready', ops_ready_alert_minutes,
    'transit', ops_transit_alert_minutes, 'auto_refuse', order_auto_refuse_minutes,
    'relaunch', courier_relaunch_minutes, 'relaunch_max', courier_relaunch_max)
    into v_before from public.countries where code = p_country;
  update public.countries set
    ops_pending_alert_minutes = coalesce((p_values ->> 'pending')::smallint, ops_pending_alert_minutes),
    ops_ready_alert_minutes = coalesce((p_values ->> 'ready')::smallint, ops_ready_alert_minutes),
    ops_transit_alert_minutes = coalesce((p_values ->> 'transit')::smallint, ops_transit_alert_minutes),
    order_auto_refuse_minutes = coalesce((p_values ->> 'auto_refuse')::smallint, order_auto_refuse_minutes),
    courier_relaunch_minutes = coalesce((p_values ->> 'relaunch')::smallint, courier_relaunch_minutes),
    courier_relaunch_max = coalesce((p_values ->> 'relaunch_max')::smallint, courier_relaunch_max)
  where code = p_country;
  perform app.admin_did(v_admin, 'ops_thresholds_set', 'country', p_country, v_before, p_values, null, p_country);
  return public.admin_ops_settings(p_country);
end
$fn$;

-- Livraisons sur la période : livreurs, courses en attente, délai de prise,
-- relances, refus automatiques, alertes « prête ».
create or replace function public.admin_dispatch(p_period text default 'day', p_at timestamptz default now())
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_since timestamptz := p_at - case p_period when 'week' then interval '7 days'
                                              when 'month' then interval '30 days'
                                              else interval '1 day' end;
begin
  perform app.require_admin();
  return jsonb_build_object(
    'couriers_active', (select count(*) from public.courier_profiles where status = 'active'),
    'couriers_online', (select count(*) from public.courier_profiles where status = 'active' and is_online),
    'waiting', (select count(*) from public.orders o
                where o.fulfillment = 'delivery' and o.status in ('accepted', 'preparing', 'ready')
                  and not exists (select 1 from public.order_couriers oc where oc.order_id = o.id)),
    'median_accept_minutes', (
      select round(percentile_cont(0.5) within group (
        order by (e.props ->> 'minutes_since_created')::numeric))::int
      from public.events e
      where e.name = 'mission_accepted' and e.occurred_at > v_since and e.occurred_at <= p_at),
    'relaunches', (select count(*) from public.events e
                   where e.name = 'courier_relaunched' and e.occurred_at > v_since and e.occurred_at <= p_at),
    'widened', (select count(*) from public.events e
                where e.name = 'courier_relaunched' and (e.props ->> 'widened')::boolean
                  and e.occurred_at > v_since and e.occurred_at <= p_at),
    'auto_refused', (select count(*) from public.events e
                     where e.name = 'order_rejected' and e.props ->> 'reason' = 'no_response'
                       and e.occurred_at > v_since and e.occurred_at <= p_at),
    'ready_alerts', (select count(*) from public.events e
                     where e.name = 'courier_ready_alerted' and e.occurred_at > v_since and e.occurred_at <= p_at));
end
$$;

-- Notifications : destinataire et textes.
create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor', 'review_received', 'support_replied_vendor', 'low_stock',
    'substitution_answered', 'freshness_claimed', 'incoming_call_vendor',
    'courier_out_for_delivery', 'courier_delivered', 'qr_paid',
    'wholesale_confirmed', 'wholesale_cancelled', 'order_auto_refused')
    then 'vendor'
    when p_kind in ('mission_available', 'courier_cash_confirmed', 'order_ready_pickup') then 'delivery'
    else 'client' end
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('order_ready_pickup', 'fr', 'Commande prête', 'La commande de {store_name} t''attend : passe la récupérer.'),
  ('order_ready_pickup', 'en', 'Order ready', 'The order from {store_name} is waiting for you: go and pick it up.'),
  ('order_auto_refused', 'fr', 'Commande refusée faute de réponse',
   'Une commande est restée sans réponse et a été refusée. La cliente est prévenue.'),
  ('order_auto_refused', 'en', 'Order declined: no answer',
   'An order got no answer and was declined. The customer has been told.')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('courier_relaunched', 'server', 'Course relancée faute de livreur (rang, élargie, livreurs prévenus)'),
  ('courier_ready_alerted', 'server', 'Livreur assigné prévenu que la commande est prête')
on conflict do nothing;

revoke all on function app.store_city_zones(uuid), app.dispatch_couriers(uuid, boolean),
  app.auto_refuse_order(uuid), app.run_dispatch_watch(timestamptz),
  public.admin_dispatch(text, timestamptz) from public;
grant execute on function public.admin_dispatch(text, timestamptz) to authenticated;
