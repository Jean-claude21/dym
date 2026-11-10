-- 0057 — Achat groupé entre voisins, départ groupé (spec 051, VISION §3 « Cliente » : prix de
-- gros, livraison partagée).
-- La vendeuse ouvre une offre groupée sur un produit : prix de groupe, quantité totale minimale,
-- date limite et, si elle veut, des frais de livraison réduits pour les membres (livraison
-- partagée). Les clientes des quartiers qu'elle dessert s'inscrivent avec une quantité ; la jauge
-- monte. Minimum atteint : le groupe est débloqué, les membres sont prévenus, et leur panier prend
-- le prix de groupe (au plus leur quantité) et les frais réduits jusqu'au lendemain de la date
-- limite. La commande consomme l'avantage. Débloqué, on ne peut plus réduire sa quantité.

create table public.group_offers (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  currency_code char(3) not null references public.currencies (code),
  group_price_minor bigint not null check (group_price_minor > 0),
  min_quantity integer not null check (min_quantity between 2 and 10000),
  member_delivery_fee_minor bigint check (member_delivery_fee_minor is null or member_delivery_fee_minor >= 0),
  closes_at timestamptz not null,
  status text not null default 'open' check (status in ('open', 'cancelled')),
  reached_at timestamptz,
  created_at timestamptz not null default clock_timestamp()
);
create index group_offers_open on public.group_offers (store_id, closes_at) where status = 'open';
alter table public.group_offers enable row level security;
revoke all on public.group_offers from authenticated, anonymous;

create table public.group_members (
  offer_id uuid not null references public.group_offers (id) on delete cascade,
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  quantity smallint not null check (quantity between 1 and 99),
  order_id uuid references public.orders (id) on delete set null,
  joined_at timestamptz not null default clock_timestamp(),
  primary key (offer_id, user_id)
);
alter table public.group_members enable row level security;
revoke all on public.group_members from authenticated, anonymous;

-- Avantage en cours : groupe débloqué, ouvert, jusqu'au lendemain de la date limite.
create or replace function app.group_active(p_offer public.group_offers) returns boolean
language sql stable
as $$
  select p_offer.status = 'open' and p_offer.reached_at is not null and now() < p_offer.closes_at + interval '1 day'
$$;

-- Prix d'une ligne de panier (0056) : le meilleur du prix conclu (marchandage), du prix de groupe
-- (membre d'un groupe débloqué, quantité au plus la sienne) et du prix du jour.
create or replace function app.cart_line_price(p_cart uuid, p_variant uuid, p_quantity integer) returns bigint
language sql stable security definer set search_path = ''
as $$
  select least(
    app.variant_price(p_variant),
    (select min(h.price_minor) from public.haggles h join public.carts c on c.user_id = h.user_id
     where c.id = p_cart and h.variant_id = p_variant and h.status = 'accepted' and h.expires_at > now()
       and p_quantity <= h.quantity),
    (select min(o.group_price_minor) from public.group_members m
     join public.group_offers o on o.id = m.offer_id
     join public.carts c on c.user_id = m.user_id
     where c.id = p_cart and o.variant_id = p_variant and app.group_active(o) and m.order_id is null
       and p_quantity <= m.quantity))
$$;

-- Frais propres d'une boutique pour ce panier : frais des membres d'un groupe débloqué dont le
-- produit est au panier, sinon ceux de la boutique.
create or replace function app.cart_store_fee(p_cart uuid, p_store uuid) returns bigint
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    (select min(o.member_delivery_fee_minor) from public.group_members m
     join public.group_offers o on o.id = m.offer_id
     join public.carts c on c.user_id = m.user_id
     where c.id = p_cart and o.store_id = p_store and app.group_active(o) and m.order_id is null
       and o.member_delivery_fee_minor is not null
       and exists (select 1 from public.cart_items ci where ci.cart_id = p_cart and ci.variant_id = o.variant_id)),
    (select delivery_fee_minor from public.stores where id = p_store))
$$;

