-- Corrections trouvées pendant la démonstration web des phases 7 à 13.
-- 1. Panier : source du prix (marchandé ou prix de groupe) pour afficher le bon libellé.
-- 2. Contenus : ouvrir un lien de partage compte une vue ; ajouter au panier depuis un post, un clic.
-- 3. Livreur : la mission montre le créneau prévu et le cash à encaisser.
-- 4. Recherche : un produit au nom exact (ou qui commence par la requête) passe devant les synonymes.
-- 5. Formules vendeuse : payées depuis le solde de la boutique, sinon depuis le wallet.
-- 6. Admins : la liste indique l'admin connecté (il ne peut pas retirer son propre accès).

-- Source du prix appliqué : `haggle` (marché conclu), `group` (groupe débloqué) ou nulle.
create or replace function app.cart_line_source(p_cart uuid, p_variant uuid, p_quantity integer) returns text
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
         and p_quantity <= m.quantity) as grp)
  select case
    when least(list, haggle, grp) >= list then null
    when grp is not null and grp <= coalesce(haggle, grp) then 'group'
    else 'haggle' end
  from p
$$;

-- Copie (0057) : chaque ligne porte la source de son prix.
create or replace function app.cart_quote(
  p_cart uuid,
  p_zone uuid,
  p_modes jsonb,
  p_payment_method uuid,
  p_at timestamptz
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_cart public.carts;
  v_city uuid := (select city_id from public.zones where id = p_zone);
  v_base bigint;
  v_extra bigint;
  v_threshold bigint;
  v_methods jsonb;
  v_method uuid;
  v_stores jsonb;
  v_delivered_subtotal bigint;
  v_result jsonb;
begin
  select * into v_cart from public.carts where id = p_cart;

  select d.base_fee_minor, d.extra_pickup_fee_minor, d.free_threshold_minor
  into v_base, v_extra, v_threshold
  from public.delivery_fee_defaults d
  where d.country_code = v_cart.country_code and d.valid_to is null
    and (d.city_id = v_city or d.city_id is null)
  order by d.city_id nulls last
  limit 1;

  -- Moyens actifs du pays acceptés par toutes les boutiques du panier.
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', pm.id, 'country_code', pm.country_code, 'provider_code', pm.provider_code,
           'operator_code', pm.operator_code, 'label', pm.label, 'sort', pm.sort) order by pm.sort), '[]'::jsonb)
  into v_methods
  from public.payment_methods pm
  where pm.country_code = v_cart.country_code and pm.is_active
    and not exists (
      select 1 from public.cart_items ci
      join public.product_variants v on v.id = ci.variant_id
      join public.products p on p.id = v.product_id
      where ci.cart_id = p_cart
        and not exists (select 1 from public.store_payment_methods spm
                        where spm.store_id = p.store_id and spm.payment_method_id = pm.id));
  v_method := coalesce(
    (select (m ->> 'id')::uuid from jsonb_array_elements(v_methods) m
     where (m ->> 'id')::uuid = p_payment_method),
    (v_methods -> 0 ->> 'id')::uuid);

  with lines as (
    select ci.variant_id, ci.quantity, ci.added_at, p.id as product_id, p.name, p.category_id,
           v.label as variant_label, v.stock_quantity, u.label as unit_label,
           (select f.object_key from public.product_photos f where f.product_id = p.id
            order by f.sort limit 1) as photo_key,
           app.cart_line_price(p_cart, v.id, ci.quantity) as unit_price, app.variant_price(v.id) as list_price,
           app.cart_line_source(p_cart, v.id, ci.quantity) as price_source,
           ci.unit_price_seen_minor,
           p.store_id,
           array_remove(array[
             case when p.status <> 'published' or not p.is_available
                    or v.stock_quantity = 0 then 'unavailable' end,
             case when v.stock_quantity > 0 and ci.quantity > v.stock_quantity then 'stock' end,
             case when app.cart_line_price(p_cart, v.id, ci.quantity) <> ci.unit_price_seen_minor then 'price_changed' end
           ], null) as issues
    from public.cart_items ci
    join public.product_variants v on v.id = ci.variant_id
    join public.products p on p.id = v.product_id
    left join public.units u on u.id = p.unit_id
    where ci.cart_id = p_cart
  ),
  stores as (
    select s.id, s.name, s.origin, z.name as zone_name, s.offers_pickup, app.cart_store_fee(p_cart, s.id) as own_fee,
           s.prep_time_minutes,
           case when coalesce(p_modes ->> s.id::text, 'delivery') = 'pickup' then 'pickup' else 'delivery' end
             as fulfillment,
           app.store_open_at(s.id, p_at) as is_open,
           sum(l.unit_price * l.quantity) as subtotal,
           jsonb_agg(jsonb_build_object(
             'variant_id', l.variant_id, 'product_id', l.product_id, 'name', l.name,
             'variant_label', l.variant_label, 'unit_label', l.unit_label, 'photo_key', l.photo_key,
             'quantity', l.quantity, 'unit_price_minor', l.unit_price, 'list_price_minor', l.list_price, 'price_source', l.price_source,
             'amount_minor', l.unit_price * l.quantity, 'stock_quantity', l.stock_quantity,
             'category_id', l.category_id, 'issues', to_jsonb(l.issues))
             order by l.added_at, l.variant_id) as lines,
           min(l.added_at) as first_added
    from lines l
    join public.stores s on s.id = l.store_id
    join public.zones z on z.id = s.zone_id
    group by s.id, z.name
  ),
  checked as (
    select st.*,
           array_remove(array[
             case when (select status from public.stores where id = st.id) <> 'active' then 'suspended' end,
             case when (select status from public.stores where id = st.id) = 'active' and not st.is_open
                  then 'closed' end,
             case when st.fulfillment = 'delivery' and p_zone is not null
                    and not app.store_serves(st.id, p_zone) then 'not_delivered' end,
             case when st.fulfillment = 'pickup' and not st.offers_pickup then 'pickup_unavailable' end,
             case when p_payment_method is not null and not exists (
                    select 1 from public.store_payment_methods spm
                    where spm.store_id = st.id and spm.payment_method_id = p_payment_method)
                  then 'payment_not_accepted' end
           ], null) as issues
    from stores st
  ),
  ranked as (
    select c.*,
           case when c.fulfillment = 'delivery'
                then row_number() over (partition by c.fulfillment order by c.subtotal desc, c.id) end
             as delivery_rank
    from checked c
  )
  select jsonb_agg(jsonb_build_object(
           'id', r.id, 'name', r.name, 'origin', r.origin, 'zone_name', r.zone_name,
           'fulfillment', r.fulfillment, 'offers_pickup', r.offers_pickup, 'is_open', r.is_open,
           'prep_time_minutes', r.prep_time_minutes,
           'issues', to_jsonb(r.issues), 'subtotal_minor', r.subtotal,
           'delivery_rank', r.delivery_rank,
           'own_fee_minor', r.own_fee, 'lines', r.lines)
           order by r.first_added, r.id)
  into v_stores
  from ranked r;

  v_stores := coalesce(v_stores, '[]'::jsonb);
  select coalesce(sum((s ->> 'subtotal_minor')::bigint), 0) into v_delivered_subtotal
  from jsonb_array_elements(v_stores) s where s ->> 'fulfillment' = 'delivery';

  -- Frais par boutique.
  select coalesce(jsonb_agg(
           (s - 'delivery_rank' - 'own_fee_minor') || jsonb_build_object(
             'delivery_fee_minor',
             case
               when s ->> 'fulfillment' <> 'delivery' then 0
               when v_threshold is not null and v_delivered_subtotal >= v_threshold then 0
               when (s ->> 'delivery_rank')::int = 1
                 then coalesce((s ->> 'own_fee_minor')::bigint, v_base, 0)
               else coalesce(v_extra, 0)
             end)
           order by o), '[]'::jsonb)
  into v_stores
  from jsonb_array_elements(v_stores) with ordinality as e(s, o);

  select jsonb_build_object(
    'country_code', v_cart.country_code,
    'currency_code', v_cart.currency_code,
    'currency', (select to_jsonb(cu) - 'created_at' - 'updated_at' from public.currencies cu
                 where cu.code = v_cart.currency_code),
    'stores', v_stores,
    'payment_methods', v_methods,
    'payment_method_id', v_method,
    'item_count', coalesce((select sum((l ->> 'quantity')::int)
                            from jsonb_array_elements(v_stores) s,
                                 jsonb_array_elements(s -> 'lines') l), 0),
    'pickup_count', (select count(*) from jsonb_array_elements(v_stores) s
                     where s ->> 'fulfillment' = 'delivery'),
    'delivery_minutes', coalesce((select delivery_minutes from public.cities where id = v_city), 0)
      + coalesce((select max((s ->> 'prep_time_minutes')::int) from jsonb_array_elements(v_stores) s), 0),
    'subtotal_minor', coalesce((select sum((s ->> 'subtotal_minor')::bigint)
                                from jsonb_array_elements(v_stores) s), 0),
    'delivery_fee_minor', coalesce((select sum((s ->> 'delivery_fee_minor')::bigint)
                                    from jsonb_array_elements(v_stores) s), 0),
    'free_threshold_minor', v_threshold,
    'remaining_for_free_minor', case when v_threshold is null then null
                                     else greatest(v_threshold - v_delivered_subtotal, 0) end,
    'blocking', exists (
      select 1 from jsonb_array_elements(v_stores) s
      where jsonb_array_length(s -> 'issues') > 0
         or exists (select 1 from jsonb_array_elements(s -> 'lines') l
                    where l -> 'issues' ?| array['unavailable', 'stock'])))
  into v_result;

  return v_result || jsonb_build_object(
    'total_minor', (v_result ->> 'subtotal_minor')::bigint + (v_result ->> 'delivery_fee_minor')::bigint);
