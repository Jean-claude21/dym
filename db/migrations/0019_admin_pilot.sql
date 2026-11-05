-- 0019 — Admin du pilote (spec 017 : A-DASH-01..08, A-ANA-01..03, A-CFG-07, A-SUP-01..03,
-- A-LIT-07, A-CLI-02, A-VEN-06/07, A-FIN-01/02). Lectures et réglages réservés à l'équipe ;
-- chaque action écrit dans `audit_log` (app.admin_did). Aucun total ne traverse les devises.

-- Vente encaissée : livrée, puis payée en ligne ou cash encaissé.
create or replace function app.order_collected(p_order public.orders, p_payment_status text)
returns boolean
language sql immutable
as $$
  select p_order.status = 'delivered'
     and (p_payment_status = 'paid' or p_order.cash_collected_at is not null)
$$;

-- Bornes d'une période (jour, semaine, mois, 30 jours) en UTC.
create or replace function app.period_bounds(p_period text, p_at timestamptz) returns tstzrange
language plpgsql immutable
as $$
begin
  return case p_period
    when 'day' then tstzrange(date_trunc('day', p_at), date_trunc('day', p_at) + interval '1 day')
    when 'week' then tstzrange(date_trunc('week', p_at), date_trunc('week', p_at) + interval '1 week')
    when 'month' then tstzrange(date_trunc('month', p_at), date_trunc('month', p_at) + interval '1 month')
    when 'last_month' then tstzrange(date_trunc('month', p_at) - interval '1 month', date_trunc('month', p_at))
    when '30d' then tstzrange(p_at - interval '30 days', p_at, '[]')
    else null
  end;
end
$$;

-- ------------------------------------------------------------------ tableau de bord

