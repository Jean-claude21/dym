-- Notifications plus utiles (spec 072) : montant et articles dans les textes,
-- « nuit calme » (pas de messages ni d'offres sur le téléphone de 22 h à 7 h,
-- heure du pays ; commandes et paiements passent toujours).

-- Montant lisible selon la devise du référentiel : « 3 500 F CFA »,
-- « GH₵3,500.00 ». Même convention que l'app (symbole après en français).
create or replace function app.format_money(p_minor bigint, p_currency text) returns text
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_units int;
  v_symbol text;
  v_fr boolean;
  v_abs bigint;
  v_scale bigint;
  v_int text;
  v_out text := '';
begin
  select minor_units, symbol, format_locale like 'fr%' into v_units, v_symbol, v_fr
  from public.currencies where code = p_currency;
  if v_symbol is null or p_minor is null then
    return null;
  end if;
  v_abs := abs(p_minor);
  v_scale := (10 ^ v_units)::bigint;
  v_int := (v_abs / v_scale)::text;
  while length(v_int) > 3 loop
    v_out := case when v_fr then U&'\202F' else ',' end || right(v_int, 3) || v_out;
    v_int := left(v_int, length(v_int) - 3);
  end loop;
  v_out := v_int || v_out;
  if v_units > 0 then
    v_out := v_out || case when v_fr then ',' else '.' end
             || lpad((v_abs % v_scale)::text, v_units, '0');
  end if;
  if p_minor < 0 then
    v_out := '-' || v_out;
  end if;
  return case when v_fr then v_out || U&'\00A0' || v_symbol else v_symbol || v_out end;
end
$$;

-- Paramètres d'une notification liée à une commande, complétés au moment de
-- l'envoi (la commande est alors complète) : total et résumé des articles,
-- dans la langue de la personne prévenue. Les paramètres fournis gardent la
-- priorité ; aucune donnée personnelle ajoutée.
create or replace function app.notification_params(p_user uuid, p_order uuid, p_params jsonb) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_total text;
  v_count int;
  v_first text;
  v_en boolean;
  v_summary text;
begin
  if p_order is null then
    return coalesce(p_params, '{}'::jsonb);
  end if;
  select app.format_money(o.total_minor, o.currency_code) into v_total
  from public.orders o where o.id = p_order;
  select count(*)::int,
         (array_agg(i.product_name order by i.amount_minor desc, i.product_name))[1]
  into v_count, v_first
  from public.order_items i where i.order_id = p_order;
  if v_total is null or coalesce(v_count, 0) = 0 then
    return coalesce(p_params, '{}'::jsonb);
  end if;
  v_en := coalesce((select locale from public.profiles where user_id = p_user), 'fr') = 'en';
  v_summary := case
    when v_count = 1 then v_first
    when v_en then v_first || ' and ' || (v_count - 1) || case when v_count = 2 then ' more item' else ' more items' end
    else v_first || ' et ' || (v_count - 1) || case when v_count = 2 then ' autre article' else ' autres articles' end
  end;
  return jsonb_build_object('total', v_total, 'items_count', v_count, 'items_summary', v_summary)
         || coalesce(p_params, '{}'::jsonb);
end
$$;

-- File d'envoi : textes rendus avec les paramètres complétés.
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
    'tokens', coalesce((select jsonb_agg(t.token) from public.push_tokens t
                        where t.user_id = f.user_id and t.app = app.notification_app(f.kind)), '[]'::jsonb))),
    '[]'::jsonb)
  into v_rows
  from full_params f;
  return v_rows;
end
$$;

update public.notification_templates set title = v.title, body = v.body
from (values
  ('new_order', 'fr', 'Nouvelle commande · {total}', '{customer_first_name} : {items_summary}. Réponds vite.'),
  ('new_order', 'en', 'New order · {total}', '{customer_first_name}: {items_summary}. Reply quickly.'),
  ('order_accepted', 'fr', 'Commande acceptée', '{store_name} a accepté ta commande de {total}.'),
  ('order_accepted', 'en', 'Order accepted', '{store_name} accepted your {total} order.'),
  ('order_preparing', 'fr', 'En préparation', '{store_name} prépare ta commande : {items_summary}.'),
  ('order_preparing', 'en', 'Being prepared', '{store_name} is preparing your order: {items_summary}.'),
  ('order_out_for_delivery', 'fr', 'En route', 'Ta commande de {total} arrive bientôt.'),
  ('order_out_for_delivery', 'en', 'On the way', 'Your {total} order is arriving soon.')
) as v(kind, locale, title, body)
where notification_templates.kind = v.kind and notification_templates.locale = v.locale;

-- « Nuit calme » : préférence à part (vraie = activée), 22 h – 7 h, heure du
-- pays de la personne. Seuls les messages et les offres sont retenus ; ils
-- restent dans le centre de notifications.
alter table public.notification_preferences drop constraint notification_preferences_category_check;
alter table public.notification_preferences add constraint notification_preferences_category_check
  check (category in ('orders', 'payments', 'messages', 'promotions', 'quiet_night'));

-- Vrai si « nuit calme » retient cette catégorie à l'instant donné.
create or replace function app.quiet_blocks(p_user uuid, p_category text, p_at timestamptz) returns boolean
language sql stable security definer set search_path = ''
as $$
  select p_category in ('messages', 'promotions')
     and coalesce((select push_enabled from public.notification_preferences
                   where user_id = p_user and category = 'quiet_night'), false)
     and coalesce((
       select (p_at at time zone c.timezone)::time >= time '22:00'
           or (p_at at time zone c.timezone)::time < time '07:00'
       from public.profiles p join public.countries c on c.code = p.country_code
       where p.user_id = p_user), false)
$$;

create or replace function app.push_allowed(p_user uuid, p_category text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    (select push_enabled from public.notification_preferences where user_id = p_user and category = p_category),
    p_category <> 'promotions')
    and not app.quiet_blocks(p_user, p_category, now())
$$;

create or replace function public.my_notification_preferences() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_agg(jsonb_build_object('category', c,
           'push_enabled', case when c = 'quiet_night'
             then coalesce((select push_enabled from public.notification_preferences
                            where user_id = app.require_user() and category = 'quiet_night'), false)
             else coalesce((select push_enabled from public.notification_preferences
                            where user_id = app.require_user() and category = c), c <> 'promotions') end)
         order by o)
  from unnest(array['orders', 'payments', 'messages', 'promotions', 'quiet_night']) with ordinality as t(c, o)
$$;

create or replace function public.set_notification_preference(p_category text, p_enabled boolean)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
begin
  if p_category not in ('orders', 'payments', 'messages', 'promotions', 'quiet_night') or p_enabled is null then
    raise exception 'catégorie inconnue' using errcode = '22023';
  end if;
  insert into public.notification_preferences (user_id, category, push_enabled)
  values (app.require_user(), p_category, p_enabled)
  on conflict (user_id, category) do update set push_enabled = excluded.push_enabled, updated_at = now();
  return public.my_notification_preferences();
end
$$;
