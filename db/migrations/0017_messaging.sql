-- 0017 — Messagerie cliente ↔ vendeuse (spec 015 : C-CHAT-01/02/04, V-MSG-01..04, V-DASH-04).
-- Une conversation par (cliente, boutique). Lectures par la Data API (fonctions
-- qui vérifient la participation) ; envois par la Function (notifications,
-- push, images signées). Les images vivent dans un stockage privé.

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  client_id uuid not null references neon_auth."user" (id) on delete cascade,
  created_at timestamptz not null default clock_timestamp(),
  last_message_at timestamptz,
  client_read_at timestamptz,
  vendor_read_at timestamptz,
  unique (store_id, client_id)
);

create index conversations_client on public.conversations (client_id, last_message_at desc);
create index conversations_store on public.conversations (store_id, last_message_at desc);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  author_id uuid references neon_auth."user" (id) on delete set null,
  author_role text not null check (author_role in ('client', 'vendor')),
  kind text not null check (kind in ('text', 'image', 'product')),
  body text check (body is null or length(body) between 1 and 1000),
  media_key text check (media_key is null or length(media_key) <= 300),
  product_id uuid references public.products (id) on delete set null,
  idempotency_key uuid not null,
  created_at timestamptz not null default clock_timestamp(),
  unique (conversation_id, author_role, idempotency_key),
  check (kind <> 'text' or body is not null),
  check (kind <> 'image' or media_key is not null)
);

create index messages_conversation on public.messages (conversation_id, created_at desc);

alter table public.conversations enable row level security;
alter table public.messages enable row level security;
-- Lecture et écriture par fonctions seulement (participation vérifiée).

-- ------------------------------------------------------------------ règles

-- Rôle de [p_user] dans la conversation : client, vendor, ou nul.
create or replace function app.conversation_role(p_user uuid, p_conversation uuid) returns text
language sql stable security definer set search_path = ''
as $$
  select case
    when c.client_id = p_user then 'client'
    when s.owner_id = p_user then 'vendor'
  end
  from public.conversations c
  join public.stores s on s.id = c.store_id
  where c.id = p_conversation
$$;

create or replace function app.message_json(p_message uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', m.id, 'conversation_id', m.conversation_id, 'author_role', m.author_role,
    'kind', m.kind, 'body', m.body, 'has_media', m.media_key is not null,
    'product', case when m.product_id is not null then app.catalog_item(m.product_id) end,
    'product_id', m.product_id, 'created_at', m.created_at)
  from public.messages m
  where m.id = p_message
$$;

-- Résumé d'une conversation vu par [p_role].
create or replace function app.conversation_json(p_conversation uuid, p_role text) returns jsonb
language sql stable security definer set search_path = ''
as $$
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
                                                         else c.vendor_read_at end, '-infinity')))
  from public.conversations c
  join public.stores s on s.id = c.store_id
  where c.id = p_conversation
$$;

