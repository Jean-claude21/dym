-- 0036 — Assistant de courses (spec 029).
-- 1. Listes de courses nommées librement : des besoins (libellé, mot de recherche, quantité),
--    résolus à chaque ouverture chez le meilleur marchand du quartier (règles de la spec 028).
-- 2. « Ma liste habituelle » : produits achetés dans au moins deux commandes sur 90 jours.
-- 3. Récurrence : rappel à 8 h (heure du pays) le jour de l'échéance, une seule fois ; jamais de
--    dépense sans validation.

create table public.shopping_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references neon_auth."user" (id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 40),
  items jsonb not null check (jsonb_typeof(items) = 'array' and jsonb_array_length(items) between 1 and 20),
  every_days smallint check (every_days in (7, 14, 30)),
  next_due_on date,
  zone_id uuid references public.zones (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((every_days is null) = (next_due_on is null))
);
create index shopping_lists_user on public.shopping_lists (user_id, created_at);
create index shopping_lists_due on public.shopping_lists (next_due_on) where every_days is not null;
alter table public.shopping_lists enable row level security;
create policy shopping_lists_owner_read on public.shopping_lists for select
  to authenticated using (user_id = app.current_user_id());
revoke all on public.shopping_lists from authenticated, anonymous;
grant select on public.shopping_lists to authenticated;

-- Date du jour dans le pays de la personne.
create or replace function app.user_local_date(p_user uuid, p_at timestamptz default now()) returns date
language sql stable security definer set search_path = ''
as $$
  select coalesce((select (p_at at time zone c.timezone)::date
                   from public.profiles pr join public.countries c on c.code = pr.country_code
                   where pr.user_id = p_user), (p_at at time zone 'UTC')::date)
$$;

-- Articles nettoyés : libellé et mot de recherche bornés, quantité 1 à 10, 20 au plus.
create or replace function app.clean_shopping_items(p_items jsonb) returns jsonb
language plpgsql immutable set search_path = ''
as $fn$
declare
  v_out jsonb := '[]'::jsonb;
  v_item jsonb;
  v_label text;
  v_query text;
  v_qty int;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'invalid_items' using errcode = '22023';
  end if;
  for v_item in select i from jsonb_array_elements(p_items) i loop
    if jsonb_typeof(v_item) <> 'object' then
      raise exception 'invalid_items' using errcode = '22023';
    end if;
    v_label := left(regexp_replace(btrim(coalesce(v_item ->> 'label', '')), '\s+', ' ', 'g'), 60);
    v_query := left(regexp_replace(btrim(coalesce(nullif(btrim(v_item ->> 'query'), ''), v_label)),
                                   '\s+', ' ', 'g'), 60);
    if length(v_label) = 0 or length(v_query) < 2 then
      raise exception 'invalid_items' using errcode = '22023';
    end if;
    v_qty := coalesce((v_item ->> 'quantity')::numeric, 1)::int;
    if v_qty not between 1 and 10 then
      raise exception 'invalid_quantity' using errcode = '22023';
    end if;
    v_out := v_out || jsonb_build_object('label', v_label, 'query', v_query, 'quantity', v_qty);
  end loop;
  if jsonb_array_length(v_out) not between 1 and 20 then
    raise exception 'invalid_items' using errcode = '22023';
  end if;
  return v_out;
end
$fn$;

create or replace function app.shopping_list_json(l public.shopping_lists) returns jsonb
language sql stable set search_path = ''
as $$
  select jsonb_build_object('id', l.id, 'name', l.name, 'items', l.items, 'every_days', l.every_days,
    'next_due_on', l.next_due_on, 'zone_id', l.zone_id, 'updated_at', l.updated_at)
$$;

