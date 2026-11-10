-- 0056 — Marchandage dans la limite de la vendeuse (spec 050, VISION §3 « Différence »).
-- La vendeuse fixe une remise maximale pour sa boutique (et, si elle veut, par produit : autre
-- limite ou jamais). La cliente propose un prix unitaire pour une quantité : au-dessus du plancher,
-- c'est conclu ; en dessous, la vendeuse (la base) propose un contre-prix. Le prix conclu vaut
-- 2 heures, pour cette cliente, cette variante et au plus cette quantité : le panier, le devis et la
-- commande le lisent par app.cart_line_price ; la commande le consomme. La limite n'est jamais
-- montrée à la cliente. 3 propositions par produit et par jour.

alter table public.stores add column haggle_max_percent smallint
  check (haggle_max_percent is null or haggle_max_percent between 1 and 50);
-- Produit : nul = limite de la boutique ; 0 = jamais de marchandage.
alter table public.products add column haggle_max_percent smallint
  check (haggle_max_percent is null or haggle_max_percent between 0 and 50);

create table public.haggles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  quantity smallint not null check (quantity between 1 and 99),
  currency_code char(3) not null references public.currencies (code),
  list_price_minor bigint not null check (list_price_minor > 0),
  offer_minor bigint not null check (offer_minor > 0),
  -- Prix conclu (accepted, used) ou contre-prix proposé (countered).
  price_minor bigint not null check (price_minor > 0 and price_minor <= list_price_minor),
  status text not null check (status in ('accepted', 'countered', 'used')),
  expires_at timestamptz not null,
  order_id uuid references public.orders (id) on delete set null,
  created_at timestamptz not null default clock_timestamp()
);
create index haggles_user_variant on public.haggles (user_id, variant_id) where status = 'accepted';
create index haggles_store on public.haggles (store_id, created_at desc);
alter table public.haggles enable row level security;
revoke all on public.haggles from authenticated, anonymous;

-- Remise maximale applicable (nulle : pas de marchandage).
create or replace function app.haggle_percent(p_product uuid) returns smallint
language sql stable security definer set search_path = ''
as $$
  select nullif(coalesce(p.haggle_max_percent, s.haggle_max_percent), 0)
  from public.products p join public.stores s on s.id = p.store_id
  where p.id = p_product
$$;

-- Prix d'une ligne de panier : le prix conclu en cours (quantité au plus celle du marché),
-- sinon le prix du jour.
create or replace function app.cart_line_price(p_cart uuid, p_variant uuid, p_quantity integer) returns bigint
language sql stable security definer set search_path = ''
as $$
  select coalesce((
    select min(h.price_minor) from public.haggles h join public.carts c on c.user_id = h.user_id
    where c.id = p_cart and h.variant_id = p_variant and h.status = 'accepted' and h.expires_at > now()
      and p_quantity <= h.quantity and h.price_minor < app.variant_price(p_variant)),
    app.variant_price(p_variant))
$$;

create or replace function app.haggle_json(p_id uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', h.id, 'product_name', p.name, 'variant_id', h.variant_id, 'quantity', h.quantity,
    'currency_code', h.currency_code, 'list_price_minor', h.list_price_minor, 'offer_minor', h.offer_minor,
    'price_minor', h.price_minor, 'expires_at', h.expires_at, 'created_at', h.created_at,
    'status', case when h.status in ('accepted', 'countered') and h.expires_at <= now() then 'expired'
                   else h.status end,
    'attempts_left', greatest(0, 3 - (select count(*) from public.haggles x
      where x.user_id = h.user_id and x.product_id = h.product_id and x.created_at > now() - interval '24 hours')))
  from public.haggles h join public.products p on p.id = h.product_id
  where h.id = p_id
$$;

