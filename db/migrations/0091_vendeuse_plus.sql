-- 0091 — Accueil de la vendeuse poussé (spec 098) : tendance jour par jour, panier moyen,
-- clientes nouvelles et fidèles, meilleurs produits, alertes de stock. Une seule lecture,
-- calculée en base dans le fuseau du pays ; aucune donnée personnelle au-delà du prénom.

create or replace function public.my_vendor_insights(p_period text default 'week', p_at timestamptz default now())
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
  v_tz text;
  v_days integer := case p_period when 'day' then 1 when 'week' then 7 when 'month' then 30 end;
  v_start timestamptz;
  v_threshold integer;
begin
  if v_days is null then raise exception 'invalid_period' using errcode = '22023'; end if;
  select c.timezone, coalesce(s.low_stock_threshold, 5) into v_tz, v_threshold
  from public.stores s join public.countries c on c.code = s.country_code where s.id = v_store;
  -- Début de période : minuit local, (jours - 1) jours avant aujourd'hui.
  v_start := (date_trunc('day', p_at at time zone v_tz) - make_interval(days => v_days - 1)) at time zone v_tz;

  return (
    with sold as (
      -- Commandes vendues : livrées, ou acceptées et en cours (pas les refus ni annulations).
      select o.*, pu.user_id as client_id
      from public.orders o join public.purchases pu on pu.id = o.purchase_id
      where o.store_id = v_store and o.created_at >= v_start and o.created_at <= p_at
        and o.status not in ('pending', 'refused', 'cancelled')
    ),
    days as (
      select generate_series(0, v_days - 1) as i
    ),
    series as (
      select d.i, (date_trunc('day', p_at at time zone v_tz) - make_interval(days => v_days - 1 - d.i))::date as day
      from days d
    ),
    firsts as (
      -- Première commande de chaque cliente dans la boutique (toutes périodes).
      select pu.user_id, min(o.created_at) as first_at, count(*) as orders
      from public.orders o join public.purchases pu on pu.id = o.purchase_id
      where o.store_id = v_store and o.status not in ('pending', 'refused', 'cancelled')
      group by pu.user_id
    )
    select jsonb_build_object(
      'period', p_period,
      'currency_code', (select currency_code from public.stores where id = v_store),
      'days', coalesce((
        select jsonb_agg(jsonb_build_object(
          'day', se.day,
          'revenue_minor', coalesce((select sum(so.total_minor) from sold so
                                     where (so.created_at at time zone v_tz)::date = se.day), 0),
          'orders', (select count(*) from sold so where (so.created_at at time zone v_tz)::date = se.day))
          order by se.i)
        from series se), '[]'::jsonb),
      'order_count', (select count(*) from sold),
      'average_basket_minor', coalesce((select round(avg(total_minor))::bigint from sold), 0),
      'customers', (select count(distinct client_id) from sold),
      'new_customers', (select count(*) from firsts f where f.first_at >= v_start and f.first_at <= p_at),
      'returning_customers', (select count(distinct so.client_id) from sold so
                              join firsts f on f.user_id = so.client_id where f.first_at < v_start),
      'top_products', coalesce((
        select jsonb_agg(t order by (t ->> 'quantity')::numeric desc, t ->> 'name')
        from (
          select jsonb_build_object(
            'product_id', i.product_id, 'name', max(i.product_name),
            'quantity', sum(i.quantity), 'revenue_minor', sum(i.amount_minor),
            'photo_key', (select f.object_key from public.product_photos f
                          where f.product_id = i.product_id order by f.sort limit 1)) as t
          from public.order_items i join sold so on so.id = i.order_id
          group by i.product_id
          order by sum(i.quantity) desc, max(i.product_name)
          limit 5) x), '[]'::jsonb),
      -- Clientes fidèles : prénom et nombre de commandes seulement.
      'loyal_customers', coalesce((
        select jsonb_agg(l order by (l ->> 'orders')::int desc, l ->> 'first_name')
        from (
          select jsonb_build_object(
            'first_name', coalesce((select p.first_name from public.profiles p where p.user_id = f.user_id), ''),
            'orders', f.orders,
            'last_order_at', (select max(o.created_at) from public.orders o join public.purchases pu
                              on pu.id = o.purchase_id where o.store_id = v_store and pu.user_id = f.user_id)) as l
          from firsts f where f.orders >= 2
          order by f.orders desc
          limit 5) y), '[]'::jsonb),
      'low_stock', coalesce((
        select jsonb_agg(jsonb_build_object(
          'product_id', p.id, 'name', p.name, 'variant', v.label, 'stock', v.stock_quantity)
          order by v.stock_quantity, p.name)
        from public.products p join public.product_variants v on v.product_id = p.id
        where p.store_id = v_store and p.status = 'published' and v.stock_quantity is not null
          and v.stock_quantity <= v_threshold), '[]'::jsonb),
      'low_stock_threshold', v_threshold)
  );
end
$$;
revoke all on function public.my_vendor_insights(text, timestamptz) from public;
grant execute on function public.my_vendor_insights(text, timestamptz) to authenticated;
insert into public.store_function_permissions (function_name, permission)
values ('public.my_vendor_insights', 'orders') on conflict do nothing;