-- Tableau de bord de l'équipe (écran 67).
create or replace function public.admin_dashboard(p_period text default 'day', p_at timestamptz default now())
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_range tstzrange := app.period_bounds(p_period, p_at);
begin
  perform app.require_admin();
  if v_range is null then
    raise exception 'période inconnue' using errcode = '22023';
  end if;
  return jsonb_build_object(
    'period', p_period,
    'active_orders', (select count(*) from public.orders o join public.purchases pu on pu.id = o.purchase_id
                      where o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
                        and pu.payment_status in ('cash_on_delivery', 'paid')),
    'stuck_orders', (select count(*) from public.orders o join public.purchases pu on pu.id = o.purchase_id
                     where app.order_stuck(o, pu.payment_status)),
    'revenue', (select coalesce(jsonb_agg(jsonb_build_object('currency_code', currency_code,
                  'sales_minor', sales, 'orders', n) order by currency_code), '[]'::jsonb)
                from (select o.currency_code, sum(o.subtotal_minor) as sales, count(*) as n
                      from public.orders o join public.purchases pu on pu.id = o.purchase_id
                      where app.order_collected(o, pu.payment_status) and o.delivered_at <@ v_range
                      group by o.currency_code) r),
    'payments_1h', (select jsonb_build_object('succeeded', count(*) filter (where status = 'succeeded'),
                      'failed', count(*) filter (where status in ('failed', 'cancelled')))
                    from public.payments where created_at > p_at - interval '1 hour'),
    'payments_24h', (select jsonb_build_object('succeeded', count(*) filter (where status = 'succeeded'),
                       'failed', count(*) filter (where status in ('failed', 'cancelled')))
                     from public.payments where created_at > p_at - interval '24 hours'),
    'deliveries', (select jsonb_build_object(
                     'delivered', count(*) filter (where status = 'delivered'),
                     'failed', count(*) filter (where status = 'refused'
                                                 or (status = 'cancelled' and cancelled_by in ('vendor', 'admin'))))
                   from public.orders where created_at <@ v_range),
    'active_users', (select jsonb_build_object(
                       'client', count(distinct actor_id) filter (where app = 'client'),
                       'vendor', count(distinct actor_id) filter (where app = 'vendor'))
                     from public.events where name = 'user_signed_in' and occurred_at > p_at - interval '7 days'),
    'new_signups', (select count(*) from public.events where name = 'user_signed_up' and occurred_at <@ v_range),
    'draft_stores', (select count(*) from public.stores where status = 'draft'),
    'open_disputes', (select count(*) from public.disputes where status = 'open'),
    'late_disputes', (select count(*) from public.disputes
                      where status = 'open' and created_at < p_at - interval '48 hours'),
    'open_tickets', (select count(*) from public.support_tickets where status <> 'closed'),
    'late_tickets', (select count(*) from public.support_tickets
                     where status <> 'closed' and first_response_at is null
                       and created_at < p_at - interval '1 hour'),
    'pending_refunds', (select count(*) from public.refunds where status in ('pending', 'failed')),
    'series_30d', (select coalesce(jsonb_agg(jsonb_build_object('day', d::date, 'orders', coalesce(x.n, 0),
                     'sales', coalesce(x.sales, '[]'::jsonb)) order by d), '[]'::jsonb)
                   from generate_series(date_trunc('day', p_at) - interval '29 days', date_trunc('day', p_at),
                                        interval '1 day') d
                   left join lateral (
                     select count(*) as n,
                            (select coalesce(jsonb_agg(jsonb_build_object('currency_code', c, 'minor', m)), '[]'::jsonb)
                             from (select o2.currency_code as c, sum(o2.subtotal_minor) as m
                                   from public.orders o2 join public.purchases p2 on p2.id = o2.purchase_id
                                   where app.order_collected(o2, p2.payment_status)
                                     and o2.delivered_at >= d and o2.delivered_at < d + interval '1 day'
                                   group by o2.currency_code) s) as sales
                     from public.orders o join public.purchases pu on pu.id = o.purchase_id
                     where o.created_at >= d and o.created_at < d + interval '1 day'
                       and pu.payment_status in ('cash_on_delivery', 'paid')) x on true),
    'top_stores', (select coalesce(jsonb_agg(t order by (t ->> 'orders')::int desc, t ->> 'name'), '[]'::jsonb)
                   from (select jsonb_build_object('id', s.id, 'name', s.name, 'currency_code', s.currency_code,
                           'orders', count(o.id), 'sales_minor', coalesce(sum(o.subtotal_minor), 0),
                           'rating', (select round(avg(r.rating)::numeric, 1) from public.reviews r
                                      where r.store_id = s.id and r.status = 'published')) as t
                         from public.stores s
                         join public.orders o on o.store_id = s.id
                         join public.purchases pu on pu.id = o.purchase_id
                         where app.order_collected(o, pu.payment_status) and o.delivered_at <@ v_range
                         group by s.id
                         order by count(o.id) desc limit 5) x),
    'top_categories', (select coalesce(jsonb_agg(jsonb_build_object('id', c.id, 'label', c.label,
                         'quantity', q) order by q desc), '[]'::jsonb)
                       from (select coalesce(cat.parent_id, cat.id) as cid, sum(i.quantity) as q
                             from public.order_items i
                             join public.orders o on o.id = i.order_id
                             join public.purchases pu on pu.id = o.purchase_id
                             join public.products p on p.id = i.product_id
                             join public.categories cat on cat.id = p.category_id
                             where app.order_collected(o, pu.payment_status) and o.delivered_at <@ v_range
                             group by 1 order by 2 desc limit 5) x
                       join public.categories c on c.id = x.cid),
    'top_products', (select coalesce(jsonb_agg(jsonb_build_object('name', name, 'store_name', store_name,
                       'quantity', q) order by q desc), '[]'::jsonb)
                     from (select i.product_name as name, s.name as store_name, sum(i.quantity) as q
                           from public.order_items i
                           join public.orders o on o.id = i.order_id
                           join public.purchases pu on pu.id = o.purchase_id
                           join public.stores s on s.id = o.store_id
                           where app.order_collected(o, pu.payment_status) and o.delivered_at <@ v_range
                           group by 1, 2 order by 3 desc limit 5) x)
  );
end
$$;

-- ------------------------------------------------------------------ feature flags

create or replace function public.admin_feature_flags() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return (select coalesce(jsonb_agg(jsonb_build_object('id', id, 'key', key, 'country_code', country_code,
            'is_enabled', is_enabled, 'description', description) order by key, country_code nulls first),
            '[]'::jsonb)
          from public.feature_flags);
end
$$;

