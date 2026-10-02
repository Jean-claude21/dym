-- Catalogue : catégories, produits, variantes, publication, stock (spec 007,
-- US1 à US4).

select plan(35);

create temporary table _t as
select tests.create_user('esi@example.com') as esi,
       '11111111-1111-4111-8111-111111111111'::uuid as p1,
       '22222222-2222-4222-8222-222222222222'::uuid as p2,
       '33333333-3333-4333-8333-333333333333'::uuid as p3,
       'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid as v1,
       'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2'::uuid as v2,
       'cccccccc-cccc-4ccc-8ccc-ccccccccccc1'::uuid as c1,
       'cccccccc-cccc-4ccc-8ccc-ccccccccccc2'::uuid as c2,
       (select id from public.units where country_code = 'TG' and code = 'piece') as piece_tg,
       (select id from public.units where country_code = 'GH' and code = 'piece') as piece_gh,
       (select id from public.categories where slug = 'boissons') as boissons,
       null::uuid as store;
update _t set store = tests.open_store(esi, 'Esi');
grant select on _t to authenticated, anonymous;

create function pg_temp._key(p_n int) returns text language sql as $$
  select 'stores/' || (select store from _t) || '/products/'
         || '00000000-0000-4000-8000-00000000000' || p_n || '.jpg'
$$;
create function pg_temp._full(p_id uuid, p_extra jsonb default '{}') returns jsonb language sql as $$
  select jsonb_build_object(
    'id', p_id, 'name', 'Jus de bissap', 'description', 'Préparé chaque matin.',
    'category_id', (select boissons from _t), 'unit_id', (select piece_tg from _t),
    'price_minor', 500, 'photo_keys', jsonb_build_array(pg_temp._key(1)),
    'variants', jsonb_build_array(
      jsonb_build_object('id', (select v1 from _t), 'label', '50 cl', 'stock_quantity', 12),
      jsonb_build_object('id', (select v2 from _t), 'label', '1 L', 'price_minor', 900, 'stock_quantity', 6)),
    'store_category_ids', jsonb_build_array((select c1 from _t))) || p_extra
$$;
grant execute on function pg_temp._key(int), pg_temp._full(uuid, jsonb) to authenticated;

select tests.login_as((select esi from _t));

-- Catégories de boutique.
select lives_ok(format($$select public.save_store_category('%s', 'Jus')$$, (select c1 from _t)),
  'catégorie créée');
select lives_ok(format($$select public.save_store_category('%s', 'Jus frais')$$, (select c1 from _t)),
  'même identifiant : renommée, sans doublon');
select is(jsonb_array_length(public.my_store_categories()), 1, 'une seule catégorie');
select throws_ok(format($$select public.save_store_category('%s', ' JUS FRAIS ')$$, (select c2 from _t)),
  '23505', null, 'nom en double (casse ignorée) refusé');

-- Brouillon, idempotence, devise de la boutique.
select lives_ok(format($$select public.save_product('{"id": "%s", "name": "Jus de bissap", "currency_code": "GHS"}')$$,
  (select p1 from _t)), 'brouillon enregistré');
select lives_ok(format($$select public.save_product('{"id": "%s", "name": "Jus de bissap"}')$$,
  (select p1 from _t)), 'nouvelle tentative');
select is(jsonb_array_length(public.my_products()), 1, 'aucun doublon');
select is(public.my_products() -> 0 ->> 'currency_code', 'XOF', 'devise de la boutique, valeur envoyée ignorée');
select is(public.my_products() -> 0 ->> 'status', 'draft', 'brouillon');
select is(jsonb_array_length(public.my_products() -> 0 -> 'variants'), 1, 'variante par défaut créée');

-- Refus.
select throws_ok(format($$select public.save_product(pg_temp._full('%s', '{"unit_id": "%s"}'))$$,
  (select p1 from _t), (select piece_gh from _t)), '22023', null, 'unité d''un autre pays refusée');