-- Prix conclu : la ligne du panier passe à la quantité du marché.
create or replace function app.haggle_to_cart(p_id uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_h public.haggles;
begin
  select * into v_h from public.haggles where id = p_id;
  if exists (select 1 from public.cart_items ci join public.carts c on c.id = ci.cart_id
             where c.user_id = v_h.user_id and ci.variant_id = v_h.variant_id) then
    perform public.cart_set_quantity(v_h.variant_id, v_h.quantity);
  else
    perform public.cart_add(v_h.variant_id, v_h.quantity);
  end if;
end
$fn$;

-- Cliente : propose un prix unitaire pour une quantité.
create or replace function public.propose_haggle(p_variant uuid, p_quantity integer, p_offer_minor bigint)
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_product public.products;
  v_store public.stores;
  v_percent smallint;
  v_list bigint;
  v_floor bigint;
  v_id uuid;
  v_status text;
  v_price bigint;
begin
  select p.* into v_product from public.products p join public.product_variants v on v.product_id = p.id
  where v.id = p_variant and p.status = 'published';
  select * into v_store from public.stores where id = v_product.store_id and status = 'active';
  if v_store.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_store.owner_id = v_user then raise exception 'own_store' using errcode = 'P0001'; end if;
  v_percent := app.haggle_percent(v_product.id);
  if v_percent is null then raise exception 'haggle_off' using errcode = 'P0001'; end if;
  if p_quantity is null or p_quantity not between 1 and 99 then
    raise exception 'invalid_quantity' using errcode = '22023';
  end if;
  if (select count(*) from public.haggles where user_id = v_user and product_id = v_product.id
      and created_at > now() - interval '24 hours') >= 3 then
    raise exception 'too_many_attempts' using errcode = 'P0001';
  end if;
  v_list := app.variant_price(p_variant);
  if p_offer_minor is null or p_offer_minor <= 0 then raise exception 'invalid_amount' using errcode = '22023'; end if;
  if p_offer_minor >= v_list then raise exception 'offer_not_lower' using errcode = 'P0001'; end if;
  v_floor := ceil(v_list * (100 - v_percent) / 100.0)::bigint;
  if p_offer_minor >= v_floor then
    v_status := 'accepted';
    v_price := p_offer_minor;
  else
    -- Contre-prix : le milieu entre l'offre et le prix, jamais sous le plancher.
    v_status := 'countered';
    v_price := least(v_list, greatest(v_floor, ceil((p_offer_minor + v_list) / 2.0)::bigint));
  end if;
  insert into public.haggles (user_id, store_id, product_id, variant_id, quantity, currency_code,
    list_price_minor, offer_minor, price_minor, status, expires_at)
  values (v_user, v_store.id, v_product.id, p_variant, p_quantity, v_store.currency_code, v_list, p_offer_minor,
    v_price, v_status, now() + case when v_status = 'accepted' then interval '2 hours' else interval '15 minutes' end)
  returning id into v_id;
  perform app.emit_event('haggle_proposed', v_user, 'client', 'server', v_store.country_code, 'store', v_store.id::text,
    jsonb_build_object('outcome', v_status, 'discount_bps', ((v_list - p_offer_minor) * 10000 / v_list)::int));
  if v_status = 'accepted' then
    perform app.haggle_to_cart(v_id);
    perform app.emit_event('haggle_accepted', v_user, 'client', 'server', v_store.country_code, 'store',
      v_store.id::text, jsonb_build_object('from', 'offer', 'discount_bps', ((v_list - v_price) * 10000 / v_list)::int));
  end if;
  return app.haggle_json(v_id);
end
$fn$;

-- Cliente : accepte le contre-prix tant qu'il vaut.
create or replace function public.accept_haggle(p_id uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_h public.haggles;
begin
  select * into v_h from public.haggles where id = p_id and user_id = v_user for update;
  if v_h.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_h.status <> 'countered' or v_h.expires_at <= now() then
    raise exception 'haggle_expired' using errcode = 'P0001';
  end if;
  update public.haggles set status = 'accepted', expires_at = now() + interval '2 hours' where id = p_id;
  perform app.haggle_to_cart(p_id);
  perform app.emit_event('haggle_accepted', v_user, 'client', 'server',
    (select country_code from public.stores where id = v_h.store_id), 'store', v_h.store_id::text,
    jsonb_build_object('from', 'counter',
      'discount_bps', ((v_h.list_price_minor - v_h.price_minor) * 10000 / v_h.list_price_minor)::int));
  return app.haggle_json(p_id);
end
$fn$;

-- La commande consomme le prix conclu de la ligne.
create or replace function app.haggle_used() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
begin
  update public.haggles h set status = 'used', order_id = new.order_id
  where h.status = 'accepted' and h.expires_at > now() and h.variant_id = new.variant_id
    and h.price_minor = new.unit_price_minor
    and h.user_id = (select pu.user_id from public.orders o join public.purchases pu on pu.id = o.purchase_id
                     where o.id = new.order_id);
  return new;
end
$fn$;
create trigger order_items_haggle after insert on public.order_items
for each row execute function app.haggle_used();

-- Vendeuse : limite de la boutique (p_product nul ; nulle = pas de marchandage) ou d'un produit
-- (nulle = celle de la boutique, 0 = jamais).
create or replace function public.set_haggle_limit(p_percent integer, p_product uuid default null) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store public.stores;
begin
  select * into v_store from public.stores where id = app.own_store_id();
  if p_product is null then
    if p_percent is not null and p_percent not between 1 and 50 then
      raise exception 'invalid_percent' using errcode = '22023';
    end if;
    update public.stores set haggle_max_percent = p_percent where id = v_store.id;
  else
    if p_percent is not null and p_percent not between 0 and 50 then
      raise exception 'invalid_percent' using errcode = '22023';
    end if;
    update public.products set haggle_max_percent = p_percent where id = p_product and store_id = v_store.id;
    if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  end if;
  perform app.emit_event('haggle_limit_set', app.current_user_id(), 'vendor', 'server', v_store.country_code,
    'store', v_store.id::text, jsonb_build_object('percent', p_percent, 'scope',
      case when p_product is null then 'store' else 'product' end));
  return public.my_haggling();
end
$fn$;

-- Vendeuse : limites, derniers marchandages (sans la cliente), marchés conclus de la semaine.
create or replace function public.my_haggling() returns jsonb
language sql stable security definer set search_path = ''
as $$
  with me as (select * from public.stores where id = app.own_store_id())
  select jsonb_build_object(
    'store_percent', (select haggle_max_percent from me),
    'products', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name,
        'percent', p.haggle_max_percent) order by p.name)
      from public.products p where p.store_id = (select id from me) and p.status = 'published'), '[]'::jsonb),
    'recent', coalesce((select jsonb_agg(app.haggle_json(r.id) order by r.created_at desc)
      from (select h.id, h.created_at from public.haggles h where h.store_id = (select id from me)
            order by h.created_at desc limit 30) r), '[]'::jsonb),
    'concluded_week', (select count(*) from public.haggles h where h.store_id = (select id from me)
      and h.status in ('accepted', 'used') and h.created_at > now() - interval '7 days'))
