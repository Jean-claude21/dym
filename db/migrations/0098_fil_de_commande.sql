-- 0098 — Fil de commande (spec 109) : pendant une livraison, la cliente, la boutique et le livreur
-- échangent dans une même conversation liée à la commande. Elle s'ouvre quand un livreur est
-- affecté et passe en lecture seule 24 h après la remise (ou à l'annulation, au refus).

alter table public.conversations
  add column order_id uuid unique references public.orders (id) on delete cascade,
  add column courier_id uuid references neon_auth."user" (id) on delete set null,
  add column courier_read_at timestamptz;

-- Une seule conversation directe par cliente et boutique ; les fils de commande à côté.
alter table public.conversations drop constraint conversations_store_id_client_id_key;
create unique index conversations_direct_key on public.conversations (store_id, client_id) where order_id is null;
create index conversations_courier_idx on public.conversations (courier_id) where courier_id is not null;

alter table public.messages drop constraint messages_author_role_check;
alter table public.messages add constraint messages_author_role_check
  check (author_role in ('client', 'vendor', 'courier'));

-- Fil fermé : 24 h après la remise, ou commande annulée ou refusée.
create or replace function app.order_thread_closed(p_order uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((
    select o.status in ('cancelled', 'refused')
        or (o.status = 'delivered' and coalesce(o.delivered_at, o.updated_at) < now() - interval '24 hours')
    from public.orders o where o.id = p_order), true)
$$;
revoke all on function app.order_thread_closed(uuid) from public;

-- Fil d'une commande : la cliente, la boutique (membre autorisé au chat) ou le livreur affecté.
-- Créé au premier accès dès qu'un livreur est affecté ; le livreur suit les réaffectations.
create or replace function public.order_thread(p_order uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_order public.orders;
  v_client uuid;
  v_courier uuid;
  v_role text;
  v_id uuid;
begin
  select o.* into v_order from public.orders o where o.id = p_order;
  select pu.user_id into v_client from public.purchases pu where pu.id = v_order.purchase_id;
  select oc.courier_id into v_courier from public.order_couriers oc where oc.order_id = p_order;
  v_role := case
    when v_order.id is null then null
    when v_client = v_user then 'client'
    when v_courier = v_user then 'courier'
    when app.store_can(v_user, v_order.store_id, 'chat') then 'vendor'
  end;
  if v_role is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if v_courier is null then
    raise exception 'no_courier' using errcode = 'P0001';
  end if;
  insert into public.conversations (store_id, client_id, order_id, courier_id)
  values (v_order.store_id, v_client, p_order, v_courier)
  on conflict (order_id) do update set courier_id = excluded.courier_id
  returning id into v_id;
  return app.conversation_json(v_id, v_role);
end
$$;
revoke all on function public.order_thread(uuid) from public;
grant execute on function public.order_thread(uuid) to authenticated;

insert into public.notification_templates (kind, locale, title, body) values
  ('new_message_courier', 'fr', 'Nouveau message', '{sender_name} t''a écrit.'),
  ('new_message_courier', 'en', 'New message', '{sender_name} sent you a message.')
on conflict do nothing;

-- Définitions reprises et étendues.

create or replace function app.conversation_role(p_user uuid, p_conversation uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select case
    when c.client_id = p_user then 'client'
    -- Fil de commande (spec 109) : le livreur affecté.
    when c.courier_id is not null and c.courier_id = p_user then 'courier'
    when app.store_can(p_user, s.id, 'chat') then 'vendor'
  end
  from public.conversations c
  join public.stores s on s.id = c.store_id
  where c.id = p_conversation
$function$
;

create or replace function app.conversation_json(p_conversation uuid, p_role text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'id', c.id, 'store_id', s.id, 'store_name', s.name, 'store_origin', s.origin,
    'store_active', s.status = 'active',
    'client_first_name', (select first_name from public.profiles where user_id = c.client_id),
    'last_message_at', c.last_message_at,
    'last_message', (select app.message_json(m.id) from public.messages m
                     where m.conversation_id = c.id order by m.created_at desc, m.id desc limit 1),
    'unread', (select count(*) from public.messages m
               where m.conversation_id = c.id and m.author_role <> p_role
                 and m.created_at > coalesce(case p_role when 'client' then c.client_read_at
                                                         when 'courier' then c.courier_read_at
                                                         else c.vendor_read_at end, '-infinity')),
    -- Fil de commande (spec 109).
    'order_id', c.order_id,
    'courier_name', (select split_part(cp.display_name, ' ', 1) from public.courier_profiles cp
                     where cp.user_id = c.courier_id),
    'closed', c.order_id is not null and app.order_thread_closed(c.order_id))
  from public.conversations c
  join public.stores s on s.id = c.store_id
  where c.id = p_conversation
$function$
;

create or replace function public.conversation(p_id uuid, p_before timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limit integer DEFAULT 50)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.require_user();
  v_role text := app.conversation_role(v_user, p_id);
begin
  if v_role is null then
    raise exception 'conversation introuvable' using errcode = 'P0002';
  end if;
  update public.conversations set
    client_read_at = case when v_role = 'client' then clock_timestamp() else client_read_at end,
    vendor_read_at = case when v_role = 'vendor' then clock_timestamp() else vendor_read_at end,
    courier_read_at = case when v_role = 'courier' then clock_timestamp() else courier_read_at end
  where id = p_id;
  return app.conversation_json(p_id, v_role) || jsonb_build_object(
    'role', v_role,
    -- Lecture de l'autre personne : les messages envoyés avant sont « vus ».
    -- Fil de commande : « vu » quand tous les autres ont lu.
    'peer_read_at', (select case
                       when order_id is null then
                         case v_role when 'client' then vendor_read_at else client_read_at end
                       when v_role = 'client' then least(vendor_read_at, courier_read_at)
                       when v_role = 'vendor' then least(client_read_at, courier_read_at)
                       else least(client_read_at, vendor_read_at) end
                     from public.conversations where id = p_id),
    'active_order', coalesce((
      select jsonb_build_object('id', o.id, 'status', o.status, 'created_at', o.created_at,
                                'total_minor', o.total_minor, 'currency_code', o.currency_code)
      from public.conversations c2 join public.orders o on o.id = c2.order_id where c2.id = p_id),
      app.conversation_active_order(p_id)),
    'messages', (select coalesce(jsonb_agg(app.message_json(x.id) order by x.created_at, x.id), '[]'::jsonb)
                 from (select id, created_at from public.messages
                       where conversation_id = p_id and (p_before is null or created_at < p_before)
                       order by created_at desc, id desc
                       limit least(greatest(coalesce(p_limit, 50), 1), 200)) x));
end
$function$
;

create or replace function app.send_message(p_user uuid, p_conversation uuid, p_kind text, p_body text, p_media_key text, p_product uuid, p_key uuid, p_duration_ms integer DEFAULT NULL::integer, p_payload jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_role text := app.conversation_role(p_user, p_conversation);
  v_conv public.conversations;
  v_store public.stores;
  v_id uuid;
  v_body text := nullif(trim(p_body), '');
  v_recipient uuid;
  v_sender text;
  v_rkind text;
  v_live integer := coalesce((p_payload ->> 'live_minutes')::integer, 0);
begin
  if v_role is null then
    raise exception 'conversation introuvable' using errcode = 'P0002';
  end if;
  if p_key is null or p_kind is null or p_kind not in
     ('text', 'image', 'product', 'audio', 'video', 'location', 'quote', 'payment_request', 'coupon') then
    raise exception 'message_invalid' using errcode = 'P0001';
  end if;
  -- Devis, demande de paiement, coupon : la boutique seulement, par leurs fonctions.
  if p_kind in ('quote', 'payment_request', 'coupon') and v_role <> 'vendor' then
    raise exception 'message_invalid' using errcode = 'P0001';
  end if;
  select id into v_id from public.messages
  where conversation_id = p_conversation and author_role = v_role and idempotency_key = p_key;
  if v_id is not null then
    return app.message_json(v_id);
  end if;
  select * into v_conv from public.conversations where id = p_conversation for update;
  select * into v_store from public.stores where id = v_conv.store_id;
  -- Fil de commande (spec 109) : fermé après la livraison ; le livreur écrit, photographie, parle,
  -- partage sa position (ni fiche, ni devis).
  if v_conv.order_id is not null and app.order_thread_closed(v_conv.order_id) then
    raise exception 'conversation_closed' using errcode = 'P0001';
  end if;
  if v_role = 'courier' and p_kind not in ('text', 'image', 'audio', 'video', 'location') then
    raise exception 'message_invalid' using errcode = 'P0001';
  end if;
  if p_kind = 'text' and (v_body is null or length(v_body) > 1000) then
    raise exception 'message_invalid' using errcode = 'P0001';
  end if;
  if p_kind = 'image' and (p_media_key is null
      or p_media_key !~ ('^chats/' || p_conversation || '/[0-9a-f-]{36}\.(jpg|webp)$')) then
    raise exception 'media_invalid' using errcode = 'P0001';
  end if;
  if p_kind = 'audio' and (p_media_key is null or p_duration_ms is null
      or p_duration_ms not between 500 and 60000
      or p_media_key !~ ('^chats/' || p_conversation || '/[0-9a-f-]{36}\.(wav|m4a|webm|ogg)$')) then
    raise exception 'media_invalid' using errcode = 'P0001';
  end if;
  -- Vidéo enregistrée ou partagée : une minute au plus (spec 099).
  if p_kind = 'video' and (p_media_key is null
      or coalesce(p_duration_ms, 500) not between 500 and 60000
      or p_media_key !~ ('^chats/' || p_conversation || '/[0-9a-f-]{36}\.(mp4|webm|mov)$')) then
    raise exception 'media_invalid' using errcode = 'P0001';
  end if;
  if p_kind = 'location' and (
      (p_payload ->> 'latitude')::numeric is null or (p_payload ->> 'longitude')::numeric is null
      or (p_payload ->> 'latitude')::numeric not between -90 and 90
      or (p_payload ->> 'longitude')::numeric not between -180 and 180
      or v_live not between 0 and 60) then
    raise exception 'location_invalid' using errcode = 'P0001';
  end if;
  if p_kind = 'product' and not exists (
    select 1 from public.products p
    where p.id = p_product and p.store_id = v_conv.store_id and p.status = 'published') then
    raise exception 'product_invalid' using errcode = 'P0001';
  end if;

  insert into public.messages (conversation_id, author_id, author_role, kind, body, media_key,
                               product_id, idempotency_key, duration_ms, payload, live_until)
  values (p_conversation, p_user, v_role, p_kind,
          case when p_kind in ('text', 'video') then v_body end,
          case when p_kind in ('image', 'audio', 'video') then p_media_key end,
          case when p_kind = 'product' then p_product end, p_key,
          case when p_kind in ('audio', 'video') then p_duration_ms end,
          case when p_kind = 'location' then jsonb_build_object(
                 'latitude', round((p_payload ->> 'latitude')::numeric, 6),
                 'longitude', round((p_payload ->> 'longitude')::numeric, 6))
               when p_kind in ('quote', 'payment_request', 'coupon') then p_payload end,
          case when p_kind = 'location' and v_live > 0
               then clock_timestamp() + make_interval(mins => v_live) end)
  returning id into v_id;
  if p_kind = 'audio' then
    perform app.emit_event('voice_message_sent', p_user, v_role, 'server',
      (select country_code from public.profiles where user_id = p_user), 'message', v_id::text,
      jsonb_build_object('duration_ms', p_duration_ms));
  end if;
  update public.conversations set
    last_message_at = clock_timestamp(),
    client_read_at = case when v_role = 'client' then clock_timestamp() else client_read_at end,
    vendor_read_at = case when v_role = 'vendor' then clock_timestamp() else vendor_read_at end,
    courier_read_at = case when v_role = 'courier' then clock_timestamp() else courier_read_at end
  where id = p_conversation;

  -- Destinataires prévenus (tous les autres participants), sans le contenu du message.
  v_sender := case v_role
    when 'client' then (select first_name from public.profiles where user_id = p_user)
    when 'courier' then (select split_part(display_name, ' ', 1) from public.courier_profiles where user_id = p_user)
    else v_store.name end;
  for v_recipient, v_rkind in
    select x.u, x.k from (values (v_conv.client_id, 'new_message', 'client'),
                                 (v_store.owner_id, 'new_message_vendor', 'vendor'),
                                 (v_conv.courier_id, 'new_message_courier', 'courier')) x(u, k, r)
    where x.r <> v_role and x.u is not null and x.u <> p_user
  loop
    perform app.notify(v_recipient, v_rkind, 'messages', null, null,
      jsonb_build_object('sender_name', coalesce(v_sender, ''), 'conversation_id', p_conversation));
  end loop;
  return app.message_json(v_id);
end
$function$
;

create or replace function app.live_on_message()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  insert into public.live_events (user_id, kind, entity_id, payload)
  select u.id, 'message', new.conversation_id,
         jsonb_build_object('message_id', new.id, 'author_role', new.author_role)
  from public.conversations c
  join public.stores s on s.id = c.store_id
  cross join lateral (values (c.client_id), (s.owner_id), (c.courier_id)) u(id)
  where c.id = new.conversation_id and u.id is not null;
  return null;
end
$function$
;

create or replace function public.my_conversations(p_role text DEFAULT 'client'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.require_user();
  v_store uuid;
begin
  if p_role is null or p_role not in ('client', 'vendor', 'courier') then
    raise exception 'rôle inconnu' using errcode = '22023';
  end if;
  if p_role = 'vendor' then
    v_store := app.own_store_id();
  end if;
  return (
    select coalesce(jsonb_agg(app.conversation_json(c.id, p_role)
             order by coalesce(c.last_message_at, c.created_at) desc), '[]'::jsonb)
    from public.conversations c
    where (p_role = 'client' and c.client_id = v_user)
       or (p_role = 'vendor' and c.store_id = v_store)
       or (p_role = 'courier' and c.courier_id = v_user));
end
$function$
;

create or replace function public.unread_messages_count(p_role text DEFAULT 'client'::text)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.require_user();
  v_store uuid;
begin
  if p_role is null or p_role not in ('client', 'vendor', 'courier') then
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
      and ((p_role = 'client' and c.client_id = v_user) or (p_role = 'vendor' and c.store_id = v_store)
           or (p_role = 'courier' and c.courier_id = v_user))
      and m.created_at > coalesce(case p_role when 'client' then c.client_read_at
                                              when 'courier' then c.courier_read_at
                                              else c.vendor_read_at end, '-infinity'));
end
$function$
;

create or replace function app.start_conversation(p_user uuid, p_store uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_store public.stores;
  v_id uuid;
begin
  if p_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  select * into v_store from public.stores where id = p_store;
  if v_store.id is null then
    raise exception 'boutique introuvable' using errcode = 'P0002';
  end if;
  if v_store.owner_id = p_user then
    raise exception 'own_store' using errcode = 'P0001';
  end if;
  select id into v_id from public.conversations where store_id = p_store and client_id = p_user and order_id is null;
  if v_id is null then
    if v_store.status <> 'active' then
      raise exception 'store_unavailable' using errcode = 'P0001';
    end if;
    insert into public.conversations (store_id, client_id) values (p_store, p_user)
    on conflict (store_id, client_id) where order_id is null do nothing
    returning id into v_id;
    if v_id is null then
      select id into v_id from public.conversations where store_id = p_store and client_id = p_user and order_id is null;
    end if;
  end if;
  return app.conversation_json(v_id, 'client');
end
$function$
;
