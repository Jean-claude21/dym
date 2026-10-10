-- 0018 — Pilote, côté apps (spec 016 : C-REV-01/03/04, V-REV-01/02/04, C-ORD-09,
-- A-SUP-01..03 côté apps). Avis après livraison et réponse de la vendeuse ;
-- réachat en un tap ; demandes d'aide (tickets) des clientes et vendeuses.

-- ------------------------------------------------------------------ avis

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  author_id uuid references neon_auth."user" (id) on delete set null,
  rating smallint not null check (rating between 1 and 5),
  tags text[] not null default '{}'
    check (tags <@ array['fresh', 'well_packed', 'fast', 'friendly']),
  comment text check (comment is null or length(comment) between 1 and 500),
  reply text check (reply is null or length(reply) between 1 and 500),
  replied_at timestamptz,
  status text not null default 'published' check (status in ('published', 'removed')),
  created_at timestamptz not null default clock_timestamp()
);

create index reviews_store on public.reviews (store_id, created_at desc) where status = 'published';

alter table public.reviews enable row level security;
-- Lecture et écriture par fonctions seulement.

create or replace function app.review_json(p_review uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', r.id, 'order_id', r.order_id, 'store_id', r.store_id, 'rating', r.rating,
    'tags', to_jsonb(r.tags), 'comment', r.comment, 'reply', r.reply,
    'replied_at', r.replied_at, 'created_at', r.created_at, 'status', r.status,
    'author_first_name', (select first_name from public.profiles where user_id = r.author_id))
  from public.reviews r where r.id = p_review
$$;

-- Note de la boutique (avis publiés).
create or replace function app.store_rating(p_store uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'rating', round(avg(rating)::numeric, 1),
    'review_count', count(*),
    'distribution', jsonb_build_object(
      '5', count(*) filter (where rating = 5), '4', count(*) filter (where rating = 4),
      '3', count(*) filter (where rating = 3), '2', count(*) filter (where rating = 2),
      '1', count(*) filter (where rating = 1)))
  from public.reviews where store_id = p_store and status = 'published'
$$;

-- Avis d'une cliente sur sa commande livrée. Refus (P0001) : review_not_allowed,
-- review_exists ; commande d'autrui : P0002.
create or replace function app.leave_review(
  p_user uuid,
  p_order uuid,
  p_rating int,
  p_tags text[],
  p_comment text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
  v_client uuid;
  v_owner uuid;
  v_id uuid;
begin
  select o.* into v_order from public.orders o where o.id = p_order;
  select user_id into v_client from public.purchases where id = v_order.purchase_id;
  if v_order.id is null or v_client is distinct from p_user then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  if v_order.status <> 'delivered' then
    raise exception 'review_not_allowed' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.reviews where order_id = p_order) then
    raise exception 'review_exists' using errcode = 'P0001';
  end if;
  if p_rating is null or p_rating not between 1 and 5 then
    raise exception 'note invalide' using errcode = '22023';
  end if;
  insert into public.reviews (order_id, store_id, author_id, rating, tags, comment)
  values (p_order, v_order.store_id, p_user, p_rating,
          coalesce((select array_agg(distinct t) from unnest(p_tags) t), '{}'),
          left(nullif(trim(p_comment), ''), 500))
  returning id into v_id;
  select owner_id into v_owner from public.stores where id = v_order.store_id;
  perform app.notify(v_owner, 'review_received', 'orders', p_order, v_order.purchase_id,
    jsonb_build_object('rating', p_rating));
  perform app.emit_event('review_left', p_user, 'client', 'server',
    (select country_code from public.purchases where id = v_order.purchase_id),
    'review', v_id::text, jsonb_build_object('rating', p_rating, 'has_comment', p_comment is not null));
  return app.review_json(v_id);
end
$$;

