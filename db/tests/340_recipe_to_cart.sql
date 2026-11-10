-- Tout pour la faire (spec 038).

select plan(9);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '34000000-0000-4000-8000-000000000001'::uuid as tomate,
       '34000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '34000000-0000-4000-8000-000000000003'::uuid as marmite,
       '34000000-0000-4000-8000-000000000004'::uuid as marmite_v,
       '34100000-0000-4000-8000-000000000001'::uuid as post,
       null::uuid as kodjo_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

-- Rayon ustensiles ouvert, rayons hors grocery retirés.
select ok((select is_active from public.categories where slug = 'ustensiles'), 'rayon ustensiles');
select ok(not (select is_active from public.categories where slug = 'pagnes-textile'), 'rayon pagnes retiré');

create function pg_temp._publish(p_id uuid, p_variant uuid, p_name text, p_category uuid, p_price bigint)
returns void language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', p_category, 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', 10))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, text, uuid, bigint) to authenticated;

select tests.login_as((select kodjo from _t));
select pg_temp._publish((select tomate from _t), (select tomate_tas from _t), 'Tomates', (select tomates from _t), 500);
select pg_temp._publish((select marmite from _t), (select marmite_v from _t), 'Marmite en fonte',
  (select id from public.categories where slug = 'ustensiles'), 8000);

select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.become_creator('Awa cuisine');
select public.save_creator_content(jsonb_build_object('id', (select post from _t), 'kind', 'post',
  'media_key', 'creators/' || (select awa from _t) || '/contents/' || (select post from _t) || '.jpg',
  'caption', 'Sauce tomate', 'product_ids', jsonb_build_array((select marmite from _t))));

-- Ingrédients : fixés par l'autrice seulement, nettoyés.
select is(public.set_content_ingredients((select post from _t), '[{"label": " Tomates ", "query": "tomate", "quantity": 3},
  {"label": "Licorne"}]') -> 0 ->> 'label', 'Tomates', 'ingrédients enregistrés');
select tests.login_as((select ama from _t));
select throws_ok(format($$select public.set_content_ingredients('%s', '[{"label": "Sel"}]')$$, (select post from _t)),
  'P0002', null, 'ingrédients d''autrui refusés');

-- « Tout pour la faire » : produit tagué + ingrédient chez la vendeuse du quartier, manquant nommé.
create temporary table _b as select public.recipe_basket((select post from _t)) as b;
select is((select (b ->> 'item_count')::int from _b), 2, 'marmite taguée et tomates');
select is((select b -> 'missing' from _b), '["Licorne"]'::jsonb, 'ingrédient introuvable nommé');
select is((select (b ->> 'total_minor')::bigint from _b), 9500::bigint, 'chiffré par la base (8 000 + 3 × 500)');
select ok((select b::text like '%"reason": "tagged"%' from _b), 'produit tagué reconnu');
select tests.logout();
select is((public.recipe_basket((select post from _t), (select be from _t)) ->> 'item_count')::int, 2,
  'quartier donné explicitement');

select * from finish();
