-- 0011 — Panier multi-boutiques, adresses et commande (spec 009 : C-CART-01..09,
-- C-CHECK-01..05, C-ADDR-01..03, C-PROF-02).
-- Prix, frais, totaux, commission et refus sont calculés ici, par une seule
-- fonction (app.cart_quote) qui sert à la fois l'affichage et la commande.
-- Aucune table n'est écrite directement par les apps.

-- ------------------------------------------------------------------ adresses

create table public.customer_addresses (
  id uuid primary key,
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  kind text not null check (kind in ('home', 'work', 'other')),
  label text check (label is null or length(trim(label)) between 1 and 40),
  zone_id uuid not null references public.zones (id),
  landmark text not null check (length(trim(landmark)) between 3 and 200),
  phone text not null check (phone ~ '^\+?[0-9 ]{8,20}$'),
  latitude numeric(9, 6) check (latitude between -90 and 90),
  longitude numeric(9, 6) check (longitude between -180 and 180),
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((latitude is null) = (longitude is null))
);

create unique index customer_addresses_one_default
  on public.customer_addresses (user_id) where is_default;
create index customer_addresses_user on public.customer_addresses (user_id);

create trigger customer_addresses_updated_at before update on public.customer_addresses
  for each row execute function app.set_updated_at();

-- ------------------------------------------------------------------ panier

-- Un panier par cliente ; son pays et sa devise sont ceux de ses articles.
create table public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references neon_auth."user" (id) on delete cascade,
  country_code char(2) not null references public.countries (code),
  currency_code char(3) not null references public.currencies (code),
  updated_at timestamptz not null default now()
);

create table public.cart_items (
  cart_id uuid not null references public.carts (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  quantity smallint not null check (quantity between 1 and 99),
  -- Prix vu à l'ajout ou à la dernière modification : signale un prix modifié.
  unit_price_seen_minor bigint not null check (unit_price_seen_minor > 0),
  added_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default now(),
  primary key (cart_id, variant_id)
);

-- ------------------------------------------------------------------ commandes

create table public.purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  idempotency_key uuid not null,
  country_code char(2) not null references public.countries (code),
  currency_code char(3) not null references public.currencies (code),
  payment_method_id uuid not null references public.payment_methods (id),
  address jsonb check (address is null or jsonb_typeof(address) = 'object'),
  substitution_allowed boolean not null default true,
  subtotal_minor bigint not null check (subtotal_minor >= 0),
  delivery_fee_minor bigint not null check (delivery_fee_minor >= 0),
  total_minor bigint not null check (total_minor = subtotal_minor + delivery_fee_minor),
  created_at timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references public.purchases (id) on delete cascade,
  store_id uuid not null references public.stores (id),
  fulfillment text not null check (fulfillment in ('delivery', 'pickup')),
  -- Les autres statuts et leurs transitions arrivent avec order-lifecycle.
  status text not null default 'pending' check (status in ('pending')),
  currency_code char(3) not null references public.currencies (code),
  subtotal_minor bigint not null check (subtotal_minor >= 0),
  delivery_fee_minor bigint not null check (delivery_fee_minor >= 0),
  total_minor bigint not null check (total_minor = subtotal_minor + delivery_fee_minor),
  commission_minor bigint not null check (commission_minor >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (purchase_id, store_id),
  check (fulfillment = 'delivery' or delivery_fee_minor = 0)
);

create index orders_store on public.orders (store_id, created_at desc);

create trigger orders_updated_at before update on public.orders
  for each row execute function app.set_updated_at();

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid not null references public.products (id),
  variant_id uuid not null references public.product_variants (id),
  product_name text not null,
  variant_label text,
  unit_label jsonb,
  unit_price_minor bigint not null check (unit_price_minor > 0),
  quantity smallint not null check (quantity between 1 and 99),
  amount_minor bigint not null check (amount_minor = unit_price_minor * quantity)
);

create index order_items_order on public.order_items (order_id);

-- ------------------------------------------------------------------ accès

alter table public.customer_addresses enable row level security;
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
alter table public.purchases enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- Commande visible par sa cliente et par la propriétaire de sa boutique.
create or replace function app.can_read_order(p_order uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.orders o
    join public.purchases pu on pu.id = o.purchase_id
    join public.stores s on s.id = o.store_id
    where o.id = p_order
      and app.current_user_id() in (pu.user_id, s.owner_id)
  )
