-- 0092 — Chat de commerce (spec 099) : vidéo, position (ponctuelle ou en direct), devis accepté en
-- un geste, demande de paiement (spec 046), coupon de boutique, transcription des vocaux.
-- Les montants restent calculés en base : un devis passe par des prix négociés (spec 050), un
-- coupon par le prix de la ligne du panier ; jamais par l'app.

-- ------------------------------------------------------------------ messages

alter table public.messages
  add column payload jsonb check (payload is null or jsonb_typeof(payload) = 'object'),
  add column transcript text check (transcript is null or length(transcript) <= 4000),
  add column live_until timestamptz;
alter table public.messages drop constraint messages_kind_check;
alter table public.messages add constraint messages_kind_check check (kind in
  ('text', 'image', 'product', 'audio', 'call', 'video', 'location', 'quote', 'payment_request', 'coupon'));
alter table public.messages add constraint messages_video_check
  check (kind <> 'video' or media_key is not null);
alter table public.messages add constraint messages_location_check
  check (kind <> 'location' or (payload ? 'latitude' and payload ? 'longitude'));

-- ------------------------------------------------------------------ devis et coupons

create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  client_id uuid not null references neon_auth."user" (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'expired')),
  note text check (note is null or length(note) <= 280),
  total_minor bigint not null check (total_minor > 0),
  currency_code char(3) not null references public.currencies (code),
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
alter table public.quotes enable row level security;
-- Lecture par les fonctions du chat seulement.
alter table public.haggles add column quote_id uuid references public.quotes (id) on delete set null;

create table public.coupons (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  conversation_id uuid references public.conversations (id) on delete set null,
  percent smallint not null check (percent between 1 and 50),
  expires_at timestamptz not null,
  created_by uuid not null,
  created_at timestamptz not null default now()
);
alter table public.coupons enable row level security;

create table public.coupon_claims (
  coupon_id uuid not null references public.coupons (id) on delete cascade,
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  claimed_at timestamptz not null default now(),
  order_id uuid references public.orders (id) on delete set null,
  primary key (coupon_id, user_id)
);
alter table public.coupon_claims enable row level security;

-- Prix « coupon » d'une variante pour la personne du panier : meilleur coupon réclamé, valide,
-- pas encore utilisé, de la boutique du produit ; arrondi à l'unité mineure supérieure.
create or replace function app.coupon_price(p_cart uuid, p_variant uuid)
returns bigint
language sql stable security definer set search_path = ''
as $$
  select ceil(app.variant_price(p_variant) * (100 - max(cp.percent)) / 100.0)::bigint
  from public.coupon_claims cc
  join public.coupons cp on cp.id = cc.coupon_id
  join public.carts c on c.user_id = cc.user_id
  join public.product_variants v on v.id = p_variant
  join public.products p on p.id = v.product_id
  where c.id = p_cart and cp.store_id = p.store_id and cp.expires_at > now() and cc.order_id is null
$$;
revoke all on function app.coupon_price(uuid, uuid) from public;

create or replace function app.cart_line_price(p_cart uuid, p_variant uuid, p_quantity integer)
returns bigint
language sql stable security definer set search_path = ''
as $$
  select least(
    app.variant_price(p_variant),
    (select min(h.price_minor) from public.haggles h join public.carts c on c.user_id = h.user_id
     where c.id = p_cart and h.variant_id = p_variant and h.status = 'accepted' and h.expires_at > now()
       and p_quantity <= h.quantity),
    (select min(o.group_price_minor) from public.group_members m
     join public.group_offers o on o.id = m.offer_id
     join public.carts c on c.user_id = m.user_id
     where c.id = p_cart and o.variant_id = p_variant and app.group_active(o) and m.order_id is null
       and p_quantity <= m.quantity),
    -- Coupon de la boutique (spec 099).
    app.coupon_price(p_cart, p_variant))
$$;

