-- Spec 021 : suivi de l'IA et des paiements (A-AI-01..03, A-DASH-06), relance
-- ciblée des clientes par la vendeuse (V-MSG-05, flag `vendor_broadcast`) et
-- alerte de stock bas (V-PROD-10).

-- ------------------------------------------------------------------ suivi IA

-- Texte d'une requête non comprise (copilote) : sans lien avec la personne
-- dans les lectures de l'équipe, 80 caractères au plus.
alter table public.ai_requests add column query_text text
  check (query_text is null or length(query_text) <= 80);

create or replace function app.record_ai_request(
  p_user uuid,
  p_usage text,
  p_outcome text,
  p_latency_ms int,
  p_query text
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_country char(2) := (select country_code from public.profiles where user_id = p_user);
  v_event text := case p_usage
    when 'search_transcription' then 'voice_search_used'
    when 'search_from_photo' then 'photo_search_used' end;
begin
  insert into public.ai_requests (usage, user_id, country_code, outcome, latency_ms, query_text)
  values (p_usage, p_user, v_country, p_outcome, greatest(coalesce(p_latency_ms, 0), 0),
          case when p_outcome <> 'success' then nullif(left(trim(coalesce(p_query, '')), 80), '') end);
  if v_event is not null then
    perform app.emit_event(v_event, p_user, 'client', 'client', v_country, null, null,
      jsonb_build_object('outcome', p_outcome, 'latency_ms', p_latency_ms));
  end if;
end
$$;

-- Signature d'origine (spec 018) : sans texte.
create or replace function app.record_ai_request(
  p_user uuid,
  p_usage text,
  p_outcome text,
  p_latency_ms int
) returns void
language sql security definer set search_path = ''
as $$
  select app.record_ai_request(p_user, p_usage, p_outcome, p_latency_ms, null)
$$;

-- Le copilote garde le texte d'une intention sans proposition (A-AI-03).
create or replace function app.copilot_proposed(
  p_user uuid,
  p_proposal jsonb,
  p_latency_ms int,
  p_text text
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_items int := coalesce((p_proposal ->> 'item_count')::int, 0);
  v_country char(2) := (select country_code from public.profiles where user_id = p_user);
begin
  perform app.record_ai_request(p_user, 'intent_copilot',
    case when v_items > 0 then 'success' else 'no_result' end, p_latency_ms, p_text);
  perform app.emit_event('copilot_proposed', p_user, 'client', 'client', v_country, null, null,
    jsonb_build_object('items_count', v_items,
      'stores_count', jsonb_array_length(coalesce(p_proposal -> 'stores', '[]'::jsonb)),
      'missing_count', jsonb_array_length(coalesce(p_proposal -> 'missing', '[]'::jsonb)),
      'latency_ms', p_latency_ms));
end
$$;

-- IA et paiements (écran 77) : compréhension et latence sur 24 h, passages à
-- la recherche classique (copilote sans proposition), paiements de la
-- dernière heure (alerte sous 90 %), série sur 7 jours, dernières requêtes non
-- comprises (sans personne).
create or replace function public.admin_ai_health(p_at timestamptz default now()) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_ai record;
  v_pay record;
begin
  perform app.require_admin();
  select count(*) as total,
         count(*) filter (where outcome = 'success') as ok,
         avg(latency_ms)::int as latency,
         count(*) filter (where usage = 'intent_copilot') as copilot,
         count(*) filter (where usage = 'intent_copilot' and outcome <> 'success') as fallback
  into v_ai
  from public.ai_requests
  where created_at > p_at - interval '24 hours' and created_at <= p_at;
  select count(*) filter (where status = 'succeeded') as ok,
         count(*) filter (where status in ('failed', 'cancelled')) as ko
  into v_pay
  from public.payments
  where created_at > p_at - interval '1 hour' and created_at <= p_at;
  return jsonb_build_object(
    'requests', v_ai.total,
    'understood_percent', case when v_ai.total > 0 then round(v_ai.ok * 100.0 / v_ai.total) end,
    'latency_ms', v_ai.latency,
    'fallback_percent', case when v_ai.copilot > 0 then round(v_ai.fallback * 100.0 / v_ai.copilot) end,
    'payments_1h', jsonb_build_object('succeeded', v_pay.ok, 'failed', v_pay.ko),
    'payments_alert', v_pay.ok + v_pay.ko > 0 and v_pay.ok * 100.0 / (v_pay.ok + v_pay.ko) < 90,
    'series_7d', (
      select jsonb_agg(jsonb_build_object('day', d::date,
        'percent', (select case when count(*) > 0
                                then round(count(*) filter (where outcome = 'success') * 100.0 / count(*)) end
                    from public.ai_requests
                    where created_at >= d and created_at < d + interval '1 day')) order by d)
      from generate_series(date_trunc('day', p_at) - interval '6 days', date_trunc('day', p_at), interval '1 day') d),
    'misses', coalesce((
      select jsonb_agg(jsonb_build_object('at', created_at, 'usage', usage, 'outcome', outcome,
                                          'query', query_text) order by created_at desc)
      from (select * from public.ai_requests
            where outcome <> 'success' and created_at <= p_at
            order by created_at desc limit 10) m), '[]'::jsonb));
end
$$;

-- ------------------------------------------------------------------ relance

create table public.broadcasts (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  segment text not null check (segment in ('regular', 'month', 'all')),
  message text not null check (length(message) between 2 and 300),
  product_id uuid references public.products (id) on delete set null,
  recipients int not null,
  sent_at timestamptz not null default clock_timestamp()
);

create index broadcasts_store on public.broadcasts (store_id, sent_at desc);

alter table public.broadcasts enable row level security;
revoke all on public.broadcasts from anonymous, authenticated;

-- Clientes d'une boutique par segment : régulières (2 commandes ou plus),
-- du mois (commande depuis 30 jours), toutes. Celles qui ont coupé les
-- promotions sont exclues ; le push suit en plus la préférence par défaut.
create or replace function app.broadcast_recipients(p_store uuid, p_segment text, p_at timestamptz)
returns setof uuid
language sql stable security definer set search_path = ''
as $$
  select pu.user_id
  from public.orders o join public.purchases pu on pu.id = o.purchase_id
  where o.store_id = p_store and o.status <> 'cancelled'
  group by pu.user_id
  having case p_segment
    when 'regular' then count(*) >= 2
    when 'month' then max(o.created_at) > p_at - interval '30 days'
    else true end
  and not exists (select 1 from public.notification_preferences np
                  where np.user_id = pu.user_id and np.category = 'promotions' and not np.push_enabled)
$$;

-- Audience (78) : nombre de clientes par segment et dernière relance.
create or replace function public.broadcast_audience(p_at timestamptz default now()) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_store uuid := app.photo_upload_store(app.require_user());
begin
  return jsonb_build_object(
    'regular', (select count(*) from app.broadcast_recipients(v_store, 'regular', p_at)),
    'month', (select count(*) from app.broadcast_recipients(v_store, 'month', p_at)),
    'all', (select count(*) from app.broadcast_recipients(v_store, 'all', p_at)),
    'last_sent_at', (select max(sent_at) from public.broadcasts where store_id = v_store),
    'low_stock_threshold', (select low_stock_threshold from public.stores where id = v_store));
end
$$;

-- Relance (Function : push). Une par jour et par boutique ; produit joint de
-- la boutique et publié ; flag `vendor_broadcast` du pays.
create or replace function app.send_broadcast(
  p_user uuid,
  p_segment text,
  p_message text,
  p_product uuid default null,
  p_at timestamptz default now()
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store public.stores;
  v_message text := nullif(trim(coalesce(p_message, '')), '');
  v_count int := 0;
  v_recipient uuid;
  v_id uuid;
begin
  select * into v_store from public.stores where id = app.photo_upload_store(p_user);
  if not app.feature_enabled('vendor_broadcast', v_store.country_code) then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  if v_store.status <> 'active' then
    raise exception 'boutique inactive' using errcode = '42501';
  end if;
  if p_segment not in ('regular', 'month', 'all') then
    raise exception 'segment inconnu' using errcode = '22023';
  end if;
  if v_message is null or length(v_message) not between 2 and 300 then
    raise exception 'broadcast_invalid' using errcode = 'P0001';
  end if;
  if p_product is not null and not exists (
    select 1 from public.products where id = p_product and store_id = v_store.id and status = 'published') then
    raise exception 'produit invalide' using errcode = '22023';
  end if;
  if exists (select 1 from public.broadcasts where store_id = v_store.id
             and sent_at > p_at - interval '24 hours') then
    raise exception 'broadcast_daily_limit' using errcode = 'P0001';
  end if;
  insert into public.broadcasts (store_id, segment, message, product_id, recipients)
  values (v_store.id, p_segment, v_message, p_product, 0) returning id into v_id;
  for v_recipient in select * from app.broadcast_recipients(v_store.id, p_segment, p_at) loop
    perform app.notify(v_recipient, 'store_broadcast', 'promotions', null, null,
      jsonb_build_object('store_id', v_store.id, 'store_name', v_store.name, 'message', v_message,
                         'product_id', p_product));
    v_count := v_count + 1;
  end loop;
  update public.broadcasts set recipients = v_count where id = v_id;
  perform app.emit_event('vendor_broadcast_sent', p_user, 'vendor', 'vendor', v_store.country_code,
    'store', v_store.id::text, jsonb_build_object('segment', p_segment, 'recipients', v_count,
                                                  'with_product', p_product is not null));
  return jsonb_build_object('id', v_id, 'recipients', v_count);
end
$$;

-- ------------------------------------------------------------------ stock bas

alter table public.stores add column low_stock_threshold int
  check (low_stock_threshold is null or low_stock_threshold between 1 and 999);

-- Seuil de la boutique (nul : alerte coupée).
create or replace function public.set_low_stock_threshold(p_threshold int) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if p_threshold is not null and p_threshold not between 1 and 999 then
    raise exception 'seuil invalide' using errcode = '22023';
  end if;
  update public.stores set low_stock_threshold = p_threshold
  where id = app.photo_upload_store(app.require_user());
end
$$;

-- Variante qui passe sous le seuil : la vendeuse est prévenue une fois.
create or replace function app.on_variant_stock_changed() returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_store public.stores;
  v_product public.products;
begin
  select * into v_product from public.products where id = new.product_id;
  select * into v_store from public.stores where id = v_product.store_id;
  if v_store.low_stock_threshold is not null and v_product.status = 'published'
     and new.stock_quantity is not null and new.stock_quantity < v_store.low_stock_threshold
     and (old.stock_quantity is null or old.stock_quantity >= v_store.low_stock_threshold) then
    perform app.notify(v_store.owner_id, 'low_stock', 'orders', null, null,
      jsonb_build_object('product_id', v_product.id, 'product_name', v_product.name,
                         'variant_label', new.label, 'stock', new.stock_quantity));
  end if;
  return new;
end
$$;

create trigger product_variants_low_stock
  after update of stock_quantity on public.product_variants
  for each row execute function app.on_variant_stock_changed();

-- ------------------------------------------------------------------ notifications

create or replace function app.notification_app(p_kind text) returns text
language sql immutable
as $$
  select case when p_kind in ('new_order', 'order_cancelled_by_client', 'dispute_opened',
    'dispute_message', 'dispute_resolved_vendor', 'order_cancelled_vendor', 'order_status_forced',
    'delivery_assigned', 'store_suspended', 'store_reactivated', 'vendor_daily_recap',
    'new_message_vendor', 'review_received', 'support_replied_vendor', 'low_stock')
    then 'vendor' else 'client' end
$$;

insert into public.notification_templates (kind, locale, title, body) values
  ('store_broadcast', 'fr', '{store_name}', '{message}'),
  ('store_broadcast', 'en', '{store_name}', '{message}'),
  ('low_stock', 'fr', 'Stock bas', 'Plus que {stock} pour {product_name}.'),
  ('low_stock', 'en', 'Low stock', 'Only {stock} left for {product_name}.');

insert into public.event_names (name, emitted_by, description) values
  ('vendor_broadcast_sent', 'server', 'Relance envoyée (segment, destinataires, produit joint)')
on conflict (name) do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function
  app.record_ai_request(uuid, text, text, int, text), app.copilot_proposed(uuid, jsonb, int, text),
  public.admin_ai_health(timestamptz), app.broadcast_recipients(uuid, text, timestamptz),
  public.broadcast_audience(timestamptz), app.send_broadcast(uuid, text, text, uuid, timestamptz),
  public.set_low_stock_threshold(int), app.on_variant_stock_changed()
from public;

grant execute on function
  public.admin_ai_health(timestamptz), public.broadcast_audience(timestamptz),
  public.set_low_stock_threshold(int)
to authenticated;