-- Choix du copilote (0035) avec un plafond de besoins : 7 par défaut (copilote), 20 au plus
-- (listes de courses). Seule la boucle change.
drop function app.copilot_pick(uuid, jsonb);
create function app.copilot_pick(p_zone uuid, p_needs jsonb, p_max int default 7) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_need jsonb;
  v_query tsquery;
  v_country char(2) := app.zone_country(p_zone);
  w public.ranking_rules := app.ranking_weights(v_country);
  v_stores uuid[] := '{}';
  v_items jsonb := '[]'::jsonb;
  v_missing jsonb := '[]'::jsonb;
  v_pick record;
  v_label text;
begin
  for v_need in select n from jsonb_array_elements(coalesce(p_needs, '[]'::jsonb)) n
                limit least(greatest(coalesce(p_max, 7), 1), 20) loop
    v_label := left(trim(coalesce(v_need ->> 'label', v_need ->> 'query', '')), 60);
    v_query := app.expand_query(v_need ->> 'query', v_country);
    v_pick := null;
    if v_query is not null then
      with cand as (
        select p.id as product_id, s.id as store_id,
               ts_rank(p.search, v_query) as text_rank,
               (s.id = any(v_stores)) as same_store,
               app.store_open_at(s.id, now()) as open_now,
               coalesce((app.store_rating(s.id) ->> 'rating')::numeric, 0) / 5 as rating,
               app.product_min_price(p.id) as price,
               (s.zone_id = p_zone) as same_zone
        from public.products p
        join public.stores s on s.id = p.store_id
        where p.status = 'published' and s.status = 'active'
          and p.search @@ v_query
          and app.store_serves(s.id, p_zone)
          and app.product_available(p.id)
      ),
      norm as (
        select c.*,
               c.text_rank / nullif(max(c.text_rank) over (), 0) as text_n,
               case when max(c.price) over () = min(c.price) over () then 1
                    else 1 - (c.price - min(c.price) over ())::numeric
                         / (max(c.price) over () - min(c.price) over ()) end as price_n
        from cand c
      ),
      scored as (
        select n.*,
               w.weight_text * coalesce(n.text_n, 0) as s_text,
               w.weight_same_store * n.same_store::int as s_store,
               w.weight_open * n.open_now::int as s_open,
               w.weight_rating * n.rating as s_rating,
               w.weight_price * n.price_n as s_price,
               w.weight_same_zone * coalesce(n.same_zone, false)::int as s_zone
        from norm n
      )
      select s.product_id, s.store_id,
             (select v.id from public.product_variants v
              where v.product_id = s.product_id and coalesce(v.stock_quantity, 1) > 0
              order by app.variant_price(v.id), v.sort limit 1) as variant_id,
             (select r.code from (values
                ('same_store', s.s_store), ('open_now', s.s_open), ('top_rated', s.s_rating),
                ('best_price', s.s_price), ('nearby', s.s_zone), ('best_match', s.s_text)
              ) as r (code, v) order by r.v desc, r.code limit 1) as reason
      into v_pick
      from scored s
      order by s.s_text + s.s_store + s.s_open + s.s_rating + s.s_price + s.s_zone desc,
               s.price, s.product_id
      limit 1;
    end if;
    if v_pick.variant_id is null then
      if length(v_label) > 0 then
        v_missing := v_missing || to_jsonb(v_label);
      end if;
    else
      v_stores := array_append(v_stores, v_pick.store_id);
      v_items := v_items || jsonb_build_object('variant_id', v_pick.variant_id,
        'quantity', coalesce((v_need ->> 'quantity')::int, 1), 'need', v_label,
        'reason', v_pick.reason);
    end if;
  end loop;
  return app.copilot_quote(v_items) || jsonb_build_object('missing', v_missing);
end
$fn$;

-- ------------------------------------------------------------------ listes