create or replace function app.cart_line_source(p_cart uuid, p_variant uuid, p_quantity integer)
returns text
language sql stable security definer set search_path = ''
as $$
  with p as (
    select app.variant_price(p_variant) as list,
      (select min(h.price_minor) from public.haggles h join public.carts c on c.user_id = h.user_id
       where c.id = p_cart and h.variant_id = p_variant and h.status = 'accepted' and h.expires_at > now()
         and p_quantity <= h.quantity) as haggle,
      (select min(o.group_price_minor) from public.group_members m
       join public.group_offers o on o.id = m.offer_id
       join public.carts c on c.user_id = m.user_id
       where c.id = p_cart and o.variant_id = p_variant and app.group_active(o) and m.order_id is null
         and p_quantity <= m.quantity) as grp,
      app.coupon_price(p_cart, p_variant) as coupon)
  select case
    when least(list, haggle, grp, coupon) >= list then null
    when grp is not null and grp <= least(coalesce(haggle, grp), coalesce(coupon, grp)) then 'group'
    when coupon is not null and coupon <= coalesce(haggle, coupon) then 'coupon'
    else 'haggle' end
  from p
$$;

-- Commande passée : le coupon de la boutique est consommé (une commande par coupon).
create or replace function app.consume_coupons()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.coupon_claims cc set order_id = new.id
  from public.coupons cp, public.purchases pu
  where cp.id = cc.coupon_id and pu.id = new.purchase_id and cc.user_id = pu.user_id
    and cp.store_id = new.store_id and cc.order_id is null and cp.expires_at > now();
  return new;
end
$$;
create trigger orders_consume_coupons after insert on public.orders
  for each row execute function app.consume_coupons();

-- ------------------------------------------------------------------ envoi

