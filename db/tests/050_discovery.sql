-- Découverte (spec 008) : boutiques près de soi, quartier le plus proche,
-- recherche, filtres, pages publiques sans données privées.

select plan(32);

-- Lundi 5 octobre 2026, Lomé (UTC+0) : 10 h (ouvert) et 20 h (fermé).
create temporary table _t as
select tests.create_user('esi@example.com') as esi,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('afi@example.com') as afi,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       '2026-10-05 20:00:00+00'::timestamptz as evening,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.zones where slug = 'tokoin') as tokoin,
       (select id from public.zones where slug = 'agoe') as agoe,
       (select id from public.categories where slug = 'legumes') as legumes,
       (select id from public.categories where slug = 'tomates') as tomates,
       (select id from public.categories where slug = 'boissons') as boissons,
       (select id from public.categories where slug = 'epices') as epices,
       '11111111-1111-4111-8111-111111111111'::uuid as bissap,
       '22222222-2222-4222-8222-222222222222'::uuid as sirop,
       '33333333-3333-4333-8333-333333333333'::uuid as epice,
       '44444444-4444-4444-8444-444444444444'::uuid as tomate,
       '55555555-5555-4555-8555-555555555555'::uuid as brouillon,
       null::uuid as esi_store, null::uuid as kodjo_store, null::uuid as afi_store;
update _t set esi_store = tests.open_store(esi, 'Les jus d''Esi', 'tokoin'),
              kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be'),
              afi_store = tests.open_store(afi, 'Chez Afi', 'agoe');
grant select on _t to authenticated, anonymous;

create function pg_temp._product(p_store uuid, p_id uuid, p_name text, p_category uuid, p_price bigint,
  p_variants jsonb default null) returns jsonb language sql as $$
  select jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', p_category, 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || p_store || '/products/' || p_id || '.jpg'),
    'variants', coalesce(p_variants, jsonb_build_array(jsonb_build_object('id', gen_random_uuid(), 'stock_quantity', 5))))
$$;
grant execute on function pg_temp._product(uuid, uuid, text, uuid, bigint, jsonb) to authenticated;

-- Esi (fait maison, Tokoin) livre aussi Bè.
select tests.login_as((select esi from _t));
select public.set_store_delivery_zones(array[(select tokoin from _t), (select be from _t)]);
select public.save_product(pg_temp._product((select esi_store from _t), (select bissap from _t),
  'Jus de bissap', (select boissons from _t), 700, jsonb_build_array(
    jsonb_build_object('id', gen_random_uuid(), 'label', '50 cl', 'price_minor', 400, 'stock_quantity', 3),
    jsonb_build_object('id', gen_random_uuid(), 'label', '1 L', 'stock_quantity', 0))));
select public.publish_product((select bissap from _t));
select public.save_product(pg_temp._product((select esi_store from _t), (select sirop from _t),
  'Sirop de bissap', (select boissons from _t), 2500));
select public.publish_product((select sirop from _t));
select public.set_product_available((select sirop from _t), false);
-- Même transaction, même now() : on départage les dates de publication.
select tests.logout();
update public.products set published_at = published_at + interval '1 second'
 where id = (select sirop from _t);
select tests.login_as((select esi from _t));
select public.save_product(pg_temp._product((select esi_store from _t), (select brouillon from _t),
  'Bissap en poudre', (select boissons from _t), 900));

-- Kodjo (au marché, Bè).
select tests.login_as((select kodjo from _t));
select public.update_store('{"origin": "marche"}');
select public.save_product(pg_temp._product((select kodjo_store from _t), (select epice from _t),
  'Épices du marché', (select epices from _t), 300));
select public.publish_product((select epice from _t));
select public.save_product(pg_temp._product((select kodjo_store from _t), (select tomate from _t),
  'Tomates fraîches', (select tomates from _t), 500,
  jsonb_build_array(jsonb_build_object('id', gen_random_uuid(), 'stock_quantity', 0))));
select public.publish_product((select tomate from _t));

-- Visiteuse anonyme.
select tests.login_anonymous();

-- Accueil.
select is(
  (select jsonb_agg(s ->> 'name') from jsonb_array_elements(
    public.discover_stores((select be from _t), 20, (select morning from _t)) -> 'stores') s),
  jsonb_build_array('Étal de Kodjo', 'Les jus d''Esi'),
  'boutiques qui livrent Bè : celles du quartier d''abord, Chez Afi absente');
select is((public.discover_stores((select be from _t), 20, (select morning from _t)) ->> 'estimate_minutes')::int,
  50, 'estimation : préparation la plus rapide (30) + ville (20)');
select is((public.discover_stores((select be from _t), 20, (select morning from _t)) -> 'stores' -> 0 ->> 'open_now'),
  'true', 'ouverte à 10 h');