end
$$;

-- Copie (0047) : l'ouverture compte aussi une vue.
create or replace function public.open_share_link(p_code text) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_link public.share_links;
  v_user uuid := app.current_user_id();
begin
  select * into v_link from public.share_links where code = lower(btrim(p_code));
  if v_link.code is null or not exists (select 1 from public.contents c where c.id = v_link.content_id
                                        and app.content_visible(c, now())) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  update public.share_links set opens = opens + 1 where code = v_link.code;
  -- Une ouverture de lien est une vue du contenu (statistiques de la créatrice).
  update public.contents set view_count = view_count + 1 where id = v_link.content_id;
  perform app.emit_event('share_link_opened', v_user, case when v_user is null then 'anonymous' else 'client' end,
    'server', null, 'content', v_link.content_id::text, '{}'::jsonb);
  return app.content_json(v_link.content_id, v_user);
end
$fn$;

-- Copie (0046) : l'ajout au panier depuis un contenu compte un clic.
create or replace function public.content_touch(p_content uuid, p_variants uuid[]) returns void
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
begin
  if coalesce(array_length(p_variants, 1), 0) > 30 then
    raise exception 'invalid_items' using errcode = '22023';
  end if;
  if not exists (select 1 from public.contents c where c.id = p_content and c.author_id is not null
                 and c.author_id <> v_user and app.content_visible(c, now())) then
    return;
  end if;
  insert into public.affiliate_touches (user_id, variant_id, content_id, via)
  select v_user, v.id, p_content,
         case when exists (select 1 from public.content_products cp
                           where cp.content_id = p_content and cp.product_id = v.product_id)
              then 'tagged' else 'ingredient' end
  from public.product_variants v where v.id = any (p_variants)
  on conflict (user_id, variant_id) do update
    set content_id = excluded.content_id, via = excluded.via, touched_at = clock_timestamp();
  -- Ajout au panier depuis le contenu : un clic.
  if coalesce(array_length(p_variants, 1), 0) > 0 then
    update public.contents set click_count = click_count + 1 where id = p_content;
  end if;
