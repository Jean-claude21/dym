-- Catalogue : lecture publique, écritures croisées, propositions de l'IA,
-- boutique suspendue (spec 007, US1, US5).

select plan(28);

create temporary table _t as
select tests.create_user('esi@example.com') as esi,
       tests.create_user('kodjo@example.com') as kodjo,
       '11111111-1111-4111-8111-111111111111'::uuid as p1,
       '22222222-2222-4222-8222-222222222222'::uuid as p2,
       '33333333-3333-4333-8333-333333333333'::uuid as p3,
       '44444444-4444-4444-8444-444444444444'::uuid as p4,
       'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'::uuid as v1,
       'cccccccc-cccc-4ccc-8ccc-ccccccccccc1'::uuid as c1,
       'cccccccc-cccc-4ccc-8ccc-ccccccccccc2'::uuid as c2,
       (select id from public.categories where slug = 'boissons') as boissons,
       null::uuid as store,
       null::uuid as kodjo_store,
       null::uuid as suggestion;
update _t set store = tests.open_store(esi, 'Esi'), kodjo_store = tests.open_store(kodjo, 'Kodjo', 'be');
grant select on _t to authenticated, anonymous;

create function pg_temp._key(p_n int) returns text language sql as $$
  select 'stores/' || (select store from _t) || '/products/'
         || '00000000-0000-4000-8000-00000000000' || p_n || '.jpg'
$$;
create function pg_temp._product(p_id uuid, p_name text, p_extra jsonb default '{}') returns jsonb
language sql as $$
  select jsonb_build_object(
    'id', p_id, 'name', p_name, 'description', 'Préparé chaque matin.',
    'category_id', (select boissons from _t), 'price_minor', 500,
    'photo_keys', jsonb_build_array(pg_temp._key(1))) || p_extra
$$;
grant execute on function pg_temp._key(int), pg_temp._product(uuid, text, jsonb) to authenticated;

-- Proposition enregistrée par la Function (rôle propriétaire).
update _t set suggestion = app.record_product_suggestion(
  esi, pg_temp._key(1), 'gpt-5.4-mini', 'Jus de bissap', boissons, 'Préparé chaque matin.');
select isnt((select suggestion from _t), null, 'proposition conservée');
select is(
  (select category_id from app.ai_product_suggestions
   where id = app.record_product_suggestion((select esi from _t), pg_temp._key(2), 'm', 'X', gen_random_uuid(), null)),
  null, 'rayon proposé inconnu : ignoré');
select throws_ok(format($$select app.suggestion_context('%s', '%s')$$, (select kodjo from _t), pg_temp._key(1)),
  '42501', null, 'proposition sur la photo d''une autre boutique refusée');
select is((app.suggestion_context((select esi from _t), pg_temp._key(1)) -> 'model'), 'null'::jsonb,
  'modèle inactif : aucun modèle (saisie manuelle)');
select ok(jsonb_array_length(app.suggestion_context((select esi from _t), pg_temp._key(1)) -> 'categories') > 10,
  'rayons actifs fournis au modèle');

-- Catalogue d'Esi : publié, brouillon, archivé, publié depuis une proposition.
select tests.login_as((select esi from _t));
select public.save_store_category((select c1 from _t), 'Jus');
select public.save_store_category((select c2 from _t), 'Pâtisseries');
select public.archive_store_category((select c2 from _t), true);
select public.save_product(pg_temp._product((select p1 from _t), 'Jus de gingembre', jsonb_build_object(
  'variants', jsonb_build_array(jsonb_build_object('id', (select v1 from _t), 'stock_quantity', 4)),
  'store_category_ids', jsonb_build_array((select c1 from _t), (select c2 from _t)))));
select public.publish_product((select p1 from _t));
select public.save_product(pg_temp._product((select p2 from _t), 'Sirop de bissap'));
select public.save_product(pg_temp._product((select p3 from _t), 'Jus de baobab'));
select public.publish_product((select p3 from _t));
select public.archive_product((select p3 from _t), true);
select public.save_product(pg_temp._product((select p4 from _t), 'Jus de bissap 50 cl',
  jsonb_build_object('suggestion_id', (select suggestion from _t))));