-- Réponse de la vendeuse (une seule, modifiable). Avis d'une autre boutique : P0002.
create or replace function app.reply_review(p_user uuid, p_review uuid, p_reply text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_review public.reviews;
  v_client uuid;
  v_text text := left(nullif(trim(p_reply), ''), 500);
begin
  select r.* into v_review from public.reviews r
  join public.stores s on s.id = r.store_id
  where r.id = p_review and s.owner_id = p_user;
  if v_review.id is null then
    raise exception 'avis introuvable' using errcode = 'P0002';
  end if;
  if v_text is null then
    raise exception 'reply_invalid' using errcode = 'P0001';
  end if;
  update public.reviews set reply = v_text, replied_at = now() where id = p_review;
  select p.user_id into v_client from public.orders o
  join public.purchases p on p.id = o.purchase_id where o.id = v_review.order_id;
  perform app.notify(v_client, 'review_replied', 'orders', v_review.order_id, null,
    jsonb_build_object('store_name', (select name from public.stores where id = v_review.store_id)));
  return app.review_json(p_review);
end
$$;

-- Avis publiés d'une boutique active (visiteuse comprise).
create or replace function public.store_reviews(p_store uuid, p_limit int default 30) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select app.store_rating(p_store) || jsonb_build_object(
    'reviews', (select coalesce(jsonb_agg(app.review_json(r.id) order by r.created_at desc), '[]'::jsonb)
                from (select id, created_at from public.reviews
                      where store_id = p_store and status = 'published'
                      order by created_at desc
                      limit least(greatest(coalesce(p_limit, 30), 1), 100)) r))
  where exists (select 1 from public.stores where id = p_store and status = 'active')
$$;

-- Avis de ma boutique (vendeuse).
create or replace function public.my_store_reviews(p_limit int default 50) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select app.store_rating(app.own_store_id()) || jsonb_build_object(
    'reviews', (select coalesce(jsonb_agg(app.review_json(r.id) order by r.created_at desc), '[]'::jsonb)
                from (select id, created_at from public.reviews
                      where store_id = app.own_store_id() and status = 'published'
                      order by created_at desc
                      limit least(greatest(coalesce(p_limit, 50), 1), 200)) r))
$$;

-- Avis de la cliente sur une commande (nul : pas encore donné).
create or replace function public.order_review(p_order uuid) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  if not exists (select 1 from public.orders o join public.purchases p on p.id = o.purchase_id
                 where o.id = p_order and p.user_id = v_user) then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  return (select app.review_json(id) from public.reviews where order_id = p_order);
end
$$;

-- Note dans les résumés de boutique (accueil, page boutique, recherche).
create or replace function app.store_summary(p_store uuid, p_at timestamptz) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', s.id, 'name', s.name, 'description', s.description, 'origin', s.origin,
    'zone_id', s.zone_id, 'zone_name', z.name,
    'zone_latitude', z.latitude, 'zone_longitude', z.longitude,
    'country_code', s.country_code, 'currency_code', s.currency_code,
    'prep_time_minutes', s.prep_time_minutes, 'offers_pickup', s.offers_pickup,
    'open_now', app.store_open_at(s.id, p_at),
    'closes_at', (select to_char(h.closes_at, 'HH24:MI') from app.store_hours_today(s.id, p_at) h
                  where h.store_id is not null),
    'delivery_minutes', s.prep_time_minutes + c.delivery_minutes,
    'cover_key', (
      select f.object_key from public.products p
      join public.product_photos f on f.product_id = p.id
      where p.store_id = s.id and p.status = 'published'
      order by p.published_at, f.sort limit 1),
    'product_count', (select count(*) from public.products p where p.store_id = s.id and p.status = 'published'),
    'rating', (select round(avg(r.rating)::numeric, 1) from public.reviews r
               where r.store_id = s.id and r.status = 'published'),
    'review_count', (select count(*) from public.reviews r where r.store_id = s.id and r.status = 'published')
  )
  from public.stores s
  join public.zones z on z.id = s.zone_id
  join public.cities c on c.id = z.city_id
  where s.id = p_store and s.status = 'active'
$$;

-- ------------------------------------------------------------------ réachat

