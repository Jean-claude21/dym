-- 0100 — Chat refait (spec 111) : répondre à un message, réactions, supprimer (pour soi, ou pour
-- tout le monde dans l'heure), transférer (texte, produit, position), documents, « reçu » et
-- « écrit… ». Les médias restent privés ; un message supprimé pour tous n'expose plus rien.

alter table public.messages drop constraint messages_kind_check;
alter table public.messages add constraint messages_kind_check check (kind in (
  'text', 'image', 'product', 'audio', 'call', 'video', 'location', 'quote', 'payment_request',
  'coupon', 'file'));
alter table public.messages
  add column reply_to uuid references public.messages (id) on delete set null,
  add column deleted_at timestamptz,
  add column forwarded boolean not null default false,
  add constraint messages_file_check check (kind <> 'file' or media_key is not null);

-- Signal « écrit… » en direct (spec 111).
alter table public.live_events drop constraint live_events_kind_check;
alter table public.live_events add constraint live_events_kind_check
  check (kind in ('message', 'order_status', 'notification', 'typing'));

alter table public.conversations
  add column client_delivered_at timestamptz,
  add column vendor_delivered_at timestamptz,
  add column courier_delivered_at timestamptz;

-- Réactions : une par personne et par message.
create table public.message_reactions (
  message_id uuid not null references public.messages (id) on delete cascade,
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  role text not null check (role in ('client', 'vendor', 'courier')),
  emoji text not null check (length(emoji) between 1 and 16),
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);
alter table public.message_reactions enable row level security;

-- Supprimé pour soi seulement.
create table public.message_hides (
  message_id uuid not null references public.messages (id) on delete cascade,
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);
alter table public.message_hides enable row level security;

-- Signal en direct à tous les participants d'une conversation (sauf [p_except]).
create or replace function app.live_conversation(p_conversation uuid, p_kind text, p_payload jsonb,
                                                 p_except uuid default null)
returns void
language sql security definer set search_path = ''
as $$
  insert into public.live_events (user_id, kind, entity_id, payload)
  select u.id, p_kind, p_conversation, p_payload
  from public.conversations c
  join public.stores s on s.id = c.store_id
  cross join lateral (values (c.client_id), (s.owner_id), (c.courier_id)) u(id)
  where c.id = p_conversation and u.id is not null and u.id is distinct from p_except
$$;
revoke all on function app.live_conversation(uuid, text, jsonb, uuid) from public;

-- Réagir (emoji) ou retirer sa réaction (null).
create or replace function public.react_message(p_message uuid, p_emoji text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_conv uuid;
  v_role text;
begin
  select m.conversation_id into v_conv from public.messages m where m.id = p_message and m.deleted_at is null;
  v_role := app.conversation_role(v_user, v_conv);
  if v_role is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if nullif(btrim(p_emoji), '') is null then
    delete from public.message_reactions where message_id = p_message and user_id = v_user;
  else
    insert into public.message_reactions (message_id, user_id, role, emoji)
    values (p_message, v_user, v_role, btrim(p_emoji))
    on conflict (message_id, user_id) do update set emoji = excluded.emoji, created_at = now();
    perform app.emit_event('chat_reaction_added', v_user, v_role, 'server',
      (select country_code from public.profiles where user_id = v_user), 'message', p_message::text,
      jsonb_build_object('emoji', btrim(p_emoji)));
  end if;
  perform app.live_conversation(v_conv, 'message', jsonb_build_object('message_id', p_message, 'reaction', true));
  return app.message_json(p_message);
end
$$;
revoke all on function public.react_message(uuid, text) from public;
grant execute on function public.react_message(uuid, text) to authenticated;

-- Supprimer : pour soi, ou pour tout le monde (son propre message, dans l'heure).
create or replace function public.delete_message(p_message uuid, p_for_all boolean default false)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_m public.messages;
begin
  select * into v_m from public.messages where id = p_message;
  if v_m.id is null or app.conversation_role(v_user, v_m.conversation_id) is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if not p_for_all then
    insert into public.message_hides (message_id, user_id) values (p_message, v_user) on conflict do nothing;
    perform app.emit_event('chat_message_deleted', v_user, app.conversation_role(v_user, v_m.conversation_id), 'server',
      (select country_code from public.profiles where user_id = v_user), 'message', p_message::text,
      jsonb_build_object('for_all', false, 'kind', v_m.kind));
    return;
  end if;
  if v_m.author_id is distinct from v_user or v_m.kind = 'call' then
    raise exception 'not_author' using errcode = '42501';
  end if;
  if v_m.created_at < now() - interval '1 hour' then
    raise exception 'too_late' using errcode = 'P0001';
  end if;
  update public.messages set deleted_at = now(), live_until = null where id = p_message;
  delete from public.message_reactions where message_id = p_message;
  perform app.emit_event('chat_message_deleted', v_user, v_m.author_role, 'server',
    (select country_code from public.profiles where user_id = v_user), 'message', p_message::text,
    jsonb_build_object('for_all', true, 'kind', v_m.kind));
  perform app.live_conversation(v_m.conversation_id, 'message', jsonb_build_object('message_id', p_message, 'deleted', true));
end
$$;
revoke all on function public.delete_message(uuid, boolean) from public;
grant execute on function public.delete_message(uuid, boolean) to authenticated;

-- Transférer un texte, un produit ou une position vers une autre de ses conversations.
create or replace function public.forward_message(p_message uuid, p_conversation uuid, p_key uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_m public.messages;
  v_out jsonb;
begin
  select * into v_m from public.messages where id = p_message and deleted_at is null;
  if v_m.id is null or app.conversation_role(v_user, v_m.conversation_id) is null
     or app.conversation_role(v_user, p_conversation) is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  -- Photos, vidéos, vocaux et documents restent dans leur conversation (vie privée).
  if v_m.kind not in ('text', 'product', 'location') then
    raise exception 'forward_not_allowed' using errcode = 'P0001';
  end if;
  v_out := app.send_message(v_user, p_conversation, v_m.kind, v_m.body, null, v_m.product_id, p_key, null,
                            case when v_m.kind = 'location' then v_m.payload end);
  update public.messages set forwarded = true where id = (v_out ->> 'id')::uuid;
  perform app.emit_event('chat_message_forwarded', v_user, v_out ->> 'author_role', 'server',
    (select country_code from public.profiles where user_id = v_user), 'message', v_out ->> 'id',
    jsonb_build_object('kind', v_m.kind));
  return app.message_json((v_out ->> 'id')::uuid);
end
$$;
revoke all on function public.forward_message(uuid, uuid, uuid) from public;
grant execute on function public.forward_message(uuid, uuid, uuid) to authenticated;

-- « Reçu » (deux coches) : l'app le marque quand elle reçoit les messages.
create or replace function public.mark_delivered(p_role text)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_store uuid;
begin
  if p_role = 'vendor' then v_store := app.member_store_id(v_user); end if;
  update public.conversations c set
    client_delivered_at = case when p_role = 'client' then now() else c.client_delivered_at end,
    vendor_delivered_at = case when p_role = 'vendor' then now() else c.vendor_delivered_at end,
    courier_delivered_at = case when p_role = 'courier' then now() else c.courier_delivered_at end
  where (p_role = 'client' and c.client_id = v_user)
     or (p_role = 'vendor' and c.store_id = v_store and app.store_can(v_user, v_store, 'chat'))
     or (p_role = 'courier' and c.courier_id = v_user);
end
$$;
revoke all on function public.mark_delivered(text) from public;
grant execute on function public.mark_delivered(text) to authenticated;

-- « écrit… » : signal en direct aux autres, au plus un toutes les 3 secondes.
create or replace function public.chat_typing(p_conversation uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_role text := app.conversation_role(v_user, p_conversation);
begin
  if v_role is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if exists (select 1 from public.live_events e
             where e.entity_id = p_conversation and e.kind = 'typing'
               and e.payload ->> 'from' = v_user::text and e.created_at > now() - interval '3 seconds') then
    return;
  end if;
  perform app.live_conversation(p_conversation, 'typing', jsonb_build_object('from', v_user, 'role', v_role), v_user);
end
$$;
revoke all on function public.chat_typing(uuid) from public;
grant execute on function public.chat_typing(uuid) to authenticated;

-- Définitions reprises et étendues.

drop function app.send_message(uuid, uuid, text, text, text, uuid, uuid, integer, jsonb);

create or replace function app.send_message(p_user uuid, p_conversation uuid, p_kind text, p_body text, p_media_key text, p_product uuid, p_key uuid, p_duration_ms integer DEFAULT NULL::integer, p_payload jsonb DEFAULT NULL::jsonb, p_reply_to uuid DEFAULT NULL::uuid)
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
     ('text', 'image', 'product', 'audio', 'video', 'location', 'quote', 'payment_request', 'coupon', 'file') then
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
  if v_role = 'courier' and p_kind not in ('text', 'image', 'audio', 'video', 'location', 'file') then
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
  -- Document (spec 111) : fichier privé de la conversation, nom et taille (10 Mo au plus).
  if p_kind = 'file' and (p_media_key is null
      or p_media_key !~ ('^chats/' || p_conversation || '/[0-9a-f-]{36}\.(pdf|docx?|xlsx?|pptx?|txt|csv|odt|ods)$')
      or length(coalesce(p_payload ->> 'name', '')) not between 1 and 120
      or coalesce((p_payload ->> 'size')::bigint, -1) not between 1 and 10485760) then
    raise exception 'media_invalid' using errcode = 'P0001';
  end if;
  -- Réponse : à un message de la même conversation, non supprimé.
  if p_reply_to is not null and not exists (
      select 1 from public.messages r where r.id = p_reply_to and r.conversation_id = p_conversation
        and r.deleted_at is null) then
    raise exception 'reply_invalid' using errcode = 'P0001';
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
                               product_id, idempotency_key, duration_ms, payload, live_until, reply_to)
  values (p_conversation, p_user, v_role, p_kind,
          case when p_kind in ('text', 'video') then v_body end,
          case when p_kind in ('image', 'audio', 'video', 'file') then p_media_key end,
          case when p_kind = 'product' then p_product end, p_key,
          case when p_kind in ('audio', 'video') then p_duration_ms end,
          case when p_kind = 'location' then jsonb_build_object(
                 'latitude', round((p_payload ->> 'latitude')::numeric, 6),
                 'longitude', round((p_payload ->> 'longitude')::numeric, 6))
               when p_kind in ('quote', 'payment_request', 'coupon') then p_payload
               when p_kind = 'file' then jsonb_build_object(
                 'name', left(p_payload ->> 'name', 120), 'size', (p_payload ->> 'size')::bigint,
                 'mime', left(coalesce(p_payload ->> 'mime', ''), 80)) end,
          case when p_kind = 'location' and v_live > 0
               then clock_timestamp() + make_interval(mins => v_live) end,
          p_reply_to)
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
revoke all on function app.send_message(uuid, uuid, text, text, text, uuid, uuid, integer, jsonb, uuid) from public;

create or replace function app.message_json(p_message uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'id', m.id, 'conversation_id', m.conversation_id, 'author_role', m.author_role,
    'kind', m.kind,
    -- Supprimé pour tous (spec 111) : plus rien n'est exposé.
    'deleted', m.deleted_at is not null,
    'body', case when m.deleted_at is null then m.body end,
    'has_media', m.media_key is not null and m.deleted_at is null,
    'forwarded', m.forwarded,
    'reply_to', case when m.reply_to is not null then (
      select jsonb_build_object('id', r.id, 'author_role', r.author_role, 'kind', r.kind,
                                'body', case when r.deleted_at is null then left(r.body, 140) end,
                                'deleted', r.deleted_at is not null)
      from public.messages r where r.id = m.reply_to) end,
    'reactions', coalesce((
      select jsonb_agg(jsonb_build_object('emoji', x.emoji, 'count', x.n, 'roles', x.roles) order by x.n desc)
      from (select emoji, count(*) as n, jsonb_agg(distinct role) as roles
            from public.message_reactions where message_id = m.id group by emoji) x), '[]'::jsonb),
    'product', case when m.product_id is not null then app.catalog_item(m.product_id) end,
    'product_id', m.product_id, 'created_at', m.created_at,
    'duration_ms', m.duration_ms, 'transcript', m.transcript,
    'payload', case
      when m.deleted_at is not null then null
      when m.kind = 'quote' then m.payload || jsonb_build_object('status',
        (select case when q.status = 'pending' and q.expires_at <= now() then 'expired' else q.status end
         from public.quotes q where q.id = (m.payload ->> 'quote_id')::uuid))
      when m.kind = 'payment_request' then m.payload || coalesce((
        select jsonb_build_object('status', case when r.status = 'open' and r.expires_at <= now()
                                                 then 'expired' else r.status end)
        from public.payment_requests r where r.id = (m.payload ->> 'request_id')::uuid), '{}'::jsonb)
      when m.kind = 'coupon' then m.payload || jsonb_build_object(
        'expired', (select cp.expires_at <= now() from public.coupons cp where cp.id = (m.payload ->> 'coupon_id')::uuid))
      else m.payload end,
    'live_until', m.live_until,
    'call', case when m.call_id is not null then (
      select jsonb_build_object('kind', c.kind, 'status', c.status,
        'duration_s', case when c.answered_at is not null and c.ended_at is not null
                           then extract(epoch from c.ended_at - c.answered_at)::int end)
      from public.calls c where c.id = m.call_id) end)
  from public.messages m
  where m.id = p_message
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
  v_my_read timestamptz;
begin
  if v_role is null then
    raise exception 'conversation introuvable' using errcode = 'P0002';
  end if;
  -- Lecture précédente : séparateur « Nouveaux messages » (spec 111).
  select case v_role when 'client' then client_read_at when 'vendor' then vendor_read_at
                     else courier_read_at end
    into v_my_read from public.conversations where id = p_id;
  update public.conversations set
    client_read_at = case when v_role = 'client' then clock_timestamp() else client_read_at end,
    vendor_read_at = case when v_role = 'vendor' then clock_timestamp() else vendor_read_at end,
    courier_read_at = case when v_role = 'courier' then clock_timestamp() else courier_read_at end
  where id = p_id;
  return app.conversation_json(p_id, v_role) || jsonb_build_object(
    'role', v_role,
    'my_read_at', v_my_read,
    -- Lecture de l'autre personne : les messages envoyés avant sont « vus ».
    -- Fil de commande : « vu » quand tous les autres ont lu.
    'peer_read_at', (select case
                       when order_id is null then
                         case v_role when 'client' then vendor_read_at else client_read_at end
                       when v_role = 'client' then least(vendor_read_at, courier_read_at)
                       when v_role = 'vendor' then least(client_read_at, courier_read_at)
                       else least(client_read_at, vendor_read_at) end
                     from public.conversations where id = p_id),
    -- « Reçu » : quand tous les autres ont reçu (spec 111).
    'peer_delivered_at', (select case
                            when order_id is null then
                              case v_role when 'client' then vendor_delivered_at else client_delivered_at end
                            when v_role = 'client' then least(vendor_delivered_at, courier_delivered_at)
                            when v_role = 'vendor' then least(client_delivered_at, courier_delivered_at)
                            else least(client_delivered_at, vendor_delivered_at) end
                          from public.conversations where id = p_id),
    'active_order', coalesce((
      select jsonb_build_object('id', o.id, 'status', o.status, 'created_at', o.created_at,
                                'total_minor', o.total_minor, 'currency_code', o.currency_code)
      from public.conversations c2 join public.orders o on o.id = c2.order_id where c2.id = p_id),
      app.conversation_active_order(p_id)),
    'messages', (select coalesce(jsonb_agg(app.message_json(x.id) order by x.created_at, x.id), '[]'::jsonb)
                 from (select id, created_at from public.messages
                       where conversation_id = p_id and (p_before is null or created_at < p_before)
                         -- Supprimés pour soi (spec 111).
                         and not exists (select 1 from public.message_hides h
                                         where h.message_id = messages.id and h.user_id = v_user)
                       order by created_at desc, id desc
                       limit least(greatest(coalesce(p_limit, 50), 1), 200)) x));
end
$function$
;

create or replace function app.chat_media_keys(p_user uuid, p_messages uuid[])
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(jsonb_object_agg(m.id, m.media_key), '{}'::jsonb)
  from public.messages m
  where m.id = any (coalesce(p_messages, '{}')) and m.media_key is not null and m.deleted_at is null
    and app.conversation_role(p_user, m.conversation_id) is not null
$function$
;

-- Mesure (spec 111) : documents et réponses comptés dans chat_message_sent ; réactions,
-- suppressions et transferts ont leur événement. Aucune donnée personnelle.
insert into public.event_names (name, emitted_by, description) values
  ('chat_reaction_added', 'server', 'Réaction posée sur un message (emoji ; spec 111)'),
  ('chat_message_deleted', 'server', 'Message supprimé pour soi ou pour tous (type ; spec 111)'),
  ('chat_message_forwarded', 'server', 'Message transféré vers une autre conversation (type ; spec 111)')
on conflict do nothing;

create or replace function app.track_chat_message() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.kind in ('text', 'image', 'product', 'file') then
    perform app.emit_event('chat_message_sent', new.author_id, new.author_role, 'server',
      (select country_code from public.profiles where user_id = new.author_id), 'message', new.id::text,
      jsonb_build_object('kind', new.kind, 'role', new.author_role,
        'with_order', app.conversation_active_order(new.conversation_id) is not null,
        'reply', new.reply_to is not null));
  end if;
  return new;
end
$$;
