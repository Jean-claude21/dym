-- 0042 — Vocaux et appels (spec 035).
-- 1. Messages vocaux (60 s au plus), médias privés comme les images.
-- 2. Appels audio et vidéo entre la cliente et la boutique : états tenus en base (sonnerie de 60 s,
--    décroché, refusé, manqué, terminé), résumé dans la conversation. Le média passe par un
--    fournisseur ; tant qu'il n'est pas branché, l'appel est simulé et signalé (décision 0015),
--    derrière le flag pays `calls_simulated`.

alter table public.messages drop constraint messages_kind_check;
alter table public.messages add constraint messages_kind_check
  check (kind in ('text', 'image', 'product', 'audio', 'call'));
alter table public.messages add column duration_ms integer check (duration_ms is null or duration_ms between 1 and 60000);
alter table public.messages add constraint messages_audio_check
  check (kind <> 'audio' or (media_key is not null and duration_ms is not null));

create table public.calls (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  caller_role text not null check (caller_role in ('client', 'vendor')),
  caller_id uuid references neon_auth."user" (id) on delete set null,
  kind text not null check (kind in ('audio', 'video')),
  status text not null default 'ringing' check (status in ('ringing', 'ongoing', 'declined', 'missed', 'ended')),
  -- Fournisseur média : simulé jusqu'au branchement du vrai (avant la production finale).
  provider text not null default 'simulated' check (provider in ('simulated')),
  created_at timestamptz not null default clock_timestamp(),
  answered_at timestamptz,
  ended_at timestamptz
);
create index calls_conversation on public.calls (conversation_id, created_at desc);
create unique index calls_one_active on public.calls (conversation_id) where status in ('ringing', 'ongoing');
alter table public.calls enable row level security;
revoke all on public.calls from authenticated, anonymous;

alter table public.messages add column call_id uuid references public.calls (id) on delete set null;

insert into public.feature_flags (key, country_code, is_enabled, description)
select 'calls_simulated', null, true,
       'Appels audio et vidéo simulés (tests) ; à remplacer par le vrai fournisseur avant la production finale'
where not exists (select 1 from public.feature_flags where key = 'calls_simulated');

-- Sonnerie de 60 s : au-delà, l'appel est manqué.
create or replace function app.call_effective_status(c public.calls) returns text
language sql stable set search_path = ''
as $$
  select case when c.status = 'ringing' and c.created_at < clock_timestamp() - interval '60 seconds'
              then 'missed' else c.status end
$$;

create or replace function app.call_json(p_call uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', c.id, 'conversation_id', c.conversation_id, 'kind', c.kind,
    'status', app.call_effective_status(c), 'provider', c.provider,
    'outgoing', c.caller_id = p_user,
    'caller_name', case when c.caller_role = 'vendor' then s.name
                        else (select first_name from public.profiles where user_id = c.caller_id) end,
    'created_at', c.created_at, 'answered_at', c.answered_at, 'ended_at', c.ended_at,
    'duration_s', case when c.answered_at is not null
                       then extract(epoch from coalesce(c.ended_at, clock_timestamp()) - c.answered_at)::int end)
  from public.calls c
  join public.conversations cv on cv.id = c.conversation_id
  join public.stores s on s.id = cv.store_id
  where c.id = p_call
$$;

-- Autre partie de la conversation.
create or replace function app.conversation_peer(p_conversation uuid, p_role text) returns uuid
language sql stable security definer set search_path = ''
as $$
  select case when p_role = 'client' then s.owner_id else c.client_id end
  from public.conversations c join public.stores s on s.id = c.store_id where c.id = p_conversation
$$;

-- Clôt les sonneries dépassées (manquées) avant d'en ouvrir une autre.
create or replace function app.close_stale_calls(p_conversation uuid) returns void
language sql security definer set search_path = ''
as $$
  update public.calls set status = 'missed', ended_at = created_at + interval '60 seconds'
  where conversation_id = p_conversation and status = 'ringing'
    and created_at < clock_timestamp() - interval '60 seconds'
$$;

