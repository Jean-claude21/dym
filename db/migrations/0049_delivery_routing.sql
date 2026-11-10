-- 0049 — Tournées, code de remise, consignes de conservation (spec 042, VISION §3 « Livreur »).
-- 1. Tournée : accepter une course prend toutes les commandes à livrer du même achat (plusieurs
--    boutiques, une cliente) ; la limite du pays compte les tournées, pas les commandes.
-- 2. Code de remise : 4 chiffres tirés quand un livreur DYM prend la commande ; la cliente le voit,
--    le livreur le saisit pour déclarer la commande livrée (5 essais, ensuite l'équipe).
-- 3. Conservation : consigne par rayon (donnée de référence), remplaçable par produit ; affichée au
--    livreur pour chaque course.

alter table public.categories add column storage text
  check (storage is null or storage in ('ambient', 'cool', 'frozen', 'fragile'));
alter table public.products add column storage text
  check (storage is null or storage in ('ambient', 'cool', 'frozen', 'fragile'));

-- Consignes par défaut du référentiel (modifiables par l'équipe).
update public.categories set storage = 'cool'
where slug in ('feuilles', 'jus-maison', 'plats-sauces', 'poissons-fumes');
update public.categories set storage = 'fragile' where slug in ('tomates', 'fruits', 'patisseries');

alter table public.orders
  add column handover_code char(4) check (handover_code is null or handover_code ~ '^[0-9]{4}$'),
  add column handover_attempts smallint not null default 0 check (handover_attempts between 0 and 50);

-- Livreur DYM sur la commande : code de remise tiré (jamais pour une saisie manuelle de l'équipe).
create or replace function app.order_courier_code() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
begin
  if new.courier_id is not null then
    update public.orders
    set handover_code = lpad((floor(random() * 10000))::int::text, 4, '0'), handover_attempts = 0
    where id = new.order_id;
  end if;
  return null;
end
$fn$;
create trigger order_couriers_code after insert on public.order_couriers
  for each row execute function app.order_courier_code();

-- Code de remise, pour la cliente de la commande, tant qu'elle n'est pas livrée.
create or replace function public.my_handover_code(p_order uuid) returns text
language sql stable security definer set search_path = ''
as $$
  select o.handover_code from public.orders o join public.purchases pu on pu.id = o.purchase_id
  where o.id = p_order and pu.user_id = app.current_user_id()
    and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery')
$$;

-- Remise par le livreur : le code de la cliente est exigé.
create or replace function public.courier_deliver(p_order uuid, p_code text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_order public.orders;
begin
  select o.* into v_order from public.orders o
  join public.order_couriers oc on oc.order_id = o.id and oc.courier_id = v_user
  where o.id = p_order for update of o;
  if v_order.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_order.handover_attempts >= 5 then raise exception 'code_locked' using errcode = 'P0001'; end if;
  if v_order.handover_code is null or btrim(coalesce(p_code, '')) <> v_order.handover_code then
    update public.orders set handover_attempts = handover_attempts + 1 where id = p_order;
    perform app.emit_event('handover_code_failed', v_user, 'courier', 'server', null, 'order', p_order::text,
      jsonb_build_object('attempts', v_order.handover_attempts + 1));
    return jsonb_build_object('ok', false, 'attempts_left', greatest(0, 4 - v_order.handover_attempts));
  end if;
  perform app.transition_order(v_user, p_order, 'delivered', 'out_for_delivery');
  return jsonb_build_object('ok', true, 'mission', app.mission_json(p_order, v_user));
end
$fn$;

-- Le livreur déclare « livrée » par le code seulement ; « récupérée » reste un geste simple.
create or replace function public.courier_transition(p_order uuid, p_to text, p_expected text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if p_to = 'delivered' then raise exception 'code_required' using errcode = 'P0001'; end if;
  perform app.transition_order(v_user, p_order, p_to, p_expected);
  return app.mission_json(p_order, v_user);
end
$fn$;

-- Consigne de conservation d'un produit de sa boutique ; nulle : celle du rayon.
create or replace function public.set_product_storage(p_product uuid, p_storage text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
begin
  if p_storage is not null and p_storage not in ('ambient', 'cool', 'frozen', 'fragile') then
    raise exception 'invalid_storage' using errcode = '22023';
  end if;
  update public.products set storage = p_storage where id = p_product and store_id = app.own_store_id();
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  return jsonb_build_object('storage', p_storage);
end
$fn$;

-- Consignes d'une commande : celles de ses produits, sinon de leur rayon (ou du rayon parent).
create or replace function app.order_storage(p_order uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(distinct s), '[]'::jsonb)
  from (select coalesce(p.storage, c.storage, pc.storage) as s
        from public.order_items i
        join public.products p on p.id = i.product_id
        left join public.categories c on c.id = p.category_id
        left join public.categories pc on pc.id = c.parent_id
        where i.order_id = p_order) x
  where s is not null
$$;

insert into public.event_names (name, emitted_by, description) values
  ('handover_code_failed', 'server', 'Code de remise erroné (essais)'),
  ('run_accepted', 'server', 'Tournée acceptée (nombre de boutiques)')
on conflict do nothing;

-- Missions (0048) : tournée, consignes, limite par tournée.
create or replace function app.mission_json(p_order uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'order_id', o.id, 'purchase_id', o.purchase_id, 'status', o.status, 'created_at', o.created_at,
    -- Tournée : commandes à livrer du même achat ; consignes de conservation.
    'run_size', (select count(*) from public.orders r where r.purchase_id = o.purchase_id
                 and r.fulfillment = 'delivery' and r.status not in ('refused', 'cancelled')),
    'storage', app.order_storage(o.id),
    'ready_at', o.ready_at, 'eta_at', app.order_eta(o.id),
    'delivery_fee_minor', o.delivery_fee_minor, 'currency_code', o.currency_code,
    'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
    'store', jsonb_build_object('name', s.name,
      'zone_name', (select z.name from public.zones z where z.id = s.zone_id),
      'landmark', case when mine then (select concat_ws(' · ', a.address, a.landmark)
                                       from public.store_pickup_addresses a where a.store_id = s.id) end,
      'phone', case when mine then (select a.contact_phone from public.store_pickup_addresses a
                                    where a.store_id = s.id) end),
    'customer', jsonb_build_object(
      'zone_name', (select z.name from public.zones z where z.id = (pu.address ->> 'zone_id')::uuid),
      'first_name', case when mine then (select p.first_name from public.profiles p where p.user_id = pu.user_id) end,
      'landmark', case when mine then pu.address ->> 'landmark' end,
      'phone', case when mine then pu.address ->> 'phone' end,
      'latitude', case when mine then pu.address -> 'latitude' end,
      'longitude', case when mine then pu.address -> 'longitude' end),
    'accepted_at', oc.accepted_at,
    'next', case when mine then app.order_next_statuses('courier', o.fulfillment, o.status) else '[]'::jsonb end)
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.stores s on s.id = o.store_id
  left join public.order_couriers oc on oc.order_id = o.id
  cross join lateral (select oc.courier_id is not distinct from p_user and oc.courier_id is not null as mine) m
  where o.id = p_order
$$;

create or replace function public.accept_mission(p_order uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_courier public.courier_profiles;
  v_order public.orders;
  v_owner uuid;
  v_client uuid;
  v_sibling record;
  v_run integer;
begin
  select * into v_courier from public.courier_profiles where user_id = v_user;
  if v_courier.user_id is null then raise exception 'not_courier' using errcode = '42501'; end if;
  select * into v_order from public.orders where id = p_order for update;
  if v_order.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  -- Limite : tournées (achats) en cours, pas commandes.
  if (select count(distinct o.purchase_id) from public.order_couriers oc join public.orders o on o.id = oc.order_id
      where oc.courier_id = v_user and o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery'))
     >= (select courier_max_active from public.countries where code = v_courier.country_code) then
    raise exception 'too_many_missions' using errcode = 'P0001';
  end if;
  if not app.mission_open_for(p_order, v_user) then
    raise exception 'mission_taken' using errcode = 'P0001';
  end if;
  insert into public.order_couriers (order_id, name, phone, courier_id, accepted_at)
  values (p_order, v_courier.display_name, v_courier.phone, v_user, now());
  select owner_id into v_owner from public.stores where id = v_order.store_id;
  select user_id into v_client from public.purchases where id = v_order.purchase_id;
  perform app.notify(v_owner, 'delivery_assigned', 'orders', p_order, v_order.purchase_id,
    jsonb_build_object('courier_name', v_courier.display_name, 'courier_phone', v_courier.phone));
  perform app.notify(v_client, 'courier_assigned', 'orders', p_order, v_order.purchase_id,
    jsonb_build_object('courier_name', v_courier.display_name));
  -- Tournée : les autres commandes du même achat encore libres suivent.
  v_run := 1;
  for v_sibling in
    select o.id, o.store_id from public.orders o
    where o.purchase_id = v_order.purchase_id and o.id <> p_order and app.mission_open_for(o.id, v_user)
    for update
  loop
    insert into public.order_couriers (order_id, name, phone, courier_id, accepted_at)
    values (v_sibling.id, v_courier.display_name, v_courier.phone, v_user, now());
    perform app.notify((select owner_id from public.stores where id = v_sibling.store_id), 'delivery_assigned',
      'orders', v_sibling.id, v_order.purchase_id,
      jsonb_build_object('courier_name', v_courier.display_name, 'courier_phone', v_courier.phone));
    v_run := v_run + 1;
  end loop;
  if v_run > 1 then
    perform app.emit_event('run_accepted', v_user, 'courier', 'server', v_courier.country_code,
      'purchase', v_order.purchase_id::text, jsonb_build_object('stores', v_run));
  end if;
  perform app.emit_event('mission_accepted', v_user, 'courier', 'server', v_courier.country_code,
    'order', p_order::text, jsonb_build_object('minutes_since_created',
      round(extract(epoch from now() - v_order.created_at) / 60)::int));
  return app.mission_json(p_order, v_user);
end
$fn$;

create or replace function public.my_missions() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.mission_json(oc.order_id, app.current_user_id())
                            order by (o.status = 'delivered'), o.purchase_id, oc.accepted_at desc), '[]'::jsonb)
  from public.order_couriers oc join public.orders o on o.id = oc.order_id
  where oc.courier_id = app.current_user_id()
    and (o.status in ('accepted', 'preparing', 'ready', 'out_for_delivery')
         or (o.status = 'delivered' and o.delivered_at > now() - interval '24 hours'))
$$;


revoke all on function app.order_courier_code(), public.my_handover_code(uuid), public.courier_deliver(uuid, text),
  public.set_product_storage(uuid, text), app.order_storage(uuid) from public;
grant execute on function public.my_handover_code(uuid), public.courier_deliver(uuid, text),
  public.set_product_storage(uuid, text) to authenticated;
