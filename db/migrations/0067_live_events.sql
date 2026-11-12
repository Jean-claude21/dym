-- 0067 — Événements en direct (spec 067).
-- Chaque changement utile est écrit, dans la même transaction, comme un
-- événement adressé à une personne. La passerelle temps réel (Function
-- `/v1/live`) les pousse par WebSocket à leur seule destinataire, identifiée
-- par son jeton : aucune autorisation par sujet à vérifier. Rien n'est lisible
-- par la Data API ; les événements sont courts (identifiants, statut) et
-- l'app recharge ce qu'elle affiche.

create table public.live_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  kind text not null check (kind in ('message', 'order_status', 'notification')),
  entity_id uuid,
  payload jsonb not null default '{}'::jsonb
    check (jsonb_typeof(payload) = 'object' and pg_column_size(payload) <= 1024),
  created_at timestamptz not null default clock_timestamp()
);
create index live_events_user on public.live_events (user_id, id);
create index live_events_time on public.live_events (created_at);
alter table public.live_events enable row level security;

-- Nouveau message : la cliente et la vendeuse (autres appareils compris).
create or replace function app.live_on_message() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.live_events (user_id, kind, entity_id, payload)
  select u.id, 'message', new.conversation_id,
         jsonb_build_object('message_id', new.id, 'author_role', new.author_role)
  from public.conversations c
  join public.stores s on s.id = c.store_id
  cross join lateral (values (c.client_id), (s.owner_id)) u(id)
  where c.id = new.conversation_id and u.id is not null;
  return null;
end
$$;
create trigger messages_live after insert on public.messages
  for each row execute function app.live_on_message();

-- Statut d'une commande : cliente, vendeuse, livreur assigné.
create or replace function app.live_on_order_status() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if old.status is not distinct from new.status then
    return null;
  end if;
  insert into public.live_events (user_id, kind, entity_id, payload)
  select distinct u.id, 'order_status', new.id,
         jsonb_build_object('status', new.status, 'purchase_id', new.purchase_id)
  from (
    select pu.user_id as id from public.purchases pu where pu.id = new.purchase_id
    union all
    select s.owner_id from public.stores s where s.id = new.store_id
    union all
    select oc.courier_id from public.order_couriers oc where oc.order_id = new.id
  ) u
  where u.id is not null;
  return null;
end
$$;
create trigger orders_live after update of status on public.orders
  for each row execute function app.live_on_order_status();

-- Notification créée (course proposée, commande prête, livreur assigné…).
create or replace function app.live_on_notification() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.live_events (user_id, kind, entity_id, payload)
  values (new.user_id, 'notification', coalesce(new.order_id, new.purchase_id),
          jsonb_build_object('kind', new.kind, 'category', new.category));
  return null;
end
$$;
create trigger notifications_live after insert on public.notifications
  for each row execute function app.live_on_notification();

-- Lecture par la passerelle : événements des personnes connectées après un
-- curseur. Relecture d'une fenêtre courte (les identifiants ne sont pas
-- validés dans l'ordre) ; la passerelle écarte les doublons.
create or replace function app.live_events_since(p_users uuid[], p_after bigint, p_limit integer default 500)
returns setof public.live_events
language sql stable security definer set search_path = ''
as $$
  select * from public.live_events e
  where e.user_id = any (p_users) and e.id > p_after
  order by e.id
  limit least(greatest(p_limit, 1), 1000)
$$;

-- Dernier identifiant (curseur de départ d'une connexion neuve).
create or replace function app.live_last_id() returns bigint
language sql stable security definer set search_path = ''
as $$
  select coalesce(max(id), 0) from public.live_events
$$;

-- Ménage : les événements servent à la reprise après une coupure courte.
create or replace function app.prune_live_events(p_at timestamptz default now()) returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_count integer;
begin
  delete from public.live_events where created_at < p_at - interval '24 hours';
  get diagnostics v_count = row_count;
  return v_count;
end
$$;

revoke all on function app.live_on_message(), app.live_on_order_status(), app.live_on_notification(),
  app.live_events_since(uuid[], bigint, integer), app.live_last_id(), app.prune_live_events(timestamptz)
  from public;