create or replace function public.start_call(p_conversation uuid, p_kind text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_role text := app.conversation_role(v_user, p_conversation);
  v_country char(2) := (select country_code from public.profiles where user_id = v_user);
  v_id uuid;
begin
  if v_role is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if p_kind not in ('audio', 'video') then raise exception 'invalid_kind' using errcode = '22023'; end if;
  if not app.feature_enabled('calls_simulated', v_country) then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  perform app.close_stale_calls(p_conversation);
  if exists (select 1 from public.calls where conversation_id = p_conversation and status in ('ringing', 'ongoing')) then
    raise exception 'call_in_progress' using errcode = '22023';
  end if;
  insert into public.calls (conversation_id, caller_role, caller_id, kind)
  values (p_conversation, v_role, v_user, p_kind) returning id into v_id;
  perform app.notify(app.conversation_peer(p_conversation, v_role),
    case when v_role = 'client' then 'incoming_call_vendor' else 'incoming_call' end, 'messages', null, null,
    jsonb_build_object('conversation_id', p_conversation, 'call_id', v_id, 'kind', p_kind));
  perform app.emit_event('call_started', v_user, v_role, 'server', v_country, 'call', v_id::text,
    jsonb_build_object('kind', p_kind));
  return app.call_json(v_id, v_user);
end
$fn$;

create or replace function public.answer_call(p_call uuid, p_accept boolean) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_call public.calls;
begin
  select * into v_call from public.calls where id = p_call for update;
  if v_call.id is null or app.conversation_role(v_user, v_call.conversation_id) is null
     or v_call.caller_id = v_user then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if app.call_effective_status(v_call) <> 'ringing' then
    raise exception 'call_not_ringing' using errcode = '22023';
  end if;
  update public.calls set
    status = case when p_accept then 'ongoing' else 'declined' end,
    answered_at = case when p_accept then clock_timestamp() end,
    ended_at = case when p_accept then null else clock_timestamp() end
  where id = p_call;
  if not p_accept then perform app.call_summary(p_call); end if;
  return app.call_json(p_call, v_user);
end
$fn$;

create or replace function public.end_call(p_call uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_call public.calls;
  v_status text;
begin
  select * into v_call from public.calls where id = p_call for update;
  if v_call.id is null or app.conversation_role(v_user, v_call.conversation_id) is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  v_status := app.call_effective_status(v_call);
  if v_status in ('ringing', 'ongoing') or (v_status = 'missed' and v_call.status = 'ringing') then
    update public.calls set
      status = case when v_status = 'ongoing' then 'ended' else 'missed' end,
      ended_at = clock_timestamp()
    where id = p_call;
    perform app.call_summary(p_call);
  end if;
  return app.call_json(p_call, v_user);
end
$fn$;

-- Résumé de l'appel dans la conversation (une fois), événement de fin.
create or replace function app.call_summary(p_call uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_call public.calls;
  v_duration int;
begin
  select * into v_call from public.calls where id = p_call;
  if exists (select 1 from public.messages where call_id = p_call) then return; end if;
  v_duration := case when v_call.answered_at is not null
                     then extract(epoch from v_call.ended_at - v_call.answered_at)::int else 0 end;
  insert into public.messages (conversation_id, author_id, author_role, kind, call_id, idempotency_key)
  values (v_call.conversation_id, v_call.caller_id, v_call.caller_role, 'call', p_call, p_call);
  update public.conversations set last_message_at = clock_timestamp() where id = v_call.conversation_id;
  perform app.emit_event('call_ended', v_call.caller_id, v_call.caller_role, 'server',
    (select country_code from public.profiles where user_id = v_call.caller_id), 'call', p_call::text,
    jsonb_build_object('status', v_call.status, 'duration_s', v_duration, 'kind', v_call.kind));
end
$fn$;

-- État d'un appel (sondage de l'écran d'appel).
create or replace function public.call_state(p_call uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if not exists (select 1 from public.calls c where c.id = p_call
                 and app.conversation_role(v_user, c.conversation_id) is not null) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  return app.call_json(p_call, v_user);
end
$fn$;

-- Appel qui sonne pour moi (le plus récent), comme cliente ou comme vendeuse.
create or replace function public.my_incoming_call() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select app.call_json(c.id, app.current_user_id())
  from public.calls c
  where c.status = 'ringing' and c.created_at > clock_timestamp() - interval '60 seconds'
    and c.caller_id is distinct from app.current_user_id()
    and app.conversation_role(app.current_user_id(), c.conversation_id) is not null
  order by c.created_at desc limit 1
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('incoming_call', 'fr', 'Appel entrant', 'On t''appelle depuis une conversation DYM.'),
  ('incoming_call', 'en', 'Incoming call', 'Someone is calling you from a DYM chat.'),
  ('incoming_call_vendor', 'fr', 'Appel d''une cliente', 'Une cliente t''appelle depuis une conversation.'),
  ('incoming_call_vendor', 'en', 'Call from a customer', 'A customer is calling you from a chat.')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('call_started', 'server', 'Appel lancé depuis une conversation (audio, vidéo)'),
  ('call_ended', 'server', 'Fin d''appel (issue, durée)'),
  ('voice_message_sent', 'server', 'Message vocal envoyé (durée)')
on conflict do nothing;

-- Message (0017) : durée des vocaux, résumé des appels.
create or replace function app.message_json(p_message uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', m.id, 'conversation_id', m.conversation_id, 'author_role', m.author_role,
    'kind', m.kind, 'body', m.body, 'has_media', m.media_key is not null,
    'product', case when m.product_id is not null then app.catalog_item(m.product_id) end,
    'product_id', m.product_id, 'created_at', m.created_at,
    'duration_ms', m.duration_ms,
    'call', case when m.call_id is not null then (
      select jsonb_build_object('kind', c.kind, 'status', c.status,
        'duration_s', case when c.answered_at is not null and c.ended_at is not null
                           then extract(epoch from c.ended_at - c.answered_at)::int end)
      from public.calls c where c.id = m.call_id) end)
  from public.messages m
  where m.id = p_message
$$;

-- Envoi (0017) : vocaux.
drop function app.send_message(uuid, uuid, text, text, text, uuid, uuid);
create function app.send_message(
  p_user uuid,
  p_conversation uuid,
  p_kind text,
  p_body text,
  p_media_key text,
  p_product uuid,
  p_key uuid,
  p_duration_ms integer default null
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
  if p_key is null or p_kind is null or p_kind not in ('text', 'image', 'product', 'audio') then
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
  if p_kind = 'audio' and (p_media_key is null or p_duration_ms is null
      or p_duration_ms not between 500 and 60000
      or p_media_key !~ ('^chats/' || p_conversation || '/[0-9a-f-]{36}\.(wav|m4a|webm|ogg)$')) then
    raise exception 'media_invalid' using errcode = 'P0001';
  end if;
  if p_kind = 'product' and not exists (
    select 1 from public.products p
    where p.id = p_product and p.store_id = v_conv.store_id and p.status = 'published') then
    raise exception 'product_invalid' using errcode = 'P0001';
  end if;

  insert into public.messages (conversation_id, author_id, author_role, kind, body, media_key,
                               product_id, idempotency_key, duration_ms)
  values (p_conversation, p_user, v_role, p_kind,
          case when p_kind = 'text' then v_body end,
          case when p_kind in ('image', 'audio') then p_media_key end,
          case when p_kind = 'product' then p_product end, p_key,
          case when p_kind = 'audio' then p_duration_ms end)
  returning id into v_id;
  if p_kind = 'audio' then
    perform app.emit_event('voice_message_sent', p_user, v_role, 'server',
      (select country_code from public.profiles where user_id = p_user), 'message', v_id::text,
      jsonb_build_object('duration_ms', p_duration_ms));
  end if;
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

-- Notifications vers l'app vendeuse (0041) : appel entrant.
create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor', 'review_received', 'support_replied_vendor', 'low_stock',
    'substitution_answered', 'freshness_claimed', 'incoming_call_vendor')
    then 'vendor' else 'client' end
$$;

-- ------------------------------------------------------------------ droits

revoke all on function app.call_effective_status(public.calls), app.call_json(uuid, uuid),
  app.conversation_peer(uuid, text), app.close_stale_calls(uuid), app.call_summary(uuid),
  public.start_call(uuid, text), public.answer_call(uuid, boolean), public.end_call(uuid),
  public.call_state(uuid), public.my_incoming_call(),
  app.send_message(uuid, uuid, text, text, text, uuid, uuid, integer) from public;
grant execute on function public.start_call(uuid, text), public.answer_call(uuid, boolean),
  public.end_call(uuid), public.call_state(uuid), public.my_incoming_call() to authenticated;
