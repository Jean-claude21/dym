-- Précommande et créneaux (spec 033).

select plan(17);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '29000000-0000-4000-8000-000000000001'::uuid as tomate,
       '29000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '29000000-0000-4000-8000-000000000003'::uuid as igname,
       '29000000-0000-4000-8000-000000000004'::uuid as igname_tas,
       null::uuid as kodjo_store,
       -- Demain (Lomé = UTC) et un créneau de l'après-midi.
       (now() at time zone 'Africa/Lome')::date + 1 as tomorrow,
       (select id from public.delivery_windows where country_code = 'TG' and starts_at = '14:00') as afternoon;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._publish(p_id uuid, p_variant uuid, p_name text) returns void
language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', (select tomates from _t), 'price_minor', 500,
    'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', 20))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, text) to authenticated;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select public.set_store_hours((select jsonb_agg(jsonb_build_object('weekday', d, 'opens_at', '06:00',
  'closes_at', '22:00')) from generate_series(1, 7) d));
select pg_temp._publish((select tomate from _t), (select tomate_tas from _t), 'Tomates');
select pg_temp._publish((select igname from _t), (select igname_tas from _t), 'Igname nouvelle');

-- Arrivage : date passée refusée ; date future affichée sur la fiche.
select throws_ok(format($$select public.set_product_arrival('%s', current_date - 1)$$, (select igname from _t)),
  '22023', 'invalid_arrival', 'arrivage passé refusé');
select public.set_product_arrival((select igname from _t), (select tomorrow from _t) + 2);
select is((public.product_page((select igname from _t)) ->> 'arrival_on')::date, (select tomorrow from _t) + 2,
  'fiche : date d''arrivage');

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);

-- Créneaux proposés : sans arrivage, pas obligatoire ; 6 créneaux demain.
select is((public.delivery_slots() ->> 'required')::boolean, false, 'sans arrivage : créneau facultatif');
select is((select jsonb_array_length(d -> 'windows') from jsonb_array_elements(public.delivery_slots() -> 'days') d
           where (d ->> 'date')::date = (select tomorrow from _t)), 6, 'six créneaux demain');
select ok(jsonb_array_length(public.delivery_slots() -> 'days') <= 8, 'horizon du pays respecté');
select tests.logout();

-- Heure de commande fixe (aujourd'hui, 10 h ou 23 h 30 à Lomé) : le test ne dépend pas de l'heure.
create function pg_temp._order_at(p_slot jsonb, p_at timestamptz) returns jsonb language sql as $$
  select app.place_order_scheduled((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup'), 'slot', p_slot), p_at, '{}')
$$;
create function pg_temp._order(p_slot jsonb) returns jsonb language sql as $$
  select pg_temp._order_at(p_slot, (((select tomorrow from _t) - 1) + time '10:00') at time zone 'Africa/Lome')
$$;

-- Commande programmée demain 14 h : créneau enregistré, heure affichée = début du créneau.
create temporary table _o as select pg_temp._order(jsonb_build_object('date', (select tomorrow from _t),
  'window_id', (select afternoon from _t))) as r;
select is((select scheduled_start from public.orders o
           where o.purchase_id = (select (r -> 'purchase' ->> 'id')::uuid from _o)),
  ((select tomorrow from _t) + time '14:00') at time zone 'Africa/Lome', 'créneau enregistré');
select is((select app.order_eta(o.id) from public.orders o
           where o.purchase_id = (select (r -> 'purchase' ->> 'id')::uuid from _o)),
  ((select tomorrow from _t) + time '14:00') at time zone 'Africa/Lome', 'heure affichée : début du créneau');

-- Refus : créneau hors horizon, créneau inconnu (rien n'est créé).
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
select throws_ok($$select pg_temp._order(jsonb_build_object('date', current_date + 40,
  'window_id', (select afternoon from _t)))$$, 'P0001', 'invalid_slot', 'jour hors horizon refusé');
select throws_ok($$select pg_temp._order(jsonb_build_object('date', (select tomorrow from _t),
  'window_id', gen_random_uuid()))$$, 'P0001', 'invalid_slot', 'créneau inconnu refusé');
select is((select count(*)::int from public.purchases where user_id = (select awa from _t)), 1,
  'refus : aucune commande créée');

-- Boutique fermée à l'heure de la commande (23 h 30) : « dès que possible » refusé ; un créneau
-- de demain où elle est ouverte est accepté, et le panier ne bloque plus avec ce créneau.
select tests.login_as((select awa from _t));
select ok((public.my_cart(p_at => (((select tomorrow from _t) - 1) + time '23:30') at time zone 'Africa/Lome')
  ->> 'blocking')::boolean, 'fermée maintenant : panier bloqué');
select ok(not (public.my_cart(p_at => (((select tomorrow from _t) - 1) + time '23:30') at time zone 'Africa/Lome',
  p_slot => jsonb_build_object('date', (select tomorrow from _t), 'window_id', (select afternoon from _t)))
  ->> 'blocking')::boolean, 'créneau de demain : panier commandable');
select tests.logout();
select throws_ok($$select pg_temp._order_at(null,
  (((select tomorrow from _t) - 1) + time '23:30') at time zone 'Africa/Lome')$$,
  'P0001', 'cart_blocked', 'fermée : dès que possible refusé');
select ok((pg_temp._order_at(jsonb_build_object('date', (select tomorrow from _t), 'window_id', (select afternoon from _t)),
  (((select tomorrow from _t) - 1) + time '23:30') at time zone 'Africa/Lome') -> 'purchase' ->> 'id') is not null,
  'fermée maintenant, ouverte au créneau : commande acceptée');

-- Précommande : créneau obligatoire, à partir de l'arrivage ; prix figé.
select tests.login_as((select awa from _t));
select public.cart_add((select igname_tas from _t), 1);
select is((public.delivery_slots() ->> 'min_date')::date, (select tomorrow from _t) + 2, 'premier jour : l''arrivage');
select tests.logout();
select throws_ok($$select pg_temp._order(null)$$, 'P0001', 'slot_required', 'précommande : créneau obligatoire');
select throws_ok($$select pg_temp._order(jsonb_build_object('date', (select tomorrow from _t),
  'window_id', (select afternoon from _t)))$$, 'P0001', 'slot_too_early', 'créneau avant l''arrivage refusé');

select * from finish();