$$;

insert into public.event_names (name, emitted_by, description) values
  ('haggle_proposed', 'server', 'Prix proposé par une cliente (issue, remise demandée en points de base)'),
  ('haggle_accepted', 'server', 'Marché conclu (offre ou contre-prix, remise en points de base)'),
  ('haggle_limit_set', 'server', 'Limite de marchandage fixée (pourcentage, boutique ou produit)')
on conflict do nothing;

-- Copies (0011, 0054) : le prix d'une ligne passe par app.cart_line_price ; la fiche dit si le
-- marchandage est possible.
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
    select s.id, s.name, s.origin, z.name as zone_name, s.offers_pickup, s.delivery_fee_minor as own_fee,
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

create or replace function public.cart_add(p_variant uuid, p_quantity int default 1) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_store public.stores;
  v_variant public.product_variants;
  v_cart public.carts;
  v_existing int;
  v_quantity int;
begin
  if p_quantity is null or p_quantity not between 1 and 99 then
    raise exception 'quantité entre 1 et 99' using errcode = '22023';
  end if;
  select v.* into v_variant from public.product_variants v where v.id = p_variant;
  select s.* into v_store
  from public.products p join public.stores s on s.id = p.store_id
  where p.id = v_variant.product_id and p.status = 'published' and s.status = 'active';
  if v_store.id is null then
    raise exception 'produit introuvable' using errcode = 'P0002';
  end if;
  if not app.product_available(v_variant.product_id) or v_variant.stock_quantity = 0 then
    raise exception 'unavailable' using errcode = '22023';
  end if;

  select * into v_cart from public.carts where user_id = v_user for update;
  if v_cart.id is null then
    insert into public.carts (user_id, country_code, currency_code)
    values (v_user, v_store.country_code, v_store.currency_code)
    returning * into v_cart;
  elsif v_cart.country_code <> v_store.country_code then
    if exists (select 1 from public.cart_items where cart_id = v_cart.id) then
      raise exception 'other_country' using errcode = '22023';
    end if;
    update public.carts set country_code = v_store.country_code, currency_code = v_store.currency_code
    where id = v_cart.id returning * into v_cart;
  end if;

  v_existing := coalesce((select quantity from public.cart_items
                          where cart_id = v_cart.id and variant_id = p_variant), 0);
  v_quantity := least(v_existing + p_quantity, 99, coalesce(v_variant.stock_quantity, 99));
  insert into public.cart_items (cart_id, variant_id, quantity, unit_price_seen_minor)
  values (v_cart.id, p_variant, v_quantity, app.cart_line_price(v_cart.id, p_variant, v_quantity))
  on conflict (cart_id, variant_id) do update
    set quantity = excluded.quantity, unit_price_seen_minor = excluded.unit_price_seen_minor,
        updated_at = now();
  update public.carts set updated_at = now() where id = v_cart.id;
  return public.my_cart();