select throws_ok(format($$select public.save_product(pg_temp._full('%s', jsonb_build_object('photo_keys',
  jsonb_build_array('stores/00000000-0000-4000-8000-000000000000/products/00000000-0000-4000-8000-000000000001.jpg'))))$$,
  (select p1 from _t)), '42501', null, 'photo d''une autre boutique refusée');
select throws_ok(format($$select public.save_product(pg_temp._full('%s', jsonb_build_object('photo_keys',
  jsonb_build_array(pg_temp._key(1), pg_temp._key(2), pg_temp._key(3), pg_temp._key(4), pg_temp._key(5), pg_temp._key(6)))))$$,
  (select p1 from _t)), '22023', null, 'plus de 5 photos refusées');
select throws_ok(format($$select public.save_product(pg_temp._full('%s', '{"price_minor": 0}'))$$,
  (select p1 from _t)), '23514', null, 'prix nul refusé');
select throws_ok(format($$select public.save_product(pg_temp._full('%s', '{"name": "J"}'))$$,
  (select p1 from _t)), '23514', null, 'nom trop court refusé');
select throws_ok(format($$select public.save_product(pg_temp._full('%s', jsonb_build_object('variants',
  (select jsonb_agg(jsonb_build_object('id', gen_random_uuid(), 'label', 'T' || i)) from generate_series(1, 11) i))))$$,
  (select p1 from _t)), '22023', null, 'plus de 10 variantes refusées');
select throws_ok(format($$select public.publish_product('%s')$$, (select p1 from _t)),
  'P0001', null, 'publication incomplète refusée');

-- Fiche complète et publication.
select lives_ok(format($$select public.save_product(pg_temp._full('%s'))$$, (select p1 from _t)), 'fiche complète');
select is(jsonb_array_length(public.my_products() -> 0 -> 'variants'), 2, 'deux variantes');
select is(public.my_products() -> 0 -> 'store_category_ids', jsonb_build_array((select c1 from _t)),
  'catégorie de boutique assignée');
select lives_ok(format($$select public.publish_product('%s')$$, (select p1 from _t)), 'publication');
select lives_ok(format($$select public.publish_product('%s')$$, (select p1 from _t)), 'publication rejouée');
select is(public.my_products() -> 0 ->> 'status', 'published', 'publié');
select ok(not (public.my_products() -> 0 ? 'search') and not (public.my_store() ? 'search'),
  'colonne technique search non servie');

-- Stock et rupture.
select lives_ok(format($$select public.set_product_available('%s', false)$$, (select p1 from _t)), 'rupture');
select is((public.my_products() -> 0 ->> 'is_available')::boolean, false, 'en rupture');
select lives_ok(format($$select public.set_variant_stock('%s', 5)$$, (select v1 from _t)), 'stock d''une variante');
select throws_ok(format($$select public.set_variant_stock('%s', -1)$$, (select v1 from _t)),
  '23514', null, 'stock négatif refusé');
select lives_ok(format($$select public.save_product(pg_temp._full('%s'))$$, (select p1 from _t)),
  'stock modifié par la fiche (12 au lieu de 5)');

-- Archivage et suppression.
select lives_ok(format($$select public.archive_product('%s', true)$$, (select p1 from _t)), 'archivage');
select lives_ok(format($$select public.archive_product('%s', false)$$, (select p1 from _t)), 'restauration');
select throws_ok(format($$select public.delete_product_draft('%s')$$, (select p1 from _t)),
  'P0001', null, 'un produit publié ne se supprime pas');

-- Événements (lus par le propriétaire).
select tests.logout();
select is((select count(*)::int from public.events where name = 'product_published' and entity_id = (select p1 from _t)::text),
  1, 'product_published une seule fois');
select is(array(select props ->> 'change' from public.events
                where name = 'product_stock_changed' and entity_id = (select p1 from _t)::text order by id),
  array['out_of_stock', 'quantity', 'quantity'], 'product_stock_changed : rupture, variante, fiche');
select is((select status from public.products where id = (select p1 from _t)), 'published',
  'restauré publié');

select * from finish();
