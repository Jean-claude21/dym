-- Catalogue de la vendeuse (spec 007) : catégories de boutique, produits,
-- variantes, photos et propositions de l'IA.
--
-- Lecture publique des produits publiés des boutiques actives (RLS). Toutes
-- les écritures passent par des fonctions SECURITY DEFINER qui vérifient la
-- propriété. Les fonctions `app.*` à identifiant explicite sont réservées aux
-- Functions (rôle propriétaire, sans droit Data API).

-- ------------------------------------------------------------------ tables

create table public.store_categories (
  id uuid primary key,
  store_id uuid not null references public.stores (id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 40),
  sort smallint not null default 0,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index store_categories_name_unique
  on public.store_categories (store_id, lower(trim(name)));

-- Propositions de l'IA : privées (schéma app), comparées à la fiche publiée.
create table app.ai_product_suggestions (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  object_key text not null,
  model text not null,
  name text,
  category_id uuid references public.categories (id),
  description text,
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key,
  store_id uuid not null references public.stores (id) on delete cascade,
  name text not null check (length(trim(name)) between 2 and 80),
  description text check (description is null or length(description) <= 500),
  category_id uuid references public.categories (id),
  unit_id uuid references public.units (id),
  price_minor bigint check (price_minor is null or price_minor > 0),
  currency_code char(3) not null references public.currencies (code),
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  is_available boolean not null default true,
  suggestion_id uuid references app.ai_product_suggestions (id) on delete set null,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index products_store on public.products (store_id, status);

-- Stock nul : non suivi (fait maison du jour). Libellé nul : variante unique.
create table public.product_variants (
  id uuid primary key,
  product_id uuid not null references public.products (id) on delete cascade,
  label text check (label is null or length(trim(label)) between 1 and 30),
  price_minor bigint check (price_minor is null or price_minor > 0),
  stock_quantity integer check (stock_quantity is null or stock_quantity >= 0),
  sort smallint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index product_variants_label_unique
  on public.product_variants (product_id, lower(coalesce(trim(label), '')));

create table public.product_photos (
  product_id uuid not null references public.products (id) on delete cascade,
  object_key text not null
    check (object_key ~ '^stores/[0-9a-f-]{36}/products/[0-9a-f-]{36}\.(jpg|webp)$'),
  sort smallint not null default 0,
  primary key (product_id, object_key)
);

create table public.product_store_categories (
  product_id uuid not null references public.products (id) on delete cascade,
  store_category_id uuid not null references public.store_categories (id) on delete cascade,
  primary key (product_id, store_category_id)
);

do $$
declare t text;
begin
  foreach t in array array['store_categories', 'products', 'product_variants'] loop
    execute format(
      'create trigger %I before update on public.%I for each row execute function app.set_updated_at()',
      t || '_updated_at', t
    );
  end loop;
end
$$;

-- ------------------------------------------------------------------ accès

alter table public.store_categories enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.product_photos enable row level security;
alter table public.product_store_categories enable row level security;

create or replace function app.product_is_public(p_product uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.products p
    where p.id = p_product and p.status = 'published' and app.store_is_active(p.store_id)
  )
$$;

grant execute on function app.product_is_public(uuid) to authenticated, anonymous;

create policy store_categories_public_read on public.store_categories for select
  to authenticated, anonymous using (not is_archived and app.store_is_active(store_id));
create policy products_public_read on public.products for select
  to authenticated, anonymous using (status = 'published' and app.store_is_active(store_id));
create policy product_variants_public_read on public.product_variants for select
  to authenticated, anonymous using (app.product_is_public(product_id));
create policy product_photos_public_read on public.product_photos for select
  to authenticated, anonymous using (app.product_is_public(product_id));
create policy product_store_categories_public_read on public.product_store_categories for select
  to authenticated, anonymous using (app.product_is_public(product_id));

-- Colonnes publiques : jamais la proposition d'origine.
grant select (
  id, store_id, name, description, category_id, unit_id, price_minor, currency_code,
  status, is_available, published_at
) on public.products to authenticated, anonymous;
grant select (id, store_id, name, sort) on public.store_categories to authenticated, anonymous;
grant select on public.product_variants, public.product_photos, public.product_store_categories
  to authenticated, anonymous;

-- ------------------------------------------------------------------ propriété

-- Boutique modifiable de l'utilisatrice courante : la sienne, non suspendue.
create or replace function app.own_editable_store() returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
begin
  if exists (select 1 from public.stores where id = v_store and status = 'suspended') then
    raise exception 'boutique suspendue' using errcode = '42501';
  end if;
  return v_store;
end
$$;

-- Produit de la boutique modifiable (sinon refus, sans dire s'il existe).
create or replace function app.own_product(p_product uuid) returns public.products
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_editable_store();
  v_product public.products;
begin
  select * into v_product from public.products where id = p_product;
  if v_product.id is null or v_product.store_id <> v_store then
    raise exception 'produit inaccessible' using errcode = '42501';
  end if;
  return v_product;
end
$$;

-- Ce qui manque pour publier (vide = complet).
create or replace function app.product_missing(p_product uuid) returns text[]
language sql stable security definer set search_path = ''
as $$
  select array_remove(array[
    case when p.category_id is null then 'category' end,
    case when p.price_minor is null then 'price' end,
    case when not exists (select 1 from public.product_photos f where f.product_id = p.id) then 'photo' end,
    case when not exists (select 1 from public.product_variants v where v.product_id = p.id) then 'variant' end
  ], null)
  from public.products p where p.id = p_product
$$;

-- Fiche complète pour sa propriétaire.
create or replace function app.product_json(p_product uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select to_jsonb(p) - 'store_id'
    || jsonb_build_object(
      'variants', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', v.id, 'label', v.label, 'price_minor', v.price_minor,
          'stock_quantity', v.stock_quantity, 'sort', v.sort) order by v.sort, v.created_at)
        from public.product_variants v where v.product_id = p.id), '[]'::jsonb),
      'photo_keys', coalesce((
        select jsonb_agg(f.object_key order by f.sort)
        from public.product_photos f where f.product_id = p.id), '[]'::jsonb),
      'store_category_ids', coalesce((
        select jsonb_agg(c.store_category_id)
        from public.product_store_categories c where c.product_id = p.id), '[]'::jsonb),
      'missing', to_jsonb(app.product_missing(p.id))
    )
  from public.products p where p.id = p_product
$$;

create or replace function app.emit_stock_changed(p_product public.products, p_change text)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  perform app.emit_event(
    'product_stock_changed', app.current_user_id(), 'vendor', 'vendor',
    (select country_code from public.stores where id = p_product.store_id),
    'product', p_product.id::text, jsonb_build_object('change', p_change));
end
$$;

-- ------------------------------------------------------------------ catégories de boutique

create or replace function public.my_store_categories() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', c.id, 'name', c.name, 'sort', c.sort, 'is_archived', c.is_archived,
      'product_count', (select count(*) from public.product_store_categories pc
                        join public.products p on p.id = pc.product_id
                        where pc.store_category_id = c.id and p.status <> 'archived'))
    order by c.is_archived, c.sort, c.created_at), '[]'::jsonb)
  from public.store_categories c
  where c.store_id = app.own_store_id()