-- Activer ou couper un flag (tous les pays si [p_country] est nul) ; audité.
create or replace function public.admin_set_feature_flag(p_key text, p_country char(2), p_enabled boolean)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_before boolean;
begin
  select is_enabled into v_before from public.feature_flags
  where key = p_key and country_code is not distinct from p_country;
  if v_before is null then
    if not exists (select 1 from public.feature_flags where key = p_key) then
      raise exception 'flag inconnu' using errcode = 'P0002';
    end if;
    insert into public.feature_flags (key, country_code, is_enabled, description)
    select p_key, p_country, p_enabled, description from public.feature_flags
    where key = p_key and country_code is null;
  else
    update public.feature_flags set is_enabled = p_enabled
    where key = p_key and country_code is not distinct from p_country;
  end if;
  perform app.admin_did(v_admin, 'feature_flag_set', 'feature_flag', p_key,
    jsonb_build_object('country_code', p_country, 'is_enabled', v_before),
    jsonb_build_object('country_code', p_country, 'is_enabled', p_enabled), null, p_country);
  return public.admin_feature_flags();
end
$$;

-- ------------------------------------------------------------------ support

create or replace function public.admin_tickets(p_status text default 'open', p_limit int default 100)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  if p_status is null or p_status not in ('open', 'pending', 'closed') then
    raise exception 'statut inconnu' using errcode = '22023';
  end if;
  return (select coalesce(jsonb_agg(app.ticket_json(t.id, true) order by t.created_at), '[]'::jsonb)
          from (select id, created_at from public.support_tickets where status = p_status
                order by created_at limit least(greatest(coalesce(p_limit, 100), 1), 500)) t);
end
$$;