end
$fn$;

-- Copie (0049) : créneau prévu et cash à encaisser.
create or replace function app.mission_json(p_order uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'order_id', o.id, 'purchase_id', o.purchase_id, 'status', o.status, 'created_at', o.created_at,
    -- Tournée : commandes à livrer du même achat ; consignes de conservation.
    'run_size', (select count(*) from public.orders r where r.purchase_id = o.purchase_id
                 and r.fulfillment = 'delivery' and r.status not in ('refused', 'cancelled')),
    'storage', app.order_storage(o.id),
    'ready_at', o.ready_at, 'eta_at', app.order_eta(o.id),
    'scheduled_start', o.scheduled_start, 'scheduled_end', o.scheduled_end,
    -- Cash à encaisser auprès de la cliente (paiement à la livraison).
    'cash_to_collect_minor', case when pu.payment_status = 'cash_on_delivery' then o.total_minor else 0 end,
    'delivery_fee_minor', o.delivery_fee_minor, 'currency_code', o.currency_code,
    'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
    'store', jsonb_build_object('name', s.name,
      'zone_name', (select z.name from public.zones z where z.id = s.zone_id),
      'landmark', case when mine then (select concat_ws(' · ', a.address, a.landmark)
                                       from public.store_pickup_addresses a where a.store_id = s.id) end,
      'phone', case when mine then (select a.contact_phone from public.store_pickup_addresses a
                                    where a.store_id = s.id) end),
    'customer', jsonb_build_object(
      'zone_name', (select z.name from public.zones z where z.id = (pu.address ->> 'zone_id')::uuid),
      'first_name', case when mine then (select p.first_name from public.profiles p where p.user_id = pu.user_id) end,
      'landmark', case when mine then pu.address ->> 'landmark' end,
      'phone', case when mine then pu.address ->> 'phone' end,
      'latitude', case when mine then pu.address -> 'latitude' end,
      'longitude', case when mine then pu.address -> 'longitude' end),
    'accepted_at', oc.accepted_at,
    'next', case when mine then app.order_next_statuses('courier', o.fulfillment, o.status) else '[]'::jsonb end)
  from public.orders o
  join public.purchases pu on pu.id = o.purchase_id
  join public.stores s on s.id = o.store_id
  left join public.order_couriers oc on oc.order_id = o.id
  cross join lateral (select oc.courier_id is not distinct from p_user and oc.courier_id is not null as mine) m
  where o.id = p_order