$$;
grant execute on function app.can_read_order(uuid) to authenticated;

create policy customer_addresses_owner_read on public.customer_addresses for select
  to authenticated using (user_id = app.current_user_id());
create policy purchases_owner_read on public.purchases for select
  to authenticated using (user_id = app.current_user_id());
create policy orders_party_read on public.orders for select
  to authenticated using (app.can_read_order(id));
create policy order_items_party_read on public.order_items for select
  to authenticated using (app.can_read_order(order_id));

grant select on public.customer_addresses, public.purchases, public.order_items to authenticated;
-- La commission est interne : jamais servie par l'API.
grant select (
  id, purchase_id, store_id, fulfillment, status, currency_code,
  subtotal_minor, delivery_fee_minor, total_minor, created_at, updated_at
) on public.orders to authenticated;

-- Élément de liste : variante par défaut (ajout direct au panier quand le
-- produit n'a qu'une variante).
create or replace function app.catalog_item(p_product uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', p.id, 'name', p.name, 'category_id', p.category_id,
    'price_minor', p.price_minor, 'min_price_minor', app.product_min_price(p.id),
    'currency_code', p.currency_code,
    'unit_label', u.label,
    'photo_key', (select f.object_key from public.product_photos f where f.product_id = p.id order by f.sort limit 1),
    'variant_count', (select count(*) from public.product_variants v where v.product_id = p.id),
    'default_variant_id', (select v.id from public.product_variants v where v.product_id = p.id
                           order by v.sort, v.created_at limit 1),
    'available', app.product_available(p.id),
    'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin, 'zone_name', z.name),
    'store_category_ids', coalesce((
      select jsonb_agg(pc.store_category_id) from public.product_store_categories pc
      join public.store_categories sc on sc.id = pc.store_category_id and not sc.is_archived
      where pc.product_id = p.id), '[]'::jsonb)
  )
  from public.products p
  join public.stores s on s.id = p.store_id
  join public.zones z on z.id = s.zone_id
  left join public.units u on u.id = p.unit_id
  where p.id = p_product and p.status = 'published' and s.status = 'active'
$$;

-- ------------------------------------------------------------------ calculs

-- Prix courant d'une variante (le sien, sinon celui du produit).
create or replace function app.variant_price(p_variant uuid) returns bigint
language sql stable security definer set search_path = ''
as $$
  select coalesce(v.price_minor, p.price_minor)
  from public.product_variants v join public.products p on p.id = v.product_id
  where v.id = p_variant
$$;

-- Taux de commission d'un rayon (le sien, celui de son parent, sinon celui du pays).
create or replace function app.commission_rate(p_country char(2), p_category uuid) returns integer
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    (select r.rate_bps from public.commission_rules r
     where r.country_code = p_country and r.valid_to is null and r.category_id = p_category),
    (select r.rate_bps from public.commission_rules r
     join public.categories c on c.parent_id = r.category_id
     where r.country_code = p_country and r.valid_to is null and c.id = p_category),
    (select r.rate_bps from public.commission_rules r
     where r.country_code = p_country and r.valid_to is null and r.category_id is null),
    0)
$$;