-- Crée (sans id) ou modifie (id) une liste de la personne. `starts_on` : première échéance
-- (aujourd'hui au plus tôt) ; absente : dans une période.
create or replace function public.save_shopping_list(p jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.current_user_id();
  v_id uuid := nullif(p ->> 'id', '')::uuid;
  v_name text := regexp_replace(btrim(coalesce(p ->> 'name', '')), '\s+', ' ', 'g');
  v_items jsonb;
  v_every smallint := nullif(p ->> 'every_days', '')::smallint;
  v_zone uuid := nullif(p ->> 'zone_id', '')::uuid;
  v_today date;
  v_due date;
  v_row public.shopping_lists;
begin
  if v_user is null then raise exception 'authentication required' using errcode = '42501'; end if;
  if length(v_name) not between 1 and 40 then raise exception 'invalid_name' using errcode = '22023'; end if;
  v_items := app.clean_shopping_items(p -> 'items');
  if v_every is not null and v_every not in (7, 14, 30) then
    raise exception 'invalid_period' using errcode = '22023';
  end if;
  if v_zone is not null and not exists (select 1 from public.zones where id = v_zone) then
    raise exception 'quartier inconnu' using errcode = '22023';
  end if;
  v_today := app.user_local_date(v_user);
  if v_every is not null then
    v_due := coalesce(nullif(p ->> 'starts_on', '')::date, v_today + v_every);
    if v_due < v_today then raise exception 'invalid_start' using errcode = '22023'; end if;
  end if;
  if v_id is null then
    if (select count(*) from public.shopping_lists where user_id = v_user) >= 20 then
      raise exception 'too_many_lists' using errcode = '22023';
    end if;
    insert into public.shopping_lists (user_id, name, items, every_days, next_due_on, zone_id)
    values (v_user, v_name, v_items, v_every, v_due, v_zone) returning * into v_row;
  else
    update public.shopping_lists set name = v_name, items = v_items, every_days = v_every,
      next_due_on = v_due, zone_id = v_zone, updated_at = now()
    where id = v_id and user_id = v_user returning * into v_row;
    if v_row.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  end if;
  perform app.emit_event('shopping_list_saved', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'shopping_list', v_row.id::text,
    jsonb_build_object('items_count', jsonb_array_length(v_items), 'recurring', v_every is not null,
      'every_days', v_every, 'created', v_id is null));
  return app.shopping_list_json(v_row);
end
$fn$;

create or replace function public.delete_shopping_list(p_id uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
begin
  delete from public.shopping_lists where id = p_id and user_id = app.current_user_id();
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
end
$fn$;

create or replace function public.my_shopping_lists() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(app.shopping_list_json(l) order by l.created_at, l.id), '[]'::jsonb)
  from public.shopping_lists l where l.user_id = app.current_user_id()
$$;

-- Ma liste habituelle : produits commandés dans au moins deux commandes (90 jours), les plus
-- fréquents d'abord, quantité médiane ; 12 au plus. Le nom du produit sert de mot de recherche.
create or replace function public.shopping_habits(p_at timestamptz default now()) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object('label', x.label, 'query', x.label, 'quantity', x.qty)
                            order by x.n desc, x.last desc), '[]'::jsonb)
  from (
    select left(btrim((array_agg(oi.product_name order by o.created_at desc))[1]), 60) as label,
           count(distinct o.id) as n,
           max(o.created_at) as last,
           least(10, greatest(1, round(percentile_cont(0.5) within group (order by oi.quantity))))::int as qty
    from public.order_items oi
    join public.orders o on o.id = oi.order_id
    join public.purchases pu on pu.id = o.purchase_id
    where app.current_user_id() is not null and pu.user_id = app.current_user_id()
      and o.status not in ('refused', 'cancelled')
      and o.created_at > p_at - interval '90 days'
    group by oi.product_id
    having count(distinct o.id) >= 2
    order by count(distinct o.id) desc, max(o.created_at) desc
    limit 12) x
  where length(x.label) >= 2
$$;

-- Panier proposé pour une liste : composé et chiffré en base (quartier donné, sinon celui de la
-- liste, sinon celui du profil).
create or replace function public.shopping_list_proposal(p_id uuid, p_zone uuid default null) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.current_user_id();
  v_list public.shopping_lists;
  v_zone uuid;
  v_out jsonb;