select is((public.discover_stores((select be from _t), 20, (select morning from _t)) -> 'stores' -> 0 ->> 'closes_at'),
  '19:00', 'fermeture du jour');
select is((public.discover_stores((select be from _t), 20, (select evening from _t)) -> 'stores' -> 0 ->> 'open_now'),
  'false', 'fermée à 20 h');
select is(public.discover_stores((select be from _t), 20, (select evening from _t)) -> 'estimate_minutes',
  'null'::jsonb, 'aucune boutique ouverte : pas d''estimation');
select is((public.discover_stores((select be from _t), 20, (select morning from _t)) -> 'stores' -> 1 ->> 'cover_key'),
  'stores/' || (select esi_store from _t) || '/products/' || (select bissap from _t) || '.jpg',
  'couverture : photo du premier produit publié');
select ok(not (public.discover_stores((select be from _t), 20, (select morning from _t)) -> 'stores' -> 0 ? 'owner_id'),
  'aucun propriétaire servi');

-- Quartier le plus proche.
select is(public.nearest_zone(6.151, 1.217) ->> 'zone_name', 'Tokoin', 'position près de Tokoin');
select is(public.nearest_zone(5.556, -0.18) ->> 'country_code', 'TG',
  'le Ghana inactif n''est pas proposé');
select is(public.nearest_zone(95, 1) , null, 'position invalide : rien');

-- Recherche.
select is((public.search_catalog('epices') -> 'products' -> 0 ->> 'name'), 'Épices du marché',
  'accents ignorés');
select is((public.search_catalog('BISS') ->> 'total')::int, 2, 'préfixe, casse ignorée ; brouillon exclu');
select is((public.search_catalog('biss', p_available_only => true) ->> 'total')::int, 1,
  'disponibles seulement : sirop en rupture exclu');
select is((public.search_catalog(null, p_origin => 'marche') ->> 'total')::int, 2, 'filtre par origine');
select is((public.search_catalog(null, p_category => (select legumes from _t)) -> 'products' -> 0 ->> 'name'),
  'Tomates fraîches', 'rayon : sous-rayons compris');
select is((public.search_catalog(null, p_category => (select legumes from _t)) -> 'products' -> 0 ->> 'available'),
  'false', 'stock épuisé : indisponible');
select is((select jsonb_agg(p ->> 'name') from jsonb_array_elements(
    public.search_catalog(null, p_sort => 'price_asc') -> 'products') p),
  jsonb_build_array('Épices du marché', 'Jus de bissap', 'Tomates fraîches', 'Sirop de bissap'),
  'tri par prix (le plus bas des variantes)');
select is((public.search_catalog(null, p_min_price => 350, p_max_price => 600) ->> 'total')::int, 2,
  'filtre de prix');
select is((public.search_catalog(null, p_zone => (select agoe from _t)) ->> 'total')::int, 0,
  'quartier non desservi : rien');
select is((public.search_catalog('esi') -> 'stores' -> 0 ->> 'name'), 'Les jus d''Esi', 'boutiques trouvées');
select throws_ok($$select public.search_catalog('x', p_sort => 'note')$$, '22023', null, 'tri inconnu refusé');
select is((public.search_catalog(null, p_limit => 1, p_offset => 1, p_sort => 'price_asc') -> 'products' -> 0 ->> 'name'),
  'Jus de bissap', 'pagination');

-- Pages.
select is(jsonb_array_length(public.store_page((select esi_store from _t), (select morning from _t)) -> 'products'),
  2, 'page boutique : publiés seulement');
select ok(not (public.store_page((select esi_store from _t)) ?| array['owner_id', 'pickup_address', 'search']),
  'page boutique : ni propriétaire, ni adresse');
select is((public.product_page((select bissap from _t), (select be from _t)) -> 'variants' -> 1 ->> 'price_minor'),
  '700', 'variante sans prix : prix de base');
select is((public.product_page((select bissap from _t), (select be from _t)) -> 'variants' -> 1 ->> 'available'),
  'false', 'variante épuisée');
select is((public.product_page((select bissap from _t), (select be from _t)) -> 'store' ->> 'delivery_minutes')::int,
  50, 'délai estimé : préparation + ville');
select ok(not (public.product_page((select bissap from _t)) ? 'suggestion_id'), 'proposition non servie');
select is(public.product_page((select brouillon from _t)), null, 'brouillon : pas de fiche');

-- Boutique suspendue : invisible partout.
select tests.logout();
update public.stores set status = 'suspended', is_open = false where id = (select esi_store from _t);
select tests.login_anonymous();
select is(public.store_page((select esi_store from _t)), null, 'suspendue : pas de page');
select is((public.search_catalog('biss') ->> 'total')::int, 0, 'suspendue : produits absents');

select * from finish();
