-- 0102 — Groupe famille (spec 112) : pas de boutique. `store_id` rendu vide plutôt que nul, pour
-- que les apps déjà installées (qui l'exigent) lisent encore la liste des conversations.

create or replace function app.conversation_json(p_conversation uuid, p_role text)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', c.id, 'store_id', coalesce(s.id::text, ''), 'store_name', coalesce(s.name, ''), 'store_origin', s.origin,
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