drop function app.send_message(uuid, uuid, text, text, text, uuid, uuid, integer);
create function app.send_message(
  p_user uuid, p_conversation uuid, p_kind text, p_body text, p_media_key text, p_product uuid,
  p_key uuid, p_duration_ms integer default null, p_payload jsonb default null
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
  v_live integer := coalesce((p_payload ->> 'live_minutes')::integer, 0);
begin
  if v_role is null then
    raise exception 'conversation introuvable' using errcode = 'P0002';
  end if;
  if p_key is null or p_kind is null or p_kind not in
     ('text', 'image', 'product', 'audio', 'video', 'location', 'quote', 'payment_request', 'coupon') then
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
  if p_kind = 'location' and (
      (p_payload ->> 'latitude')::numeric is null or (p_payload ->> 'longitude')::numeric is null
      or (p_payload ->> 'latitude')::numeric not between -90 and 90
      or (p_payload ->> 'longitude')::numeric not between -180 and 180
      or v_live not between 0 and 60) then
    raise exception 'location_invalid' using errcode = 'P0001';
  end if;
  if p_kind = 'product' and not exists (
    select 1 from public.products p
    where p.id = p_product and p.store_id = v_conv.store_id and p.status = 'published') then
    raise exception 'product_invalid' using errcode = 'P0001';
  end if;

  insert into public.messages (conversation_id, author_id, author_role, kind, body, media_key,
                               product_id, idempotency_key, duration_ms, payload, live_until)
  values (p_conversation, p_user, v_role, p_kind,
          case when p_kind in ('text', 'video') then v_body end,
          case when p_kind in ('image', 'audio', 'video') then p_media_key end,
          case when p_kind = 'product' then p_product end, p_key,
          case when p_kind in ('audio', 'video') then p_duration_ms end,
          case when p_kind = 'location' then jsonb_build_object(
                 'latitude', round((p_payload ->> 'latitude')::numeric, 6),
                 'longitude', round((p_payload ->> 'longitude')::numeric, 6))
               when p_kind in ('quote', 'payment_request', 'coupon') then p_payload end,
          case when p_kind = 'location' and v_live > 0
               then clock_timestamp() + make_interval(mins => v_live) end)
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
revoke all on function app.send_message(uuid, uuid, text, text, text, uuid, uuid, integer, jsonb) from public;

-- Message lu par l'app : contenu structuré et état à jour (devis, paiement, coupon).
create or replace function app.message_json(p_message uuid)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', m.id, 'conversation_id', m.conversation_id, 'author_role', m.author_role,
    'kind', m.kind, 'body', m.body, 'has_media', m.media_key is not null,
    'product', case when m.product_id is not null then app.catalog_item(m.product_id) end,
    'product_id', m.product_id, 'created_at', m.created_at,
    'duration_ms', m.duration_ms, 'transcript', m.transcript,
    'payload', case
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
$$;

-- Position en direct : l'autrice la met à jour jusqu'à la fin (60 min au plus), ou l'arrête.
create or replace function public.chat_update_location(p_message uuid, p_latitude numeric, p_longitude numeric)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  update public.messages set payload = jsonb_build_object(
      'latitude', round(p_latitude, 6), 'longitude', round(p_longitude, 6), 'updated_at', clock_timestamp())
  where id = p_message and author_id = v_user and kind = 'location' and live_until > clock_timestamp()
    and p_latitude between -90 and 90 and p_longitude between -180 and 180;
  if not found then raise exception 'not_live' using errcode = 'P0001'; end if;
  return app.message_json(p_message);
end
$$;
revoke all on function public.chat_update_location(uuid, numeric, numeric) from public;
grant execute on function public.chat_update_location(uuid, numeric, numeric) to authenticated;

create or replace function public.chat_stop_location(p_message uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  update public.messages set live_until = clock_timestamp()
  where id = p_message and author_id = v_user and kind = 'location' and live_until > clock_timestamp();
  return app.message_json(p_message);
end
$$;
revoke all on function public.chat_stop_location(uuid) from public;
grant execute on function public.chat_stop_location(uuid) to authenticated;

-- Position, envoyée par la Data API (sans média).
create or replace function public.chat_send_location(
  p_conversation uuid, p_latitude numeric, p_longitude numeric, p_live_minutes integer, p_key uuid
) returns jsonb
language sql security definer set search_path = ''
as $$
  select app.send_message(app.require_user(), p_conversation, 'location', null, null, null, p_key, null,
    jsonb_build_object('latitude', p_latitude, 'longitude', p_longitude, 'live_minutes', coalesce(p_live_minutes, 0)))
$$;
revoke all on function public.chat_send_location(uuid, numeric, numeric, integer, uuid) from public;
grant execute on function public.chat_send_location(uuid, numeric, numeric, integer, uuid) to authenticated;

-- ------------------------------------------------------------------ devis

-- La vendeuse propose un devis (lignes : variante, quantité, prix) valable 48 h.
create or replace function public.send_quote(p_conversation uuid, p_lines jsonb, p_note text, p_key uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_conv public.conversations;
  v_store public.stores;
  v_quote uuid;
  v_line jsonb;
  v_list bigint;
  v_total bigint := 0;
  v_items jsonb := '[]'::jsonb;
  v_existing uuid;
begin
  select * into v_conv from public.conversations where id = p_conversation;
  if v_conv.id is null or app.conversation_role(v_user, p_conversation) <> 'vendor' then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  select id into v_existing from public.messages
  where conversation_id = p_conversation and author_role = 'vendor' and idempotency_key = p_key;
  if v_existing is not null then return app.message_json(v_existing); end if;
  select * into v_store from public.stores where id = v_conv.store_id;
  if jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) not between 1 and 20 then
    raise exception 'quote_invalid' using errcode = 'P0001';
  end if;
  insert into public.quotes (conversation_id, store_id, client_id, note, total_minor, currency_code, expires_at)
  values (p_conversation, v_store.id, v_conv.client_id, left(nullif(btrim(p_note), ''), 280), 1,
          v_store.currency_code, now() + interval '48 hours')
  returning id into v_quote;
  for v_line in select * from jsonb_array_elements(p_lines) loop
    select app.variant_price(v.id) into v_list from public.product_variants v
    join public.products p on p.id = v.product_id
    where v.id = (v_line ->> 'variant_id')::uuid and p.store_id = v_store.id and p.status = 'published';
    if v_list is null or (v_line ->> 'quantity')::int not between 1 and 99
       or (v_line ->> 'price_minor')::bigint not between 1 and v_list then
      raise exception 'quote_invalid' using errcode = 'P0001';
    end if;
    insert into public.haggles (user_id, store_id, product_id, variant_id, quantity, currency_code,
                                list_price_minor, offer_minor, price_minor, status, expires_at, quote_id)
    select v_conv.client_id, v_store.id, v.product_id, v.id, (v_line ->> 'quantity')::int, v_store.currency_code,
           v_list, (v_line ->> 'price_minor')::bigint, (v_line ->> 'price_minor')::bigint, 'countered',
           now() + interval '48 hours', v_quote
    from public.product_variants v where v.id = (v_line ->> 'variant_id')::uuid;
    v_total := v_total + (v_line ->> 'price_minor')::bigint * (v_line ->> 'quantity')::int;
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'variant_id', v_line ->> 'variant_id', 'quantity', (v_line ->> 'quantity')::int,
      'price_minor', (v_line ->> 'price_minor')::bigint, 'list_price_minor', v_list,
      'name', (select p.name || coalesce(' · ' || v.label, '') from public.product_variants v
               join public.products p on p.id = v.product_id where v.id = (v_line ->> 'variant_id')::uuid)));
  end loop;
  update public.quotes set total_minor = v_total where id = v_quote;
  return app.send_message(v_user, p_conversation, 'quote', null, null, null, p_key, null,
    jsonb_build_object('quote_id', v_quote, 'lines', v_items, 'total_minor', v_total,
      'currency_code', v_store.currency_code, 'note', left(nullif(btrim(p_note), ''), 280),
      'expires_at', now() + interval '48 hours'));
