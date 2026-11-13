-- Pilotage admin (spec 073) : chiffres de la période comparés à la période
-- précédente au même moment (aujourd'hui jusqu'à 10 h contre hier jusqu'à
-- 10 h), courbe par heure ou par jour, entonnoir d'achat, issues des
-- commandes. Mêmes définitions que `admin_dashboard` (spec 019).

-- Chiffres d'un intervalle.
create or replace function app.admin_kpis(p_range tstzrange) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'orders', (select count(*) from public.orders o join public.purchases pu on pu.id = o.purchase_id
               where o.created_at <@ p_range and pu.payment_status in ('cash_on_delivery', 'paid')),
    'sales', (select coalesce(jsonb_agg(jsonb_build_object('currency_code', c, 'minor', m, 'orders', n)
                                        order by c), '[]'::jsonb)
              from (select o.currency_code as c, sum(o.subtotal_minor) as m, count(*) as n
                    from public.orders o join public.purchases pu on pu.id = o.purchase_id
                    where app.order_collected(o, pu.payment_status) and o.delivered_at <@ p_range
                    group by o.currency_code) s),
    'delivered', (select count(*) from public.orders o where o.status = 'delivered' and o.delivered_at <@ p_range),
    'failed', (select count(*) from public.orders o
               where o.created_at <@ p_range
                 and (o.status = 'refused' or (o.status = 'cancelled' and o.cancelled_by in ('vendor', 'admin')))),
    'signups', (select count(*) from public.events e where e.name = 'user_signed_up' and e.occurred_at <@ p_range),
    'active_clients', (select count(distinct e.actor_id) from public.events e
                       where e.app = 'client' and e.occurred_at <@ p_range),
    'payments_ok', (select count(*) from public.payments p where p.status = 'succeeded' and p.created_at <@ p_range),
    'payments_failed', (select count(*) from public.payments p
                        where p.status in ('failed', 'cancelled') and p.created_at <@ p_range))
$$;

create or replace function public.admin_overview(p_period text default 'day', p_at timestamptz default now())
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_full tstzrange := app.period_bounds(p_period, p_at);
  v_start timestamptz;
  v_end timestamptz;
  v_len interval;
  v_step interval;
  v_cur tstzrange;
  v_prev tstzrange;
begin
  perform app.require_admin();
  if v_full is null or p_period not in ('day', 'week', 'month') then
    raise exception 'période inconnue' using errcode = '22023';
  end if;
  v_start := lower(v_full);
  v_end := least(p_at, upper(v_full));
  v_len := case p_period when 'day' then interval '1 day' when 'week' then interval '1 week'
                         else interval '1 month' end;
  v_step := case p_period when 'day' then interval '1 hour' else interval '1 day' end;
  v_cur := tstzrange(v_start, v_end, '[)');
  -- Période précédente, arrêtée au même moment.
  v_prev := tstzrange(v_start - v_len, (v_start - v_len) + (v_end - v_start), '[)');
  return jsonb_build_object(
    'period', p_period,
    'from', v_start,
    'to', v_end,
    'current', app.admin_kpis(v_cur),
    'previous', app.admin_kpis(v_prev),
    'series', (select coalesce(jsonb_agg(jsonb_build_object(
                 'at', b,
                 'orders', (select count(*) from public.orders o join public.purchases pu on pu.id = o.purchase_id
                            where o.created_at >= b and o.created_at < b + v_step
                              and pu.payment_status in ('cash_on_delivery', 'paid')),
                 'delivered', (select count(*) from public.orders o
                               where o.status = 'delivered' and o.delivered_at >= b and o.delivered_at < b + v_step),
                 'sales', (select coalesce(jsonb_agg(jsonb_build_object('currency_code', c, 'minor', m)), '[]'::jsonb)
                           from (select o.currency_code as c, sum(o.subtotal_minor) as m
                                 from public.orders o join public.purchases pu on pu.id = o.purchase_id
                                 where app.order_collected(o, pu.payment_status)
                                   and o.delivered_at >= b and o.delivered_at < b + v_step
                                 group by o.currency_code) s))
                 order by b), '[]'::jsonb)
               from generate_series(v_start, upper(v_full) - v_step, v_step) b
               where b <= v_end),
    -- Entonnoir : personnes distinctes à chaque étape, sur la période.
    'funnel', jsonb_build_object(
      'active', (select count(distinct e.actor_id) from public.events e
                 where e.app = 'client' and e.occurred_at <@ v_cur),
      'viewed', (select count(distinct e.actor_id) from public.events e
                 where e.name = 'product_viewed' and e.occurred_at <@ v_cur),
      'added', (select count(distinct e.actor_id) from public.events e
                where e.name = 'cart_item_added' and e.occurred_at <@ v_cur),
      'ordered', (select count(distinct e.actor_id) from public.events e
                  where e.name = 'order_created' and e.occurred_at <@ v_cur),
      'delivered', (select count(distinct pu.user_id) from public.orders o
                    join public.purchases pu on pu.id = o.purchase_id
                    where o.status = 'delivered' and o.delivered_at <@ v_cur)),
    -- Issue des commandes créées sur la période.
    'outcomes', (select jsonb_build_object(
                   'delivered', count(*) filter (where o.status = 'delivered'),
                   'in_progress', count(*) filter (where o.status in ('pending', 'accepted', 'preparing', 'ready',
                                                                       'out_for_delivery')),
                   'refused', count(*) filter (where o.status = 'refused'),
                   'cancelled', count(*) filter (where o.status = 'cancelled'))
                 from public.orders o join public.purchases pu on pu.id = o.purchase_id
                 where o.created_at <@ v_cur and pu.payment_status in ('cash_on_delivery', 'paid')));
end
$$;

revoke all on function app.admin_kpis(tstzrange) from public;
revoke all on function public.admin_overview(text, timestamptz) from public, anonymous;
grant execute on function public.admin_overview(text, timestamptz) to authenticated;
