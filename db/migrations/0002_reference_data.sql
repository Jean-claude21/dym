-- 0002 — Référentiel générique (spec 004, A-CFG-01..06).
-- Données de configuration lues par les apps, jamais écrites par elles.
-- Libellés multilingues : jsonb avec au moins « fr ». Montants : unités mineures.

-- Libellé multilingue valide : objet non vide de chaînes, avec le français.
create or replace function app.is_label(p jsonb) returns boolean
language sql immutable
as $$
  select jsonb_typeof(p) = 'object'
    and p ? 'fr'
    and length(trim(p ->> 'fr')) > 0
    and not exists (
      select 1 from jsonb_each(p) e where jsonb_typeof(e.value) <> 'string'
    )
$$;

-- ------------------------------------------------------------------ devises

create table public.currencies (
  code char(3) primary key check (code ~ '^[A-Z]{3}$'),
  minor_units smallint not null check (minor_units between 0 and 3),
  symbol text not null check (length(symbol) between 1 and 8),
  format_locale text not null check (format_locale ~ '^[a-z]{2}(_[A-Z]{2})?$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------------ pays

create table public.countries (
  code char(2) primary key check (code ~ '^[A-Z]{2}$'),
  name jsonb not null check (app.is_label(name)),
  currency_code char(3) not null references public.currencies (code),
  dial_code text not null check (dial_code ~ '^\+[0-9]{1,4}$'),
  default_locale text not null check (default_locale ~ '^[a-z]{2}(_[A-Z]{2})?$'),
  timezone text not null,
  is_active boolean not null default false,
  sort smallint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------------ villes et quartiers

create table public.cities (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries (code),
  slug text not null check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null check (length(trim(name)) > 0),
  is_active boolean not null default true,
  sort smallint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (country_code, slug)
);

create table public.zones (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references public.cities (id),
  slug text not null check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null check (length(trim(name)) > 0),
  is_active boolean not null default true,
  sort smallint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (city_id, slug)
);

-- ------------------------------------------------------------------ rayons

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories (id),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  label jsonb not null check (app.is_label(label)),
  icon text,
  sort smallint not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (parent_id is distinct from id)
);

-- Deux niveaux au plus : un sous-rayon ne peut pas avoir d'enfant.
create or replace function app.check_category_depth() returns trigger
language plpgsql
as $$
begin
  if new.parent_id is not null and exists (
    select 1 from public.categories where id = new.parent_id and parent_id is not null
  ) then
    raise exception 'rayon : deux niveaux au plus' using errcode = '23514';
  end if;
  if new.parent_id is not null and exists (
    select 1 from public.categories where parent_id = new.id
  ) then
    raise exception 'rayon : un rayon parent ne peut pas devenir sous-rayon' using errcode = '23514';
  end if;
  return new;
end
$$;

create trigger categories_depth before insert or update of parent_id on public.categories
  for each row execute function app.check_category_depth();

-- ------------------------------------------------------------------ origines et unités

create table public.store_origins (
  code text primary key check (code ~ '^[a-z_]+$'),
  label jsonb not null check (app.is_label(label)),
  description jsonb check (description is null or app.is_label(description)),
  sort smallint not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.units (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries (code),
  code text not null check (code ~ '^[a-z_]+$'),
  label jsonb not null check (app.is_label(label)),
  kind text not null check (kind in ('piece', 'weight', 'volume', 'bundle')),
  indicative_grams integer check (indicative_grams > 0),
  indicative_ml integer check (indicative_ml > 0),
  sort smallint not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (country_code, code)
);

-- ------------------------------------------------------------------ paiement

create table public.payment_providers (
  code text primary key check (code ~ '^[a-z_]+$'),
  label jsonb not null check (app.is_label(label)),
  kind text not null check (kind in ('cash', 'mobile_money', 'card', 'digital')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries (code),
  provider_code text not null references public.payment_providers (code),
  operator_code text check (operator_code ~ '^[a-z_]+$'),
  label jsonb not null check (app.is_label(label)),
  sort smallint not null default 0,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index payment_methods_unique
  on public.payment_methods (country_code, provider_code, coalesce(operator_code, ''));

-- ------------------------------------------------------------------ commission et frais

create table public.commission_rules (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries (code),
  category_id uuid references public.categories (id),
  rate_bps integer not null check (rate_bps between 0 and 10000),
  valid_from timestamptz not null default now(),
  valid_to timestamptz,
  created_at timestamptz not null default now(),
  check (valid_to is null or valid_to > valid_from)
);

-- Une seule règle ouverte par pays et par rayon (NULL = taux par défaut du pays).
create unique index commission_rules_one_open
  on public.commission_rules (
    country_code,
    coalesce(category_id, '00000000-0000-0000-0000-000000000000'::uuid)
  )
  where valid_to is null;

create table public.delivery_fee_defaults (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries (code),
  city_id uuid references public.cities (id),
  currency_code char(3) not null references public.currencies (code),
  base_fee_minor bigint not null check (base_fee_minor >= 0),
  extra_pickup_fee_minor bigint not null default 0 check (extra_pickup_fee_minor >= 0),
  free_threshold_minor bigint check (free_threshold_minor >= 0),
  valid_from timestamptz not null default now(),
  valid_to timestamptz,
  created_at timestamptz not null default now(),
  check (valid_to is null or valid_to > valid_from)
);

create unique index delivery_fee_defaults_one_open
  on public.delivery_fee_defaults (
    country_code,
    coalesce(city_id, '00000000-0000-0000-0000-000000000000'::uuid)
  )
  where valid_to is null;

-- Un frais est dans la devise de son pays ; la ville appartient au pays.
create or replace function app.check_delivery_fee() returns trigger
language plpgsql
as $$
begin
  if new.currency_code <> (select currency_code from public.countries where code = new.country_code) then
    raise exception 'frais de livraison : devise % différente de celle du pays %',
      new.currency_code, new.country_code using errcode = '23514';
  end if;
  if new.city_id is not null and not exists (
    select 1 from public.cities where id = new.city_id and country_code = new.country_code
  ) then
    raise exception 'frais de livraison : ville hors du pays %', new.country_code
      using errcode = '23514';
  end if;
  return new;
end
$$;

create trigger delivery_fee_defaults_check before insert or update on public.delivery_fee_defaults
  for each row execute function app.check_delivery_fee();

-- ------------------------------------------------------------------ flags et IA

create table public.feature_flags (
  id uuid primary key default gen_random_uuid(),
  key text not null check (key ~ '^[a-z][a-z0-9_]*$'),
  country_code char(2) references public.countries (code),
  is_enabled boolean not null default false,
  description text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index feature_flags_unique
  on public.feature_flags (key, coalesce(country_code, '**'));

create table public.ai_models (
  usage text primary key check (usage ~ '^[a-z][a-z0-9_]*$'),
  provider text not null check (provider ~ '^[a-z][a-z0-9_]*$'),
  model text not null check (length(model) > 0),
  params jsonb not null default '{}'::jsonb check (jsonb_typeof(params) = 'object'),
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------------ horodatage

do $$
declare t text;
begin
  foreach t in array array[
    'currencies', 'countries', 'cities', 'zones', 'categories', 'store_origins', 'units',
    'payment_providers', 'payment_methods', 'feature_flags', 'ai_models'
  ] loop
    execute format(
      'create trigger %I before update on public.%I for each row execute function app.set_updated_at()',
      t || '_updated_at', t
    );
  end loop;
end
$$;

-- ------------------------------------------------------------------ accès (RLS)
-- Les apps lisent ce qui est actif ; aucune n'écrit. Un parent inactif masque
-- ses enfants. ai_models : aucun accès (lu par les Functions avec le rôle
-- propriétaire).

alter table public.currencies enable row level security;
alter table public.countries enable row level security;
alter table public.cities enable row level security;
alter table public.zones enable row level security;
alter table public.categories enable row level security;
alter table public.store_origins enable row level security;
alter table public.units enable row level security;
alter table public.payment_providers enable row level security;
alter table public.payment_methods enable row level security;
alter table public.commission_rules enable row level security;
alter table public.delivery_fee_defaults enable row level security;
alter table public.feature_flags enable row level security;
alter table public.ai_models enable row level security;

-- Pays actif (utilisé par les politiques des enfants).
create or replace function app.country_is_active(p_code char(2)) returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((select is_active from public.countries where code = p_code), false)
$$;

create or replace function app.city_is_visible(p_city uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.cities c
    where c.id = p_city and c.is_active and app.country_is_active(c.country_code)
  )
$$;

grant execute on function app.country_is_active(char), app.city_is_visible(uuid)
  to authenticated, anonymous;

create policy currencies_read on public.currencies for select
  to authenticated, anonymous using (true);

create policy countries_read on public.countries for select
  to authenticated, anonymous using (is_active);

create policy cities_read on public.cities for select
  to authenticated, anonymous using (is_active and app.country_is_active(country_code));

create policy zones_read on public.zones for select
  to authenticated, anonymous using (is_active and app.city_is_visible(city_id));

-- Fonction dédiée : une politique ne peut pas relire sa propre table (récursion).
create or replace function app.category_is_active(p_id uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((select is_active from public.categories where id = p_id), false)
$$;

grant execute on function app.category_is_active(uuid) to authenticated, anonymous;

create policy categories_read on public.categories for select
  to authenticated, anonymous
  using (is_active and (parent_id is null or app.category_is_active(parent_id)));

create policy store_origins_read on public.store_origins for select
  to authenticated, anonymous using (is_active);

create policy units_read on public.units for select
  to authenticated, anonymous using (is_active and app.country_is_active(country_code));

create policy payment_providers_read on public.payment_providers for select
  to authenticated, anonymous using (is_active);

create policy payment_methods_read on public.payment_methods for select
  to authenticated, anonymous
  using (
    is_active
    and app.country_is_active(country_code)
    and exists (
      select 1 from public.payment_providers p where p.code = provider_code and p.is_active
    )
  );

create policy commission_rules_read on public.commission_rules for select
  to authenticated using (app.country_is_active(country_code));

create policy delivery_fee_defaults_read on public.delivery_fee_defaults for select
  to authenticated, anonymous using (app.country_is_active(country_code));

create policy feature_flags_read on public.feature_flags for select
  to authenticated, anonymous
  using (country_code is null or app.country_is_active(country_code));

grant select on
  public.currencies, public.countries, public.cities, public.zones, public.categories,
  public.store_origins, public.units, public.payment_providers, public.payment_methods,
  public.delivery_fee_defaults, public.feature_flags
  to authenticated, anonymous;

grant select on public.commission_rules to authenticated;
