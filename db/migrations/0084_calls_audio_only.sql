-- 0084 — Appels audio seulement pour commencer (spec 089) : la vidéo est fermée par le flag
-- `calls_video` (global, coupé) ; l'app cache le bouton, la base refuse l'appel vidéo.

insert into public.feature_flags (key, country_code, is_enabled, description)
select 'calls_video', null, false, 'Appels vidéo dans le chat (sinon audio seulement)'
where not exists (select 1 from public.feature_flags where key = 'calls_video');

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
  -- Vidéo coupée tant que le flag `calls_video` ne l'ouvre pas (spec 089).
  if p_kind = 'video' and not app.feature_enabled('calls_video', v_country) then
    raise exception 'video_disabled' using errcode = 'P0001';
  end if;
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
