-- 0055 — Achat de gros groupé (spec 049, VISION §3 « Vendeuse » : meilleures marges).
-- Une boutique grossiste ouvre une offre (produit, prix unitaire, quantité minimale, date limite).
-- Les vendeuses du même pays s'engagent sur des quantités ; la jauge monte. Minimum atteint : la
-- grossiste confirme et les acheteuses sont prévenues. Le règlement se fait hors de DYM
-- (aucun mouvement au grand livre) ; DYM tient l'engagement et la trace.

alter table public.stores add column is_wholesaler boolean not null default false;

create table public.wholesale_offers (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  unit_price_minor bigint not null check (unit_price_minor > 0 and unit_price_minor <= 100000000),
  currency_code char(3) not null references public.currencies (code),
  min_quantity integer not null check (min_quantity between 1 and 100000),
  closes_at timestamptz not null,
  status text not null default 'open' check (status in ('open', 'confirmed', 'cancelled')),
  note text check (note is null or length(note) <= 200),
  created_at timestamptz not null default clock_timestamp(),
  decided_at timestamptz
);
create index wholesale_offers_open on public.wholesale_offers (closes_at) where status = 'open';
alter table public.wholesale_offers enable row level security;
revoke all on public.wholesale_offers from authenticated, anonymous;

create table public.wholesale_commitments (
  offer_id uuid not null references public.wholesale_offers (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  quantity integer not null check (quantity between 1 and 100000),
  updated_at timestamptz not null default clock_timestamp(),
  primary key (offer_id, store_id)
);
alter table public.wholesale_commitments enable row level security;
revoke all on public.wholesale_commitments from authenticated, anonymous;

-- Offre vue par [p_store] (grossiste ou acheteuse).
create or replace function app.wholesale_json(p_offer uuid, p_store uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id, 'product_name', p.name,
    'photo_key', (select f.object_key from public.product_photos f where f.product_id = p.id order by f.sort limit 1),
    'store_name', s.name, 'unit_price_minor', o.unit_price_minor, 'currency_code', o.currency_code,
    'min_quantity', o.min_quantity, 'closes_at', o.closes_at, 'note', o.note,
    'committed', coalesce((select sum(quantity) from public.wholesale_commitments where offer_id = o.id), 0),
    'buyers', (select count(*) from public.wholesale_commitments where offer_id = o.id),
    'my_quantity', (select quantity from public.wholesale_commitments where offer_id = o.id and store_id = p_store),
    'mine', o.store_id = p_store,
    'status', case when o.status = 'open' and o.closes_at < now() then 'closed' else o.status end,
    'commitments', case when o.store_id = p_store then coalesce((select jsonb_agg(jsonb_build_object(
        'store_name', b.name, 'quantity', c.quantity) order by c.quantity desc)
      from public.wholesale_commitments c join public.stores b on b.id = c.store_id
      where c.offer_id = o.id), '[]'::jsonb) end)
  from public.wholesale_offers o
  join public.products p on p.id = o.product_id
  join public.stores s on s.id = o.store_id
  where o.id = p_offer
$$;

-- Devenir (ou ne plus être) grossiste.
create or replace function public.set_wholesaler(p_on boolean) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store uuid := app.own_store_id();
begin
  if v_store is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  update public.stores set is_wholesaler = coalesce(p_on, false) where id = v_store;
  return public.wholesale_board();
end
$fn$;

-- Grossiste : nouvelle offre sur un de ses produits publiés (1 à 30 jours).
create or replace function public.create_wholesale_offer(p_product uuid, p_unit_price_minor bigint,
  p_min_quantity integer, p_days integer default 7, p_note text default null) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store public.stores;
  v_id uuid;
begin
  select * into v_store from public.stores where id = app.own_store_id();
  if v_store.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if not v_store.is_wholesaler then raise exception 'not_wholesaler' using errcode = '42501'; end if;
  if not exists (select 1 from public.products where id = p_product and store_id = v_store.id and status = 'published') then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if p_unit_price_minor is null or p_unit_price_minor <= 0 or p_unit_price_minor > 100000000 then
    raise exception 'invalid_amount' using errcode = '22023';
  end if;
  if p_min_quantity is null or p_min_quantity not between 1 and 100000 then
    raise exception 'invalid_quantity' using errcode = '22023';
  end if;
  if p_days is null or p_days not between 1 and 30 then raise exception 'invalid_days' using errcode = '22023'; end if;
  insert into public.wholesale_offers (store_id, product_id, unit_price_minor, currency_code, min_quantity, closes_at, note)
  values (v_store.id, p_product, p_unit_price_minor, v_store.currency_code, p_min_quantity,
          now() + make_interval(days => p_days), nullif(left(btrim(coalesce(p_note, '')), 200), ''))
  returning id into v_id;
  perform app.emit_event('wholesale_offer_opened', app.current_user_id(), 'vendor', 'server', v_store.country_code,
    'store', v_store.id::text, jsonb_build_object('min_quantity', p_min_quantity, 'days', p_days));
  return app.wholesale_json(v_id, v_store.id);
end
$fn$;

-- Acheteuse : quantité engagée (0 : retrait) tant que l'offre est ouverte.
create or replace function public.commit_wholesale(p_offer uuid, p_quantity integer) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store public.stores;
  v_offer public.wholesale_offers;
begin
  select * into v_store from public.stores where id = app.own_store_id();
  if v_store.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  select o.* into v_offer from public.wholesale_offers o join public.stores s on s.id = o.store_id
  where o.id = p_offer and s.country_code = v_store.country_code for update of o;
  if v_offer.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_offer.store_id = v_store.id then raise exception 'own_offer' using errcode = 'P0001'; end if;
  if v_offer.status <> 'open' or v_offer.closes_at < now() then raise exception 'offer_closed' using errcode = 'P0001'; end if;
  if p_quantity is null or p_quantity not between 0 and 100000 then raise exception 'invalid_quantity' using errcode = '22023'; end if;
  if p_quantity = 0 then
    delete from public.wholesale_commitments where offer_id = p_offer and store_id = v_store.id;
  else
    insert into public.wholesale_commitments (offer_id, store_id, quantity) values (p_offer, v_store.id, p_quantity)
    on conflict (offer_id, store_id) do update set quantity = excluded.quantity, updated_at = clock_timestamp();
  end if;
  perform app.emit_event('wholesale_committed', app.current_user_id(), 'vendor', 'server', v_store.country_code,
    'store', v_store.id::text, jsonb_build_object('quantity', p_quantity));
  return app.wholesale_json(p_offer, v_store.id);
end
$fn$;

-- Grossiste : confirmer (minimum atteint) ou annuler ; les acheteuses sont prévenues.
create or replace function public.decide_wholesale_offer(p_offer uuid, p_confirm boolean) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store uuid := app.own_store_id();
  v_offer public.wholesale_offers;
  v_committed bigint;
begin
  select * into v_offer from public.wholesale_offers where id = p_offer and store_id = v_store for update;
  if v_offer.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_offer.status <> 'open' then raise exception 'offer_closed' using errcode = 'P0001'; end if;
  select coalesce(sum(quantity), 0) into v_committed from public.wholesale_commitments where offer_id = p_offer;
  if p_confirm and v_committed < v_offer.min_quantity then raise exception 'minimum_not_reached' using errcode = 'P0001'; end if;
  update public.wholesale_offers set status = case when p_confirm then 'confirmed' else 'cancelled' end,
    decided_at = clock_timestamp() where id = p_offer;
  perform app.notify(s.owner_id, case when p_confirm then 'wholesale_confirmed' else 'wholesale_cancelled' end,
    'orders', null, null, jsonb_build_object('product_name', (select name from public.products where id = v_offer.product_id),
      'quantity', c.quantity))
  from public.wholesale_commitments c join public.stores s on s.id = c.store_id
  where c.offer_id = p_offer;
  return app.wholesale_json(p_offer, v_store);
end
$fn$;

-- Tableau : offres ouvertes du pays (autres grossistes), mes engagements, mes offres.
create or replace function public.wholesale_board() returns jsonb
language sql stable security definer set search_path = ''
as $$
  with me as (select * from public.stores where id = app.own_store_id())
  select jsonb_build_object(
    'is_wholesaler', (select is_wholesaler from me),
    'open', coalesce((select jsonb_agg(app.wholesale_json(o.id, (select id from me)) order by o.closes_at)
      from public.wholesale_offers o join public.stores s on s.id = o.store_id
      where o.status = 'open' and o.closes_at > now() and o.store_id <> (select id from me)
        and s.country_code = (select country_code from me) and s.status = 'active'), '[]'::jsonb),
    'mine', coalesce((select jsonb_agg(app.wholesale_json(o.id, (select id from me)) order by o.created_at desc)
      from public.wholesale_offers o where o.store_id = (select id from me)
        and o.created_at > now() - interval '60 days'), '[]'::jsonb))
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('wholesale_confirmed', 'fr', 'Achat de gros confirmé', 'L''achat groupé de {product_name} est confirmé : {quantity} pour toi.'),
  ('wholesale_confirmed', 'en', 'Bulk purchase confirmed', 'The group purchase of {product_name} is confirmed: {quantity} for you.'),
  ('wholesale_cancelled', 'fr', 'Achat de gros annulé', 'L''achat groupé de {product_name} est annulé.'),
  ('wholesale_cancelled', 'en', 'Bulk purchase cancelled', 'The group purchase of {product_name} is cancelled.')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('wholesale_offer_opened', 'server', 'Offre de gros ouverte (minimum, durée)'),
  ('wholesale_committed', 'server', 'Engagement sur une offre de gros (quantité)')
on conflict do nothing;

-- Notifications (0052) : achats de gros vers l'app vendeuse.
create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor', 'review_received', 'support_replied_vendor', 'low_stock',
    'substitution_answered', 'freshness_claimed', 'incoming_call_vendor',
    'courier_out_for_delivery', 'courier_delivered', 'qr_paid',
    'wholesale_confirmed', 'wholesale_cancelled')
    then 'vendor'
    when p_kind in ('mission_available', 'courier_cash_confirmed') then 'delivery'
    else 'client' end
$$;


revoke all on function app.wholesale_json(uuid, uuid), public.set_wholesaler(boolean),
  public.create_wholesale_offer(uuid, bigint, integer, integer, text), public.commit_wholesale(uuid, integer),
  public.decide_wholesale_offer(uuid, boolean), public.wholesale_board() from public;
grant execute on function public.set_wholesaler(boolean), public.create_wholesale_offer(uuid, bigint, integer, integer, text),
  public.commit_wholesale(uuid, integer), public.decide_wholesale_offer(uuid, boolean), public.wholesale_board()
  to authenticated;
