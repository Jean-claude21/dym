-- 0038 — Espaces partagés (spec 031).
-- Un espace (nom libre) réunit des membres : `payer` valide et paie, `member` remplit. Un panier
-- commun, chiffré par la base ; la validation passe les articles dans le panier de la personne qui
-- valide (règles de `cart_add`), dans la limite d'un budget mensuel facultatif. La poche commune et
-- le paiement à plusieurs viennent avec la spec `spaces-money`.

create table public.spaces (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) between 1 and 40),
  owner_id uuid not null references neon_auth."user" (id) on delete cascade,
  country_code char(2) not null references public.countries (code),
  currency_code char(3) not null references public.currencies (code),
  monthly_budget_minor bigint check (monthly_budget_minor is null or monthly_budget_minor > 0),
  join_code text not null unique check (join_code ~ '^[A-Z2-9]{8}$'),
  created_at timestamptz not null default clock_timestamp()
);

create table public.space_members (
  space_id uuid not null references public.spaces (id) on delete cascade,
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  role text not null check (role in ('payer', 'member')),
  joined_at timestamptz not null default clock_timestamp(),
  primary key (space_id, user_id)
);
create index space_members_user on public.space_members (user_id);

create table public.space_items (
  space_id uuid not null references public.spaces (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  quantity smallint not null check (quantity between 1 and 99),
  added_by uuid references neon_auth."user" (id) on delete set null,
  added_at timestamptz not null default clock_timestamp(),
  primary key (space_id, variant_id)
);

create table public.space_validations (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.spaces (id) on delete cascade,
  validated_by uuid references neon_auth."user" (id) on delete set null,
  items_count integer not null check (items_count >= 0),
  total_minor bigint not null check (total_minor >= 0),
  created_at timestamptz not null default clock_timestamp()
);
create index space_validations_space on public.space_validations (space_id, created_at);

-- Rôle de la personne dans l'espace (nul : pas membre).
create or replace function app.space_role(p_space uuid, p_user uuid) returns text
language sql stable security definer set search_path = ''
as $$
  select role from public.space_members where space_id = p_space and user_id = p_user
$$;

alter table public.spaces enable row level security;
alter table public.space_members enable row level security;
alter table public.space_items enable row level security;
alter table public.space_validations enable row level security;
create policy spaces_members_read on public.spaces for select
  to authenticated using (app.space_role(id, app.current_user_id()) is not null);
create policy space_members_read on public.space_members for select
  to authenticated using (app.space_role(space_id, app.current_user_id()) is not null);
create policy space_items_read on public.space_items for select
  to authenticated using (app.space_role(space_id, app.current_user_id()) is not null);
create policy space_validations_read on public.space_validations for select
  to authenticated using (app.space_role(space_id, app.current_user_id()) is not null);
revoke all on public.spaces, public.space_members, public.space_items, public.space_validations
  from authenticated, anonymous;
grant select on public.spaces, public.space_members, public.space_items, public.space_validations
  to authenticated;

-- ------------------------------------------------------------------ lecture

-- Dépensé du mois en cours (fuseau du pays de l'espace).
create or replace function app.space_spent_month(p_space uuid, p_at timestamptz default now())
returns bigint
language sql stable security definer set search_path = ''
as $$
  select coalesce(sum(v.total_minor), 0)::bigint
  from public.space_validations v
  join public.spaces s on s.id = v.space_id
  join public.countries c on c.code = s.country_code
  where v.space_id = p_space
    and date_trunc('month', v.created_at at time zone c.timezone)
        = date_trunc('month', p_at at time zone c.timezone)
$$;

-- Panier commun au prix du jour.
create or replace function app.space_items_json(p_space uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'variant_id', x.variant_id, 'product_id', x.product_id, 'name', x.name,
      'variant_label', x.variant_label, 'photo_key', x.photo_key, 'store_name', x.store_name,
      'quantity', x.quantity, 'unit_price_minor', x.unit_price_minor, 'available', x.available,
      'added_by', x.added_by_name) order by x.added_at, x.variant_id), '[]'::jsonb)
  from (
    select i.variant_id, i.quantity, i.added_at, p.id as product_id, p.name, v.label as variant_label,
           (select f.object_key from public.product_photos f where f.product_id = p.id
            order by f.sort limit 1) as photo_key,
           st.name as store_name, app.variant_price(v.id) as unit_price_minor,
           (p.status = 'published' and st.status = 'active' and coalesce(v.stock_quantity, 1) > 0
             and app.product_available(p.id)) as available,
           (select pr.first_name from public.profiles pr where pr.user_id = i.added_by) as added_by_name
    from public.space_items i
    join public.product_variants v on v.id = i.variant_id
    join public.products p on p.id = v.product_id
    join public.stores st on st.id = p.store_id
    where i.space_id = p_space) x