-- Ouvrir (ou retrouver) la conversation d'une cliente avec une boutique
-- active. Refus (P0001) : store_unavailable, own_store.
create or replace function app.start_conversation(p_user uuid, p_store uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
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
  select id into v_id from public.conversations where store_id = p_store and client_id = p_user;
  if v_id is null then
    if v_store.status <> 'active' then
      raise exception 'store_unavailable' using errcode = 'P0001';
    end if;
    insert into public.conversations (store_id, client_id) values (p_store, p_user)
    on conflict (store_id, client_id) do nothing
    returning id into v_id;
    if v_id is null then
      select id into v_id from public.conversations where store_id = p_store and client_id = p_user;
    end if;
  end if;
  return app.conversation_json(v_id, 'client');
end
$$;

-- Envoyer un message. Refus (P0001) : message_invalid, media_invalid,
-- product_invalid ; conversation d'autrui : P0002. Rejeu (même clé) : le
-- message existant est renvoyé, sans nouvelle notification.
create or replace function app.send_message(
  p_user uuid,
  p_conversation uuid,
  p_kind text,
  p_body text,
  p_media_key text,
  p_product uuid,
  p_key uuid
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_role text := app.conversation_role(p_user, p_conversation);
  v_conv public.conversations;
  v_store public.stores;
  v_id uuid;
  v_body text := nullif(trim(p_body), '');
  v_recipient uuid;
  v_sender text;
begin
  if v_role is null then
    raise exception 'conversation introuvable' using errcode = 'P0002';
  end if;
  if p_key is null or p_kind is null or p_kind not in ('text', 'image', 'product') then
    raise exception 'message_invalid' using errcode = 'P0001';
  end if;
  select id into v_id from public.messages
  where conversation_id = p_conversation and author_role = v_role and idempotency_key = p_key;
  if v_id is not null then
    return app.message_json(v_id);
  end if;
  select * into v_conv from public.conversations where id = p_conversation for update;
  select * into v_store from public.stores where id = v_conv.store_id;
  if p_kind = 'text' and (v_body is null or length(v_body) > 1000) then
    raise exception 'message_invalid' using errcode = 'P0001';
  end if;
  if p_kind = 'image' and (p_media_key is null
      or p_media_key !~ ('^chats/' || p_conversation || '/[0-9a-f-]{36}\.(jpg|webp)$')) then
    raise exception 'media_invalid' using errcode = 'P0001';
  end if;
  if p_kind = 'product' and not exists (
    select 1 from public.products p
    where p.id = p_product and p.store_id = v_conv.store_id and p.status = 'published') then
    raise exception 'product_invalid' using errcode = 'P0001';
  end if;

  insert into public.messages (conversation_id, author_id, author_role, kind, body, media_key,
                               product_id, idempotency_key)
  values (p_conversation, p_user, v_role, p_kind,
          case when p_kind = 'text' then v_body end,
          case when p_kind = 'image' then p_media_key end,
          case when p_kind = 'product' then p_product end, p_key)
  returning id into v_id;
  update public.conversations set
    last_message_at = clock_timestamp(),
    client_read_at = case when v_role = 'client' then clock_timestamp() else client_read_at end,
    vendor_read_at = case when v_role = 'vendor' then clock_timestamp() else vendor_read_at end
  where id = p_conversation;

  -- Destinataire prévenu, sans le contenu du message.
  if v_role = 'client' then
    v_recipient := v_store.owner_id;
    v_sender := (select first_name from public.profiles where user_id = p_user);
  else
    v_recipient := v_conv.client_id;
    v_sender := v_store.name;
  end if;
  perform app.notify(v_recipient, case when v_role = 'client' then 'new_message_vendor' else 'new_message' end,
    'messages', null, null,
    jsonb_build_object('sender_name', coalesce(v_sender, ''), 'conversation_id', p_conversation));
  return app.message_json(v_id);
end
$$;

-- Clés des images lisibles par [p_user] (liens signés par la Function).
create or replace function app.chat_media_keys(p_user uuid, p_messages uuid[]) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_object_agg(m.id, m.media_key), '{}'::jsonb)
  from public.messages m
  where m.id = any (coalesce(p_messages, '{}')) and m.media_key is not null
    and app.conversation_role(p_user, m.conversation_id) is not null
$$;

-- Espace d'envoi d'une image : participante seulement.
create or replace function app.chat_upload_allowed(p_user uuid, p_conversation uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select app.conversation_role(p_user, p_conversation) is not null
$$;

-- ------------------------------------------------------------------ lectures (Data API)

-- Mes conversations, les plus récentes d'abord. [p_role] : client (Awa) ou
-- vendor (ma boutique).
create or replace function public.my_conversations(p_role text default 'client') returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_store uuid;
begin
  if p_role is null or p_role not in ('client', 'vendor') then
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
       or (p_role = 'vendor' and c.store_id = v_store));
end
$$;

-- Une conversation et ses messages (les plus récents, [p_limit] au plus,
-- avant [p_before]) ; la marque lue.
create or replace function public.conversation(
  p_id uuid,
  p_before timestamptz default null,
  p_limit int default 50
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_role text := app.conversation_role(v_user, p_id);
begin
  if v_role is null then
    raise exception 'conversation introuvable' using errcode = 'P0002';
  end if;
  update public.conversations set
    client_read_at = case when v_role = 'client' then clock_timestamp() else client_read_at end,
    vendor_read_at = case when v_role = 'vendor' then clock_timestamp() else vendor_read_at end
  where id = p_id;
  return app.conversation_json(p_id, v_role) || jsonb_build_object(
    'role', v_role,
    'messages', (select coalesce(jsonb_agg(app.message_json(x.id) order by x.created_at, x.id), '[]'::jsonb)
                 from (select id, created_at from public.messages
                       where conversation_id = p_id and (p_before is null or created_at < p_before)
                       order by created_at desc, id desc
                       limit least(greatest(coalesce(p_limit, 50), 1), 200)) x));
end
$$;

-- Messages non lus (badge et accueil de la vendeuse).
create or replace function public.unread_messages_count(p_role text default 'client') returns int
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_store uuid;
begin
  if p_role is null or p_role not in ('client', 'vendor') then
    raise exception 'rôle inconnu' using errcode = '22023';
  end if;
  if p_role = 'vendor' then
    select id into v_store from public.stores where owner_id = v_user;
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
$$;

-- ------------------------------------------------------------------ notifications

create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor')
    then 'vendor' else 'client' end
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('new_message', 'fr', 'Nouveau message', '{sender_name} t''a écrit.'),
  ('new_message', 'en', 'New message', '{sender_name} sent you a message.'),
  ('new_message_vendor', 'fr', 'Nouveau message', '{sender_name} t''a écrit.'),
  ('new_message_vendor', 'en', 'New message', '{sender_name} sent you a message.');

-- ------------------------------------------------------------------ droits

revoke all on function
  app.conversation_role(uuid, uuid), app.message_json(uuid), app.conversation_json(uuid, text),
  app.start_conversation(uuid, uuid), app.send_message(uuid, uuid, text, text, text, uuid, uuid),
  app.chat_media_keys(uuid, uuid[]), app.chat_upload_allowed(uuid, uuid),
  public.my_conversations(text), public.conversation(uuid, timestamptz, int),
  public.unread_messages_count(text)
from public;

grant execute on function
  public.my_conversations(text), public.conversation(uuid, timestamptz, int),
  public.unread_messages_count(text)
to authenticated;
