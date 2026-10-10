-- Spec 014 : V-DASH-01..05/08, V-ANA-01/02. Les chiffres restent en SQL.
create table app.vendor_daily_recaps (
  store_id uuid not null references public.stores(id) on delete cascade,
  local_date date not null,
  created_at timestamptz not null default now(),
  primary key (store_id, local_date)
);
revoke all on app.vendor_daily_recaps from public, authenticated, anonymous;

create function app.vendor_dashboard(p_store uuid, p_period text, p_at timestamptz)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_timezone text;
  v_currency text;
  v_local timestamp;
  v_start timestamptz;
  v_end timestamptz;
  v_stats jsonb;
begin
  if p_period is null or p_period not in ('day', 'week', 'month') or p_at is null then
    raise exception 'invalid_period' using errcode = '22023';
  end if;
  select c.timezone, s.currency_code into strict v_timezone, v_currency
  from public.stores s join public.countries c on c.code = s.country_code where s.id = p_store;
  v_local := p_at at time zone v_timezone;
  v_start := date_trunc(p_period, v_local) at time zone v_timezone;
  v_end := (date_trunc(p_period, v_local) + case p_period
    when 'day' then interval '1 day' when 'week' then interval '1 week' else interval '1 month' end)
    at time zone v_timezone;
  select jsonb_build_object(
    'revenue_minor', coalesce(sum(case when o.status = 'delivered'
      and (pu.payment_status = 'paid' or o.cash_collected_at is not null)
      and o.delivered_at >= v_start and o.delivered_at < v_end then
        greatest(o.subtotal_minor - coalesce((select sum((r.amount_minor::numeric * o.subtotal_minor
          / nullif(o.total_minor, 0))::bigint) from public.refunds r
          where r.order_id = o.id and r.status = 'succeeded'), 0), 0) else 0 end), 0),
    'order_count', count(*) filter (where o.created_at >= v_start and o.created_at < v_end
      and o.status not in ('refused', 'cancelled')),
    'pending_payments', count(*) filter (where o.created_at >= v_start and o.created_at < v_end
      and o.status not in ('refused', 'cancelled') and (pu.payment_status in ('awaiting_payment', 'failed')
        or (pu.payment_status = 'cash_on_delivery' and o.cash_collected_at is null))),
    'pending_orders', count(*) filter (where o.status = 'pending'
      and pu.payment_status in ('paid', 'cash_on_delivery')),
    'active_orders', count(*) filter (where o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery')
      and pu.payment_status in ('paid', 'cash_on_delivery')))
  into v_stats from public.orders o join public.purchases pu on pu.id = o.purchase_id
  where o.store_id = p_store;
  return v_stats || jsonb_build_object('period', p_period, 'starts_at', v_start, 'ends_at', v_end,
    'local_date', v_local::date, 'currency_code', v_currency,
    'out_of_stock', (select count(*) from public.product_variants pv join public.products p on p.id = pv.product_id
      where p.store_id = p_store and p.status = 'published' and (not p.is_available or pv.stock_quantity = 0)),
    'critical_notifications', (select count(*) from public.notifications n join public.stores s on s.id = p_store
      where n.user_id = s.owner_id and n.read_at is null
        and n.kind in ('dispute_opened', 'dispute_message', 'order_status_forced', 'store_suspended')));
end $$;

create function public.my_vendor_dashboard(p_period text default 'day') returns jsonb
language sql stable security definer set search_path = '' as $$
  select app.vendor_dashboard(app.own_store_id(), p_period, now())
$$;

create function app.create_vendor_recaps(p_at timestamptz default now()) returns integer
language plpgsql security definer set search_path = '' as $$
declare v record; v_count integer := 0; v_claim uuid; v_summary jsonb;
begin
  if p_at is null then raise exception 'invalid_time' using errcode = '22023'; end if;
  -- Une date future (appel forgé) ne déclenche jamais un récap avant l'heure.
  p_at := least(p_at, now());
  for v in select s.id, s.owner_id, s.name, (p_at at time zone c.timezone)::date as day
    from public.stores s join public.countries c on c.code = s.country_code
    where s.status = 'active' and c.is_active and (p_at at time zone c.timezone)::time >= time '19:00'
  loop
    v_claim := null;
    insert into app.vendor_daily_recaps(store_id, local_date) values(v.id, v.day)
    on conflict do nothing returning store_id into v_claim;
    if v_claim is not null then
      v_summary := app.vendor_dashboard(v.id, 'day', p_at);
      perform app.notify(v.owner_id, 'vendor_daily_recap', 'orders', null, null,
        v_summary || jsonb_build_object('store_name', v.name));
      v_count := v_count + 1;
    end if;
  end loop;
  return v_count;
end $$;

-- Garder les types vendeuse précédents et ajouter le récapitulatif.
create or replace function app.notification_app(p_kind text) returns text
language sql immutable as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap')
    then 'vendor' else 'client' end
$$;
insert into public.notification_templates(kind, locale, title, body) values
 ('vendor_daily_recap', 'fr', 'Ton récap du jour', 'Retrouve tes ventes et commandes du jour dans ton accueil.'),
 ('vendor_daily_recap', 'en', 'Your daily recap', 'See today’s sales and orders on your home screen.');
revoke all on function app.vendor_dashboard(uuid, text, timestamptz),
  app.create_vendor_recaps(timestamptz), public.my_vendor_dashboard(text) from public;
grant execute on function public.my_vendor_dashboard(text) to authenticated;
