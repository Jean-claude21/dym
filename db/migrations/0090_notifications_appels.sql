-- 0090 — Notifications et appels (spec 097) : appel manqué notifié, boîte de notifications par
-- app (vendeuse, livreur) avec le texte rendu dans la langue de la personne.

-- Appel manqué : la personne appelée est prévenue (une fois), dans la bonne app.
create or replace function app.notify_missed_call()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_callee uuid := app.conversation_peer(new.conversation_id, new.caller_role);
begin
  if new.status = 'missed' and old.status = 'ringing' and v_callee is not null then
    perform app.notify(v_callee,
      case when new.caller_role = 'client' then 'call_missed_vendor' else 'call_missed' end,
      'messages', null, null,
      jsonb_build_object('conversation_id', new.conversation_id, 'call_id', new.id, 'kind', new.kind,
        'caller_name', coalesce((select p.first_name from public.profiles p where p.user_id = new.caller_id), '')));
    perform app.emit_event('call_missed', new.caller_id, new.caller_role, 'server', null, 'call', new.id::text,
      jsonb_build_object('kind', new.kind));
  end if;
  return new;
end
$$;
create trigger calls_missed_notify after update of status on public.calls
  for each row execute function app.notify_missed_call();

-- Balayage (cron des Functions) : les sonneries de plus de 60 s deviennent manquées.
create or replace function app.sweep_missed_calls(p_at timestamptz default now())
returns integer
language sql security definer set search_path = ''
as $$
  with missed as (
    update public.calls set status = 'missed', ended_at = created_at + interval '60 seconds'
    where status = 'ringing' and created_at < p_at - interval '60 seconds'
    returning id
  )
  select count(*)::int from missed
$$;
revoke all on function app.sweep_missed_calls(timestamptz) from public;

insert into public.notification_templates (kind, locale, title, body) values
  ('call_missed', 'fr', 'Appel manqué', '{caller_name} a essayé de t''appeler.'),
  ('call_missed', 'en', 'Missed call', '{caller_name} tried to call you.'),
  ('call_missed_vendor', 'fr', 'Appel manqué', '{caller_name} a essayé de t''appeler.'),
  ('call_missed_vendor', 'en', 'Missed call', '{caller_name} tried to call you.');

CREATE OR REPLACE FUNCTION app.notification_app(p_kind text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor', 'review_received', 'support_replied_vendor', 'low_stock',
    'substitution_answered', 'freshness_claimed', 'incoming_call_vendor',
    'courier_out_for_delivery', 'courier_delivered', 'qr_paid',
    'wholesale_confirmed', 'wholesale_cancelled', 'order_auto_refused',
    'store_approved', 'store_rejected', 'call_missed_vendor')
    then 'vendor'
    when p_kind in ('mission_available', 'courier_cash_confirmed', 'order_ready_pickup',
      'store_courier_added', 'store_mission_assigned', 'courier_approved', 'courier_rejected') then 'delivery'
    else 'client' end
$function$;

-- Boîte de notifications d'une app (spec 097) : seulement celles de cette app, texte rendu.
create or replace function public.my_app_notifications(p_app text, p_limit integer default 50)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  with me as (
    select app.require_user() as id,
           coalesce((select locale from public.profiles where user_id = app.current_user_id()), 'fr') as lang
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', n.id, 'kind', n.kind, 'category', n.category, 'order_id', n.order_id,
    'purchase_id', n.purchase_id, 'params', n.params, 'read_at', n.read_at, 'created_at', n.created_at,
    'text', app.render_notification(n.kind, me.lang, n.params))
    order by n.created_at desc, n.id), '[]'::jsonb)
  from me, lateral (
    select * from public.notifications x
    where x.user_id = me.id and app.notification_app(x.kind) = p_app
    order by x.created_at desc, x.id
    limit least(greatest(coalesce(p_limit, 50), 1), 200)) n
$$;
revoke all on function public.my_app_notifications(text, integer) from public;
grant execute on function public.my_app_notifications(text, integer) to authenticated;

create or replace function public.unread_app_notifications(p_app text)
returns integer
language sql stable security definer set search_path = ''
as $$
  select count(*)::int from public.notifications
  where user_id = app.require_user() and read_at is null and app.notification_app(kind) = p_app
$$;
revoke all on function public.unread_app_notifications(text) from public;
grant execute on function public.unread_app_notifications(text) to authenticated;

insert into public.event_names (name, emitted_by, description) values
  ('call_missed', 'server', 'Appel non décroché en 60 s (spec 097)')
on conflict do nothing;