end
$$;

create or replace function public.cart_set_quantity(p_variant uuid, p_quantity int) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_cart uuid := (select id from public.carts where user_id = v_user);
  v_stock int := (select stock_quantity from public.product_variants where id = p_variant);
begin
  if p_quantity is null or p_quantity not between 0 and 99 then
    raise exception 'quantité entre 0 et 99' using errcode = '22023';
  end if;
  if not exists (select 1 from public.cart_items where cart_id = v_cart and variant_id = p_variant) then
    raise exception 'ligne introuvable' using errcode = 'P0002';
  end if;
  if p_quantity = 0 then
    delete from public.cart_items where cart_id = v_cart and variant_id = p_variant;
  else
    update public.cart_items
    set quantity = greatest(least(p_quantity, coalesce(nullif(v_stock, 0), 99)), 1),
        unit_price_seen_minor = app.cart_line_price(
          v_cart, p_variant, greatest(least(p_quantity, coalesce(nullif(v_stock, 0), 99)), 1)),
        updated_at = now()
    where cart_id = v_cart and variant_id = p_variant;
  end if;
  update public.carts set updated_at = now() where id = v_cart;
  return public.my_cart();
end
$$;

create or replace function public.product_page(
  p_product uuid,
  p_zone uuid default null,
  p_at timestamptz default now()
) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select app.catalog_item(p.id) || jsonb_build_object(
    'description', p.description,
    'photo_keys', coalesce((select jsonb_agg(f.object_key order by f.sort)
                            from public.product_photos f where f.product_id = p.id), '[]'::jsonb),
    'variants', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', v.id, 'label', v.label,
        'price_minor', app.eom_price(coalesce(v.price_minor, p.price_minor), p.id),
        'available', p.is_available and (v.stock_quantity is null or v.stock_quantity > 0))
        order by v.sort, v.created_at)
      from public.product_variants v where v.product_id = p.id), '[]'::jsonb),
    'store', app.store_summary(p.store_id, p_at),
    'zone_name', (select z.name from public.zones z where z.id = p_zone),
    'serves_zone', app.store_serves(p.store_id, p_zone),
    -- Marchandage (spec 050) : possible ou non, jamais la limite de la vendeuse.
    'can_haggle', app.haggle_percent(p.id) is not null
  )
  from public.products p
  join public.stores s on s.id = p.store_id
  where p.id = p_product and p.status = 'published' and s.status = 'active'
$$;

revoke all on function app.haggle_percent(uuid), app.cart_line_price(uuid, uuid, integer), app.haggle_json(uuid),
  app.haggle_to_cart(uuid), app.haggle_used(), public.propose_haggle(uuid, integer, bigint),
  public.accept_haggle(uuid), public.set_haggle_limit(integer, uuid), public.my_haggling() from public;
grant execute on function public.propose_haggle(uuid, integer, bigint), public.accept_haggle(uuid),
  public.set_haggle_limit(integer, uuid), public.my_haggling() to authenticated;