end
$$;
revoke all on function public.send_quote(uuid, jsonb, text, uuid) from public;
grant execute on function public.send_quote(uuid, jsonb, text, uuid) to authenticated;

-- La cliente accepte en un geste : les lignes passent au panier, aux prix du devis.
create or replace function public.accept_quote(p_quote uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_q public.quotes;
  v_h record;
begin
  select * into v_q from public.quotes where id = p_quote and client_id = v_user for update;
  if v_q.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_q.status <> 'pending' or v_q.expires_at <= now() then
    raise exception 'quote_expired' using errcode = 'P0001';
  end if;
  update public.quotes set status = 'accepted' where id = p_quote;
  for v_h in select id from public.haggles where quote_id = p_quote loop
    update public.haggles set status = 'accepted', expires_at = now() + interval '24 hours' where id = v_h.id;
    perform app.haggle_to_cart(v_h.id);
  end loop;
  perform app.emit_event('quote_accepted', v_user, 'client', 'server',
    (select country_code from public.stores where id = v_q.store_id), 'store', v_q.store_id::text,
    jsonb_build_object('lines', (select count(*) from public.haggles where quote_id = p_quote)));
  return jsonb_build_object('quote_id', p_quote, 'status', 'accepted');
end
$$;
revoke all on function public.accept_quote(uuid) from public;
grant execute on function public.accept_quote(uuid) to authenticated;

-- ------------------------------------------------------------------ paiement et coupon

-- Demande de paiement dans le chat (spec 046) : la cliente paie avec son wallet.
create or replace function public.send_payment_request(
  p_conversation uuid, p_amount_minor bigint, p_label text, p_key uuid
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_req jsonb;
  v_existing uuid;
begin
  if app.conversation_role(v_user, p_conversation) <> 'vendor' then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  select id into v_existing from public.messages
  where conversation_id = p_conversation and author_role = 'vendor' and idempotency_key = p_key;
  if v_existing is not null then return app.message_json(v_existing); end if;
  v_req := public.create_payment_request(p_amount_minor, p_key, p_label);
  return app.send_message(v_user, p_conversation, 'payment_request', null, null, null, p_key, null,
    jsonb_build_object('request_id', v_req ->> 'id', 'code', v_req ->> 'code',
      'amount_minor', (v_req ->> 'amount_minor')::bigint, 'currency_code', v_req ->> 'currency_code',
      'label', v_req ->> 'label'));
end
$$;
revoke all on function public.send_payment_request(uuid, bigint, text, uuid) from public;
grant execute on function public.send_payment_request(uuid, bigint, text, uuid) to authenticated;

-- Coupon de la boutique pour cette cliente : pourcentage, validité en jours (30 au plus).
create or replace function public.send_coupon(p_conversation uuid, p_percent integer, p_days integer, p_key uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_conv public.conversations;
  v_coupon uuid;
  v_existing uuid;
  v_expires timestamptz := now() + make_interval(days => coalesce(p_days, 7));
begin
  select * into v_conv from public.conversations where id = p_conversation;
  if v_conv.id is null or app.conversation_role(v_user, p_conversation) <> 'vendor' then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  select id into v_existing from public.messages
  where conversation_id = p_conversation and author_role = 'vendor' and idempotency_key = p_key;
  if v_existing is not null then return app.message_json(v_existing); end if;
  if p_percent not between 1 and 50 or coalesce(p_days, 7) not between 1 and 30 then
    raise exception 'coupon_invalid' using errcode = 'P0001';
  end if;
  insert into public.coupons (store_id, conversation_id, percent, expires_at, created_by)
  values (v_conv.store_id, p_conversation, p_percent, v_expires, v_user) returning id into v_coupon;
  return app.send_message(v_user, p_conversation, 'coupon', null, null, null, p_key, null,
    jsonb_build_object('coupon_id', v_coupon, 'percent', p_percent, 'expires_at', v_expires,
      'store_name', (select name from public.stores where id = v_conv.store_id)));
end
$$;
revoke all on function public.send_coupon(uuid, integer, integer, uuid) from public;
grant execute on function public.send_coupon(uuid, integer, integer, uuid) to authenticated;

-- La cliente garde le coupon : il s'applique à sa prochaine commande dans la boutique.
create or replace function public.claim_coupon(p_coupon uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_c public.coupons;
begin
  select cp.* into v_c from public.coupons cp
  join public.conversations cv on cv.id = cp.conversation_id
  where cp.id = p_coupon and cv.client_id = v_user;
  if v_c.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_c.expires_at <= now() then raise exception 'coupon_expired' using errcode = 'P0001'; end if;
  insert into public.coupon_claims (coupon_id, user_id) values (p_coupon, v_user) on conflict do nothing;
  perform app.emit_event('coupon_claimed', v_user, 'client', 'server',
    (select country_code from public.stores where id = v_c.store_id), 'store', v_c.store_id::text,
    jsonb_build_object('percent', v_c.percent));
  return jsonb_build_object('coupon_id', p_coupon, 'percent', v_c.percent, 'expires_at', v_c.expires_at);
end
$$;
revoke all on function public.claim_coupon(uuid) from public;
grant execute on function public.claim_coupon(uuid) to authenticated;

-- ------------------------------------------------------------------ transcription

-- La Function enregistre le texte d'un vocal (fournisseur IA ou simulateur signalé).
create or replace function app.set_transcript(p_message uuid, p_text text)
returns void
language sql security definer set search_path = ''
as $$
  update public.messages set transcript = left(nullif(btrim(p_text), ''), 4000)
  where id = p_message and kind = 'audio'
$$;
revoke all on function app.set_transcript(uuid, text) from public;

-- Vocal lisible par la personne (participante), pas encore transcrit.
create or replace function app.transcript_target(p_user uuid, p_message uuid)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('media_key', m.media_key, 'transcript', m.transcript,
    'locale', coalesce((select locale from public.profiles where user_id = p_user), 'fr'))
  from public.messages m
  where m.id = p_message and m.kind = 'audio'
    and app.conversation_role(p_user, m.conversation_id) is not null
$$;
revoke all on function app.transcript_target(uuid, uuid) from public;

insert into public.store_function_permissions (function_name, permission) values
  ('public.send_quote', 'chat'), ('public.send_payment_request', 'chat'), ('public.send_coupon', 'chat')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('quote_accepted', 'server', 'Devis du chat accepté en un geste (spec 099)'),
  ('coupon_claimed', 'server', 'Coupon de boutique gardé par la cliente (spec 099)')
on conflict do nothing;

insert into public.feature_flags (key, country_code, is_enabled, description)
select 'chat_transcription', null, true,
       'Transcription des vocaux du chat (spec 099) ; simulée et signalée sans fournisseur IA'
where not exists (select 1 from public.feature_flags where key = 'chat_transcription' and country_code is null);

-- Modèle de transcription du chat : celui des vocaux de recherche, si le pays l'autorise.
create or replace function app.chat_transcription_model(p_user uuid)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('provider', m.provider, 'model', m.model, 'params', m.params)
  from public.ai_models m
  where m.usage = 'search_transcription' and m.is_active
    and app.feature_enabled('chat_transcription',
          (select country_code from public.profiles where user_id = p_user))
  limit 1
$$;
revoke all on function app.chat_transcription_model(uuid) from public;
