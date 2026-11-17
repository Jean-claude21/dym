-- 0101 — Groupes de discussion (spec 112) : espace famille et achat groupé.
-- Famille : une cliente crée le groupe, ajoute ses proches par leur code DYM (20 personnes au
-- plus) ; tout le monde écrit, partage des produits de n'importe quelle boutique. Achat groupé :
-- un fil par offre, ouvert aux membres de l'offre et à la boutique. Chaque membre a sa lecture,
-- sa réception, son prénom sur ses messages ; les notifications ne contiennent jamais le message.

alter table public.conversations
  add column kind text not null default 'direct'
    check (kind in ('direct', 'order', 'family', 'group_buy')),
  add column title text check (title is null or length(title) between 1 and 60),
  add column group_offer_id uuid references public.group_offers (id) on delete cascade,
  alter column store_id drop not null;
update public.conversations set kind = 'order' where order_id is not null;
alter table public.conversations add constraint conversations_kind_shape check (
  ((kind = 'family') = (store_id is null))
  and ((kind = 'group_buy') = (group_offer_id is not null))
  and ((kind = 'order') = (order_id is not null)));

-- Un fil de commande se reconnaît à sa commande (fonctions de la spec 109 inchangées).
create or replace function app.conversation_kind_from_order() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if new.order_id is not null then new.kind := 'order'; end if;
  return new;
end
$$;
create trigger conversations_kind before insert on public.conversations
  for each row execute function app.conversation_kind_from_order();

drop index public.conversations_direct_key;
create unique index conversations_direct_key on public.conversations (store_id, client_id) where kind = 'direct';
create unique index conversations_group_offer_key on public.conversations (group_offer_id) where kind = 'group_buy';

-- Membres d'un groupe famille ; lecture et réception de chacun (famille et achat groupé).
create table public.conversation_members (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  admin boolean not null default false,
  read_at timestamptz,
  delivered_at timestamptz,
  joined_at timestamptz not null default clock_timestamp(),
  primary key (conversation_id, user_id)
);
create index conversation_members_user on public.conversation_members (user_id);
alter table public.conversation_members enable row level security;
revoke all on public.conversation_members from authenticated, anonymous;

-- Personnes d'un groupe : membres de la famille, ou membres de l'offre groupée.
create or replace function app.group_members_of(p_conversation uuid)
returns setof uuid
language sql stable security definer set search_path = ''
as $$
  select m.user_id from public.conversation_members m
  join public.conversations c on c.id = m.conversation_id
  where c.id = p_conversation and c.kind = 'family'
  union
  select g.user_id from public.group_members g
  join public.conversations c on c.group_offer_id = g.offer_id
  where c.id = p_conversation and c.kind = 'group_buy'
$$;
revoke all on function app.group_members_of(uuid) from public;

create or replace function app.group_member(p_user uuid, p_conversation uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from app.group_members_of(p_conversation) g(u) where g.u = p_user)
$$;
revoke all on function app.group_member(uuid, uuid) from public;

-- Nom affiché d'un groupe : son titre, ou le produit de l'offre groupée.
create or replace function app.group_title(p_conversation uuid)
returns text
language sql stable security definer set search_path = ''
as $$
  select coalesce(c.title, (select p.name from public.group_offers o join public.products p on p.id = o.product_id
                            where o.id = c.group_offer_id))
  from public.conversations c where c.id = p_conversation and c.kind in ('family', 'group_buy')
$$;
revoke all on function app.group_title(uuid) from public;

-- « Vu » ou « reçu » dans un groupe : quand toutes les autres personnes l'ont fait.
create or replace function app.group_peer_at(p_conversation uuid, p_user uuid, p_delivered boolean)
returns timestamptz
language sql stable security definer set search_path = ''
as $$
  select case when count(*) > 0 and count(x.at) = count(*) then min(x.at) end
  from (select case when p_delivered then cm.delivered_at else cm.read_at end as at
        from app.group_members_of(p_conversation) g(u)
        left join public.conversation_members cm on cm.conversation_id = p_conversation and cm.user_id = g.u
        where g.u <> p_user) x