$$;

create or replace function app.space_json(p_space uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', s.id, 'name', s.name, 'currency_code', s.currency_code,
    'monthly_budget_minor', s.monthly_budget_minor,
    'spent_month_minor', app.space_spent_month(s.id),
    'join_code', s.join_code,
    'my_role', app.space_role(s.id, p_user),
    'is_owner', s.owner_id = p_user,
    'members', coalesce((
      select jsonb_agg(jsonb_build_object(
          'user_id', m.user_id, 'first_name', coalesce(pr.first_name, '?'), 'role', m.role,
          'is_owner', m.user_id = s.owner_id, 'is_me', m.user_id = p_user)
        order by m.user_id <> s.owner_id, m.joined_at)
      from public.space_members m left join public.profiles pr on pr.user_id = m.user_id
      where m.space_id = s.id), '[]'::jsonb),
    'items', app.space_items_json(s.id),
    'total_minor', coalesce((
      select sum(app.variant_price(i.variant_id) * i.quantity) from public.space_items i
      where i.space_id = s.id), 0))
  from public.spaces s where s.id = p_space
$$;

create or replace function public.my_spaces() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', s.id, 'name', s.name, 'currency_code', s.currency_code, 'my_role', m.role,
      'monthly_budget_minor', s.monthly_budget_minor,
      'spent_month_minor', app.space_spent_month(s.id),
      'members_count', (select count(*) from public.space_members x where x.space_id = s.id),
      'items_count', (select count(*) from public.space_items x where x.space_id = s.id))
    order by s.created_at, s.id), '[]'::jsonb)
  from public.space_members m join public.spaces s on s.id = m.space_id
  where m.user_id = app.current_user_id()
$$;

create or replace function public.space_detail(p_space uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if app.space_role(p_space, v_user) is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  return app.space_json(p_space, v_user);
end
$fn$;

-- ------------------------------------------------------------------ membres

create or replace function public.create_space(p_name text, p_monthly_budget_minor bigint default null)
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_name text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_country char(2) := (select country_code from public.profiles where user_id = v_user);
  v_id uuid;
  v_code text;
begin
  if v_country is null then raise exception 'profile_required' using errcode = '22023'; end if;
  if length(v_name) not between 1 and 40 then raise exception 'invalid_name' using errcode = '22023'; end if;
  if p_monthly_budget_minor is not null and p_monthly_budget_minor <= 0 then
    raise exception 'invalid_budget' using errcode = '22023';
  end if;
  if (select count(*) from public.space_members where user_id = v_user) >= 20 then
    raise exception 'too_many_spaces' using errcode = '22023';
  end if;
  loop
    v_code := (select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 1 + floor(random() * 32)::int, 1), '')
               from generate_series(1, 8));
    exit when not exists (select 1 from public.spaces where join_code = v_code);
  end loop;
  insert into public.spaces (name, owner_id, country_code, currency_code, monthly_budget_minor, join_code)
  values (v_name, v_user, v_country, (select currency_code from public.countries where code = v_country),
          p_monthly_budget_minor, v_code)
  returning id into v_id;
  insert into public.space_members (space_id, user_id, role) values (v_id, v_user, 'payer');
  perform app.emit_event('space_created', v_user, 'client', 'server', v_country, 'space', v_id::text,
    jsonb_build_object('budget', p_monthly_budget_minor is not null));
  return app.space_json(v_id, v_user);
end
$fn$;

-- Réglages de la responsable : nom et budget (budget nul : sans budget).
create or replace function public.update_space(p_space uuid, p_name text, p_monthly_budget_minor bigint)
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_name text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
begin
  if not exists (select 1 from public.spaces where id = p_space and owner_id = v_user) then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if length(v_name) not between 1 and 40 then raise exception 'invalid_name' using errcode = '22023'; end if;
  if p_monthly_budget_minor is not null and p_monthly_budget_minor <= 0 then
    raise exception 'invalid_budget' using errcode = '22023';
  end if;
  update public.spaces set name = v_name, monthly_budget_minor = p_monthly_budget_minor where id = p_space;
  return app.space_json(p_space, v_user);