$$;

-- Copie (0035) : le nom exact passe devant.
create or replace function public.search_catalog(
  p_query text default null,
  p_zone uuid default null,
  p_category uuid default null,
  p_origin text default null,
  p_min_price bigint default null,
  p_max_price bigint default null,
  p_available_only boolean default false,
  p_sort text default 'relevance',
  p_limit integer default 20,
  p_offset integer default 0,
  p_at timestamptz default now()
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_query tsquery := app.expand_query(p_query, app.zone_country(p_zone));
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 50));
  v_result jsonb;
begin
  if p_sort not in ('relevance', 'price_asc', 'price_desc') then
    raise exception 'tri inconnu' using errcode = '22023';
  end if;
  with matches as (
    select p.id, p.name,
           app.product_min_price(p.id) as price,
           case when v_query is null then 0 else ts_rank(p.search, v_query) end as rank,
           -- Nom exact, puis nom qui commence par la requête : devant les synonymes.
           case when lower(p.name) = lower(btrim(coalesce(p_query, ''))) then 2
                when btrim(coalesce(p_query, '')) <> ''
                 and lower(p.name) like lower(btrim(p_query)) || '%' then 1 else 0 end as name_match
    from public.products p
    join public.stores s on s.id = p.store_id
    left join public.categories cat on cat.id = p.category_id
    where p.status = 'published' and s.status = 'active'
      and (v_query is null or p.search @@ v_query)
      and app.store_serves(s.id, p_zone)
      and (p_category is null or p.category_id = p_category or cat.parent_id = p_category)
      and (p_origin is null or s.origin = p_origin)
      and (p_min_price is null or app.product_min_price(p.id) >= p_min_price)
      and (p_max_price is null or app.product_min_price(p.id) <= p_max_price)
      and (not p_available_only or app.product_available(p.id))
  )
  select jsonb_build_object(
    'total', (select count(*) from matches),
    'products', coalesce((
      select jsonb_agg(app.catalog_item(id) order by ord)
      from (
        select id, row_number() over (order by
          case when p_sort = 'price_asc' then price end asc,
          case when p_sort = 'price_desc' then price end desc,
          name_match desc, rank desc, name, id) as ord
        from matches
        order by ord
        limit v_limit offset greatest(coalesce(p_offset, 0), 0)
      ) page), '[]'::jsonb),
    'stores', case when v_query is null or coalesce(p_offset, 0) > 0 then '[]'::jsonb else coalesce((
      select jsonb_agg(app.store_summary(id, p_at) order by rank desc, name)
      from (
        select s.id, s.name, ts_rank(s.search, v_query) as rank
        from public.stores s
        where s.status = 'active' and s.search @@ v_query
          and app.store_serves(s.id, p_zone)
          and (p_origin is null or s.origin = p_origin)
        order by rank desc, s.name
        limit 5
      ) t), '[]'::jsonb) end
  ) into v_result;
  return v_result;
