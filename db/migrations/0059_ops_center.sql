-- 0059 — Centre d'opérations (spec 053, VISION §3 « Différence », phase 13).
-- Vue en direct d'un pays pour l'équipe : commandes des dernières 24 h par statut, chiffre livré,
-- commandes en retard (seuils par pays, données de référence), livreurs en ligne, missions sans
-- livreur, litiges, tickets et signalements ouverts, cash des livreurs à recevoir.
-- Rôles par pays : un admin peut être limité à des pays (aucune ligne : tous les pays) ; le centre
-- d'opérations et ses réglages respectent ce périmètre. Seul un admin sans limite gère les limites.
-- Réglages : seuils d'alerte, poids du fil (0044), formules (0058). Toute écriture est auditée.

alter table public.countries
  add column ops_pending_alert_minutes smallint not null default 10
    check (ops_pending_alert_minutes between 1 and 240),
  add column ops_ready_alert_minutes smallint not null default 20
    check (ops_ready_alert_minutes between 1 and 240),
  add column ops_transit_alert_minutes smallint not null default 60
    check (ops_transit_alert_minutes between 1 and 480);

create table public.admin_scopes (
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  country_code char(2) not null references public.countries (code),
  granted_by uuid references neon_auth."user" (id) on delete set null,
  created_at timestamptz not null default clock_timestamp(),
  primary key (user_id, country_code)
);
alter table public.admin_scopes enable row level security;
revoke all on public.admin_scopes from authenticated, anonymous;

-- Pays que l'admin courant peut piloter (tous les pays actifs s'il n'est pas limité).
create or replace function app.admin_countries() returns char(2)[]
language sql stable security definer set search_path = ''
as $$
  select case when not app.is_admin() then '{}'::char(2)[]
    when exists (select 1 from public.admin_scopes where user_id = app.current_user_id())
      then array(select country_code from public.admin_scopes where user_id = app.current_user_id()
                 order by country_code)
    else array(select code from public.countries where is_active order by code) end
$$;

create or replace function app.require_ops(p_country char(2)) returns uuid
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_admin uuid := app.require_admin();
begin
  if p_country is null or not p_country = any(app.admin_countries()) then
    raise exception 'country_out_of_scope' using errcode = '42501';
  end if;
  return v_admin;
end
$fn$;

-- Cash des livreurs du pays dû à DYM (remis par l'équipe avec admin_confirm_courier_cash).
create or replace function app.ops_courier_cash(p_country char(2)) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(x order by (x ->> 'amount_minor')::bigint desc), '[]'::jsonb)
  from (
    select jsonb_build_object('courier_id', cp.user_id, 'name', cp.display_name, 'phone', cp.phone,
             'amount_minor', -app.ledger_balance(a.id), 'currency_code', a.currency_code) as x
    from public.courier_profiles cp
    join public.ledger_accounts a on a.kind = 'courier_cash' and a.user_id = cp.user_id and a.store_id is null
    where cp.country_code = p_country and -app.ledger_balance(a.id) > 0
  ) t
$$;

-- Pays pilotables par l'admin courant (choix du pays du centre d'opérations).
create or replace function public.ops_countries() returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
begin
  perform app.require_admin();
  return to_jsonb(app.admin_countries());
end
$fn$;

-- Vue en direct d'un pays.
create or replace function public.ops_live(p_country char(2)) returns jsonb
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
    'countries', to_jsonb(app.admin_countries()),
    'orders_by_status', coalesce((
      select jsonb_object_agg(status, n) from (
        select o.status, count(*) as n from public.orders o join public.stores s on s.id = o.store_id
        where s.country_code = p_country and o.created_at > now() - interval '24 hours'
        group by o.status) t), '{}'::jsonb),
    'delivered_minor', coalesce((
      select sum(o.total_minor) from public.orders o join public.stores s on s.id = o.store_id
      where s.country_code = p_country and o.status = 'delivered' and o.created_at > now() - interval '24 hours'), 0),
    'alerts', coalesce((
      select jsonb_agg(a order by (a ->> 'minutes')::int desc) from (
        select jsonb_build_object('order_id', o.id, 'store_name', s.name, 'status', o.status,
                 'fulfillment', o.fulfillment, 'minutes', w.minutes,
                 'has_courier', exists (select 1 from public.order_couriers oc where oc.order_id = o.id)) as a
        from public.orders o
        join public.stores s on s.id = o.store_id
        cross join lateral (
          select floor(extract(epoch from now() - coalesce(
            (select max(e.occurred_at) from public.order_status_events e where e.order_id = o.id),
            o.created_at)) / 60)::int as minutes) w
        where s.country_code = p_country
          and o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
          and w.minutes > case o.status
            when 'pending' then v_country.ops_pending_alert_minutes
            when 'ready' then v_country.ops_ready_alert_minutes
            when 'out_for_delivery' then v_country.ops_transit_alert_minutes
            else s.prep_time_minutes + v_country.ops_ready_alert_minutes end
        order by w.minutes desc
        limit 50) t), '[]'::jsonb),
    'couriers_online', (select count(*) from public.courier_profiles
                        where country_code = p_country and is_online and status = 'active'),
    'missions_waiting', (select count(*) from public.orders o join public.stores s on s.id = o.store_id
      where s.country_code = p_country and o.fulfillment = 'delivery'
        and o.status in ('accepted', 'preparing', 'ready')
        and not exists (select 1 from public.order_couriers oc where oc.order_id = o.id)),
    'open_disputes', (select count(*) from public.disputes d join public.orders o on o.id = d.order_id
      join public.stores s on s.id = o.store_id where s.country_code = p_country and d.status = 'open'),
    'open_tickets', (select count(*) from public.support_tickets t join public.profiles p on p.user_id = t.user_id
      where p.country_code = p_country and t.status in ('open', 'pending')),
    'open_reports', (select count(*) from public.reports where status = 'open'),
    'courier_cash', app.ops_courier_cash(p_country));
