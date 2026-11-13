-- Accueil de la vendeuse (spec 076) : ventes et commandes de la période
-- précédente au même moment (comparaison), heure limite de la commande en
-- attente la plus ancienne. Mêmes définitions que `app.vendor_dashboard`.

create or replace function app.vendor_sales_between(p_store uuid, p_from timestamptz, p_to timestamptz)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'revenue_minor', coalesce(sum(case when o.status = 'delivered'
      and (pu.payment_status = 'paid' or o.cash_collected_at is not null)
      and o.delivered_at >= p_from and o.delivered_at < p_to then
        greatest(o.subtotal_minor - coalesce((select sum((r.amount_minor::numeric * o.subtotal_minor
          / nullif(o.total_minor, 0))::bigint) from public.refunds r
          where r.order_id = o.id and r.status = 'succeeded'), 0), 0) else 0 end), 0),
    'order_count', count(*) filter (where o.created_at >= p_from and o.created_at < p_to
      and o.status not in ('refused', 'cancelled')))
  from public.orders o join public.purchases pu on pu.id = o.purchase_id
  where o.store_id = p_store
$$;

create or replace function public.my_vendor_dashboard(p_period text default 'day') returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
  v jsonb;
  v_start timestamptz;
  v_len interval;
begin
  v := app.vendor_dashboard(v_store, p_period, now());
  v_start := (v ->> 'starts_at')::timestamptz;
  v_len := case p_period when 'day' then interval '1 day' when 'week' then interval '1 week'
                         else interval '1 month' end;
  return v || jsonb_build_object(
    'previous', app.vendor_sales_between(v_store, v_start - v_len, now() - v_len),
    'respond_by', (select min(app.order_respond_by(o.id)) from public.orders o
                   join public.purchases pu on pu.id = o.purchase_id
                   where o.store_id = v_store and o.status = 'pending'
                     and pu.payment_status in ('paid', 'cash_on_delivery')));
end
$$;

revoke all on function app.vendor_sales_between(uuid, timestamptz, timestamptz) from public;