begin
  select * into v_list from public.shopping_lists where id = p_id and user_id = v_user;
  if v_list.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  v_zone := coalesce(p_zone, v_list.zone_id, (select zone_id from public.profiles where user_id = v_user));
  v_out := app.copilot_pick(v_zone, v_list.items, 20);
  perform app.emit_event('shopping_list_proposed', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'shopping_list', v_list.id::text,
    jsonb_build_object('items_count', coalesce((v_out ->> 'item_count')::int, 0),
      'stores_count', jsonb_array_length(coalesce(v_out -> 'stores', '[]'::jsonb)),
      'missing_count', jsonb_array_length(coalesce(v_out -> 'missing', '[]'::jsonb))));
  return v_out || jsonb_build_object('list_id', v_list.id, 'list_name', v_list.name);
end
$fn$;

-- ------------------------------------------------------------------ rappels

-- Tâche planifiée (toutes les 15 min) : à partir de 8 h locales, une notification par liste échue ;
-- l'échéance avance dans la même requête (jamais deux rappels).
create or replace function app.create_shopping_reminders(p_at timestamptz default now()) returns integer
language plpgsql security definer set search_path = ''
as $fn$
declare
  v record;
  v_count integer := 0;
begin
  if p_at is null then raise exception 'invalid_time' using errcode = '22023'; end if;
  -- Une date future (appel forgé) ne déclenche jamais un rappel avant l'heure.
  p_at := least(p_at, now());
  for v in
    select l.id, l.user_id, l.name, l.every_days, l.next_due_on, pr.country_code,
           (p_at at time zone c.timezone)::date as today
    from public.shopping_lists l
    join public.profiles pr on pr.user_id = l.user_id
    join public.countries c on c.code = pr.country_code
    where l.every_days is not null
      and l.next_due_on <= (p_at at time zone c.timezone)::date
      and (p_at at time zone c.timezone)::time >= time '08:00'
    for update of l skip locked
  loop
    update public.shopping_lists
    set next_due_on = v.next_due_on + v.every_days * ((v.today - v.next_due_on) / v.every_days + 1)
    where id = v.id;
    perform app.notify(v.user_id, 'shopping_list_due', 'orders', null, null,
      jsonb_build_object('list_id', v.id, 'list_name', v.name));
    perform app.emit_event('shopping_reminder_sent', v.user_id, 'client', 'server', v.country_code,
      'shopping_list', v.id::text, jsonb_build_object('every_days', v.every_days));
    v_count := v_count + 1;
  end loop;
  return v_count;
end
$fn$;

insert into public.notification_templates (kind, locale, title, body) values
  ('shopping_list_due', 'fr', 'Tes courses sont prêtes', '« {list_name} » : vérifie et valide ton panier.'),
  ('shopping_list_due', 'en', 'Your shopping is ready', '“{list_name}”: check and confirm your basket.')
on conflict do nothing;

insert into public.event_names (name, emitted_by, description) values
  ('shopping_list_saved', 'server', 'Liste de courses enregistrée (articles, récurrence)'),
  ('shopping_list_proposed', 'server', 'Panier proposé pour une liste (articles, boutiques, manquants)'),
  ('shopping_reminder_sent', 'server', 'Rappel de courses récurrentes envoyé'),
  ('shopping_list_cart_added', 'client', 'Panier d''une liste ajouté au panier (articles)')
on conflict do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function app.user_local_date(uuid, timestamptz), app.clean_shopping_items(jsonb),
  app.shopping_list_json(public.shopping_lists), app.copilot_pick(uuid, jsonb, int),
  app.create_shopping_reminders(timestamptz),
  public.save_shopping_list(jsonb), public.delete_shopping_list(uuid), public.my_shopping_lists(),
  public.shopping_habits(timestamptz), public.shopping_list_proposal(uuid, uuid) from public;
grant execute on function public.save_shopping_list(jsonb), public.delete_shopping_list(uuid),
  public.my_shopping_lists(), public.shopping_habits(timestamptz),
  public.shopping_list_proposal(uuid, uuid) to authenticated;
