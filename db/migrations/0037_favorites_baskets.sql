-- 0037 — Carnet, favoris et paniers enregistrés (spec 030).
-- 1. Boutiques et produits favoris : un geste pour ajouter ou retirer ; seuls ceux encore actifs
--    sont affichés (gardés en base s'ils reviennent).
-- 2. Paniers enregistrés sous un nom libre (« Petit-déjeuner ») : articles exacts et quantités ;
--    remis au panier aux règles de `cart_add`, prix du jour calculé par la base.

create table public.favorite_stores (
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  created_at timestamptz not null default clock_timestamp(),
  primary key (user_id, store_id)
);

create table public.favorite_products (
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  created_at timestamptz not null default clock_timestamp(),
  primary key (user_id, product_id)
);

create table public.saved_baskets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 40),
  items jsonb not null check (jsonb_typeof(items) = 'array' and jsonb_array_length(items) between 1 and 50),
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp()
);
create index saved_baskets_user on public.saved_baskets (user_id, created_at);

alter table public.favorite_stores enable row level security;
alter table public.favorite_products enable row level security;
alter table public.saved_baskets enable row level security;
create policy favorite_stores_owner_read on public.favorite_stores for select
  to authenticated using (user_id = app.current_user_id());
create policy favorite_products_owner_read on public.favorite_products for select
  to authenticated using (user_id = app.current_user_id());
create policy saved_baskets_owner_read on public.saved_baskets for select
  to authenticated using (user_id = app.current_user_id());
revoke all on public.favorite_stores, public.favorite_products, public.saved_baskets
  from authenticated, anonymous;
grant select on public.favorite_stores, public.favorite_products, public.saved_baskets to authenticated;

-- ------------------------------------------------------------------ favoris

-- Ajoute ou retire un favori (`store` ou `product`) ; renvoie l'état final.
create or replace function public.toggle_favorite(p_kind text, p_id uuid) returns boolean
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if p_kind = 'store' then
    if not exists (select 1 from public.stores where id = p_id and status = 'active') then
      if exists (select 1 from public.favorite_stores where user_id = v_user and store_id = p_id) then
        delete from public.favorite_stores where user_id = v_user and store_id = p_id;
        return false;
      end if;
      raise exception 'not_found' using errcode = 'P0002';
    end if;
    delete from public.favorite_stores where user_id = v_user and store_id = p_id;
    if found then return false; end if;
    if (select count(*) from public.favorite_stores where user_id = v_user) >= 200 then
      raise exception 'too_many_favorites' using errcode = '22023';
    end if;
    insert into public.favorite_stores (user_id, store_id) values (v_user, p_id);
  elsif p_kind = 'product' then
    if not exists (select 1 from public.products where id = p_id and status = 'published') then
      if exists (select 1 from public.favorite_products where user_id = v_user and product_id = p_id) then
        delete from public.favorite_products where user_id = v_user and product_id = p_id;
        return false;
      end if;
      raise exception 'not_found' using errcode = 'P0002';
    end if;
    delete from public.favorite_products where user_id = v_user and product_id = p_id;
    if found then return false; end if;
    if (select count(*) from public.favorite_products where user_id = v_user) >= 200 then
      raise exception 'too_many_favorites' using errcode = '22023';
    end if;
    insert into public.favorite_products (user_id, product_id) values (v_user, p_id);
  else
    raise exception 'invalid_kind' using errcode = '22023';
  end if;
  perform app.emit_event('favorite_added', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), p_kind, p_id::text,
    jsonb_build_object('kind', p_kind));
  return true;
end
$fn$;

-- Identifiants des favoris (état des cœurs).
create or replace function public.my_favorite_ids() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'store_ids', coalesce((select jsonb_agg(store_id order by created_at desc)
                           from public.favorite_stores where user_id = app.current_user_id()), '[]'::jsonb),
    'product_ids', coalesce((select jsonb_agg(product_id order by created_at desc)
                             from public.favorite_products where user_id = app.current_user_id()), '[]'::jsonb))
$$;

-- Favoris affichables : boutiques actives, produits publiés de boutiques actives (les plus récents
-- d'abord).
create or replace function public.my_favorites(p_at timestamptz default now()) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'stores', coalesce((
      select jsonb_agg(app.store_summary(s.id, p_at) order by f.created_at desc)
      from public.favorite_stores f join public.stores s on s.id = f.store_id
      where f.user_id = app.current_user_id() and s.status = 'active'), '[]'::jsonb),
    'products', coalesce((
      select jsonb_agg(app.catalog_item(p.id) order by f.created_at desc)
      from public.favorite_products f
      join public.products p on p.id = f.product_id
      join public.stores s on s.id = p.store_id
      where f.user_id = app.current_user_id() and p.status = 'published' and s.status = 'active'),
      '[]'::jsonb))
$$;

-- ------------------------------------------------------------------ paniers enregistrés

