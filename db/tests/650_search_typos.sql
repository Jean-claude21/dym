-- Recherche tolérante aux fautes (spec 079).

select plan(5);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.categories where slug = 'tomates') as tomates,
       '65000000-0000-4000-8000-000000000001'::uuid as tomate,
       null::uuid as kodjo_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates fraîches', 'category_id', (select tomates from _t),
  'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', gen_random_uuid(), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));
select tests.logout();

select is(public.search_catalog('tomates') ->> 'fuzzy', 'false', 'mot exact : pas de tolérance');
select ok((public.search_catalog('tomattes') ->> 'total')::int >= 1, 'faute de frappe : trouvé quand même');
select is(public.search_catalog('tomattes') ->> 'fuzzy', 'true', 'résultat signalé comme approché');
select is((public.search_catalog('tomtes') -> 'products' -> 0 ->> 'name'), 'Tomates fraîches',
  'lettre oubliée');
select is((public.search_catalog('zzqxw') ->> 'total')::int, 0, 'rien de proche : aucun résultat');

select * from finish();