end
$$;

-- Copie (0058) : solde de la boutique pour les formules vendeuse.
create or replace function public.membership_offer(p_audience text) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_store public.stores;
  v_country char(2);
begin
  if p_audience = 'vendor' then
    select * into v_store from public.stores where id = app.own_store_id();
    v_country := v_store.country_code;
  elsif p_audience = 'client' then
    v_country := (select country_code from public.profiles where user_id = v_user);
  else
    raise exception 'invalid_audience' using errcode = '22023';
  end if;
  return jsonb_build_object(
    'currency_code', app.user_currency(v_user),
    'wallet_balance_minor', coalesce(app.ledger_balance(
      (select id from public.ledger_accounts where kind = 'user_wallet' and user_id = v_user
         and currency_code = app.user_currency(v_user))), 0),
    -- Formules vendeuse : payées d'abord depuis le solde de la boutique.
    'store_balance_minor', case when v_store.id is null then null else coalesce(app.ledger_balance(
      (select id from public.ledger_accounts where kind = 'store_balance' and store_id = v_store.id
         and currency_code = app.user_currency(v_user))), 0) end,
    'plans', coalesce((select jsonb_agg(jsonb_build_object(
        'id', pl.id, 'code', pl.code, 'name', pl.name, 'description', pl.description,
        'price_minor', pl.price_minor, 'currency_code', pl.currency_code, 'period_days', pl.period_days,
        'benefits', pl.benefits,
        'active_until', (select max(m.ends_at) from public.memberships m where m.plan_id = pl.id
          and m.ends_at > now()
          and (case when p_audience = 'vendor' then m.store_id = v_store.id else m.user_id = v_user end)))
        order by pl.sort, pl.code)
      from public.membership_plans pl
      where pl.country_code = v_country and pl.audience = p_audience and pl.is_active), '[]'::jsonb));
end
$fn$;

