-- Notifications, suite (spec 080) : photo du produit principal dans le push
-- d'une commande ; rappel « Ton panier t'attend » (une fois par jour au plus,
-- de 9 h à 20 h, heure du pays).

-- Photo du produit le plus cher de la commande (clé publique du catalogue).
create or replace function app.order_cover_key(p_order uuid) returns text
language sql stable security definer set search_path = ''
as $$
  select ph.object_key
  from public.order_items i
  join public.product_photos ph on ph.product_id = i.product_id
  where i.order_id = p_order
  order by i.amount_minor desc, ph.sort, ph.object_key
  limit 1
$$;

create or replace function app.claim_pushes(p_limit int default 50) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_rows jsonb;
begin
  with claimed as (
    update public.notifications n set pushed_at = now(), push_outcome = 'claimed'
    where n.id in (
      select id from public.notifications
      where pushed_at is null and created_at > now() - interval '1 day'
      order by created_at
      limit least(greatest(coalesce(p_limit, 50), 1), 500)
      for update skip locked)
    returning n.*
  ), full_params as (
    select c.*, app.notification_params(c.user_id, c.order_id, c.params) as rich,
           coalesce((select locale from public.profiles where user_id = c.user_id), 'fr') as lang
    from claimed c
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', f.id, 'kind', f.kind, 'category', f.category, 'order_id', f.order_id,
    'purchase_id', f.purchase_id, 'params', f.params,
    'locale', f.lang,
    'allowed', app.push_allowed(f.user_id, f.category),
    'text', app.render_notification(f.kind, f.lang, f.rich),
    'image_key', case when f.order_id is not null then app.order_cover_key(f.order_id) end,
    'tokens', coalesce((select jsonb_agg(t.token) from public.push_tokens t
                        where t.user_id = f.user_id and t.app = app.notification_app(f.kind)), '[]'::jsonb))),
    '[]'::jsonb)
  into v_rows
  from full_params f;
  return v_rows;
end
$$;

-- Rappels de panier déjà envoyés.
create table app.cart_reminders (
  cart_id uuid primary key references public.carts (id) on delete cascade,
  reminded_at timestamptz not null
);
revoke all on app.cart_reminders from public, authenticated, anonymous;

insert into public.event_names (name, emitted_by, description) values
  ('cart_reminded', 'server', 'Rappel « Ton panier t''attend » envoyé (articles)')
on conflict do nothing;

insert into public.notification_templates (kind, locale, title, body) values
  ('cart_reminder', 'fr', 'Ton panier t''attend', '{items_summary} : finalise ta commande en un geste.'),
  ('cart_reminder', 'en', 'Your cart is waiting', '{items_summary}: finish your order in one tap.')
on conflict do nothing;

-- Paniers laissés de 3 h à 48 h, une fois par jour au plus, de 9 h à 20 h
-- (heure du pays) ; pas si la personne a commandé depuis.
create or replace function app.remind_carts(p_at timestamptz default now()) returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v record;
  v_count integer := 0;
  v_summary text;
begin
  for v in
    select c.id, c.user_id, c.country_code, p.locale,
           (select count(*)::int from public.cart_items ci where ci.cart_id = c.id) as n,
           (select pr.name from public.cart_items ci
            join public.product_variants pv on pv.id = ci.variant_id
            join public.products pr on pr.id = pv.product_id
            where ci.cart_id = c.id
            order by ci.added_at limit 1) as first_name
    from public.carts c
    join public.countries co on co.code = c.country_code
    join public.profiles p on p.user_id = c.user_id
    where exists (select 1 from public.cart_items ci where ci.cart_id = c.id)
      and c.updated_at < p_at - interval '3 hours'
      and c.updated_at > p_at - interval '48 hours'
      and extract(hour from p_at at time zone co.timezone) between 9 and 19
      and not exists (select 1 from app.cart_reminders r
                      where r.cart_id = c.id
                        and (r.reminded_at > c.updated_at or r.reminded_at > p_at - interval '24 hours'))
      and not exists (select 1 from public.purchases pu
                      where pu.user_id = c.user_id and pu.created_at > c.updated_at)
    order by c.updated_at
    limit 200
  loop
    v_summary := case
      when v.n = 1 then v.first_name
      when v.locale = 'en' then v.first_name || ' and ' || (v.n - 1) || case when v.n = 2 then ' more item' else ' more items' end
      else v.first_name || ' et ' || (v.n - 1) || case when v.n = 2 then ' autre article' else ' autres articles' end
    end;
    insert into app.cart_reminders (cart_id, reminded_at) values (v.id, p_at)
    on conflict (cart_id) do update set reminded_at = excluded.reminded_at;
    perform app.notify(v.user_id, 'cart_reminder', 'orders', null, null,
      jsonb_build_object('items_summary', v_summary, 'items_count', v.n));
    perform app.emit_event('cart_reminded', v.user_id, 'client', 'server', v.country_code,
      'cart', v.id::text, jsonb_build_object('items', v.n));
    v_count := v_count + 1;
  end loop;
  return v_count;
end
$$;

revoke all on function app.order_cover_key(uuid), app.remind_carts(timestamptz) from public;