-- Devis du panier : lignes, problèmes, frais, totaux, moyens de paiement.
-- [p_zone] : quartier de livraison (null : pas encore d'adresse) ;
-- [p_modes] : {store_id: "delivery" | "pickup"} (livraison par défaut).
-- Frais (maquette 05) : la boutique livrée au plus gros sous-total porte la
-- base (ou ses propres frais), chaque autre boutique livrée un supplément ;
-- tout est offert quand le sous-total livré atteint le seuil.
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
           app.variant_price(v.id) as unit_price, ci.unit_price_seen_minor,
           p.store_id,
           array_remove(array[
             case when p.status <> 'published' or not p.is_available
                    or v.stock_quantity = 0 then 'unavailable' end,
             case when v.stock_quantity > 0 and ci.quantity > v.stock_quantity then 'stock' end,
             case when app.variant_price(v.id) <> ci.unit_price_seen_minor then 'price_changed' end
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
             'quantity', l.quantity, 'unit_price_minor', l.unit_price,
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

-- Panier vide (pays du profil, s'il est connu).
create or replace function app.empty_cart(p_country char(2)) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'country_code', p_country,
    'currency_code', (select c.currency_code from public.countries c where c.code = p_country),
    'currency', (select to_jsonb(cu) - 'created_at' - 'updated_at' from public.currencies cu
                 join public.countries c on c.currency_code = cu.code where c.code = p_country),
    'stores', '[]'::jsonb, 'payment_methods', '[]'::jsonb, 'payment_method_id', null,
    'item_count', 0, 'pickup_count', 0, 'delivery_minutes', 0,
    'subtotal_minor', 0, 'delivery_fee_minor', 0, 'total_minor', 0,
    'free_threshold_minor', null, 'remaining_for_free_minor', null, 'blocking', false)
$$;

-- Session obligatoire.
create or replace function app.require_user() returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
begin
  if v_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  return v_user;
end
$$;

-- Adresse de la cliente dans un pays : [p_address], sinon celle par défaut.
create or replace function app.delivery_address(p_user uuid, p_address uuid, p_country char(2))
returns public.customer_addresses
language sql stable security definer set search_path = ''
as $$
  select a.* from public.customer_addresses a
  join public.zones z on z.id = a.zone_id
  join public.cities c on c.id = z.city_id
  where a.user_id = p_user and c.country_code = p_country
    and (a.id = p_address or (p_address is null and a.is_default))
  limit 1
$$;

-- ------------------------------------------------------------------ panier (Data API)

create or replace function public.my_cart(
  p_address uuid default null,
  p_modes jsonb default '{}'::jsonb,
  p_payment_method uuid default null,
  p_at timestamptz default now()
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_cart public.carts;
  v_address public.customer_addresses;
  v_zone uuid;
  v_country char(2);
begin
  select * into v_cart from public.carts where user_id = v_user;
  if v_cart.id is null or not exists (select 1 from public.cart_items where cart_id = v_cart.id) then
    v_country := coalesce(v_cart.country_code, (select country_code from public.profiles where user_id = v_user));
    return app.empty_cart(v_country);
  end if;
  v_address := app.delivery_address(v_user, p_address, v_cart.country_code);
  v_zone := coalesce(v_address.zone_id,
    (select p.zone_id from public.profiles p
     join public.zones z on z.id = p.zone_id join public.cities c on c.id = z.city_id
     where p.user_id = v_user and c.country_code = v_cart.country_code));
  return app.cart_quote(v_cart.id, v_zone, coalesce(p_modes, '{}'::jsonb), p_payment_method, p_at)
    || jsonb_build_object('address_id', v_address.id, 'zone_id', v_zone);
end
$$;

-- Ajoute une variante (la quantité s'additionne ; 99 et le stock suivi au plus).
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
  values (v_cart.id, p_variant, v_quantity, app.variant_price(p_variant))
  on conflict (cart_id, variant_id) do update
    set quantity = excluded.quantity, unit_price_seen_minor = excluded.unit_price_seen_minor,
        updated_at = now();
  update public.carts set updated_at = now() where id = v_cart.id;
  return public.my_cart();
end
$$;

-- Fixe la quantité d'une ligne (0 : la retire). Le prix vu est remis à jour.
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
        unit_price_seen_minor = app.variant_price(p_variant), updated_at = now()
    where cart_id = v_cart and variant_id = p_variant;
  end if;
  update public.carts set updated_at = now() where id = v_cart;
  return public.my_cart();
end
$$;

-- ------------------------------------------------------------------ adresses (Data API)

create or replace function public.my_addresses() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', a.id, 'kind', a.kind, 'label', a.label, 'zone_id', a.zone_id,
    'zone_name', z.name, 'city_name', c.name, 'country_code', c.country_code,
    'landmark', a.landmark, 'phone', a.phone,
    'latitude', a.latitude, 'longitude', a.longitude, 'is_default', a.is_default)
    order by a.is_default desc, a.created_at desc), '[]'::jsonb)
  from public.customer_addresses a
  join public.zones z on z.id = a.zone_id
  join public.cities c on c.id = z.city_id
  where a.user_id = app.require_user()
$$;

-- Crée ou modifie une adresse (identifiant fourni par l'app : rejouable).
create or replace function public.save_address(p_address jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_id uuid := (p_address ->> 'id')::uuid;
  v_zone uuid := (p_address ->> 'zone_id')::uuid;
  v_owner uuid;
  v_default boolean;
begin
  if v_id is null then
    raise exception 'identifiant obligatoire' using errcode = '22023';
  end if;
  select user_id into v_owner from public.customer_addresses where id = v_id;
  if v_owner is not null and v_owner <> v_user then
    raise exception 'adresse d''une autre personne' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.zones z where z.id = v_zone and z.is_active and app.city_is_visible(z.city_id)
  ) then
    raise exception 'quartier inactif' using errcode = '22023';
  end if;
  if v_owner is null and (select count(*) from public.customer_addresses where user_id = v_user) >= 20 then
    raise exception '20 adresses au plus' using errcode = '22023';
  end if;
  v_default := coalesce((p_address ->> 'is_default')::boolean, false)
    or not exists (select 1 from public.customer_addresses where user_id = v_user and id <> v_id);
  if v_default then
    update public.customer_addresses set is_default = false
    where user_id = v_user and is_default and id <> v_id;
  end if;

  insert into public.customer_addresses (
    id, user_id, kind, label, zone_id, landmark, phone, latitude, longitude, is_default)
  values (
    v_id, v_user, p_address ->> 'kind', nullif(trim(p_address ->> 'label'), ''), v_zone,
    trim(p_address ->> 'landmark'), trim(p_address ->> 'phone'),
    (p_address ->> 'latitude')::numeric, (p_address ->> 'longitude')::numeric, v_default)
  on conflict (id) do update set
    kind = excluded.kind, label = excluded.label, zone_id = excluded.zone_id,
    landmark = excluded.landmark, phone = excluded.phone,
    latitude = excluded.latitude, longitude = excluded.longitude,
    is_default = excluded.is_default or public.customer_addresses.is_default;
  return public.my_addresses();
end
$$;

-- Supprime une adresse ; si c'était l'adresse par défaut, la plus récente la remplace.
create or replace function public.delete_address(p_id uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_was_default boolean;
begin
  delete from public.customer_addresses where id = p_id and user_id = v_user
  returning is_default into v_was_default;
  if not found then
    raise exception 'adresse introuvable' using errcode = 'P0002';
  end if;
  if v_was_default then
    update public.customer_addresses set is_default = true
    where id = (select id from public.customer_addresses where user_id = v_user
                order by created_at desc, id limit 1);
  end if;
  return public.my_addresses();
end
$$;

create or replace function public.set_default_address(p_id uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  if not exists (select 1 from public.customer_addresses where id = p_id and user_id = v_user) then
    raise exception 'adresse introuvable' using errcode = 'P0002';
  end if;
  update public.customer_addresses set is_default = false where user_id = v_user and is_default;
  update public.customer_addresses set is_default = true where id = p_id;
  return public.my_addresses();
end
$$;

-- ------------------------------------------------------------------ commande

-- Achat et ses commandes (sans commission).
create or replace function app.purchase_json(p_purchase uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', pu.id, 'created_at', pu.created_at,
    'country_code', pu.country_code, 'currency_code', pu.currency_code,
    'payment_method', jsonb_build_object('id', pm.id, 'country_code', pm.country_code,
                                         'provider_code', pm.provider_code,
                                         'operator_code', pm.operator_code, 'label', pm.label),
    'address', pu.address, 'substitution_allowed', pu.substitution_allowed,
    'subtotal_minor', pu.subtotal_minor, 'delivery_fee_minor', pu.delivery_fee_minor,
    'total_minor', pu.total_minor,
    'orders', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', o.id, 'status', o.status, 'fulfillment', o.fulfillment,
        'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin),
        'subtotal_minor', o.subtotal_minor, 'delivery_fee_minor', o.delivery_fee_minor,
        'total_minor', o.total_minor,
        'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
        'items', (select coalesce(jsonb_agg(jsonb_build_object(
                    'product_id', i.product_id, 'variant_id', i.variant_id, 'name', i.product_name,
                    'variant_label', i.variant_label, 'unit_label', i.unit_label,
                    'unit_price_minor', i.unit_price_minor, 'quantity', i.quantity,
                    'amount_minor', i.amount_minor) order by i.product_name), '[]'::jsonb)
                  from public.order_items i where i.order_id = o.id))
        order by o.total_minor desc, o.id), '[]'::jsonb)
      from public.orders o join public.stores s on s.id = o.store_id
      where o.purchase_id = pu.id))
  from public.purchases pu
  join public.payment_methods pm on pm.id = pu.payment_method_id
  where pu.id = p_purchase
$$;

create or replace function public.my_purchase(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.purchases where id = p_id and user_id = app.require_user()) then
    raise exception 'achat introuvable' using errcode = 'P0002';
  end if;
  return app.purchase_json(p_id);
end
$$;

-- Crée l'achat et une commande par boutique, à partir du panier lu ici.
-- Appelée par la Function POST /v1/orders seulement (utilisateur explicite).
-- [p_request] : address_id, modes, payment_method_id, substitution_allowed,
-- expected_total_minor. Refus (P0001, message = code) : cart_empty,
-- address_required, cart_blocked, payment_not_accepted, payment_unavailable,
-- total_changed. Une clé déjà vue rend le même achat ({replayed: true}).
create or replace function app.place_order(
  p_user uuid,
  p_key uuid,
  p_request jsonb,
  p_at timestamptz default now()
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_existing uuid;
  v_cart public.carts;
  v_address public.customer_addresses;
  v_zone uuid;
  v_method public.payment_methods;
  v_quote jsonb;
  v_purchase uuid;
  v_order uuid;
  v_store jsonb;
  v_line jsonb;
  v_commission bigint;
  v_expected bigint := (p_request ->> 'expected_total_minor')::bigint;
begin
  if p_user is null or p_key is null then
    raise exception 'utilisateur et clé obligatoires' using errcode = '22023';
  end if;
  select id into v_existing from public.purchases where user_id = p_user and idempotency_key = p_key;
  if v_existing is not null then
    return jsonb_build_object('replayed', true, 'purchase', app.purchase_json(v_existing));
  end if;

  select * into v_cart from public.carts where user_id = p_user for update;
  -- Une demande concurrente avec la même clé a pu finir pendant l'attente.
  select id into v_existing from public.purchases where user_id = p_user and idempotency_key = p_key;
  if v_existing is not null then
    return jsonb_build_object('replayed', true, 'purchase', app.purchase_json(v_existing));
  end if;
  if v_cart.id is null or not exists (select 1 from public.cart_items where cart_id = v_cart.id) then
    raise exception 'cart_empty' using errcode = 'P0001';
  end if;
  -- Stocks verrouillés avant le devis : il reste vrai jusqu'à la fin.
  perform 1 from public.product_variants v
  join public.cart_items ci on ci.variant_id = v.id
  where ci.cart_id = v_cart.id
  for update of v;

  if p_request ->> 'address_id' is not null then
    v_address := app.delivery_address(p_user, (p_request ->> 'address_id')::uuid, v_cart.country_code);
  end if;
  v_zone := v_address.zone_id;
  select * into v_method from public.payment_methods where id = (p_request ->> 'payment_method_id')::uuid;
  v_quote := app.cart_quote(v_cart.id, v_zone, coalesce(p_request -> 'modes', '{}'::jsonb), v_method.id, p_at);

  if v_address.id is null and exists (
    select 1 from jsonb_array_elements(v_quote -> 'stores') s where s ->> 'fulfillment' = 'delivery'
  ) then
    raise exception 'address_required' using errcode = 'P0001';
  end if;
  if v_method.id is null or not exists (
    select 1 from jsonb_array_elements(v_quote -> 'payment_methods') m where (m ->> 'id')::uuid = v_method.id
  ) then
    raise exception 'payment_not_accepted' using errcode = 'P0001';
  end if;
  if (v_quote ->> 'blocking')::boolean then
    raise exception 'cart_blocked' using errcode = 'P0001';
  end if;
  -- Seul le paiement à la livraison est construit (MoMo : spec payments).
  if v_method.provider_code <> 'cash' then
    raise exception 'payment_unavailable' using errcode = 'P0001';
  end if;
  if v_expected is not null and v_expected <> (v_quote ->> 'total_minor')::bigint then
    raise exception 'total_changed' using errcode = 'P0001';
  end if;

  insert into public.purchases (
    user_id, idempotency_key, country_code, currency_code, payment_method_id, address,
    substitution_allowed, subtotal_minor, delivery_fee_minor, total_minor)
  values (
    p_user, p_key, v_cart.country_code, v_cart.currency_code, v_method.id,
    case when v_address.id is null then null else (
      select jsonb_build_object(
        'id', v_address.id, 'kind', v_address.kind, 'label', v_address.label,
        'zone_id', z.id, 'zone_name', z.name, 'city_name', c.name,
        'landmark', v_address.landmark, 'phone', v_address.phone,
        'latitude', v_address.latitude, 'longitude', v_address.longitude)
      from public.zones z join public.cities c on c.id = z.city_id where z.id = v_address.zone_id)
    end,
    coalesce((p_request ->> 'substitution_allowed')::boolean, true),
    (v_quote ->> 'subtotal_minor')::bigint, (v_quote ->> 'delivery_fee_minor')::bigint,
    (v_quote ->> 'total_minor')::bigint)
  returning id into v_purchase;

  for v_store in select * from jsonb_array_elements(v_quote -> 'stores') loop
    select coalesce(sum(floor((l ->> 'amount_minor')::bigint
             * app.commission_rate(v_cart.country_code, (l ->> 'category_id')::uuid) / 10000.0)), 0)
    into v_commission
    from jsonb_array_elements(v_store -> 'lines') l;

    insert into public.orders (
      purchase_id, store_id, fulfillment, currency_code,
      subtotal_minor, delivery_fee_minor, total_minor, commission_minor)
    values (
      v_purchase, (v_store ->> 'id')::uuid, v_store ->> 'fulfillment', v_cart.currency_code,
      (v_store ->> 'subtotal_minor')::bigint, (v_store ->> 'delivery_fee_minor')::bigint,
      (v_store ->> 'subtotal_minor')::bigint + (v_store ->> 'delivery_fee_minor')::bigint,
      v_commission)
    returning id into v_order;

    for v_line in select * from jsonb_array_elements(v_store -> 'lines') loop
      insert into public.order_items (
        order_id, product_id, variant_id, product_name, variant_label, unit_label,
        unit_price_minor, quantity, amount_minor)
      values (
        v_order, (v_line ->> 'product_id')::uuid, (v_line ->> 'variant_id')::uuid,
        v_line ->> 'name', v_line ->> 'variant_label', v_line -> 'unit_label',
        (v_line ->> 'unit_price_minor')::bigint, (v_line ->> 'quantity')::smallint,
        (v_line ->> 'amount_minor')::bigint);
      update public.product_variants
      set stock_quantity = stock_quantity - (v_line ->> 'quantity')::int
      where id = (v_line ->> 'variant_id')::uuid and stock_quantity is not null;
    end loop;
  end loop;

  delete from public.cart_items where cart_id = v_cart.id;
  update public.carts set updated_at = now() where id = v_cart.id;

  perform app.emit_event(
    'order_created', p_user, 'client', 'server', v_cart.country_code, 'purchase', v_purchase::text,
    jsonb_build_object(
      'stores_count', jsonb_array_length(v_quote -> 'stores'),
      'items_count', (v_quote ->> 'item_count')::int,
      'delivery_count', (v_quote ->> 'pickup_count')::int,
      'payment_provider', v_method.provider_code));

  return jsonb_build_object('replayed', false, 'purchase', app.purchase_json(v_purchase));
end
$$;

-- ------------------------------------------------------------------ droits

revoke all on function
  public.my_cart(uuid, jsonb, uuid, timestamptz), public.cart_add(uuid, int),
  public.cart_set_quantity(uuid, int), public.my_addresses(), public.save_address(jsonb),
  public.delete_address(uuid), public.set_default_address(uuid), public.my_purchase(uuid),
  app.place_order(uuid, uuid, jsonb, timestamptz), app.cart_quote(uuid, uuid, jsonb, uuid, timestamptz)
from public;

grant execute on function
  public.my_cart(uuid, jsonb, uuid, timestamptz), public.cart_add(uuid, int),
  public.cart_set_quantity(uuid, int), public.my_addresses(), public.save_address(jsonb),
  public.delete_address(uuid), public.set_default_address(uuid), public.my_purchase(uuid)
to authenticated;