end
$fn$;

-- Réglages des opérations d'un pays : seuils, poids du fil, formules, limites des admins.
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
      'ready', v_country.ops_ready_alert_minutes, 'transit', v_country.ops_transit_alert_minutes),
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
    'transit', ops_transit_alert_minutes) into v_before from public.countries where code = p_country;
  update public.countries set
    ops_pending_alert_minutes = coalesce((p_values ->> 'pending')::smallint, ops_pending_alert_minutes),
    ops_ready_alert_minutes = coalesce((p_values ->> 'ready')::smallint, ops_ready_alert_minutes),
    ops_transit_alert_minutes = coalesce((p_values ->> 'transit')::smallint, ops_transit_alert_minutes)
  where code = p_country;
  perform app.admin_did(v_admin, 'ops_thresholds_set', 'country', p_country, v_before, p_values, null, p_country);
  return public.admin_ops_settings(p_country);
end
$fn$;

-- Poids du fil (0044) pour un pays du périmètre.
create or replace function public.admin_set_feed_weights(p_country char(2), p_weights jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
begin
  perform app.require_ops(p_country);
  perform public.admin_set_feed_ranking(p_country, p_weights);
  return public.admin_ops_settings(p_country);
end
$fn$;

-- Formule (0058) : création ou modification. Devise : celle du pays.
create or replace function public.admin_save_membership_plan(p_plan jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_country char(2) := p_plan ->> 'country_code';
  v_admin uuid := app.require_ops(v_country);
  v_id uuid := (p_plan ->> 'id')::uuid;
  v_before jsonb;
begin
  if v_id is null then
    insert into public.membership_plans (country_code, code, audience, name, description, price_minor, currency_code,
      period_days, benefits, is_active, sort)
    values (v_country, p_plan ->> 'code', p_plan ->> 'audience', p_plan -> 'name', p_plan -> 'description',
      (p_plan ->> 'price_minor')::bigint, (select currency_code from public.countries where code = v_country),
      (p_plan ->> 'period_days')::integer, coalesce(p_plan -> 'benefits', '{}'::jsonb),
      coalesce((p_plan ->> 'is_active')::boolean, true), coalesce((p_plan ->> 'sort')::smallint, 0))
    returning id into v_id;
  else
    select to_jsonb(pl) into v_before from public.membership_plans pl where id = v_id and country_code = v_country;
    if v_before is null then raise exception 'not_found' using errcode = 'P0002'; end if;
    update public.membership_plans set
      name = coalesce(p_plan -> 'name', name),
      description = coalesce(p_plan -> 'description', description),
      price_minor = coalesce((p_plan ->> 'price_minor')::bigint, price_minor),
      period_days = coalesce((p_plan ->> 'period_days')::integer, period_days),
      benefits = coalesce(p_plan -> 'benefits', benefits),
      is_active = coalesce((p_plan ->> 'is_active')::boolean, is_active),
      sort = coalesce((p_plan ->> 'sort')::smallint, sort)
    where id = v_id;
  end if;
  perform app.admin_did(v_admin, 'membership_plan_saved', 'membership_plan', v_id::text, v_before,
    (select to_jsonb(pl) - 'created_at' from public.membership_plans pl where id = v_id), null, v_country);
  return public.admin_ops_settings(v_country);
end
$fn$;

-- Limite d'un admin à un pays (on) ou retrait (off). Réservé aux admins sans limite.
create or replace function public.admin_set_scope(p_email text, p_country char(2), p_on boolean) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_admin uuid := app.require_admin();
  v_user uuid;
begin
  if exists (select 1 from public.admin_scopes where user_id = v_admin) then
    raise exception 'scoped_admin' using errcode = '42501';
  end if;
  select u.id into v_user from neon_auth."user" u where lower(u.email) = lower(btrim(p_email));
  if v_user is null or not exists (select 1 from public.user_roles where user_id = v_user and role = 'admin') then
    raise exception 'not_admin' using errcode = 'P0002';
  end if;
  if v_user = v_admin then raise exception 'own_scope' using errcode = 'P0001'; end if;
  if p_on then
    insert into public.admin_scopes (user_id, country_code, granted_by) values (v_user, p_country, v_admin)
    on conflict do nothing;
  else
    delete from public.admin_scopes where user_id = v_user and country_code = p_country;
  end if;
  perform app.admin_did(v_admin, case when p_on then 'admin_scope_added' else 'admin_scope_removed' end,
    'user', v_user::text, null, jsonb_build_object('country_code', p_country), null, p_country);
  return public.admin_ops_settings(p_country);
end
$fn$;

revoke all on function app.admin_countries(), app.require_ops(char), app.ops_courier_cash(char),
  public.ops_countries(), public.ops_live(char), public.admin_ops_settings(char), public.admin_set_ops_thresholds(char, jsonb),
  public.admin_set_feed_weights(char, jsonb), public.admin_save_membership_plan(jsonb),
  public.admin_set_scope(text, char, boolean) from public;
grant execute on function public.ops_countries(), public.ops_live(char), public.admin_ops_settings(char),
  public.admin_set_ops_thresholds(char, jsonb), public.admin_set_feed_weights(char, jsonb),
  public.admin_save_membership_plan(jsonb), public.admin_set_scope(text, char, boolean) to authenticated;