$$;
revoke all on function app.group_peer_at(uuid, uuid, boolean) from public;

create or replace function app.conversation_role(p_user uuid, p_conversation uuid)
returns text
language sql stable security definer set search_path = ''
as $$
  select case
    -- Groupe (spec 112) : chaque membre écrit comme cliente ; la boutique d'une offre groupée aussi.
    when c.kind in ('family', 'group_buy') and app.group_member(p_user, c.id) then 'client'
    when c.kind = 'family' then null
    when c.kind = 'group_buy' then case when app.store_can(p_user, c.store_id, 'chat') then 'vendor' end
    when c.client_id = p_user then 'client'
    when c.courier_id is not null and c.courier_id = p_user then 'courier'
    when app.store_can(p_user, c.store_id, 'chat') then 'vendor'
  end
  from public.conversations c
  where c.id = p_conversation
$$;

create or replace function app.conversation_json(p_conversation uuid, p_role text)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', c.id, 'store_id', s.id, 'store_name', coalesce(s.name, ''), 'store_origin', s.origin,
    'store_active', coalesce(s.status = 'active', true),
    'client_first_name', (select first_name from public.profiles where user_id = c.client_id),
    'last_message_at', c.last_message_at,
    'last_message', (select app.message_json(m.id) from public.messages m
                     where m.conversation_id = c.id order by m.created_at desc, m.id desc limit 1),
    'unread', case
      when c.kind in ('family', 'group_buy') and p_role = 'client' then (
        select count(*) from public.messages m
        where m.conversation_id = c.id and m.author_id is distinct from app.current_user_id()
          and m.created_at > coalesce((select cm.read_at from public.conversation_members cm
                                       where cm.conversation_id = c.id and cm.user_id = app.current_user_id()),
                                      '-infinity'))
      else (select count(*) from public.messages m
            where m.conversation_id = c.id and m.author_role <> p_role
              and m.created_at > coalesce(case p_role when 'client' then c.client_read_at
                                                      when 'courier' then c.courier_read_at
                                                      else c.vendor_read_at end, '-infinity')) end,
    'order_id', c.order_id,
    'courier_name', (select split_part(cp.display_name, ' ', 1) from public.courier_profiles cp
                     where cp.user_id = c.courier_id),
    'closed', c.order_id is not null and app.order_thread_closed(c.order_id),
    -- Groupe (spec 112).
    'kind', c.kind,
    'title', app.group_title(c.id),
    'group_offer_id', c.group_offer_id,
    'members_count', case when c.kind in ('family', 'group_buy')
                          then (select count(*) from app.group_members_of(c.id)) end)
  from public.conversations c
  left join public.stores s on s.id = c.store_id
  where c.id = p_conversation
$$;

create or replace function public.my_conversations(p_role text default 'client')
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
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
    where (p_role = 'client' and c.kind in ('direct', 'order') and c.client_id = v_user)
       or (p_role = 'client' and c.kind = 'family'
           and c.id in (select conversation_id from public.conversation_members where user_id = v_user))
       or (p_role = 'client' and c.kind = 'group_buy'
           and c.group_offer_id in (select offer_id from public.group_members where user_id = v_user))
       or (p_role = 'vendor' and c.store_id = v_store)
       or (p_role = 'courier' and c.courier_id = v_user));
end
$$;

create or replace function public.unread_messages_count(p_role text default 'client')
returns integer
language plpgsql stable security definer set search_path = ''
as $$
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
      and ((p_role = 'client' and c.kind in ('direct', 'order') and c.client_id = v_user)
           or (p_role = 'vendor' and c.store_id = v_store)
           or (p_role = 'courier' and c.courier_id = v_user))
      and m.created_at > coalesce(case p_role when 'client' then c.client_read_at
                                              when 'courier' then c.courier_read_at
                                              else c.vendor_read_at end, '-infinity'))
  + case when p_role = 'client' then (
    select count(*) from public.messages m
    join public.conversations c on c.id = m.conversation_id
    left join public.conversation_members cm on cm.conversation_id = c.id and cm.user_id = v_user
    where c.kind in ('family', 'group_buy') and m.author_id is distinct from v_user
      and app.group_member(v_user, c.id)
      and m.created_at > coalesce(cm.read_at, '-infinity')) else 0 end;
