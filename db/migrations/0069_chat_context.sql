-- Conversation en contexte (spec 070) : « vu » (lecture de l'autre personne)
-- et commande en cours entre la cliente et la boutique, affichée en tête du fil.

-- Dernière commande en cours de cette cliente dans cette boutique (nulle sinon).
create or replace function app.conversation_active_order(p_conversation uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('id', o.id, 'status', o.status, 'created_at', o.created_at,
                            'total_minor', o.total_minor, 'currency_code', o.currency_code)
  from public.conversations c
  join public.orders o on o.store_id = c.store_id
  join public.purchases p on p.id = o.purchase_id and p.user_id = c.client_id
  where c.id = p_conversation
    and o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
  order by o.created_at desc, o.id desc
  limit 1
$$;

revoke all on function app.conversation_active_order(uuid) from public;

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
    -- Lecture de l'autre personne : les messages envoyés avant sont « vus ».
    'peer_read_at', (select case v_role when 'client' then vendor_read_at else client_read_at end
                     from public.conversations where id = p_id),
    'active_order', app.conversation_active_order(p_id),
    'messages', (select coalesce(jsonb_agg(app.message_json(x.id) order by x.created_at, x.id), '[]'::jsonb)
                 from (select id, created_at from public.messages
                       where conversation_id = p_id and (p_before is null or created_at < p_before)
                       order by created_at desc, id desc
                       limit least(greatest(coalesce(p_limit, 50), 1), 200)) x));
end
$$;

-- Mesure (METRICS) : chaque message texte, photo ou produit (le vocal a déjà
-- `voice_message_sent`), avec le type, le rôle et une commande en cours ou non.
insert into public.event_names (name, emitted_by, description) values
  ('chat_message_sent', 'server', 'Message envoyé (type, rôle, commande en cours)')
on conflict do nothing;

create or replace function app.track_chat_message() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.kind in ('text', 'image', 'product') then
    perform app.emit_event('chat_message_sent', new.author_id, new.author_role, 'server',
      (select country_code from public.profiles where user_id = new.author_id), 'message', new.id::text,
      jsonb_build_object('kind', new.kind, 'role', new.author_role,
        'with_order', app.conversation_active_order(new.conversation_id) is not null));
  end if;
  return new;
end
$$;

create trigger messages_track after insert on public.messages
  for each row execute function app.track_chat_message();
