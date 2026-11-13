-- 0079 — Appels réels dans le chat (spec 084).
-- Le média des appels passe par LiveKit quand le flag `calls_livekit` est actif (pays ou global) ;
-- sinon l'appel reste simulé (flag `calls_simulated`, décision 0015). Le fournisseur est fixé à la
-- création de l'appel. Seules les deux personnes de la conversation reçoivent un accès au média,
-- et seulement pendant l'appel décroché (jeton émis par la Function, jamais par l'app).

alter table public.calls drop constraint calls_provider_check;
alter table public.calls add constraint calls_provider_check check (provider in ('simulated', 'livekit'));

insert into public.feature_flags (key, country_code, is_enabled, description)
select 'calls_livekit', null, false,
       'Appels audio et vidéo réels (LiveKit) ; sinon simulés'
where not exists (select 1 from public.feature_flags where key = 'calls_livekit');

create or replace function public.start_call(p_conversation uuid, p_kind text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_role text := app.conversation_role(v_user, p_conversation);
  v_country char(2) := (select country_code from public.profiles where user_id = v_user);
  v_real boolean;
  v_id uuid;
begin
  if v_role is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if p_kind not in ('audio', 'video') then raise exception 'invalid_kind' using errcode = '22023'; end if;
  v_real := app.feature_enabled('calls_livekit', v_country);
  if not v_real and not app.feature_enabled('calls_simulated', v_country) then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  perform app.close_stale_calls(p_conversation);
  if exists (select 1 from public.calls where conversation_id = p_conversation and status in ('ringing', 'ongoing')) then
    raise exception 'call_in_progress' using errcode = '22023';
  end if;
  insert into public.calls (conversation_id, caller_role, caller_id, kind, provider)
  values (p_conversation, v_role, v_user, p_kind, case when v_real then 'livekit' else 'simulated' end)
  returning id into v_id;
  perform app.notify(app.conversation_peer(p_conversation, v_role),
    case when v_role = 'client' then 'incoming_call_vendor' else 'incoming_call' end, 'messages', null, null,
    jsonb_build_object('conversation_id', p_conversation, 'call_id', v_id, 'kind', p_kind));
  perform app.emit_event('call_started', v_user, v_role, 'server', v_country, 'call', v_id::text,
    jsonb_build_object('kind', p_kind, 'provider', case when v_real then 'livekit' else 'simulated' end));
  return app.call_json(v_id, v_user);
end
$fn$;

-- Accès au média (appelé par la Function avant d'émettre le jeton LiveKit) : salle de l'appel,
-- identité et nom affiché. Refusé hors de la conversation, pour un appel simulé ou non décroché.
create or replace function app.call_media_access(p_user uuid, p_call uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_call public.calls;
  v_role text;
begin
  select * into v_call from public.calls where id = p_call;
  if v_call.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  v_role := app.conversation_role(p_user, v_call.conversation_id);
  if v_role is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_call.provider <> 'livekit' then raise exception 'call_simulated' using errcode = '22023'; end if;
  if app.call_effective_status(v_call) <> 'ongoing' then
    raise exception 'call_not_active' using errcode = '22023';
  end if;
  return jsonb_build_object(
    'room', 'call-' || v_call.id,
    'identity', p_user,
    'role', v_role,
    'name', case when v_role = 'vendor'
                 then (select s.name from public.conversations c join public.stores s on s.id = c.store_id
                       where c.id = v_call.conversation_id)
                 else (select first_name from public.profiles where user_id = p_user) end,
    'video', v_call.kind = 'video');
end
$fn$;

revoke all on function app.call_media_access(uuid, uuid) from public;
revoke all on function public.start_call(uuid, text) from public;
grant execute on function public.start_call(uuid, text) to authenticated;