end
$$;

create or replace function app.live_conversation(p_conversation uuid, p_kind text, p_payload jsonb,
                                                 p_except uuid default null)
returns void
language sql security definer set search_path = ''
as $$
  insert into public.live_events (user_id, kind, entity_id, payload)
  select distinct u.id, p_kind, p_conversation, p_payload
  from (
    select x.id from public.conversations c
    left join public.stores s on s.id = c.store_id
    cross join lateral (values (case when c.kind in ('direct', 'order') then c.client_id end),
                               (s.owner_id), (c.courier_id)) x(id)
    where c.id = p_conversation
    union all
    select g.u from app.group_members_of(p_conversation) g(u)) u
  where u.id is not null and u.id is distinct from p_except
$$;

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
  where (p_role = 'client' and c.kind in ('direct', 'order') and c.client_id = v_user)
     or (p_role = 'vendor' and c.store_id = v_store and app.store_can(v_user, v_store, 'chat'))
     or (p_role = 'courier' and c.courier_id = v_user);
  -- Groupes (spec 112) : la réception de chacun.
  if p_role = 'client' then
    insert into public.conversation_members (conversation_id, user_id, delivered_at)
    select c.id, v_user, now() from public.conversations c
    where (c.kind = 'family' and c.id in (select conversation_id from public.conversation_members where user_id = v_user))
       or (c.kind = 'group_buy' and c.group_offer_id in (select offer_id from public.group_members where user_id = v_user))
    on conflict (conversation_id, user_id) do update set delivered_at = excluded.delivered_at;
  end if;
end
$$;

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
  select id into v_id from public.conversations where store_id = p_store and client_id = p_user and kind = 'direct';
  if v_id is null then
    if v_store.status <> 'active' then
      raise exception 'store_unavailable' using errcode = 'P0001';
    end if;
    insert into public.conversations (store_id, client_id) values (p_store, p_user)
    on conflict (store_id, client_id) where kind = 'direct' do nothing
    returning id into v_id;
    if v_id is null then
      select id into v_id from public.conversations where store_id = p_store and client_id = p_user and kind = 'direct';
    end if;
  end if;
  return app.conversation_json(v_id, 'client');
end
$function$
;

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
    where p.id = p_product and p.status = 'published'
      -- Espace famille (spec 112) : un produit de n'importe quelle boutique.
      and (p.store_id = v_conv.store_id or v_conv.kind = 'family')) then
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
  -- Groupe (spec 112) : la lecture de chacun est la sienne.
  if v_conv.kind in ('family', 'group_buy') and v_role = 'client' then
    insert into public.conversation_members (conversation_id, user_id, read_at)
    values (p_conversation, p_user, clock_timestamp())
    on conflict (conversation_id, user_id) do update set read_at = excluded.read_at;
  end if;

  -- Destinataires prévenus (tous les autres participants), sans le contenu du message.
  v_sender := case v_role
    when 'client' then (select first_name from public.profiles where user_id = p_user)
    when 'courier' then (select split_part(display_name, ' ', 1) from public.courier_profiles where user_id = p_user)
    else v_store.name end;
  for v_recipient, v_rkind in
    select distinct x.u, x.k from (
      select v_conv.client_id as u, 'new_message' as k, 'client' as r where v_conv.kind in ('direct', 'order')
      union all select v_store.owner_id, 'new_message_vendor', 'vendor' where v_store.id is not null
      union all select v_conv.courier_id, 'new_message_courier', 'courier'
      -- Groupe (spec 112) : chaque membre, sauf l'auteur.
      union all select g.u, 'new_message_group', 'member' from app.group_members_of(p_conversation) g(u)) x
    where x.u is not null and x.u <> p_user and (x.r = 'member' or x.r <> v_role)
  loop
    perform app.notify(v_recipient, v_rkind, 'messages', null, null,
      jsonb_build_object('sender_name', coalesce(v_sender, ''), 'conversation_id', p_conversation,
                         'group', coalesce(app.group_title(p_conversation), '')));
  end loop;
  return app.message_json(v_id);
