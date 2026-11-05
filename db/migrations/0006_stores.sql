-- 0006 — Boutiques : onboarding, adresse privée, conditions, horaires
-- (spec 006 : V-AUTH-03/04, V-SET-01..05, V-DEL-01..04).
-- Toute écriture passe par les fonctions ci-dessous : statut, pays et
-- complétude sont décidés en SQL. Les clientes lisent les boutiques actives
-- sans l'adresse ni la propriétaire.

create table public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references neon_auth."user" (id) on delete cascade,
  name text not null check (length(trim(name)) between 2 and 60),
  description text check (description is null or length(description) <= 280),
  origin text references public.store_origins (code),
  zone_id uuid references public.zones (id),
  country_code char(2) references public.countries (code),
  currency_code char(3) references public.currencies (code),
  main_category_id uuid references public.categories (id),
  prep_time_minutes smallint not null default 30 check (prep_time_minutes between 5 and 240),
  offers_pickup boolean not null default false,
  delivery_fee_minor bigint check (delivery_fee_minor is null or delivery_fee_minor >= 0),
  status text not null default 'draft' check (status in ('draft', 'active', 'suspended')),
  is_open boolean not null default false,
  onboarding_step smallint not null default 1 check (onboarding_step between 1 and 7),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (not is_open or status = 'active')
);

create index stores_zone on public.stores (zone_id) where status = 'active';

create trigger stores_updated_at before update on public.stores
  for each row execute function app.set_updated_at();

-- Adresse de ramassage : privée (propriétaire et équipe ; livreur de la
-- commande avec order-lifecycle).
create table public.store_pickup_addresses (
  store_id uuid primary key references public.stores (id) on delete cascade,
  address text not null check (length(trim(address)) between 3 and 200),
  landmark text check (landmark is null or length(landmark) <= 200),
  latitude numeric(9, 6) check (latitude between -90 and 90),
  longitude numeric(9, 6) check (longitude between -180 and 180),
  contact_phone text check (contact_phone is null or contact_phone ~ '^\+?[0-9 ]{8,20}$'),
  updated_at timestamptz not null default now()
);

create table public.store_delivery_zones (
  store_id uuid not null references public.stores (id) on delete cascade,
  zone_id uuid not null references public.zones (id),
  primary key (store_id, zone_id)
);

create table public.store_payment_methods (
  store_id uuid not null references public.stores (id) on delete cascade,
  payment_method_id uuid not null references public.payment_methods (id),
  primary key (store_id, payment_method_id)
);

create table public.store_hours (
  store_id uuid not null references public.stores (id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7), -- 1 = lundi (ISO)
  opens_at time not null,
  closes_at time not null,
  primary key (store_id, weekday),
  check (opens_at < closes_at)
);

-- ------------------------------------------------------------------ accès

alter table public.stores enable row level security;
alter table public.store_pickup_addresses enable row level security;
alter table public.store_delivery_zones enable row level security;
alter table public.store_payment_methods enable row level security;
alter table public.store_hours enable row level security;

create or replace function app.store_is_active(p_store uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.stores where id = p_store and status = 'active')
$$;

grant execute on function app.store_is_active(uuid) to authenticated, anonymous;

create policy stores_public_read on public.stores for select
  to authenticated, anonymous using (status = 'active' or app.is_admin());
create policy store_delivery_zones_read on public.store_delivery_zones for select
  to authenticated, anonymous using (app.store_is_active(store_id));
create policy store_payment_methods_read on public.store_payment_methods for select
  to authenticated, anonymous using (app.store_is_active(store_id));
create policy store_hours_read on public.store_hours for select
  to authenticated, anonymous using (app.store_is_active(store_id));
create policy store_pickup_addresses_admin on public.store_pickup_addresses for select
  to authenticated using (app.is_admin());

-- Colonnes publiques seulement : jamais owner_id.
grant select (
  id, name, description, origin, zone_id, country_code, currency_code, main_category_id,
  prep_time_minutes, offers_pickup, delivery_fee_minor, status, is_open, published_at
) on public.stores to authenticated, anonymous;
grant select on public.store_delivery_zones, public.store_payment_methods, public.store_hours
  to authenticated, anonymous;
grant select on public.store_pickup_addresses to authenticated;

-- ------------------------------------------------------------------ fonctions