-- Offre vue par [p_user] (cliente) ou par la vendeuse (p_user nul).
create or replace function app.group_offer_json(p_offer uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id, 'store_id', o.store_id, 'store_name', s.name, 'product_id', o.product_id,
    'product_name', p.name, 'variant_id', o.variant_id,
    'photo_key', (select f.object_key from public.product_photos f where f.product_id = p.id order by f.sort limit 1),
    'currency_code', o.currency_code, 'group_price_minor', o.group_price_minor,
    'price_minor', app.variant_price(o.variant_id), 'min_quantity', o.min_quantity,
    'member_delivery_fee_minor', o.member_delivery_fee_minor, 'closes_at', o.closes_at,
    'committed', coalesce((select sum(quantity) from public.group_members where offer_id = o.id), 0),
    'members', (select count(*) from public.group_members where offer_id = o.id),
    'my_quantity', (select quantity from public.group_members where offer_id = o.id and user_id = p_user),
    'ordered', exists (select 1 from public.group_members where offer_id = o.id and user_id = p_user
                       and order_id is not null),
    'reached', o.reached_at is not null,
    'status', case when o.status = 'cancelled' then 'cancelled'
                   when o.closes_at <= now() then 'closed' else 'open' end)
  from public.group_offers o
  join public.stores s on s.id = o.store_id
  join public.products p on p.id = o.product_id
  where o.id = p_offer
$$;

-- Vendeuse : nouvelle offre groupée sur un produit publié (première variante).
create or replace function public.create_group_offer(p_product uuid, p_group_price_minor bigint,
  p_min_quantity integer, p_days integer default 3, p_member_delivery_fee_minor bigint default null)
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store public.stores;
  v_variant uuid;
  v_id uuid;
begin
  select * into v_store from public.stores where id = app.own_store_id();
  select v.id into v_variant from public.product_variants v join public.products p on p.id = v.product_id
  where p.id = p_product and p.store_id = v_store.id and p.status = 'published'
  order by v.sort, v.created_at limit 1;
  if v_variant is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if p_group_price_minor is null or p_group_price_minor <= 0
     or p_group_price_minor >= app.variant_price(v_variant) then
    raise exception 'invalid_amount' using errcode = '22023';
  end if;
  if p_min_quantity is null or p_min_quantity not between 2 and 10000 then
    raise exception 'invalid_quantity' using errcode = '22023';
  end if;
  if p_days is null or p_days not between 1 and 14 then raise exception 'invalid_days' using errcode = '22023'; end if;
  if p_member_delivery_fee_minor is not null and p_member_delivery_fee_minor < 0 then
    raise exception 'invalid_amount' using errcode = '22023';
  end if;
  insert into public.group_offers (store_id, product_id, variant_id, currency_code, group_price_minor, min_quantity,
    member_delivery_fee_minor, closes_at)
  values (v_store.id, p_product, v_variant, v_store.currency_code, p_group_price_minor, p_min_quantity,
    p_member_delivery_fee_minor, now() + make_interval(days => p_days))
  returning id into v_id;
  perform app.emit_event('group_offer_opened', app.current_user_id(), 'vendor', 'server', v_store.country_code,
    'store', v_store.id::text, jsonb_build_object('min_quantity', p_min_quantity, 'days', p_days,
      'shared_delivery', p_member_delivery_fee_minor is not null));
  return app.group_offer_json(v_id, null);
end
$fn$;

-- Vendeuse : annuler une offre ; les membres sont prévenus.
create or replace function public.cancel_group_offer(p_offer uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_offer public.group_offers;
begin
  select * into v_offer from public.group_offers where id = p_offer and store_id = app.own_store_id() for update;
  if v_offer.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_offer.status <> 'open' then raise exception 'offer_closed' using errcode = 'P0001'; end if;
  update public.group_offers set status = 'cancelled' where id = p_offer;
  perform app.notify(m.user_id, 'group_cancelled', 'orders', null, null,
    jsonb_build_object('product_name', (select name from public.products where id = v_offer.product_id)))
  from public.group_members m where m.offer_id = p_offer;
  return app.group_offer_json(p_offer, null);
end
$fn$;

-- Vendeuse : ses offres des 60 derniers jours.
create or replace function public.my_group_offers() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.group_offer_json(o.id, null) order by o.created_at desc), '[]'::jsonb)
  from public.group_offers o
  where o.store_id = app.own_store_id() and o.created_at > now() - interval '60 days'
$$;

-- Cliente : offres ouvertes des boutiques qui livrent son quartier, et ses groupes encore actifs.
create or replace function public.group_offers_near(p_zone uuid default null) returns jsonb
language sql stable security definer set search_path = ''
as $$
  with me as (
    select app.require_user() as id,
           coalesce(p_zone, (select zone_id from public.profiles where user_id = app.current_user_id())) as zone
  )
  select coalesce(jsonb_agg(app.group_offer_json(o.id, (select id from me)) order by o.closes_at), '[]'::jsonb)
  from public.group_offers o join public.stores s on s.id = o.store_id
  where s.status = 'active' and o.status = 'open'
    and ((o.closes_at > now() and app.store_serves(s.id, (select zone from me)))
         or (app.group_active(o) and exists (select 1 from public.group_members m
                                              where m.offer_id = o.id and m.user_id = (select id from me))))