end
$function$
;

create or replace function app.message_json(p_message uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'id', m.id, 'conversation_id', m.conversation_id, 'author_role', m.author_role,
    'kind', m.kind,
    -- Groupe (spec 112) : prénom de l'auteur ; « mine » selon la session (nul côté serveur).
    'author_name', case when m.author_role = 'client' and exists (
        select 1 from public.conversations c where c.id = m.conversation_id and c.kind in ('family', 'group_buy'))
      then (select first_name from public.profiles where user_id = m.author_id) end,
    'mine', case when app.current_user_id() is not null then m.author_id = app.current_user_id() end,
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
      select jsonb_agg(jsonb_build_object('emoji', x.emoji, 'count', x.n, 'roles', x.roles, 'mine', x.mine)
                       order by x.n desc)
      from (select emoji, count(*) as n, jsonb_agg(distinct role) as roles,
                   bool_or(user_id = app.current_user_id()) as mine
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
  v_kind text;
begin
  if v_role is null then
    raise exception 'conversation introuvable' using errcode = 'P0002';
  end if;
  -- Lecture précédente : séparateur « Nouveaux messages » (spec 111).
  select case when kind in ('family', 'group_buy') and v_role = 'client' then
                (select read_at from public.conversation_members where conversation_id = p_id and user_id = v_user)
              when v_role = 'client' then client_read_at when v_role = 'vendor' then vendor_read_at
              else courier_read_at end, kind
    into v_my_read, v_kind from public.conversations where id = p_id;
  -- Groupe (spec 112) : ma lecture, à moi seule.
  if v_kind in ('family', 'group_buy') and v_role = 'client' then
    insert into public.conversation_members (conversation_id, user_id, read_at)
    values (p_id, v_user, clock_timestamp())
    on conflict (conversation_id, user_id) do update set read_at = excluded.read_at;
  end if;
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
    'peer_read_at', case when v_kind in ('family', 'group_buy') then app.group_peer_at(p_id, v_user, false)
                    else (select case
                       when order_id is null then
                         case v_role when 'client' then vendor_read_at else client_read_at end
                       when v_role = 'client' then least(vendor_read_at, courier_read_at)
                       when v_role = 'vendor' then least(client_read_at, courier_read_at)
                       else least(client_read_at, vendor_read_at) end
                     from public.conversations where id = p_id) end,
    -- « Reçu » : quand tous les autres ont reçu (spec 111).
    'peer_delivered_at', case when v_kind in ('family', 'group_buy') then app.group_peer_at(p_id, v_user, true)
                         else (select case
                            when order_id is null then
                              case v_role when 'client' then vendor_delivered_at else client_delivered_at end
                            when v_role = 'client' then least(vendor_delivered_at, courier_delivered_at)
                            when v_role = 'vendor' then least(client_delivered_at, courier_delivered_at)
                            else least(client_delivered_at, vendor_delivered_at) end
                          from public.conversations where id = p_id) end,
    'active_order', case when v_kind in ('direct', 'order') then coalesce((
      select jsonb_build_object('id', o.id, 'status', o.status, 'created_at', o.created_at,
                                'total_minor', o.total_minor, 'currency_code', o.currency_code)
      from public.conversations c2 join public.orders o on o.id = c2.order_id where c2.id = p_id),
      app.conversation_active_order(p_id)) end,
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
  perform app.live_conversation(p_conversation, 'typing', jsonb_build_object('from', v_user, 'role', v_role,
    'name', case when v_role = 'client' then (select first_name from public.profiles where user_id = v_user) end), v_user);
end
$$;

-- ------------------------------------------------------------------ gestion des groupes

-- Détail d'un groupe : nom, membres (prénom), suis-je administratrice.
create or replace function public.group_info(p_conversation uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_conv public.conversations;
begin
  select * into v_conv from public.conversations where id = p_conversation and kind in ('family', 'group_buy');
  if v_conv.id is null or app.conversation_role(v_user, p_conversation) is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  return jsonb_build_object(
    'id', v_conv.id, 'kind', v_conv.kind, 'title', app.group_title(v_conv.id),
    'group_offer_id', v_conv.group_offer_id,
    'store_name', (select name from public.stores where id = v_conv.store_id),
    'me_admin', exists (select 1 from public.conversation_members
                        where conversation_id = v_conv.id and user_id = v_user and admin),
    'members', coalesce((
      select jsonb_agg(jsonb_build_object(
               'user_id', g.u,
               'first_name', coalesce((select first_name from public.profiles where user_id = g.u), ''),
               'admin', coalesce(cm.admin, false),
               'me', g.u = v_user)
             order by coalesce(cm.admin, false) desc, (select first_name from public.profiles where user_id = g.u))
      from app.group_members_of(v_conv.id) g(u)
      left join public.conversation_members cm on cm.conversation_id = v_conv.id and cm.user_id = g.u),
      '[]'::jsonb));
end
$$;
revoke all on function public.group_info(uuid) from public;
grant execute on function public.group_info(uuid) to authenticated;

-- Espace famille : la créatrice en est l'administratrice.
create or replace function public.create_family_group(p_title text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_title text := nullif(btrim(p_title), '');
  v_id uuid;
begin
  if v_title is null or length(v_title) > 60 then
    raise exception 'title_invalid' using errcode = 'P0001';
  end if;
  if (select count(*) from public.conversation_members m join public.conversations c on c.id = m.conversation_id
      where m.user_id = v_user and m.admin and c.kind = 'family') >= 10 then
    raise exception 'too_many_groups' using errcode = 'P0001';
  end if;
  insert into public.conversations (kind, title, client_id, store_id, last_message_at)
  values ('family', v_title, v_user, null, clock_timestamp())
  returning id into v_id;
  insert into public.conversation_members (conversation_id, user_id, admin, read_at, delivered_at)
  values (v_id, v_user, true, clock_timestamp(), clock_timestamp());
  perform app.emit_event('group_created', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'conversation', v_id::text,
    jsonb_build_object('kind', 'family'));
  return app.conversation_json(v_id, 'client');
end
$$;
revoke all on function public.create_family_group(text) from public;
grant execute on function public.create_family_group(text) to authenticated;

-- Ajouter un proche par son code DYM (administratrice seulement ; 20 personnes au plus).
create or replace function public.group_add_member(p_conversation uuid, p_handle text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_new uuid := app.user_by_handle(p_handle);
begin
  if not exists (select 1 from public.conversation_members m join public.conversations c on c.id = m.conversation_id
                 where c.id = p_conversation and c.kind = 'family' and m.user_id = v_user and m.admin) then
    raise exception 'not_admin' using errcode = '42501';
  end if;
  if v_new is null or v_new = v_user then
    raise exception 'recipient_unknown' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.conversation_members where conversation_id = p_conversation and user_id = v_new) then
    return public.group_info(p_conversation);
  end if;
  if (select count(*) from public.conversation_members where conversation_id = p_conversation) >= 20 then
    raise exception 'group_full' using errcode = 'P0001';
  end if;
  insert into public.conversation_members (conversation_id, user_id) values (p_conversation, v_new);
  perform app.notify(v_new, 'group_added', 'messages', null, null, jsonb_build_object(
    'by_name', coalesce((select first_name from public.profiles where user_id = v_user), ''),
    'group', coalesce(app.group_title(p_conversation), ''), 'conversation_id', p_conversation));
  perform app.live_conversation(p_conversation, 'message', jsonb_build_object('members', true));
  perform app.emit_event('group_member_added', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'conversation', p_conversation::text,
    jsonb_build_object('kind', 'family'));
  return public.group_info(p_conversation);
end
$$;
revoke all on function public.group_add_member(uuid, text) from public;
grant execute on function public.group_add_member(uuid, text) to authenticated;

-- Retirer quelqu'un (administratrice) ou quitter le groupe (soi-même, sauf l'administratrice).
create or replace function public.group_remove_member(p_conversation uuid, p_user uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_admin boolean := exists (select 1 from public.conversation_members m join public.conversations c on c.id = m.conversation_id
                             where c.id = p_conversation and c.kind = 'family' and m.user_id = v_user and m.admin);
begin
  if p_user = v_user then
    if v_admin then raise exception 'admin_cannot_leave' using errcode = 'P0001'; end if;
  elsif not v_admin then
    raise exception 'not_admin' using errcode = '42501';
  end if;
  delete from public.conversation_members where conversation_id = p_conversation and user_id = p_user;
  perform app.live_conversation(p_conversation, 'message', jsonb_build_object('members', true));
end
$$;
revoke all on function public.group_remove_member(uuid, uuid) from public;
grant execute on function public.group_remove_member(uuid, uuid) to authenticated;

create or replace function public.group_rename(p_conversation uuid, p_title text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_title text := nullif(btrim(p_title), '');
begin
  if not exists (select 1 from public.conversation_members m join public.conversations c on c.id = m.conversation_id
                 where c.id = p_conversation and c.kind = 'family' and m.user_id = v_user and m.admin) then
    raise exception 'not_admin' using errcode = '42501';
  end if;
  if v_title is null or length(v_title) > 60 then
    raise exception 'title_invalid' using errcode = 'P0001';
  end if;
  update public.conversations set title = v_title where id = p_conversation;
  return public.group_info(p_conversation);
end
$$;
revoke all on function public.group_rename(uuid, text) from public;
grant execute on function public.group_rename(uuid, text) to authenticated;

-- Fil d'une offre groupée : ouvert à ses membres et à la boutique, créé au premier besoin.
create or replace function public.group_offer_thread(p_offer uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_offer public.group_offers;
  v_member boolean;
  v_id uuid;
begin
  select * into v_offer from public.group_offers where id = p_offer;
  v_member := exists (select 1 from public.group_members where offer_id = p_offer and user_id = v_user);
  if v_offer.id is null or not (v_member or app.store_can(v_user, v_offer.store_id, 'chat')) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  insert into public.conversations (kind, store_id, client_id, group_offer_id, last_message_at)
  values ('group_buy', v_offer.store_id, v_user, p_offer, clock_timestamp())
  on conflict (group_offer_id) where kind = 'group_buy' do nothing;
  select id into v_id from public.conversations where group_offer_id = p_offer and kind = 'group_buy';
  return app.conversation_json(v_id, case when v_member then 'client' else 'vendor' end);
end
$$;
revoke all on function public.group_offer_thread(uuid) from public;
grant execute on function public.group_offer_thread(uuid) to authenticated;

insert into public.event_names (name, emitted_by, description) values
  ('group_created', 'server', 'Groupe de discussion créé (type ; spec 112)'),
  ('group_member_added', 'server', 'Proche ajouté à un groupe (type ; spec 112)')
on conflict do nothing;

insert into public.notification_templates (kind, locale, title, body) values
  ('new_message_group', 'fr', '{group}', '{sender_name} a écrit dans le groupe.'),
  ('new_message_group', 'en', '{group}', '{sender_name} wrote in the group.'),
  ('group_added', 'fr', 'Nouveau groupe', '{by_name} t''a ajoutée au groupe « {group} ».'),
  ('group_added', 'en', 'New group', '{by_name} added you to the group "{group}".')
on conflict do nothing;