-- Lignes d'un panier enregistré avec le prix et la disponibilité du jour.
create or replace function app.basket_json(b public.saved_baskets) returns jsonb
language sql stable security definer set search_path = ''
as $$
  with lines as (
    select (i ->> 'variant_id')::uuid as variant_id, (i ->> 'quantity')::int as quantity, ord
    from jsonb_array_elements(b.items) with ordinality as x (i, ord)
  ),
  priced as (
    select l.ord, l.variant_id, l.quantity, p.id as product_id, p.name, v.label as variant_label,
           (select f.object_key from public.product_photos f where f.product_id = p.id
            order by f.sort limit 1) as photo_key,
           s.name as store_name, s.currency_code,
           app.variant_price(v.id) as unit_price_minor,
           (p.status = 'published' and s.status = 'active' and coalesce(v.stock_quantity, 1) > 0
             and app.product_available(p.id)) as available
    from lines l
    join public.product_variants v on v.id = l.variant_id
    join public.products p on p.id = v.product_id
    join public.stores s on s.id = p.store_id
  )
  select jsonb_build_object(
    'id', b.id, 'name', b.name, 'updated_at', b.updated_at,
    'currency_code', (select min(currency_code) from priced),
    'total_minor', coalesce((select sum(unit_price_minor * quantity) from priced where available), 0),
    'available_count', (select count(*) from priced where available),
    'items', coalesce((select jsonb_agg(jsonb_build_object(
        'variant_id', variant_id, 'product_id', product_id, 'name', name, 'variant_label', variant_label,
        'photo_key', photo_key, 'store_name', store_name, 'quantity', quantity,
        'unit_price_minor', unit_price_minor, 'available', available) order by ord)
      from priced), '[]'::jsonb))
$$;

create or replace function public.my_baskets() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.basket_json(b) order by b.created_at, b.id), '[]'::jsonb)
  from public.saved_baskets b where b.user_id = app.current_user_id()
$$;

-- Enregistre le panier en cours sous un nom libre.
create or replace function public.save_cart_as_basket(p_name text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_name text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_items jsonb;
  v_row public.saved_baskets;
begin
  if length(v_name) not between 1 and 40 then raise exception 'invalid_name' using errcode = '22023'; end if;
  select jsonb_agg(jsonb_build_object('variant_id', i.variant_id, 'quantity', i.quantity) order by i.added_at)
  into v_items
  from public.cart_items i join public.carts c on c.id = i.cart_id where c.user_id = v_user;
  if v_items is null then raise exception 'cart_empty' using errcode = '22023'; end if;
  if jsonb_array_length(v_items) > 50 then raise exception 'too_many_items' using errcode = '22023'; end if;
  if (select count(*) from public.saved_baskets where user_id = v_user) >= 20 then
    raise exception 'too_many_baskets' using errcode = '22023';
  end if;
  insert into public.saved_baskets (user_id, name, items) values (v_user, v_name, v_items) returning * into v_row;
  perform app.emit_event('basket_saved', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'saved_basket', v_row.id::text,
    jsonb_build_object('items_count', jsonb_array_length(v_items)));
  return app.basket_json(v_row);
end
$fn$;

create or replace function public.rename_basket(p_id uuid, p_name text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_name text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_row public.saved_baskets;
begin
  if length(v_name) not between 1 and 40 then raise exception 'invalid_name' using errcode = '22023'; end if;
  update public.saved_baskets set name = v_name, updated_at = clock_timestamp()
  where id = p_id and user_id = app.require_user() returning * into v_row;
  if v_row.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  return app.basket_json(v_row);
end
$fn$;

create or replace function public.delete_basket(p_id uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
begin
  delete from public.saved_baskets where id = p_id and user_id = app.require_user();
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
end
$fn$;

-- Remet un panier enregistré dans le panier en cours (règles de `cart_add`) ; nomme ce qui n'a pas
-- pu être ajouté.
create or replace function public.basket_to_cart(p_id uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_basket public.saved_baskets;
  v_item record;
  v_added int := 0;
  v_skipped jsonb := '[]'::jsonb;
  v_cart jsonb;
begin
  select * into v_basket from public.saved_baskets where id = p_id and user_id = v_user;
  if v_basket.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  for v_item in
    select (i ->> 'variant_id')::uuid as variant_id, (i ->> 'quantity')::int as quantity,
           coalesce(p.name, '?') as name
    from jsonb_array_elements(v_basket.items) with ordinality as x (i, ord)
    left join public.product_variants v on v.id = (i ->> 'variant_id')::uuid
    left join public.products p on p.id = v.product_id
    order by ord
  loop
    begin
      v_cart := public.cart_add(v_item.variant_id, v_item.quantity);
      v_added := v_added + 1;
    exception when others then
      v_skipped := v_skipped || to_jsonb(v_item.name);
    end;
  end loop;
  perform app.emit_event('basket_reordered', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'saved_basket', p_id::text,
    jsonb_build_object('added', v_added, 'skipped', jsonb_array_length(v_skipped)));
  return jsonb_build_object('added', v_added, 'skipped', v_skipped, 'cart', coalesce(v_cart, public.my_cart()));
end
$fn$;

insert into public.event_names (name, emitted_by, description) values
  ('favorite_added', 'server', 'Boutique ou produit ajouté aux favoris (type)'),
  ('basket_saved', 'server', 'Panier enregistré (lignes)'),
  ('basket_reordered', 'server', 'Panier enregistré remis au panier (ajoutés, non ajoutés)')
on conflict do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function public.toggle_favorite(text, uuid), public.my_favorite_ids(),
  public.my_favorites(timestamptz), app.basket_json(public.saved_baskets), public.my_baskets(),
  public.save_cart_as_basket(text), public.rename_basket(uuid, text), public.delete_basket(uuid),
  public.basket_to_cart(uuid) from public;
grant execute on function public.toggle_favorite(text, uuid), public.my_favorite_ids(),
  public.my_favorites(timestamptz), public.my_baskets(), public.save_cart_as_basket(text),
  public.rename_basket(uuid, text), public.delete_basket(uuid), public.basket_to_cart(uuid)
  to authenticated;