-- Copie (0058) : formule vendeuse payée depuis le solde de la boutique, sinon le wallet.
create or replace function public.subscribe_plan(p_plan uuid, p_key uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_plan public.membership_plans;
  v_store public.stores;
  v_wallet uuid;
  v_payer uuid;
  v_start timestamptz;
  v_country char(2);
begin
  select * into v_plan from public.membership_plans where id = p_plan and is_active;
  if v_plan.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if p_key is null then raise exception 'invalid_key' using errcode = '22023'; end if;
  if exists (select 1 from public.memberships where idempotency_key = p_key and paid_by = v_user) then
    return public.membership_offer(v_plan.audience);
  end if;
  if v_plan.audience = 'vendor' then
    select * into v_store from public.stores where id = app.own_store_id();
    v_country := v_store.country_code;
  else
    v_country := (select country_code from public.profiles where user_id = v_user);
  end if;
  if v_country is distinct from v_plan.country_code
     or app.user_currency(v_user) is distinct from v_plan.currency_code then
    raise exception 'other_country' using errcode = 'P0001';
  end if;
  v_wallet := app.ledger_user_account('user_wallet', v_plan.currency_code, v_user);
  -- Vendeuse : solde de la boutique s'il suffit, sinon son wallet.
  if v_store.id is not null then
    v_payer := app.ledger_account('store_balance', v_plan.currency_code, v_store.id);
    perform 1 from public.ledger_accounts where id = v_payer for update;
    if app.ledger_balance(v_payer) < v_plan.price_minor then
      v_payer := null;
    end if;
  end if;
  if v_payer is null then
    v_payer := v_wallet;
    perform 1 from public.ledger_accounts where id = v_payer for update;
    if app.ledger_balance(v_payer) < v_plan.price_minor then
      raise exception 'wallet_insufficient' using errcode = 'P0001';
    end if;
  end if;
  select greatest(now(), coalesce(max(m.ends_at), now())) into v_start
  from public.memberships m
  where m.plan_id = v_plan.id
    and (case when v_store.id is not null then m.store_id = v_store.id else m.user_id = v_user end);
  perform app.ledger_post('membership', 'membership:' || p_key, v_plan.currency_code, jsonb_build_array(
    jsonb_build_object('account', v_payer, 'amount', v_plan.price_minor),
    jsonb_build_object('account', app.ledger_account('platform_subscriptions', v_plan.currency_code),
                       'amount', -v_plan.price_minor)),
    p_user => v_user);
  insert into public.memberships (plan_id, user_id, store_id, paid_by, starts_at, ends_at, idempotency_key)
  values (v_plan.id, case when v_store.id is null then v_user end, v_store.id, v_user, v_start,
          v_start + make_interval(days => v_plan.period_days), p_key);
  perform app.emit_event('membership_started', v_user, v_plan.audience, 'server', v_plan.country_code,
    case when v_store.id is null then 'user' else 'store' end, coalesce(v_store.id, v_user)::text,
    jsonb_build_object('plan_code', v_plan.code, 'renewal', v_start > now()));
  return public.membership_offer(v_plan.audience);
end
$fn$;

-- Copie (0025) : l'admin connecté est signalé.
create or replace function public.admin_admins() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  return coalesce((
    select jsonb_agg(row_to_json(a)::jsonb order by a.status, a.email)
    from (
      select lower(u.email) as email, u.id as user_id, p.first_name,
        coalesce(i.source, 'admin') as source,
        'active' as status, r.granted_at as since, u.id = app.current_user_id() as is_me
      from public.user_roles r
      join neon_auth."user" u on u.id = r.user_id
      left join public.profiles p on p.user_id = u.id
      left join public.admin_invites i on i.email = lower(u.email)
      where r.role = 'admin'
      union all
      select i.email, null, null, i.source, 'invited', i.created_at, false
      from public.admin_invites i
      where not exists (
        select 1 from neon_auth."user" u
        join public.user_roles r on r.user_id = u.id and r.role = 'admin'
        where lower(u.email) = i.email)
    ) a), '[]'::jsonb);
end
$$;

-- ------------------------------------------------------------------ droits

revoke all on function app.cart_line_source(uuid, uuid, integer) from public;
