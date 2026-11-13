-- Statistiques admin des échanges (specs 070 à 072) : messages, conversations,
-- boutiques actives par origine (supermarchés compris), notifications
-- envoyées ou retenues, nuit calme.

create or replace function public.admin_exchanges(p_period text default 'day', p_at timestamptz default now())
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_since timestamptz := p_at - case p_period when 'week' then interval '7 days'
                                              when 'month' then interval '30 days'
                                              else interval '1 day' end;
begin
  perform app.require_admin();
  return jsonb_build_object(
    'messages', (select count(*) from public.events e
                 where e.name in ('chat_message_sent', 'voice_message_sent')
                   and e.occurred_at > v_since and e.occurred_at <= p_at),
    'messages_with_order', (select count(*) from public.events e
                            where e.name = 'chat_message_sent' and (e.props ->> 'with_order')::boolean
                              and e.occurred_at > v_since and e.occurred_at <= p_at),
    'conversations_active', (select count(distinct m.conversation_id) from public.messages m
                             where m.created_at > v_since and m.created_at <= p_at),
    'stores_by_origin', (select coalesce(jsonb_agg(jsonb_build_object(
                           'code', o.code, 'label', o.label,
                           'stores', (select count(*) from public.stores s
                                      where s.origin = o.code and s.status = 'active'))
                           order by o.sort), '[]'::jsonb)
                         from public.store_origins o where o.is_active),
    'push_sent', (select count(*) from public.notifications n
                  where n.push_outcome = 'sent' and n.pushed_at > v_since and n.pushed_at <= p_at),
    'push_skipped', (select count(*) from public.notifications n
                     where n.push_outcome = 'skipped' and n.pushed_at > v_since and n.pushed_at <= p_at),
    'push_failed', (select count(*) from public.notifications n
                    where n.push_outcome = 'failed' and n.pushed_at > v_since and n.pushed_at <= p_at),
    'quiet_night_users', (select count(*) from public.notification_preferences
                          where category = 'quiet_night' and push_enabled));
end
$$;

revoke all on function public.admin_exchanges(text, timestamptz) from public, anonymous;
grant execute on function public.admin_exchanges(text, timestamptz) to authenticated;