-- Remet au panier les articles d'une commande encore en vente (quantité
-- d'origine, prix du jour). Renvoie le panier et les articles écartés.
create or replace function public.reorder(p_order uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_item record;
  v_added int := 0;
  v_skipped jsonb := '[]'::jsonb;
  v_cart jsonb;
begin
  if not exists (select 1 from public.orders o join public.purchases p on p.id = o.purchase_id
                 where o.id = p_order and p.user_id = v_user) then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  for v_item in select i.variant_id, i.product_name as name, i.quantity from public.order_items i
                where i.order_id = p_order order by i.product_name loop
    begin
      v_cart := public.cart_add(v_item.variant_id, v_item.quantity);
      v_added := v_added + 1;
    exception when others then
      v_skipped := v_skipped || jsonb_build_array(v_item.name);
    end;
  end loop;
  perform app.emit_event('reorder_tapped', v_user, 'client', 'client',
    (select country_code from public.profiles where user_id = v_user), 'order', p_order::text,
    jsonb_build_object('added', v_added, 'skipped', jsonb_array_length(v_skipped)));
  return jsonb_build_object('added', v_added, 'skipped', v_skipped,
    'cart', coalesce(v_cart, public.my_cart()));
end
$$;

-- ------------------------------------------------------------------ support

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  app text not null check (app in ('client', 'vendor')),
  subject text not null check (subject in ('order', 'payment', 'account', 'store', 'other')),
  order_id uuid references public.orders (id) on delete set null,
  status text not null default 'open' check (status in ('open', 'pending', 'closed')),
  created_at timestamptz not null default clock_timestamp(),
  last_activity_at timestamptz not null default clock_timestamp(),
  first_response_at timestamptz,
  closed_at timestamptz
);

create index support_tickets_open on public.support_tickets (status, last_activity_at);

create table public.support_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets (id) on delete cascade,
  author_id uuid references neon_auth."user" (id) on delete set null,
  author_role text not null check (author_role in ('user', 'team')),
  body text not null check (length(body) between 1 and 2000),
  created_at timestamptz not null default clock_timestamp()
);

create index support_messages_ticket on public.support_messages (ticket_id, created_at);

alter table public.support_tickets enable row level security;
alter table public.support_messages enable row level security;

create or replace function app.ticket_json(p_ticket uuid, p_internal boolean default false) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', t.id, 'app', t.app, 'subject', t.subject, 'order_id', t.order_id,
    'order_reference', case when t.order_id is null then null else upper(left(t.order_id::text, 8)) end,
    'status', t.status, 'created_at', t.created_at, 'last_activity_at', t.last_activity_at,
    'first_response_at', t.first_response_at, 'closed_at', t.closed_at,
    'messages', (select coalesce(jsonb_agg(jsonb_build_object(
                   'id', m.id, 'author_role', m.author_role, 'body', m.body, 'created_at', m.created_at)
                   order by m.created_at, m.id), '[]'::jsonb)
                 from public.support_messages m where m.ticket_id = t.id))
  || case when p_internal then jsonb_build_object(
       'user_first_name', (select first_name from public.profiles where user_id = t.user_id),
       'user_id', t.user_id,
       'store_name', (select name from public.stores where owner_id = t.user_id))
     else '{}'::jsonb end
  from public.support_tickets t where t.id = p_ticket
$$;