-- Réponse de l'équipe : en attente de l'utilisatrice, prévenue (Function).
create or replace function app.admin_reply_ticket(p_admin uuid, p_ticket uuid, p_body text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_ticket public.support_tickets;
  v_body text := nullif(trim(p_body), '');
begin
  perform app.assert_admin(p_admin);
  select * into v_ticket from public.support_tickets where id = p_ticket for update;
  if v_ticket.id is null then
    raise exception 'demande introuvable' using errcode = 'P0002';
  end if;
  if v_body is null or length(v_body) > 2000 then
    raise exception 'ticket_invalid' using errcode = 'P0001';
  end if;
  insert into public.support_messages (ticket_id, author_id, author_role, body)
  values (p_ticket, p_admin, 'team', v_body);
  update public.support_tickets set status = 'pending', last_activity_at = now(),
    first_response_at = coalesce(first_response_at, now()), closed_at = null
  where id = p_ticket;
  perform app.notify(v_ticket.user_id,
    case when v_ticket.app = 'vendor' then 'support_replied_vendor' else 'support_replied' end,
    'orders', v_ticket.order_id, null, jsonb_build_object('ticket_id', p_ticket));
  perform app.admin_did(p_admin, 'ticket_replied', 'ticket', p_ticket::text,
    jsonb_build_object('status', v_ticket.status), jsonb_build_object('status', 'pending'), null, null);
  return app.ticket_json(p_ticket, true);
end
$$;

create or replace function public.admin_close_ticket(p_ticket uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v_status text;
begin
  select status into v_status from public.support_tickets where id = p_ticket for update;
  if v_status is null then
    raise exception 'demande introuvable' using errcode = 'P0002';
  end if;
  update public.support_tickets set status = 'closed', closed_at = now() where id = p_ticket;
  perform app.admin_did(v_admin, 'ticket_closed', 'ticket', p_ticket::text,
    jsonb_build_object('status', v_status), jsonb_build_object('status', 'closed'), null, null);
  return app.ticket_json(p_ticket, true);
end
$$;

-- ------------------------------------------------------------------ clientes

create or replace function public.admin_clients(p_query text default null, p_limit int default 50)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_q text := nullif(trim(p_query), '');
  v_like text;
begin
  perform app.require_admin();
  v_like := '%' || replace(replace(replace(coalesce(v_q, ''), '\', '\\'), '%', '\%'), '_', '\_') || '%';
  return (select coalesce(jsonb_agg(jsonb_build_object('id', x.user_id, 'first_name', x.first_name,
            'created_at', x.created_at, 'orders', x.n) order by x.created_at desc), '[]'::jsonb)
          from (select pr.user_id, pr.first_name, pr.created_at,
                       (select count(*) from public.orders o join public.purchases pu on pu.id = o.purchase_id
                        where pu.user_id = pr.user_id) as n
                from public.profiles pr
                join neon_auth."user" u on u.id = pr.user_id
                where not exists (select 1 from public.stores s where s.owner_id = pr.user_id)
                  and (v_q is null or pr.first_name ilike v_like or u.email ilike v_like
                       or exists (select 1 from public.orders o join public.purchases pu on pu.id = o.purchase_id
                                  where pu.user_id = pr.user_id and upper(left(o.id::text, 8)) like upper(v_q) || '%'))
                order by pr.created_at desc
                limit least(greatest(coalesce(p_limit, 50), 1), 200)) x);
end
$$;

-- Profil d'une cliente (écran 68), en lecture ; chaque consultation est auditée.
create or replace function public.admin_client(p_user uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v jsonb;
begin
  select jsonb_build_object(
    'id', pr.user_id, 'first_name', pr.first_name, 'email', u.email, 'country_code', pr.country_code,
    'zone_name', (select z.name from public.zones z where z.id = pr.zone_id),
    'city_name', (select c.name from public.zones z join public.cities c on c.id = z.city_id where z.id = pr.zone_id),
    'created_at', pr.created_at,
    'orders', (select coalesce(jsonb_agg(app.admin_order_row(o.id) order by o.created_at desc), '[]'::jsonb)
               from (select o.id, o.created_at from public.orders o join public.purchases pu on pu.id = o.purchase_id
                     where pu.user_id = pr.user_id order by o.created_at desc limit 20) o),
    'spent', (select coalesce(jsonb_agg(jsonb_build_object('currency_code', c, 'minor', m)), '[]'::jsonb)
              from (select o.currency_code as c, sum(o.total_minor) as m
                    from public.orders o join public.purchases pu on pu.id = o.purchase_id
                    where pu.user_id = pr.user_id and app.order_collected(o, pu.payment_status)
                    group by 1) s),
    'order_count', (select count(*) from public.orders o join public.purchases pu on pu.id = o.purchase_id
                    where pu.user_id = pr.user_id),
    'dispute_count', (select count(*) from public.disputes d where d.opened_by = pr.user_id),
    'ticket_count', (select count(*) from public.support_tickets t where t.user_id = pr.user_id),
    'addresses', (select coalesce(jsonb_agg(jsonb_build_object('kind', a.kind, 'label', a.label,
                    'zone_name', z.name, 'landmark', a.landmark) order by a.is_default desc), '[]'::jsonb)
                  from public.customer_addresses a join public.zones z on z.id = a.zone_id
                  where a.user_id = pr.user_id),
    'reviews', (select coalesce(jsonb_agg(app.review_json(r.id) || jsonb_build_object('store_name', s.name)
                  order by r.created_at desc), '[]'::jsonb)
                from public.reviews r join public.stores s on s.id = r.store_id
                where r.author_id = pr.user_id))
  into v
  from public.profiles pr join neon_auth."user" u on u.id = pr.user_id
  where pr.user_id = p_user;
  if v is null then
    raise exception 'cliente introuvable' using errcode = 'P0002';
  end if;
  perform app.audit(v_admin, 'client_viewed', 'user', p_user::text, null, null, null);
  return v;
end
$$;

-- ------------------------------------------------------------------ vendeuses

-- Vue de l'app d'une vendeuse (A-VEN-07), en lecture : boutique, produits,
-- commandes récentes ; chaque consultation est auditée.
create or replace function public.admin_vendor_view(p_store uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_admin uuid := app.require_admin();
  v jsonb;
begin
  select app.admin_store_json(s.id) || jsonb_build_object(
    'products', (select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name, 'status', p.status,
                   'price_minor', p.price_minor, 'is_available', p.is_available,
                   'stock', (select sum(v.stock_quantity) from public.product_variants v where v.product_id = p.id))
                   order by p.status, p.name), '[]'::jsonb)
                 from public.products p where p.store_id = s.id),
    'recent_orders', (select coalesce(jsonb_agg(app.admin_order_row(o.id) order by o.created_at desc), '[]'::jsonb)
                      from (select id, created_at from public.orders where store_id = s.id
                            order by created_at desc limit 20) o),
    'rating', app.store_rating(s.id))
  into v from public.stores s where s.id = p_store;
  if v is null then
    raise exception 'boutique introuvable' using errcode = 'P0002';
  end if;
  perform app.audit(v_admin, 'vendor_viewed', 'store', p_store::text, null, null, null);
  return v;
end
$$;

-- Supprimer le compte d'une vendeuse (A-VEN-06). Une boutique qui a déjà des
-- commandes garde son historique : refus `vendor_has_orders` (suspendre).
create or replace function app.admin_delete_vendor(p_admin uuid, p_store uuid, p_reason text) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_store public.stores;
  v_reason text;
begin
  perform app.assert_admin(p_admin);
  select * into v_store from public.stores where id = p_store for update;
  if v_store.id is null then
    raise exception 'boutique introuvable' using errcode = 'P0002';
  end if;
  v_reason := app.admin_reason(p_reason);
  if exists (select 1 from public.orders where store_id = p_store) then
    raise exception 'vendor_has_orders' using errcode = 'P0001';
  end if;
  perform app.admin_did(p_admin, 'vendor_deleted', 'store', p_store::text,
    app.admin_store_row(p_store), null, v_reason, v_store.country_code);
  perform app.emit_event('account_deleted', v_store.owner_id, 'vendor', 'server', v_store.country_code,
    'user', v_store.owner_id::text, jsonb_build_object('roles', '["vendor"]'::jsonb));
  delete from neon_auth."user" where id = v_store.owner_id;
end
$$;

-- ------------------------------------------------------------------ finances

-- Revenus de la plateforme (A-FIN-01/02), par devise et par boutique.
create or replace function public.admin_revenue(p_period text default 'month', p_at timestamptz default now())
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_range tstzrange := app.period_bounds(p_period, p_at);
begin
  perform app.require_admin();
  if v_range is null then
    raise exception 'période inconnue' using errcode = '22023';
  end if;
  return jsonb_build_object(
    'period', p_period,
    'totals', (select coalesce(jsonb_agg(jsonb_build_object('currency_code', c, 'orders', n,
                 'sales_minor', sales, 'commission_minor', comm, 'net_minor', sales - comm,
                 'refunds_minor', coalesce((select sum(r.amount_minor) from public.refunds r
                                            where r.status = 'succeeded' and r.currency_code = c
                                              and r.completed_at <@ v_range), 0))
                 order by c), '[]'::jsonb)
               from (select o.currency_code as c, count(*) as n, sum(o.subtotal_minor) as sales,
                            sum(o.commission_minor) as comm
                     from public.orders o join public.purchases pu on pu.id = o.purchase_id
                     where app.order_collected(o, pu.payment_status) and o.delivered_at <@ v_range
                     group by 1) t),
    'stores', (select coalesce(jsonb_agg(jsonb_build_object('id', id, 'name', name, 'currency_code', c,
                 'orders', n, 'sales_minor', sales, 'commission_minor', comm, 'net_minor', sales - comm)
                 order by sales desc), '[]'::jsonb)
               from (select s.id, s.name, o.currency_code as c, count(*) as n, sum(o.subtotal_minor) as sales,
                            sum(o.commission_minor) as comm
                     from public.orders o join public.purchases pu on pu.id = o.purchase_id
                     join public.stores s on s.id = o.store_id
                     where app.order_collected(o, pu.payment_status) and o.delivered_at <@ v_range
                     group by s.id, s.name, o.currency_code) x));
end
$$;

-- ------------------------------------------------------------------ référentiel

insert into public.feature_flags (key, country_code, is_enabled, description) values
  ('ai_search', null, false, 'Recherche vocale et par photo (phase 4)'),
  ('intent_copilot', null, false, 'Copilote d''intention : panier proposé (phase 4)'),
  ('shoppable_content', null, false, 'Stories et vidéos shoppables (phase 4)'),
  ('vendor_broadcast', null, false, 'Relance ciblée des clientes par la vendeuse (phase 4)')
on conflict do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function
  app.order_collected(public.orders, text), app.period_bounds(text, timestamptz),
  public.admin_dashboard(text, timestamptz), public.admin_feature_flags(),
  public.admin_set_feature_flag(text, char, boolean), public.admin_tickets(text, int),
  app.admin_reply_ticket(uuid, uuid, text), public.admin_close_ticket(uuid),
  public.admin_clients(text, int), public.admin_client(uuid), public.admin_vendor_view(uuid),
  app.admin_delete_vendor(uuid, uuid, text), public.admin_revenue(text, timestamptz)
from public;

grant execute on function
  public.admin_dashboard(text, timestamptz), public.admin_feature_flags(),
  public.admin_set_feature_flag(text, char, boolean), public.admin_tickets(text, int),
  public.admin_close_ticket(uuid), public.admin_clients(text, int), public.admin_client(uuid),
  public.admin_vendor_view(uuid), public.admin_revenue(text, timestamptz)
to authenticated;
