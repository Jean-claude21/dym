-- Nouvelle commande chez la vendeuse (spec 075) : heure limite de réponse
-- avant le refus automatique (délai du pays, spec 066), dans la liste et le
-- détail, pour un compte à rebours visible.

create or replace function app.order_respond_by(p_order uuid) returns timestamptz
language sql stable security definer set search_path = ''
as $$
  select o.created_at + make_interval(mins => c.order_auto_refuse_minutes)
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.countries c on c.code = pu.country_code
  where o.id = p_order and o.status = 'pending'
$$;

revoke all on function app.order_respond_by(uuid) from public;

create or replace function public.my_store_orders(p_scope text default null, p_limit int default 50)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.store_order_json(o.id, false)
    || jsonb_build_object('eta_at', case when o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
                                         then app.order_eta(o.id) end,
                                 'scheduled_start', o.scheduled_start, 'scheduled_end', o.scheduled_end,
                                 'respond_by', app.order_respond_by(o.id))
    order by o.created_at desc, o.id), '[]'::jsonb)
  from (
    select o.id, o.created_at, o.status, o.scheduled_start, o.scheduled_end from public.orders o
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
    || (app.order_json(p_id, 'vendor') - 'store' - 'items' - 'payment_method' - 'substitution_allowed')
    || jsonb_build_object('respond_by', app.order_respond_by(p_id));
end
$$;