-- Boutique de l'utilisatrice courante (erreur si absente).
create or replace function app.own_store_id() returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_id uuid;
begin
  select id into v_id from public.stores where owner_id = app.current_user_id();
  if v_id is null then
    raise exception 'aucune boutique' using errcode = 'P0002';
  end if;
  return v_id;
end
$$;

-- Ce qui manque pour ouvrir (vide = complète).
create or replace function app.store_missing(p_store uuid) returns text[]
language sql stable security definer set search_path = ''
as $$
  select array_remove(array[
    case when s.origin is null then 'origin' end,
    case when s.zone_id is null then 'zone' end,
    case when s.main_category_id is null then 'category' end,
    case when not exists (select 1 from public.store_pickup_addresses a where a.store_id = s.id) then 'pickup_address' end,
    case when not exists (select 1 from public.store_delivery_zones z where z.store_id = s.id) then 'delivery_zones' end,
    case when not exists (select 1 from public.store_payment_methods p where p.store_id = s.id) then 'payment_methods' end,
    case when not exists (select 1 from public.store_hours h where h.store_id = s.id) then 'hours' end
  ], null)
  from public.stores s where s.id = p_store
$$;

-- Ma boutique, complète (adresse comprise), pour sa propriétaire.
create or replace function public.my_store() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select case when s.id is null then null else
    to_jsonb(s) - 'owner_id'
    || jsonb_build_object(
      'pickup_address', (select to_jsonb(a) - 'store_id' from public.store_pickup_addresses a where a.store_id = s.id),
      'delivery_zone_ids', coalesce((select jsonb_agg(z.zone_id) from public.store_delivery_zones z where z.store_id = s.id), '[]'::jsonb),
      'payment_method_ids', coalesce((select jsonb_agg(p.payment_method_id) from public.store_payment_methods p where p.store_id = s.id), '[]'::jsonb),
      'hours', coalesce((select jsonb_agg(jsonb_build_object('weekday', h.weekday, 'opens_at', to_char(h.opens_at, 'HH24:MI'), 'closes_at', to_char(h.closes_at, 'HH24:MI')) order by h.weekday) from public.store_hours h where h.store_id = s.id), '[]'::jsonb),
      'missing', to_jsonb(app.store_missing(s.id))
    )
  end
  from (select 1) one
  left join public.stores s on s.owner_id = app.current_user_id()
$$;

-- Crée la boutique en brouillon (ou renomme la boutique existante : une par
-- vendeuse). Rôle vendeuse requis.
create or replace function public.start_store(p_name text, p_description text default null)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
begin
  if v_user is null or not app.has_role('vendor') then
    raise exception 'rôle vendeuse requis' using errcode = '42501';
  end if;
  insert into public.stores (owner_id, name, description, onboarding_step)
  values (v_user, trim(p_name), nullif(trim(p_description), ''), 2)
  on conflict (owner_id) do update
    set name = excluded.name,
        description = excluded.description,
        onboarding_step = greatest(public.stores.onboarding_step, 2);
  return public.my_store();
end
$$;

