-- 0082 — Personnel des boutiques et succursales (spec 087).
-- La propriétaire invite du personnel par email avec un rôle : gérante (tout sauf l'argent, les
-- réglages de la boutique et l'équipe), préparatrice (commandes, chat), caissière (caisse,
-- commandes). Une même personne peut travailler pour plusieurs boutiques (succursales d'une
-- enseigne : une boutique par lieu) et choisit sa boutique active.
-- La garde commune `app.own_store_id` exige, pour le personnel, la permission de la fonction
-- appelante (`store_function_permissions`) ; une fonction non déclarée reste réservée à la
-- propriétaire (sûr par défaut). Argent, réglages et équipe : propriétaire seulement.

create table public.store_members (
  store_id uuid not null references public.stores (id) on delete cascade,
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  role text not null check (role in ('manager', 'preparer', 'cashier')),
  invited_by uuid,
  created_at timestamptz not null default now(),
  primary key (store_id, user_id)
);
create index store_members_user on public.store_members (user_id);

create table public.store_invites (
  store_id uuid not null references public.stores (id) on delete cascade,
  email text not null check (email = lower(email) and email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  role text not null check (role in ('manager', 'preparer', 'cashier')),
  invited_by uuid,
  created_at timestamptz not null default now(),
  primary key (store_id, email)
);

create table public.store_role_permissions (
  role text not null,
  permission text not null check (permission ~ '^[a-z_]+$'),
  primary key (role, permission)
);

create table public.store_function_permissions (
  function_name text primary key check (function_name ~ '^(public|app)\.[a-z_]+$'),
  permission text not null
);

create table public.vendor_active_store (
  user_id uuid primary key references neon_auth."user" (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  updated_at timestamptz not null default now()
);

alter table public.store_members enable row level security;
alter table public.store_invites enable row level security;
alter table public.store_role_permissions enable row level security;
alter table public.store_function_permissions enable row level security;
alter table public.vendor_active_store enable row level security;
revoke all on public.store_members, public.store_invites, public.store_role_permissions,
  public.store_function_permissions, public.vendor_active_store from authenticated, anonymous;

insert into public.store_role_permissions (role, permission) values
  ('manager', 'orders'), ('manager', 'catalog'), ('manager', 'chat'), ('manager', 'till'),
  ('manager', 'offers'),
  ('preparer', 'orders'), ('preparer', 'chat'),
  ('cashier', 'till'), ('cashier', 'orders');

insert into public.store_function_permissions (function_name, permission) values
  ('app.own_product', 'catalog'), ('public.archive_store_category', 'catalog'),
  ('public.import_products', 'catalog'), ('public.my_products', 'catalog'),
  ('public.my_store_categories', 'catalog'), ('public.reorder_store_categories', 'catalog'),
  ('public.save_product', 'catalog'), ('public.save_store_category', 'catalog'),
  ('public.set_product_arrival', 'catalog'), ('public.set_product_storage', 'catalog'),
  ('public.my_store_order', 'orders'), ('public.my_store_orders', 'orders'),
  ('public.my_store_reviews', 'orders'), ('public.confirm_courier_cash', 'orders'),
  ('public.store_courier_cash', 'orders'), ('public.my_vendor_dashboard', 'orders'),
  ('public.set_store_open', 'orders'),
  ('public.my_conversations', 'chat'), ('public.my_haggling', 'chat'),
  ('public.my_till', 'till'), ('public.record_till_sale', 'till'), ('public.void_till_sale', 'till'),
  ('public.till_parse', 'till'), ('public.create_payment_request', 'till'),
  ('public.cancel_payment_request', 'till'), ('public.my_payment_request', 'till'),
  ('public.save_credit', 'till'), ('public.my_credits', 'till'), ('app.own_credit', 'till'),
  ('public.cancel_group_offer', 'offers'), ('public.create_group_offer', 'offers'),
  ('public.my_group_offers', 'offers'), ('public.clear_end_of_market', 'offers'),
  ('public.my_end_of_market', 'offers'), ('public.set_end_of_market', 'offers'),
  ('public.commit_wholesale', 'offers'), ('public.create_wholesale_offer', 'offers'),
  ('public.decide_wholesale_offer', 'offers'), ('public.wholesale_board', 'offers'),
  ('public.set_haggle_limit', 'offers');
-- Réglages (zones, horaires, paiements, adresse, publication), argent (versements, abonnement,
-- affiliation) et équipe : aucune entrée, donc propriétaire seulement.

-- ------------------------------------------------------------------ accès

-- Boutique active d'une personne : choisie (si elle y a toujours accès), sinon la sienne, sinon
-- la première où elle travaille.
create or replace function app.member_store_id(p_user uuid) returns uuid
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    (select a.store_id from public.vendor_active_store a
     where a.user_id = p_user
       and (exists (select 1 from public.stores s where s.id = a.store_id and s.owner_id = p_user)
            or exists (select 1 from public.store_members m where m.store_id = a.store_id and m.user_id = p_user))),
    (select id from public.stores where owner_id = p_user),
    (select store_id from public.store_members where user_id = p_user order by created_at limit 1))
$$;

-- Rôle dans une boutique : 'owner', rôle du personnel, ou null.
create or replace function app.store_role(p_user uuid, p_store uuid) returns text
language sql stable security definer set search_path = ''
as $$
  select case
    when exists (select 1 from public.stores where id = p_store and owner_id = p_user) then 'owner'
    else (select role from public.store_members where store_id = p_store and user_id = p_user)
  end
$$;

create or replace function app.store_can(p_user uuid, p_store uuid, p_permission text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select case app.store_role(p_user, p_store)
    when 'owner' then true
    when null then false
    else exists (select 1 from public.store_role_permissions
                 where role = app.store_role(p_user, p_store) and permission = p_permission)
  end
$$;

-- Permissions affichées à l'app vendeuse (la propriétaire a tout).
create or replace function app.store_permissions(p_user uuid, p_store uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select case app.store_role(p_user, p_store)
    when 'owner' then '["orders", "catalog", "chat", "till", "offers", "settings", "finance", "staff"]'::jsonb
    else coalesce((select jsonb_agg(permission order by permission) from public.store_role_permissions
                   where role = app.store_role(p_user, p_store)), '[]'::jsonb)
  end
$$;

-- Fonctions de la pile d'appels, de la plus proche à la plus lointaine. PL/pgSQL : « function
-- public.nom( » ; SQL : « SQL function "nom" » (sans schéma : public puis app).
create or replace function app.context_functions(p_context text) returns setof text
language sql immutable set search_path = ''
as $$
  select n from (
    select m, ord from regexp_matches(p_context,
      '(?:function ((?:public|app)\.[a-z_]+)\(|SQL function "([a-z_]+)")', 'g') with ordinality as r(m, ord)
  ) x
  cross join lateral (
    select x.m[1] as n, 0 as k where x.m[1] is not null
    union all select 'public.' || x.m[2], 1 where x.m[2] is not null
    union all select 'app.' || x.m[2], 2 where x.m[2] is not null
  ) names
  order by x.ord, names.k
$$;

-- Permission exigée par la fonction vendeuse appelante (pile d'appels) ; inconnue : null.
create or replace function app.store_required_permission(p_context text) returns text
language sql stable security definer set search_path = ''
as $$
  select f.permission from app.context_functions(p_context) with ordinality c(name, ord)
  join public.store_function_permissions f on f.function_name = c.name
  order by c.ord limit 1
$$;

-- Même lecture de la pile pour la garde admin (spec 085) : les fonctions admin écrites en SQL
-- simple n'étaient pas reconnues (réservées au super-admin par prudence).
create or replace function app.admin_required_permission(p_context text) returns text
language sql stable security definer set search_path = ''
as $$
  select f.permission_code from app.context_functions(p_context) with ordinality c(name, ord)
  join public.admin_function_permissions f on f.function_name = c.name
  order by c.ord limit 1
$$;

create or replace function app.own_store_id() returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.current_user_id();
  v_store uuid := app.member_store_id(v_user);
  v_context text;
  v_permission text;
begin
  if v_store is null then
    raise exception 'aucune boutique' using errcode = 'P0002';
  end if;
  if app.store_role(v_user, v_store) <> 'owner' then
    get diagnostics v_context = pg_context;
    v_permission := app.store_required_permission(v_context);
    if v_permission is null or not app.store_can(v_user, v_store, v_permission) then
      raise exception 'permission_denied' using errcode = '42501';
    end if;
  end if;
  return v_store;
end
$$;

-- ------------------------------------------------------------------ équipe

-- Mes boutiques (la mienne et celles où je travaille) ; les invitations reçues sont acceptées.
create or replace function public.my_stores() returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_email text := (select lower(email) from neon_auth."user" where id = v_user and "emailVerified");
  v_active uuid;
begin
  if v_email is not null then
    insert into public.store_members (store_id, user_id, role, invited_by)
    select i.store_id, v_user, i.role, i.invited_by from public.store_invites i
    where i.email = v_email
      and not exists (select 1 from public.stores s where s.id = i.store_id and s.owner_id = v_user)
    on conflict (store_id, user_id) do nothing;
    delete from public.store_invites where email = v_email;
  end if;
  v_active := app.member_store_id(v_user);
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', s.id, 'name', s.name, 'role', app.store_role(v_user, s.id),
      'active', s.id = v_active) order by s.id <> v_active, s.name)
    from public.stores s
    where s.owner_id = v_user
       or exists (select 1 from public.store_members m where m.store_id = s.id and m.user_id = v_user)), '[]'::jsonb);
end
$$;

create or replace function public.set_active_store(p_store uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  if app.store_role(v_user, p_store) is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  insert into public.vendor_active_store (user_id, store_id) values (v_user, p_store)
  on conflict (user_id) do update set store_id = excluded.store_id, updated_at = now();
  return public.my_stores();
end
$$;

-- Équipe de ma boutique (propriétaire).
create or replace function public.my_store_staff() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_store_id();
begin
  return coalesce((
    select jsonb_agg(x order by x ->> 'status', x ->> 'email') from (
      select jsonb_build_object('email', lower(u.email), 'first_name', p.first_name, 'role', m.role,
        'status', 'active', 'since', m.created_at) as x
      from public.store_members m
      join neon_auth."user" u on u.id = m.user_id
      left join public.profiles p on p.user_id = m.user_id
      where m.store_id = v_store
      union all
      select jsonb_build_object('email', i.email, 'first_name', null, 'role', i.role,
        'status', 'invited', 'since', i.created_at)
      from public.store_invites i where i.store_id = v_store) t), '[]'::jsonb);
end
$$;

create or replace function public.invite_store_staff(p_email text, p_role text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_owner uuid := app.require_user();
  v_store uuid := app.own_store_id();
  v_email text := lower(trim(coalesce(p_email, '')));
  v_user uuid;
begin
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then raise exception 'email_invalid' using errcode = '22023'; end if;
  if p_role not in ('manager', 'preparer', 'cashier') then raise exception 'role_unknown' using errcode = '22023'; end if;
  select id into v_user from neon_auth."user" where lower(email) = v_email and "emailVerified";
  if v_user = v_owner then raise exception 'own_store' using errcode = 'P0001'; end if;
  if v_user is not null then
    insert into public.store_members (store_id, user_id, role, invited_by) values (v_store, v_user, p_role, v_owner)
    on conflict (store_id, user_id) do update set role = excluded.role;
  else
    insert into public.store_invites (store_id, email, role, invited_by) values (v_store, v_email, p_role, v_owner)
    on conflict (store_id, email) do update set role = excluded.role;
  end if;
  perform app.audit(v_owner, 'store_staff_invited', 'store', v_store::text, null,
    jsonb_build_object('role', p_role), null);
  return public.my_store_staff();
end
$$;

create or replace function public.remove_store_staff(p_email text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_owner uuid := app.require_user();
  v_store uuid := app.own_store_id();
  v_email text := lower(trim(coalesce(p_email, '')));
begin
  delete from public.store_members m using neon_auth."user" u
  where m.store_id = v_store and u.id = m.user_id and lower(u.email) = v_email;
  delete from public.store_invites where store_id = v_store and email = v_email;
  delete from public.vendor_active_store a using neon_auth."user" u
  where a.store_id = v_store and u.id = a.user_id and lower(u.email) = v_email;
  perform app.audit(v_owner, 'store_staff_removed', 'store', v_store::text, null, null, null);
  return public.my_store_staff();
end
$$;

-- ------------------------------------------------------------------ contrôles alignés
-- Ces fonctions vérifiaient la propriétaire ; elles acceptent le personnel autorisé.

CREATE OR REPLACE FUNCTION public.my_store()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select case when s.id is null then null else
    to_jsonb(s) - 'owner_id' - 'search'
    || jsonb_build_object(
      'staff_role', app.store_role(app.current_user_id(), s.id),
      'staff_permissions', app.store_permissions(app.current_user_id(), s.id),
      'pickup_address', (select to_jsonb(a) - 'store_id' from public.store_pickup_addresses a where a.store_id = s.id),
      'delivery_zone_ids', coalesce((select jsonb_agg(z.zone_id) from public.store_delivery_zones z where z.store_id = s.id), '[]'::jsonb),
      'payment_method_ids', coalesce((select jsonb_agg(p.payment_method_id) from public.store_payment_methods p where p.store_id = s.id), '[]'::jsonb),
      'hours', coalesce((select jsonb_agg(jsonb_build_object('weekday', h.weekday, 'opens_at', to_char(h.opens_at, 'HH24:MI'), 'closes_at', to_char(h.closes_at, 'HH24:MI')) order by h.weekday) from public.store_hours h where h.store_id = s.id), '[]'::jsonb),
      'missing', to_jsonb(app.store_missing(s.id))
    )
  end
  from (select 1) one
  left join public.stores s on s.id = app.member_store_id(app.current_user_id())
$function$

;
CREATE OR REPLACE FUNCTION public.my_store_open_now()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(
    (select app.store_open_at(s.id, now())
     from public.stores s where s.id = app.member_store_id(app.current_user_id())),
    false)
$function$

;
CREATE OR REPLACE FUNCTION public.unread_messages_count(p_role text DEFAULT 'client'::text)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.require_user();
  v_store uuid;
begin
  if p_role is null or p_role not in ('client', 'vendor') then
    raise exception 'rôle inconnu' using errcode = '22023';
  end if;
  if p_role = 'vendor' then
    v_store := app.member_store_id(v_user);
    if not app.store_can(v_user, v_store, 'chat') then v_store := null; end if;
    if v_store is null then
      return 0;
    end if;
  end if;
  return (
    select count(*) from public.messages m
    join public.conversations c on c.id = m.conversation_id
    where m.author_role <> p_role
      and ((p_role = 'client' and c.client_id = v_user) or (p_role = 'vendor' and c.store_id = v_store))
      and m.created_at > coalesce(case p_role when 'client' then c.client_read_at
                                              else c.vendor_read_at end, '-infinity'));
end
$function$

;
CREATE OR REPLACE FUNCTION app.photo_upload_store(p_user uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_store public.stores;
begin
  select * into v_store from public.stores
  where id = app.member_store_id(p_user) and app.store_can(p_user, id, 'catalog');
  if v_store.id is null then
    raise exception 'aucune boutique' using errcode = 'P0002';
  end if;
  if v_store.status = 'suspended' then
    raise exception 'boutique suspendue' using errcode = '42501';
  end if;
  return v_store.id;
end
$function$

;
CREATE OR REPLACE FUNCTION app.confirm_cash(p_user uuid, p_order uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_order public.orders;
begin
  select o.* into v_order from public.orders o
  join public.stores s on s.id = o.store_id
  where o.id = p_order and app.store_can(p_user, s.id, 'orders')
  for update of o;
  if v_order.id is null then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  if (select payment_status from public.purchases where id = v_order.purchase_id) <> 'cash_on_delivery' then
    raise exception 'not_cash' using errcode = 'P0001';
  end if;
  if v_order.status <> 'delivered' then
    raise exception 'not_delivered' using errcode = 'P0001';
  end if;
  if v_order.cash_collected_at is null then
    update public.orders set cash_collected_at = now() where id = p_order;
  end if;
  return app.order_json(p_order, 'vendor');
end
$function$

;
CREATE OR REPLACE FUNCTION app.reply_review(p_user uuid, p_review uuid, p_reply text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_review public.reviews;
  v_client uuid;
  v_text text := left(nullif(trim(p_reply), ''), 500);
begin
  select r.* into v_review from public.reviews r
  join public.stores s on s.id = r.store_id
  where r.id = p_review and app.store_can(p_user, s.id, 'orders');
  if v_review.id is null then
    raise exception 'avis introuvable' using errcode = 'P0002';
  end if;
  if v_text is null then
    raise exception 'reply_invalid' using errcode = 'P0001';
  end if;
  update public.reviews set reply = v_text, replied_at = now() where id = p_review;
  select p.user_id into v_client from public.orders o
  join public.purchases p on p.id = o.purchase_id where o.id = v_review.order_id;
  perform app.notify(v_client, 'review_replied', 'orders', v_review.order_id, null,
    jsonb_build_object('store_name', (select name from public.stores where id = v_review.store_id)));
  return app.review_json(p_review);
end
$function$

;
CREATE OR REPLACE FUNCTION app.order_party(p_user uuid, p_order uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select case
    when exists (select 1 from public.orders o join public.purchases pu on pu.id = o.purchase_id
                 where o.id = p_order and pu.user_id = p_user) then 'client'
    when exists (select 1 from public.orders o join public.stores s on s.id = o.store_id
                 where o.id = p_order and app.store_can(p_user, s.id, 'orders')) then 'vendor' end
$function$

;
CREATE OR REPLACE FUNCTION app.conversation_role(p_user uuid, p_conversation uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select case
    when c.client_id = p_user then 'client'
    when app.store_can(p_user, s.id, 'chat') then 'vendor'
  end
  from public.conversations c
  join public.stores s on s.id = c.store_id
  where c.id = p_conversation
$function$

;

-- ------------------------------------------------------------------ droits

revoke all on function app.context_functions(text), app.member_store_id(uuid), app.store_role(uuid, uuid),
  app.store_can(uuid, uuid, text), app.store_permissions(uuid, uuid),
  app.store_required_permission(text), public.my_stores(), public.set_active_store(uuid),
  public.my_store_staff(), public.invite_store_staff(text, text), public.remove_store_staff(text)
from public;
grant execute on function public.my_stores(), public.set_active_store(uuid), public.my_store_staff(),
  public.invite_store_staff(text, text), public.remove_store_staff(text) to authenticated;