select public.publish_product((select p4 from _t));

select tests.logout();
select is((select (props ->> 'fields_changed')::int from public.events
           where name = 'ai_product_suggestion_accepted' and entity_id = (select p4 from _t)::text),
  1, 'proposition acceptée avec une correction (le nom)');
select is((select (props ->> 'from_suggestion')::boolean from public.events
           where name = 'product_published' and entity_id = (select p4 from _t)::text),
  true, 'publication issue d''une proposition');

-- Visiteur anonyme.
select tests.login_anonymous();
select is(array(select name from public.products where store_id = (select store from _t) order by name),
  array['Jus de bissap 50 cl', 'Jus de gingembre'], 'seuls les produits publiés sont visibles');
select is((select count(*)::int from public.product_variants where product_id = (select p1 from _t)), 1,
  'variantes visibles');
select is((select count(*)::int from public.product_photos where product_id = (select p1 from _t)), 1,
  'photos visibles');
select is((select count(*)::int from public.product_variants where product_id = (select p2 from _t)), 0,
  'variantes d''un brouillon invisibles');
select is(array(select name from public.store_categories where store_id = (select store from _t)),
  array['Jus'], 'catégorie archivée invisible');
select throws_ok('select suggestion_id from public.products', '42501', null,
  'proposition d''origine non lisible');
select throws_ok('select * from app.ai_product_suggestions', '42501', null, 'propositions inaccessibles');

-- Autre vendeuse.
select tests.login_as((select kodjo from _t));
select is(public.my_products(), '[]'::jsonb, 'Kodjo ne voit pas le catalogue d''Esi');
select throws_ok(format($$select public.save_product(pg_temp._product('%s', 'Volé'))$$, (select p1 from _t)),
  '42501', null, 'modifier le produit d''autrui refusé');
select throws_ok(format($$select public.set_product_available('%s', false)$$, (select p1 from _t)),
  '42501', null, 'rupture du produit d''autrui refusée');
select throws_ok(format($$select public.set_variant_stock('%s', 0)$$, (select v1 from _t)),
  '42501', null, 'stock d''autrui refusé');
select throws_ok(format($$select public.publish_product('%s')$$, (select p2 from _t)),
  '42501', null, 'publier le brouillon d''autrui refusé');
select throws_ok(format($$select public.save_store_category('%s', 'Jus')$$, (select c1 from _t)),
  '42501', null, 'renommer la catégorie d''autrui refusé');
select throws_ok(format($$select public.archive_store_category('%s', true)$$, (select c1 from _t)),
  '42501', null, 'archiver la catégorie d''autrui refusé');
select throws_ok(format($$select public.save_product(jsonb_build_object('id', gen_random_uuid(), 'name', 'Jus',
  'store_category_ids', jsonb_build_array('%s')))$$, (select c1 from _t)),
  '42501', null, 'catégorie d''autrui refusée');
select throws_ok($$update public.products set status = 'published'$$, '42501', null,
  'écriture directe refusée');
select throws_ok(format($$select app.photo_upload_store('%s')$$, (select kodjo from _t)), '42501', null,
  'fonctions des Functions inaccessibles depuis la Data API');

-- Brouillon supprimé ; boutique suspendue figée et masquée.
select tests.login_as((select esi from _t));
select lives_ok(format($$select public.delete_product_draft('%s')$$, (select p2 from _t)), 'brouillon supprimé');
select is(jsonb_array_length(public.my_products()), 3, 'trois produits restent');
select tests.logout();
update public.stores set status = 'suspended', is_open = false where id = (select store from _t);
select tests.login_as((select esi from _t));
select throws_ok(format($$select public.set_product_available('%s', false)$$, (select p1 from _t)),
  '42501', null, 'boutique suspendue : catalogue figé');
select tests.login_anonymous();
select is((select count(*)::int from public.products where store_id = (select store from _t)), 0,
  'boutique suspendue : produits masqués');

select * from finish();