end
$fn$;

create or replace function public.join_space(p_code text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_space public.spaces;
begin
  select * into v_space from public.spaces where join_code = upper(btrim(coalesce(p_code, '')));
  if v_space.id is null then raise exception 'unknown_code' using errcode = 'P0002'; end if;
  if app.space_role(v_space.id, v_user) is not null then return app.space_json(v_space.id, v_user); end if;
  if (select country_code from public.profiles where user_id = v_user) is distinct from v_space.country_code then
    raise exception 'other_country' using errcode = '22023';
  end if;
  if (select count(*) from public.space_members where space_id = v_space.id) >= 20 then
    raise exception 'space_full' using errcode = '22023';
  end if;
  if (select count(*) from public.space_members where user_id = v_user) >= 20 then
    raise exception 'too_many_spaces' using errcode = '22023';
  end if;
  insert into public.space_members (space_id, user_id, role) values (v_space.id, v_user, 'member');
  perform app.emit_event('space_joined', v_user, 'client', 'server', v_space.country_code, 'space',
    v_space.id::text, '{}'::jsonb);
  return app.space_json(v_space.id, v_user);
end
$fn$;

-- Rôle d'un membre (responsable seulement ; la responsable reste `payer`).
create or replace function public.set_space_role(p_space uuid, p_user uuid, p_role text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if not exists (select 1 from public.spaces where id = p_space and owner_id = v_user) then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if p_role not in ('payer', 'member') then raise exception 'invalid_role' using errcode = '22023'; end if;
  if p_user = v_user then raise exception 'owner_is_payer' using errcode = '22023'; end if;
  update public.space_members set role = p_role where space_id = p_space and user_id = p_user;
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  return app.space_json(p_space, v_user);
end
$fn$;

-- Retire un membre (responsable) ou quitte l'espace (soi-même) ; la responsable ne quitte pas.
create or replace function public.remove_space_member(p_space uuid, p_user uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_owner uuid := (select owner_id from public.spaces where id = p_space);
begin
  if p_user = v_owner then raise exception 'owner_cannot_leave' using errcode = '22023'; end if;
  if p_user <> v_user and v_user is distinct from v_owner then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  delete from public.space_members where space_id = p_space and user_id = p_user;
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
end
$fn$;

create or replace function public.delete_space(p_space uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
begin
  delete from public.spaces where id = p_space and owner_id = app.require_user();
  if not found then raise exception 'not_allowed' using errcode = '42501'; end if;
end
$fn$;

-- ------------------------------------------------------------------ panier commun

-- Envoie le panier de la personne dans l'espace (quantités additionnées, 99 au plus) et le vide.
create or replace function public.send_cart_to_space(p_space uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_space public.spaces;
  v_cart public.carts;
  v_count int;
begin
  select * into v_space from public.spaces where id = p_space;
  if v_space.id is null or app.space_role(p_space, v_user) is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  select * into v_cart from public.carts where user_id = v_user;
  if v_cart.id is null or not exists (select 1 from public.cart_items where cart_id = v_cart.id) then
    raise exception 'cart_empty' using errcode = '22023';
  end if;
  if v_cart.country_code <> v_space.country_code then
    raise exception 'other_country' using errcode = '22023';
  end if;
  insert into public.space_items (space_id, variant_id, quantity, added_by)
  select p_space, i.variant_id, i.quantity, v_user from public.cart_items i where i.cart_id = v_cart.id
  on conflict (space_id, variant_id) do update
    set quantity = least(99, public.space_items.quantity + excluded.quantity), added_by = excluded.added_by,
        added_at = clock_timestamp();
  get diagnostics v_count = row_count;
  delete from public.cart_items where cart_id = v_cart.id;
  return app.space_json(p_space, v_user) || jsonb_build_object('sent', v_count);
end
$fn$;

-- Quantité d'un article du panier commun (0 : retiré) ; tout membre.
create or replace function public.set_space_item(p_space uuid, p_variant uuid, p_quantity int) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if app.space_role(p_space, v_user) is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if p_quantity is null or p_quantity not between 0 and 99 then
    raise exception 'invalid_quantity' using errcode = '22023';
  end if;
  if p_quantity = 0 then
    delete from public.space_items where space_id = p_space and variant_id = p_variant;
  else
    update public.space_items set quantity = p_quantity where space_id = p_space and variant_id = p_variant;
  end if;
  return app.space_json(p_space, v_user);
end
$fn$;

-- Validation par une personne qui valide : budget du mois vérifié, articles disponibles passés dans
-- son panier (règles de `cart_add`), retirés du panier commun ; les autres membres sont prévenus.
create or replace function public.validate_space(p_space uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_space public.spaces;
  v_item record;
  v_added int := 0;
  v_total bigint := 0;
  v_skipped jsonb := '[]'::jsonb;
  v_cart jsonb;
  v_price bigint;
  v_name text := (select first_name from public.profiles where user_id = v_user);
begin
  select * into v_space from public.spaces where id = p_space for update;
  if v_space.id is null or app.space_role(p_space, v_user) is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if app.space_role(p_space, v_user) <> 'payer' then raise exception 'not_payer' using errcode = '42501'; end if;
  if not exists (select 1 from public.space_items where space_id = p_space) then
    raise exception 'space_empty' using errcode = '22023';
  end if;
  if v_space.monthly_budget_minor is not null and app.space_spent_month(p_space) + (
       select coalesce(sum(app.variant_price(i.variant_id) * i.quantity), 0) from public.space_items i
       where i.space_id = p_space) > v_space.monthly_budget_minor then
    raise exception 'budget_exceeded' using errcode = '22023';
  end if;
  for v_item in
    select i.variant_id, i.quantity, p.name
    from public.space_items i
    join public.product_variants v on v.id = i.variant_id
    join public.products p on p.id = v.product_id
    where i.space_id = p_space order by i.added_at
  loop
    begin
      v_price := app.variant_price(v_item.variant_id);
      v_cart := public.cart_add(v_item.variant_id, v_item.quantity);
      delete from public.space_items where space_id = p_space and variant_id = v_item.variant_id;
      v_added := v_added + 1;
      v_total := v_total + v_price * v_item.quantity;
    exception when others then
      v_skipped := v_skipped || to_jsonb(v_item.name);
    end;
  end loop;
  if v_added > 0 then
    insert into public.space_validations (space_id, validated_by, items_count, total_minor)
    values (p_space, v_user, v_added, v_total);
    perform app.notify(m.user_id, 'space_validated', 'orders', null, null,
      jsonb_build_object('space_id', p_space, 'space_name', v_space.name, 'by_name', coalesce(v_name, '')))
    from public.space_members m where m.space_id = p_space and m.user_id <> v_user;
  end if;
  perform app.emit_event('space_validated', v_user, 'client', 'server', v_space.country_code, 'space',
    p_space::text, jsonb_build_object('added', v_added, 'skipped', jsonb_array_length(v_skipped),
      'amount_minor', v_total));
  return jsonb_build_object('added', v_added, 'skipped', v_skipped, 'cart', coalesce(v_cart, public.my_cart()));
end
$fn$;

insert into public.notification_templates (kind, locale, title, body) values
  ('space_validated', 'fr', 'Panier commun validé', '{by_name} a validé le panier de « {space_name} ».'),
  ('space_validated', 'en', 'Shared basket confirmed', '{by_name} confirmed the “{space_name}” basket.')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('space_created', 'server', 'Espace créé (budget : oui/non)'),
  ('space_joined', 'server', 'Espace rejoint avec un code'),
  ('space_validated', 'server', 'Panier commun validé (articles, montant)')
on conflict do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function app.space_role(uuid, uuid), app.space_spent_month(uuid, timestamptz),
  app.space_items_json(uuid), app.space_json(uuid, uuid), public.my_spaces(), public.space_detail(uuid),
  public.create_space(text, bigint), public.update_space(uuid, text, bigint), public.join_space(text),
  public.set_space_role(uuid, uuid, text), public.remove_space_member(uuid, uuid),
  public.delete_space(uuid), public.send_cart_to_space(uuid), public.set_space_item(uuid, uuid, int),
  public.validate_space(uuid) from public;
-- La politique RLS appelle `app.space_role` au nom de la personne connectée.
grant execute on function app.space_role(uuid, uuid) to authenticated;
grant execute on function public.my_spaces(), public.space_detail(uuid), public.create_space(text, bigint),
  public.update_space(uuid, text, bigint), public.join_space(text), public.set_space_role(uuid, uuid, text),
  public.remove_space_member(uuid, uuid), public.delete_space(uuid), public.send_cart_to_space(uuid),
  public.set_space_item(uuid, uuid, int), public.validate_space(uuid) to authenticated;