-- Ouvrir une demande (cliente ou vendeuse). Commande d'autrui : P0002.
create or replace function public.open_ticket(
  p_app text,
  p_subject text,
  p_body text,
  p_order uuid default null
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_id uuid;
  v_body text := nullif(trim(p_body), '');
begin
  if p_app is null or p_app not in ('client', 'vendor') then
    raise exception 'app inconnue' using errcode = '22023';
  end if;
  if v_body is null or length(v_body) > 2000 then
    raise exception 'ticket_invalid' using errcode = 'P0001';
  end if;
  if p_order is not null and not exists (
    select 1 from public.orders o join public.purchases p on p.id = o.purchase_id
    join public.stores s on s.id = o.store_id
    where o.id = p_order and (p.user_id = v_user or s.owner_id = v_user)) then
    raise exception 'commande introuvable' using errcode = 'P0002';
  end if;
  insert into public.support_tickets (user_id, app, subject, order_id)
  values (v_user, p_app, p_subject, p_order) returning id into v_id;
  insert into public.support_messages (ticket_id, author_id, author_role, body)
  values (v_id, v_user, 'user', v_body);
  perform app.emit_event('support_ticket_opened', v_user, p_app, p_app,
    (select country_code from public.profiles where user_id = v_user), 'ticket', v_id::text,
    jsonb_build_object('subject', p_subject));
  return app.ticket_json(v_id);
end
$$;

-- Message de l'utilisatrice sur sa demande ; la rouvre si elle était close.
create or replace function public.reply_ticket(p_ticket uuid, p_body text) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_body text := nullif(trim(p_body), '');
begin
  if not exists (select 1 from public.support_tickets where id = p_ticket and user_id = v_user) then
    raise exception 'demande introuvable' using errcode = 'P0002';
  end if;
  if v_body is null or length(v_body) > 2000 then
    raise exception 'ticket_invalid' using errcode = 'P0001';
  end if;
  insert into public.support_messages (ticket_id, author_id, author_role, body)
  values (p_ticket, v_user, 'user', v_body);
  update public.support_tickets set status = 'open', closed_at = null, last_activity_at = now()
  where id = p_ticket;
  return app.ticket_json(p_ticket);
end
$$;

create or replace function public.my_tickets(p_app text default 'client') returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.ticket_json(t.id) order by t.last_activity_at desc), '[]'::jsonb)
  from public.support_tickets t
  where t.user_id = app.require_user() and t.app = p_app
$$;

-- ------------------------------------------------------------------ notifications

create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor', 'review_received', 'support_replied_vendor')
    then 'vendor' else 'client' end
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('review_received', 'fr', 'Nouvel avis', 'Une cliente a noté ta boutique {rating}/5.'),
  ('review_received', 'en', 'New review', 'A customer rated your shop {rating}/5.'),
  ('review_replied', 'fr', 'Réponse à ton avis', '{store_name} a répondu à ton avis.'),
  ('review_replied', 'en', 'Reply to your review', '{store_name} replied to your review.'),
  ('support_replied', 'fr', 'Réponse de l''équipe', 'L''équipe DYM a répondu à ta demande.'),
  ('support_replied', 'en', 'Team reply', 'The DYM team replied to your request.'),
  ('support_replied_vendor', 'fr', 'Réponse de l''équipe', 'L''équipe DYM a répondu à ta demande.'),
  ('support_replied_vendor', 'en', 'Team reply', 'The DYM team replied to your request.');

insert into public.event_names (name, emitted_by, description) values
  ('review_left', 'server', 'Avis laissé (note, commentaire présent)'),
  ('reorder_tapped', 'server', 'Réachat en un tap (articles ajoutés, écartés)'),
  ('support_ticket_opened', 'server', 'Demande d''aide ouverte (sujet)')
on conflict (name) do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function
  app.review_json(uuid), app.store_rating(uuid), app.leave_review(uuid, uuid, int, text[], text),
  app.reply_review(uuid, uuid, text), app.ticket_json(uuid, boolean),
  public.store_reviews(uuid, int), public.my_store_reviews(int), public.order_review(uuid),
  public.reorder(uuid), public.open_ticket(text, text, text, uuid), public.reply_ticket(uuid, text),
  public.my_tickets(text)
from public;

grant execute on function public.store_reviews(uuid, int) to authenticated, anonymous;
grant execute on function
  public.my_store_reviews(int), public.order_review(uuid), public.reorder(uuid),
  public.open_ticket(text, text, text, uuid), public.reply_ticket(uuid, text), public.my_tickets(text)
to authenticated;
