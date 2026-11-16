-- Rayon souple (spec 096) : rayon par défaut de la ville, distance maximale du pays,
-- livraison longue distance sur demande au-delà du rayon de la boutique.

select plan(15);

create temporary table _t as
select tests.create_user('ama@example.com') as ama,
       tests.create_user('awa@example.com') as awa,
       tests.create_user('admin@example.com') as admin,
       (select id from public.zones where slug = 'be') as be,
       (select city_id from public.zones where slug = 'be') as lome,
       '78100000-0000-4000-8000-000000000001'::uuid as tomate,
       '78100000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '78100000-0000-4000-8000-000000000003'::uuid as address,
       null::uuid as store;
insert into public.user_roles (user_id, role) values ((select admin from _t), 'admin');
grant select, update on _t to authenticated, anonymous;

-- L'admin règle la ville (rayon proposé) et le pays (distance maximale), audité.
select tests.login_as((select admin from _t));
select lives_ok(format($$select public.admin_set_city_delivery_radius('%s', 3000)$$, (select lome from _t)),
  'rayon par défaut de la ville');
select is((public.admin_set_delivery_settings('TG', 15000) ->> 'max_distance_m')::int, 15000,
  'distance maximale du pays');
select is((public.admin_delivery_config('TG') ->> 'max_distance_m')::int, 15000, 'réglages relus');

-- Nouvelle boutique de la ville : rayon proposé par la ville.
select tests.logout();
update _t set store = tests.open_store(ama, 'Chez Ama', 'be');
alter table _t add column lat numeric, add column lng numeric;
update _t set lat = sp.lat, lng = sp.lng from app.store_point((select store from _t)) sp;
select is((select delivery_radius_m from public.stores where id = (select store from _t)), 3000,
  'nouvelle boutique : rayon de la ville');

select tests.login_as((select ama from _t));
select throws_ok($$select public.update_store('{"delivery_radius_m": 20000}')$$, '22023', 'radius_too_large',
  'rayon au-delà du maximum du pays refusé');

-- Découverte à 8 km : hors du rayon (3 km), mais livrable sur demande.
select tests.login_anonymous();
select ok((select (s ->> 'long_distance')::boolean from jsonb_array_elements(public.discover_stores(null, 20, now(),
             (select lat from _t) + 0.072, (select lng from _t)) -> 'stores') s
           where (s ->> 'id')::uuid = (select store from _t)), 'à 8 km : longue distance');
select ok(not exists (select 1 from jsonb_array_elements(public.discover_stores(null, 20, now(),
             (select lat from _t) + 0.3, (select lng from _t)) -> 'stores') s
           where (s ->> 'id')::uuid = (select store from _t)), 'à 33 km : pas de livraison');

-- Panier à 8 km : non bloqué, signalé longue distance ; à 33 km : non livré.
select tests.login_as((select ama from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select id from public.categories where slug = 'tomates'),
  'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone, latitude, longitude)
select (select address from _t), (select awa from _t), 'home', (select be from _t), 'Portail bleu',
       '+228 91 00 00 02', sp.lat + 0.072, sp.lng
from app.store_point((select store from _t)) sp;
select tests.login_as((select awa from _t));
select is(public.my_cart((select address from _t)) -> 'stores' -> 0 ->> 'long_distance', 'true',
  'panier à 8 km : longue distance');
select tests.logout();
update public.customer_addresses set latitude = latitude + 0.23 where id = (select address from _t);
select tests.login_as((select awa from _t));
select ok(public.my_cart((select address from _t)) -> 'stores' -> 0 -> 'issues' ? 'not_delivered',
  'panier à 33 km : non livré');

-- Tarif au km : 300 de prise en charge, 1 km inclus, 150 le km, arrondi à 50, plafond 2000,
-- longue distance +500, majoration de nuit +20 % (heure de Lomé).
select tests.login_as((select admin from _t));
select is((public.admin_set_delivery_pricing('TG', null, '{"mode": "per_km", "base_fee_minor": 300,
  "included_m": 1000, "per_km_minor": 150, "min_fee_minor": 400, "max_fee_minor": 2000, "rounding_minor": 50,
  "long_distance_surcharge_minor": 500}') ->> 'per_km_minor')::int, 150, 'tarif au km enregistré');
select is((public.admin_preview_delivery_fee('TG', null, 3000, false, '2026-10-05 12:00:00+00') ->> 'fee_minor')::int,
  600, '3 km à midi : 300 + 2 km × 150 = 600');
select is((public.admin_preview_delivery_fee('TG', null, 500, false, '2026-10-05 12:00:00+00') ->> 'fee_minor')::int,
  400, 'course courte : minimum 400');
select is((public.admin_preview_delivery_fee('TG', null, 8000, true, '2026-10-05 12:00:00+00') ->> 'fee_minor')::int,
  1850, 'longue distance : 300 + 7 × 150 + 500 = 1850');
select lives_ok($$select public.admin_set_delivery_surcharges('TG', null,
  '[{"label": "Nuit", "starts_at": "21:00", "ends_at": "06:00", "percent": 20}]')$$, 'majoration de nuit');
select is((public.admin_preview_delivery_fee('TG', null, 3000, false, '2026-10-05 22:30:00+00') ->> 'fee_minor')::int,
  750, 'nuit : 600 × 1,2 = 720, arrondi à 750');

select * from finish();