$$;

-- Cliente : quantité dans le groupe (0 : retrait, seulement avant le déblocage).
create or replace function public.join_group_offer(p_offer uuid, p_quantity integer) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_offer public.group_offers;
  v_store public.stores;
  v_current smallint;
  v_committed bigint;
begin
  select * into v_offer from public.group_offers where id = p_offer for update;
  select * into v_store from public.stores where id = v_offer.store_id and status = 'active';
  if v_offer.id is null or v_store.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_store.owner_id = v_user then raise exception 'own_store' using errcode = 'P0001'; end if;
  if v_offer.status <> 'open' or v_offer.closes_at <= now() then
    raise exception 'offer_closed' using errcode = 'P0001';
  end if;
  if p_quantity is null or p_quantity not between 0 and 99 then
    raise exception 'invalid_quantity' using errcode = '22023';
  end if;
  select quantity into v_current from public.group_members where offer_id = p_offer and user_id = v_user;
  if v_offer.reached_at is not null and p_quantity < coalesce(v_current, 0) then
    raise exception 'group_locked' using errcode = 'P0001';
  end if;
  if p_quantity = 0 then
    delete from public.group_members where offer_id = p_offer and user_id = v_user;
  else
    insert into public.group_members (offer_id, user_id, quantity) values (p_offer, v_user, p_quantity)
    on conflict (offer_id, user_id) do update set quantity = excluded.quantity;
  end if;
  perform app.emit_event('group_joined', v_user, 'client', 'server', v_store.country_code, 'store',
    v_store.id::text, jsonb_build_object('quantity', p_quantity));
  select coalesce(sum(quantity), 0) into v_committed from public.group_members where offer_id = p_offer;
  if v_offer.reached_at is null and v_committed >= v_offer.min_quantity then
    update public.group_offers set reached_at = clock_timestamp() where id = p_offer;
    perform app.notify(m.user_id, 'group_unlocked', 'orders', null, null,
      jsonb_build_object('product_name', (select name from public.products where id = v_offer.product_id),
        'quantity', m.quantity))
    from public.group_members m where m.offer_id = p_offer;
    perform app.emit_event('group_unlocked', null, 'client', 'server', v_store.country_code, 'store',
      v_store.id::text, jsonb_build_object('members', (select count(*) from public.group_members where offer_id = p_offer),
        'quantity', v_committed));
  end if;
  return app.group_offer_json(p_offer, v_user);
end
$fn$;

-- La commande consomme l'avantage du groupe (prix de groupe sur la ligne).
create or replace function app.group_used() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
begin
  update public.group_members m set order_id = new.order_id
  from public.group_offers o
  where o.id = m.offer_id and m.order_id is null and o.variant_id = new.variant_id
    and o.group_price_minor = new.unit_price_minor
    and m.user_id = (select pu.user_id from public.orders od join public.purchases pu on pu.id = od.purchase_id
                     where od.id = new.order_id);
  return new;
end
$fn$;
create trigger order_items_group after insert on public.order_items
for each row execute function app.group_used();

insert into public.notification_templates (kind, locale, title, body) values
  ('group_unlocked', 'fr', 'Achat groupé débloqué', 'Le groupe pour {product_name} est complet : ton prix de groupe t''attend ({quantity}).'),
  ('group_unlocked', 'en', 'Group purchase unlocked', 'The group for {product_name} is complete: your group price is waiting ({quantity}).'),
  ('group_cancelled', 'fr', 'Achat groupé annulé', 'La vendeuse a annulé l''achat groupé de {product_name}.'),
  ('group_cancelled', 'en', 'Group purchase cancelled', 'The seller cancelled the group purchase of {product_name}.')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('group_offer_opened', 'server', 'Offre groupée ouverte (minimum, durée, livraison partagée)'),
  ('group_joined', 'server', 'Inscription à un achat groupé (quantité ; 0 : retrait)'),
  ('group_unlocked', 'server', 'Achat groupé débloqué (membres, quantité totale)')
on conflict do nothing;