$$;

-- Crée (identifiant fourni par l'app : idempotent) ou renomme.
create or replace function public.save_store_category(p_id uuid, p_name text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_editable_store();
begin
  if exists (select 1 from public.store_categories where id = p_id and store_id <> v_store) then
    raise exception 'catégorie inaccessible' using errcode = '42501';
  end if;
  if not exists (select 1 from public.store_categories where id = p_id)
     and (select count(*) from public.store_categories where store_id = v_store) >= 30 then
    raise exception 'au plus 30 catégories' using errcode = '22023';
  end if;
  insert into public.store_categories (id, store_id, name, sort)
  values (p_id, v_store, trim(p_name),
          coalesce((select max(sort) + 1 from public.store_categories where store_id = v_store), 0))
  on conflict (id) do update set name = excluded.name;
  return public.my_store_categories();
end
$$;

create or replace function public.archive_store_category(p_id uuid, p_archived boolean)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_editable_store();
begin
  update public.store_categories set is_archived = p_archived
  where id = p_id and store_id = v_store;
  if not found then
    raise exception 'catégorie inaccessible' using errcode = '42501';
  end if;
  return public.my_store_categories();
end
$$;

create or replace function public.reorder_store_categories(p_ids uuid[]) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_editable_store();
begin
  update public.store_categories c set sort = o.position - 1
  from unnest(p_ids) with ordinality as o(id, position)
  where c.id = o.id and c.store_id = v_store;
  return public.my_store_categories();
end
$$;

-- ------------------------------------------------------------------ produits

create or replace function public.my_products() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.product_json(p.id) order by p.created_at desc), '[]'::jsonb)
  from public.products p
  where p.store_id = app.own_store_id()