-- Met à jour les champs libres de la boutique (liste blanche). Le pays et la
-- devise suivent le quartier.
create or replace function public.update_store(p_patch jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
  v_key text;
  v_country char(2);
  v_zone uuid;
begin
  for v_key in select jsonb_object_keys(p_patch) loop
    if v_key not in ('name', 'description', 'origin', 'zone_id', 'main_category_id',
                     'prep_time_minutes', 'offers_pickup', 'delivery_fee_minor', 'onboarding_step') then
      raise exception 'champ non modifiable : %', v_key using errcode = '22023';
    end if;
  end loop;

  if p_patch ? 'origin' and not exists (
    select 1 from public.store_origins where code = p_patch ->> 'origin' and is_active
  ) then
    raise exception 'origine inconnue' using errcode = '22023';
  end if;

  if p_patch ? 'main_category_id' and not exists (
    select 1 from public.categories
    where id = (p_patch ->> 'main_category_id')::uuid and parent_id is null and is_active
  ) then
    raise exception 'rayon principal inconnu' using errcode = '22023';
  end if;

  if p_patch ? 'zone_id' then
    v_zone := (p_patch ->> 'zone_id')::uuid;
    select c.country_code into v_country
    from public.zones z join public.cities c on c.id = z.city_id
    where z.id = v_zone and z.is_active and app.city_is_visible(c.id);
    if v_country is null then
      raise exception 'quartier inconnu ou inactif' using errcode = '22023';
    end if;
  end if;

  update public.stores s set
    name = coalesce(trim(p_patch ->> 'name'), s.name),
    description = case when p_patch ? 'description' then nullif(trim(p_patch ->> 'description'), '') else s.description end,
    origin = coalesce(p_patch ->> 'origin', s.origin),
    zone_id = coalesce(v_zone, s.zone_id),
    country_code = coalesce(v_country, s.country_code),
    currency_code = case when v_country is null then s.currency_code
      else (select currency_code from public.countries where code = v_country) end,
    main_category_id = coalesce((p_patch ->> 'main_category_id')::uuid, s.main_category_id),
    prep_time_minutes = coalesce((p_patch ->> 'prep_time_minutes')::smallint, s.prep_time_minutes),
    offers_pickup = coalesce((p_patch ->> 'offers_pickup')::boolean, s.offers_pickup),
    delivery_fee_minor = case when p_patch ? 'delivery_fee_minor' then (p_patch ->> 'delivery_fee_minor')::bigint else s.delivery_fee_minor end,
    onboarding_step = greatest(s.onboarding_step, coalesce((p_patch ->> 'onboarding_step')::smallint, s.onboarding_step))
  where s.id = v_store;

  -- Changer de ville retire les quartiers desservis d'une autre ville.
  if v_zone is not null then
    delete from public.store_delivery_zones d
    where d.store_id = v_store
      and (select city_id from public.zones where id = d.zone_id)
       <> (select city_id from public.zones where id = v_zone);
  end if;
  return public.my_store();
end
$$;

create or replace function public.set_store_pickup_address(
  p_address text,
  p_landmark text default null,
  p_latitude numeric default null,
  p_longitude numeric default null,
  p_contact_phone text default null
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
begin
  insert into public.store_pickup_addresses (store_id, address, landmark, latitude, longitude, contact_phone)
  values (v_store, trim(p_address), nullif(trim(p_landmark), ''), p_latitude, p_longitude, nullif(trim(p_contact_phone), ''))
  on conflict (store_id) do update set
    address = excluded.address, landmark = excluded.landmark, latitude = excluded.latitude,
    longitude = excluded.longitude, contact_phone = excluded.contact_phone, updated_at = now();
  return public.my_store();
end
$$;

-- Quartiers desservis : tous dans la ville du quartier de la boutique.
create or replace function public.set_store_delivery_zones(p_zone_ids uuid[]) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
  v_city uuid;
begin
  select z.city_id into v_city
  from public.stores s join public.zones z on z.id = s.zone_id where s.id = v_store;
  if v_city is null then
    raise exception 'choisir d''abord le quartier de la boutique' using errcode = '22023';
  end if;
  if exists (
    select 1 from unnest(p_zone_ids) as z(id)
    where not exists (select 1 from public.zones x where x.id = z.id and x.city_id = v_city and x.is_active)
  ) then
    raise exception 'quartier hors de la ville de la boutique' using errcode = '22023';
  end if;
  delete from public.store_delivery_zones where store_id = v_store;
  insert into public.store_delivery_zones (store_id, zone_id)
  select v_store, id from (select distinct unnest(p_zone_ids) as id) t;
  return public.my_store();
end
$$;

-- Moyens de paiement : actifs dans le pays de la boutique.
create or replace function public.set_store_payment_methods(p_method_ids uuid[]) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
  v_country char(2);
begin
  select country_code into v_country from public.stores where id = v_store;
  if v_country is null then
    raise exception 'choisir d''abord le quartier de la boutique' using errcode = '22023';
  end if;
  if exists (
    select 1 from unnest(p_method_ids) as m(id)
    where not exists (
      select 1 from public.payment_methods pm
      join public.payment_providers pp on pp.code = pm.provider_code
      where pm.id = m.id and pm.country_code = v_country and pm.is_active and pp.is_active
    )
  ) then
    raise exception 'moyen de paiement indisponible dans ce pays' using errcode = '22023';
  end if;
  delete from public.store_payment_methods where store_id = v_store;
  insert into public.store_payment_methods (store_id, payment_method_id)
  select v_store, id from (select distinct unnest(p_method_ids) as id) t;
  return public.my_store();
end
$$;

-- Horaires : [{weekday, opens_at, closes_at}], au moins un jour.
create or replace function public.set_store_hours(p_hours jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
begin
  if jsonb_typeof(p_hours) <> 'array' or jsonb_array_length(p_hours) = 0 then
    raise exception 'au moins un jour ouvert' using errcode = '22023';
  end if;
  delete from public.store_hours where store_id = v_store;
  insert into public.store_hours (store_id, weekday, opens_at, closes_at)
  select v_store, (h ->> 'weekday')::smallint, (h ->> 'opens_at')::time, (h ->> 'closes_at')::time
  from jsonb_array_elements(p_hours) as h;
  return public.my_store();
end
$$;

-- Ouverture de la boutique : complète, non suspendue.
create or replace function public.publish_store() returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
  v_missing text[] := app.store_missing(v_store);
  v_status text;
  v_origin text;
  v_country char(2);
  v_first boolean;
begin
  select status, origin, country_code, published_at is null
  into v_status, v_origin, v_country, v_first
  from public.stores where id = v_store;
  if v_status = 'suspended' then
    raise exception 'boutique suspendue par l''équipe' using errcode = '42501';
  end if;
  if cardinality(v_missing) > 0 then
    raise exception 'boutique incomplète : %', array_to_string(v_missing, ', ') using errcode = 'P0001';
  end if;
  update public.stores
  set status = 'active', is_open = true, onboarding_step = 7,
      published_at = coalesce(published_at, now())
  where id = v_store;
  if v_first then
    perform app.emit_event('store_created', app.current_user_id(), 'vendor', 'vendor', v_country,
      'store', v_store::text, jsonb_build_object('store_origin', v_origin));
  end if;
  perform app.emit_event('store_opened', app.current_user_id(), 'vendor', 'vendor', v_country,
    'store', v_store::text, jsonb_build_object('store_origin', v_origin));
  return public.my_store();
end
$$;

-- Ouvrir ou fermer en un geste (boutique active seulement).
create or replace function public.set_store_open(p_open boolean) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
  v_status text;
  v_open boolean;
  v_origin text;
  v_country char(2);
begin
  select status, is_open, origin, country_code into v_status, v_open, v_origin, v_country
  from public.stores where id = v_store;
  if v_status <> 'active' then
    raise exception 'boutique non active (%)', v_status using errcode = '42501';
  end if;
  if v_open is distinct from p_open then
    update public.stores set is_open = p_open where id = v_store;
    perform app.emit_event(
      case when p_open then 'store_opened' else 'store_closed' end,
      app.current_user_id(), 'vendor', 'vendor', v_country, 'store', v_store::text,
      jsonb_build_object('store_origin', v_origin));
  end if;
  return public.my_store();
end
$$;

-- Moyens de paiement du pays de la boutique, disponibles ou à venir (« Bientôt »,
-- spec 006 US1-5). Les inactifs restent invisibles par la Data API.
create or replace function public.store_payment_options() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', pm.id,
      'provider_code', pm.provider_code,
      'operator_code', pm.operator_code,
      'kind', pp.kind,
      'label', pm.label,
      'sort', pm.sort,
      'is_available', pm.is_active and pp.is_active
    ) order by pm.sort), '[]'::jsonb)
  from public.stores s
  join public.payment_methods pm on pm.country_code = s.country_code
  join public.payment_providers pp on pp.code = pm.provider_code
  where s.id = app.own_store_id()
$$;

revoke all on function
  public.my_store(), public.start_store(text, text), public.update_store(jsonb),
  public.set_store_pickup_address(text, text, numeric, numeric, text),
  public.set_store_delivery_zones(uuid[]), public.set_store_payment_methods(uuid[]),
  public.set_store_hours(jsonb), public.publish_store(), public.set_store_open(boolean),
  public.store_payment_options()
  from public;
grant execute on function
  public.my_store(), public.start_store(text, text), public.update_store(jsonb),
  public.set_store_pickup_address(text, text, numeric, numeric, text),
  public.set_store_delivery_zones(uuid[]), public.set_store_payment_methods(uuid[]),
  public.set_store_hours(jsonb), public.publish_store(), public.set_store_open(boolean),
  public.store_payment_options()
  to authenticated;