-- Copie (0056) : les frais propres d'une boutique passent par app.cart_store_fee.
create or replace function app.cart_quote(
  p_cart uuid,
  p_zone uuid,
  p_modes jsonb,
  p_payment_method uuid,
  p_at timestamptz
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_cart public.carts;
  v_city uuid := (select city_id from public.zones where id = p_zone);
  v_base bigint;
  v_extra bigint;
  v_threshold bigint;
  v_methods jsonb;
  v_method uuid;
  v_stores jsonb;
  v_delivered_subtotal bigint;
  v_result jsonb;
begin
  select * into v_cart from public.carts where id = p_cart;

  select d.base_fee_minor, d.extra_pickup_fee_minor, d.free_threshold_minor
  into v_base, v_extra, v_threshold
  from public.delivery_fee_defaults d
  where d.country_code = v_cart.country_code and d.valid_to is null
    and (d.city_id = v_city or d.city_id is null)
  order by d.city_id nulls last
  limit 1;

  -- Moyens actifs du pays acceptés par toutes les boutiques du panier.
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', pm.id, 'country_code', pm.country_code, 'provider_code', pm.provider_code,
           'operator_code', pm.operator_code, 'label', pm.label, 'sort', pm.sort) order by pm.sort), '[]'::jsonb)
  into v_methods
  from public.payment_methods pm
  where pm.country_code = v_cart.country_code and pm.is_active
    and not exists (
      select 1 from public.cart_items ci
      join public.product_variants v on v.id = ci.variant_id
      join public.products p on p.id = v.product_id
      where ci.cart_id = p_cart
        and not exists (select 1 from public.store_payment_methods spm
                        where spm.store_id = p.store_id and spm.payment_method_id = pm.id));
  v_method := coalesce(
    (select (m ->> 'id')::uuid from jsonb_array_elements(v_methods) m
     where (m ->> 'id')::uuid = p_payment_method),
    (v_methods -> 0 ->> 'id')::uuid);

  with lines as (
    select ci.variant_id, ci.quantity, ci.added_at, p.id as product_id, p.name, p.category_id,
           v.label as variant_label, v.stock_quantity, u.label as unit_label,
           (select f.object_key from public.product_photos f where f.product_id = p.id
            order by f.sort limit 1) as photo_key,
           app.cart_line_price(p_cart, v.id, ci.quantity) as unit_price, app.variant_price(v.id) as list_price,
           ci.unit_price_seen_minor,
           p.store_id,
           array_remove(array[
             case when p.status <> 'published' or not p.is_available
                    or v.stock_quantity = 0 then 'unavailable' end,
             case when v.stock_quantity > 0 and ci.quantity > v.stock_quantity then 'stock' end,
             case when app.cart_line_price(p_cart, v.id, ci.quantity) <> ci.unit_price_seen_minor then 'price_changed' end
           ], null) as issues
    from public.cart_items ci
    join public.product_variants v on v.id = ci.variant_id
    join public.products p on p.id = v.product_id
    left join public.units u on u.id = p.unit_id
    where ci.cart_id = p_cart
  ),
  stores as (
    select s.id, s.name, s.origin, z.name as zone_name, s.offers_pickup, app.cart_store_fee(p_cart, s.id) as own_fee,
           s.prep_time_minutes,
           case when coalesce(p_modes ->> s.id::text, 'delivery') = 'pickup' then 'pickup' else 'delivery' end
             as fulfillment,
           app.store_open_at(s.id, p_at) as is_open,
           sum(l.unit_price * l.quantity) as subtotal,
           jsonb_agg(jsonb_build_object(
             'variant_id', l.variant_id, 'product_id', l.product_id, 'name', l.name,
             'variant_label', l.variant_label, 'unit_label', l.unit_label, 'photo_key', l.photo_key,
             'quantity', l.quantity, 'unit_price_minor', l.unit_price, 'list_price_minor', l.list_price,
             'amount_minor', l.unit_price * l.quantity, 'stock_quantity', l.stock_quantity,
             'category_id', l.category_id, 'issues', to_jsonb(l.issues))
             order by l.added_at, l.variant_id) as lines,
           min(l.added_at) as first_added
    from lines l
    join public.stores s on s.id = l.store_id
    join public.zones z on z.id = s.zone_id
    group by s.id, z.name
  ),
  checked as (
    select st.*,
           array_remove(array[
             case when (select status from public.stores where id = st.id) <> 'active' then 'suspended' end,
             case when (select status from public.stores where id = st.id) = 'active' and not st.is_open
                  then 'closed' end,
             case when st.fulfillment = 'delivery' and p_zone is not null
                    and not app.store_serves(st.id, p_zone) then 'not_delivered' end,
             case when st.fulfillment = 'pickup' and not st.offers_pickup then 'pickup_unavailable' end,
             case when p_payment_method is not null and not exists (
                    select 1 from public.store_payment_methods spm
                    where spm.store_id = st.id and spm.payment_method_id = p_payment_method)
                  then 'payment_not_accepted' end
           ], null) as issues
    from stores st
  ),
  ranked as (
    select c.*,
           case when c.fulfillment = 'delivery'
                then row_number() over (partition by c.fulfillment order by c.subtotal desc, c.id) end
             as delivery_rank
    from checked c
  )
  select jsonb_agg(jsonb_build_object(
           'id', r.id, 'name', r.name, 'origin', r.origin, 'zone_name', r.zone_name,
           'fulfillment', r.fulfillment, 'offers_pickup', r.offers_pickup, 'is_open', r.is_open,
           'prep_time_minutes', r.prep_time_minutes,
           'issues', to_jsonb(r.issues), 'subtotal_minor', r.subtotal,
           'delivery_rank', r.delivery_rank,
           'own_fee_minor', r.own_fee, 'lines', r.lines)
           order by r.first_added, r.id)
  into v_stores
  from ranked r;

  v_stores := coalesce(v_stores, '[]'::jsonb);
  select coalesce(sum((s ->> 'subtotal_minor')::bigint), 0) into v_delivered_subtotal
  from jsonb_array_elements(v_stores) s where s ->> 'fulfillment' = 'delivery';

  -- Frais par boutique.
  select coalesce(jsonb_agg(
           (s - 'delivery_rank' - 'own_fee_minor') || jsonb_build_object(
             'delivery_fee_minor',
             case
               when s ->> 'fulfillment' <> 'delivery' then 0
               when v_threshold is not null and v_delivered_subtotal >= v_threshold then 0
               when (s ->> 'delivery_rank')::int = 1
                 then coalesce((s ->> 'own_fee_minor')::bigint, v_base, 0)
               else coalesce(v_extra, 0)
             end)
           order by o), '[]'::jsonb)
  into v_stores
  from jsonb_array_elements(v_stores) with ordinality as e(s, o);

  select jsonb_build_object(
    'country_code', v_cart.country_code,
    'currency_code', v_cart.currency_code,
    'currency', (select to_jsonb(cu) - 'created_at' - 'updated_at' from public.currencies cu
                 where cu.code = v_cart.currency_code),
    'stores', v_stores,
    'payment_methods', v_methods,
    'payment_method_id', v_method,
    'item_count', coalesce((select sum((l ->> 'quantity')::int)
                            from jsonb_array_elements(v_stores) s,
                                 jsonb_array_elements(s -> 'lines') l), 0),
    'pickup_count', (select count(*) from jsonb_array_elements(v_stores) s
                     where s ->> 'fulfillment' = 'delivery'),
    'delivery_minutes', coalesce((select delivery_minutes from public.cities where id = v_city), 0)
      + coalesce((select max((s ->> 'prep_time_minutes')::int) from jsonb_array_elements(v_stores) s), 0),
    'subtotal_minor', coalesce((select sum((s ->> 'subtotal_minor')::bigint)
                                from jsonb_array_elements(v_stores) s), 0),
    'delivery_fee_minor', coalesce((select sum((s ->> 'delivery_fee_minor')::bigint)
                                    from jsonb_array_elements(v_stores) s), 0),
    'free_threshold_minor', v_threshold,
    'remaining_for_free_minor', case when v_threshold is null then null
                                     else greatest(v_threshold - v_delivered_subtotal, 0) end,
    'blocking', exists (
      select 1 from jsonb_array_elements(v_stores) s
      where jsonb_array_length(s -> 'issues') > 0
         or exists (select 1 from jsonb_array_elements(s -> 'lines') l
                    where l -> 'issues' ?| array['unavailable', 'stock'])))
  into v_result;

  return v_result || jsonb_build_object(
    'total_minor', (v_result ->> 'subtotal_minor')::bigint + (v_result ->> 'delivery_fee_minor')::bigint);
end
$$;

revoke all on function app.group_active(public.group_offers), app.cart_store_fee(uuid, uuid),
  app.group_offer_json(uuid, uuid), public.create_group_offer(uuid, bigint, integer, integer, bigint),
  public.cancel_group_offer(uuid), public.my_group_offers(), public.group_offers_near(uuid),
  public.join_group_offer(uuid, integer), app.group_used() from public;
grant execute on function public.create_group_offer(uuid, bigint, integer, integer, bigint),
  public.cancel_group_offer(uuid), public.my_group_offers(), public.group_offers_near(uuid),
  public.join_group_offer(uuid, integer) to authenticated;