$$;

-- Crée ou met à jour une fiche (identifiants fournis par l'app : une nouvelle
-- tentative réécrit les mêmes lignes). Clés : id, name, description,
-- category_id, unit_id, price_minor, suggestion_id, photo_keys[],
-- store_category_ids[], variants[{id, label, price_minor, stock_quantity}].
-- La devise est celle de la boutique ; toute autre valeur est ignorée.
create or replace function public.save_product(p_product jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_editable_store();
  v_id uuid := (p_product ->> 'id')::uuid;
  v_currency char(3);
  v_country char(2);
  v_existing public.products;
  v_unit uuid := (p_product ->> 'unit_id')::uuid;
  v_category uuid := (p_product ->> 'category_id')::uuid;
  v_suggestion uuid := (p_product ->> 'suggestion_id')::uuid;
  v_keys text[] := coalesce(array(select jsonb_array_elements_text(p_product -> 'photo_keys')), '{}');
  v_store_categories uuid[] := coalesce(
    array(select jsonb_array_elements_text(p_product -> 'store_category_ids')::uuid), '{}');
  v_variants jsonb := coalesce(p_product -> 'variants', '[]'::jsonb);
  v_stock_before jsonb;
  v_stock_after jsonb;
begin
  if v_id is null then
    raise exception 'identifiant du produit requis' using errcode = '22023';
  end if;
  select currency_code, country_code into v_currency, v_country
  from public.stores where id = v_store;
  if v_currency is null then
    raise exception 'choisir d''abord le quartier de la boutique' using errcode = '22023';
  end if;
  select * into v_existing from public.products where id = v_id;
  if v_existing.id is not null and v_existing.store_id <> v_store then
    raise exception 'produit inaccessible' using errcode = '42501';
  end if;

  if v_unit is not null and not exists (
    select 1 from public.units where id = v_unit and country_code = v_country and is_active
  ) then
    raise exception 'unité indisponible dans ce pays' using errcode = '22023';
  end if;
  if v_category is not null and not app.category_is_active(v_category) then
    raise exception 'rayon inconnu' using errcode = '22023';
  end if;
  if v_suggestion is not null and not exists (
    select 1 from app.ai_product_suggestions where id = v_suggestion and store_id = v_store
  ) then
    v_suggestion := null;
  end if;
  if cardinality(v_keys) > 5 then
    raise exception 'au plus 5 photos' using errcode = '22023';
  end if;
  if exists (select 1 from unnest(v_keys) k
             where k not like 'stores/' || v_store::text || '/products/%') then
    raise exception 'photo d''une autre boutique' using errcode = '42501';
  end if;
  if exists (select 1 from jsonb_array_elements(v_variants) v where (v ->> 'id') is null) then
    raise exception 'identifiant de variante requis' using errcode = '22023';
  end if;
  if jsonb_array_length(v_variants) > 10 then
    raise exception 'au plus 10 variantes' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(v_variants) v
    join public.product_variants pv on pv.id = (v ->> 'id')::uuid
    where pv.product_id <> v_id
  ) then
    raise exception 'variante inaccessible' using errcode = '42501';
  end if;
  if exists (
    select 1 from unnest(v_store_categories) c(id)
    where not exists (select 1 from public.store_categories sc where sc.id = c.id and sc.store_id = v_store)
  ) then
    raise exception 'catégorie inaccessible' using errcode = '42501';
  end if;

  select jsonb_object_agg(id, stock_quantity) into v_stock_before
  from public.product_variants where product_id = v_id;

  insert into public.products (
    id, store_id, name, description, category_id, unit_id, price_minor, currency_code, suggestion_id)
  values (
    v_id, v_store, trim(p_product ->> 'name'), nullif(trim(p_product ->> 'description'), ''),
    v_category, v_unit, (p_product ->> 'price_minor')::bigint, v_currency,
    coalesce(v_suggestion, v_existing.suggestion_id))
  on conflict (id) do update set
    name = excluded.name, description = excluded.description, category_id = excluded.category_id,
    unit_id = excluded.unit_id, price_minor = excluded.price_minor,
    currency_code = excluded.currency_code, suggestion_id = excluded.suggestion_id;

  -- Photos : l'ordre de la liste.
  delete from public.product_photos where product_id = v_id;
  insert into public.product_photos (product_id, object_key, sort)
  select v_id, k, (o - 1)::smallint from unnest(v_keys) with ordinality as t(k, o)
  on conflict do nothing;

  -- Variantes : au moins une (sans libellé si aucune n'est fournie).
  if jsonb_array_length(v_variants) = 0 then
    v_variants := jsonb_build_array(jsonb_build_object(
      'id', coalesce((select id from public.product_variants where product_id = v_id order by sort limit 1),
                     gen_random_uuid())));
  end if;
  delete from public.product_variants
  where product_id = v_id
    and id not in (select (v ->> 'id')::uuid from jsonb_array_elements(v_variants) v);
  insert into public.product_variants (id, product_id, label, price_minor, stock_quantity, sort)
  select (v ->> 'id')::uuid, v_id, nullif(trim(v ->> 'label'), ''),
         (v ->> 'price_minor')::bigint, (v ->> 'stock_quantity')::integer, (o - 1)::smallint
  from jsonb_array_elements(v_variants) with ordinality as t(v, o)
  on conflict (id) do update set
    label = excluded.label, price_minor = excluded.price_minor,
    stock_quantity = excluded.stock_quantity, sort = excluded.sort;

  delete from public.product_store_categories where product_id = v_id;
  insert into public.product_store_categories (product_id, store_category_id)
  select v_id, c from (select distinct unnest(v_store_categories) as c) t;

  select jsonb_object_agg(id, stock_quantity) into v_stock_after
  from public.product_variants where product_id = v_id;
  if v_existing.status = 'published' and v_stock_before is distinct from v_stock_after then
    perform app.emit_stock_changed(v_existing, 'quantity');
  end if;

  return app.product_json(v_id);
end
$$;

-- Publie (refusé si incomplet). Première publication : `product_published`,
-- et comparaison avec la proposition d'origine (H8).
create or replace function public.publish_product(p_id uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_product public.products := app.own_product(p_id);
  v_missing text[] := app.product_missing(p_id);
  v_country char(2);
  v_suggestion app.ai_product_suggestions;
begin
  if cardinality(v_missing) > 0 then
    raise exception 'produit incomplet : %', array_to_string(v_missing, ', ') using errcode = 'P0001';
  end if;
  if v_product.status = 'published' then
    return app.product_json(p_id);
  end if;
  update public.products
  set status = 'published', published_at = coalesce(published_at, now())
  where id = p_id;

  if v_product.published_at is null then
    select country_code into v_country from public.stores where id = v_product.store_id;
    perform app.emit_event(
      'product_published', app.current_user_id(), 'vendor', 'vendor', v_country,
      'product', p_id::text, jsonb_build_object(
        'photo_count', (select count(*) from public.product_photos where product_id = p_id),
        'variant_count', (select count(*) from public.product_variants where product_id = p_id),
        'from_suggestion', v_product.suggestion_id is not null));
    if v_product.suggestion_id is not null then
      select * into v_suggestion from app.ai_product_suggestions where id = v_product.suggestion_id;
      perform app.emit_event(
        'ai_product_suggestion_accepted', app.current_user_id(), 'vendor', 'vendor', v_country,
        'product', p_id::text, jsonb_build_object('fields_changed',
          (v_product.name is distinct from v_suggestion.name)::int
          + (v_product.category_id is distinct from v_suggestion.category_id)::int
          + (v_product.description is distinct from v_suggestion.description)::int));
    end if;
  end if;
  return app.product_json(p_id);
end
$$;

-- Rupture ou réactivation en un geste.
create or replace function public.set_product_available(p_id uuid, p_available boolean)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_product public.products := app.own_product(p_id);
begin
  if v_product.is_available is distinct from p_available then
    update public.products set is_available = p_available where id = p_id;
    perform app.emit_stock_changed(
      v_product, case when p_available then 'back_in_stock' else 'out_of_stock' end);
  end if;
  return app.product_json(p_id);
end
$$;

-- Stock d'une variante (nul : non suivi).
create or replace function public.set_variant_stock(p_variant_id uuid, p_quantity integer)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_product_id uuid;
  v_product public.products;
  v_before integer;
begin
  select product_id, stock_quantity into v_product_id, v_before
  from public.product_variants where id = p_variant_id;
  if v_product_id is null then
    raise exception 'variante inaccessible' using errcode = '42501';
  end if;
  v_product := app.own_product(v_product_id);
  if v_before is distinct from p_quantity then
    update public.product_variants set stock_quantity = p_quantity where id = p_variant_id;
    perform app.emit_stock_changed(v_product, 'quantity');
  end if;
  return app.product_json(v_product_id);
end
$$;

-- Archive ou restaure (un produit déjà publié revient publié).
create or replace function public.archive_product(p_id uuid, p_archived boolean) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_product public.products := app.own_product(p_id);
begin
  update public.products
  set status = case
    when p_archived then 'archived'
    when v_product.published_at is not null then 'published'
    else 'draft' end
  where id = p_id;
  return app.product_json(p_id);
end
$$;

-- Seul un brouillon jamais publié se supprime.
create or replace function public.delete_product_draft(p_id uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_product public.products := app.own_product(p_id);
begin
  if v_product.status <> 'draft' or v_product.published_at is not null then
    raise exception 'seul un brouillon se supprime : archiver' using errcode = 'P0001';
  end if;
  delete from public.products where id = p_id;
end
$$;

revoke all on function
  public.my_store_categories(), public.save_store_category(uuid, text),
  public.archive_store_category(uuid, boolean), public.reorder_store_categories(uuid[]),
  public.my_products(), public.save_product(jsonb), public.publish_product(uuid),
  public.set_product_available(uuid, boolean), public.set_variant_stock(uuid, integer),
  public.archive_product(uuid, boolean), public.delete_product_draft(uuid)
  from public;
grant execute on function
  public.my_store_categories(), public.save_store_category(uuid, text),
  public.archive_store_category(uuid, boolean), public.reorder_store_categories(uuid[]),
  public.my_products(), public.save_product(jsonb), public.publish_product(uuid),
  public.set_product_available(uuid, boolean), public.set_variant_stock(uuid, integer),
  public.archive_product(uuid, boolean), public.delete_product_draft(uuid)
  to authenticated;

-- ------------------------------------------------------------------ Functions (rôle propriétaire)

-- Boutique dans laquelle `p_user` peut déposer des photos (la sienne, non
-- suspendue, quartier choisi).
create or replace function app.photo_upload_store(p_user uuid) returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_store public.stores;
begin
  select * into v_store from public.stores where owner_id = p_user;
  if v_store.id is null then
    raise exception 'aucune boutique' using errcode = 'P0002';
  end if;
  if v_store.status = 'suspended' then
    raise exception 'boutique suspendue' using errcode = '42501';
  end if;
  return v_store.id;
end
$$;

-- Contexte d'une proposition : modèle actif (ou null), rayons actifs du
-- pays (libellés fr), après vérification que la photo est à `p_user`.
create or replace function app.suggestion_context(p_user uuid, p_object_key text) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_store uuid := app.photo_upload_store(p_user);
begin
  if p_object_key not like 'stores/' || v_store::text || '/products/%' then
    raise exception 'photo d''une autre boutique' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'store_id', v_store,
    'model', (select jsonb_build_object('provider', provider, 'model', model, 'params', params)
              from public.ai_models where usage = 'product_from_photo' and is_active),
    'categories', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', c.id,
        'label', coalesce(parent.label ->> 'fr' || ' › ', '') || (c.label ->> 'fr')) order by c.sort)
      from public.categories c
      left join public.categories parent on parent.id = c.parent_id
      where c.is_active and (c.parent_id is null or parent.is_active)), '[]'::jsonb));
end
$$;

-- Conserve une proposition ; rayon inconnu ignoré. Retourne son identifiant.
create or replace function app.record_product_suggestion(
  p_user uuid,
  p_object_key text,
  p_model text,
  p_name text,
  p_category_id uuid,
  p_description text
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := ((app.suggestion_context(p_user, p_object_key)) ->> 'store_id')::uuid;
  v_id uuid;
begin
  insert into app.ai_product_suggestions (store_id, object_key, model, name, category_id, description)
  values (
    v_store, p_object_key, p_model,
    left(nullif(trim(p_name), ''), 80),
    case when app.category_is_active(p_category_id) then p_category_id end,
    left(nullif(trim(p_description), ''), 500))
  returning id into v_id;
  return v_id;
end
$$;
