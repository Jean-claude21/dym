-- « Tout pour la recette » pour N personnes (spec 057).

select plan(6);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '53000000-0000-4000-8000-000000000001'::uuid as tomate,
       '53000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '53000000-0000-4000-8000-000000000003'::uuid as marmite,
       '53000000-0000-4000-8000-000000000004'::uuid as marmite_v,
       '53100000-0000-4000-8000-000000000001'::uuid as post,
       null::uuid as kodjo_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._publish(p_id uuid, p_variant uuid, p_name text, p_category uuid, p_price bigint)
returns void language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', p_category, 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', 50))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, text, uuid, bigint) to authenticated;

select tests.login_as((select kodjo from _t));
select pg_temp._publish((select tomate from _t), (select tomate_tas from _t), 'Tomates', (select tomates from _t), 500);
select pg_temp._publish((select marmite from _t), (select marmite_v from _t), 'Marmite en fonte',
  (select id from public.categories where slug = 'ustensiles'), 8000);

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.become_creator('Awa cuisine');
select public.save_creator_content(jsonb_build_object('id', (select post from _t), 'kind', 'post',
  'media_key', 'creators/' || (select awa from _t) || '/contents/' || (select post from _t) || '.jpg',
  'caption', 'Sauce tomate', 'product_ids', jsonb_build_array((select marmite from _t))));
-- Recette pour 4 (référence) : 3 tas de tomates.
select public.set_content_ingredients((select post from _t), '[{"label": "Tomates", "query": "tomate", "quantity": 3}]');

select tests.logout();
select is((select servings from public.contents where id = (select post from _t)), 4::smallint,
  'portions de référence : 4');
select tests.login_as((select awa from _t));

-- Sans portions : quantités de la recette ; total = 8 000 + 3 × 500.
select is((public.recipe_basket((select post from _t)) ->> 'total_minor')::bigint, 9500::bigint,
  'pour 4 : quantités de la recette');

-- Pour 8 : tomates doublées (6 tas), marmite toujours 1 ; total = 8 000 + 6 × 500.
create temporary table _b as select public.recipe_basket((select post from _t), null, 8) as b;
select is((select (b ->> 'total_minor')::bigint from _b), 11000::bigint, 'pour 8 : ingrédients doublés, ustensile à 1');
select is((select (b ->> 'servings')::int from _b), 8, 'portions demandées rappelées');

-- Pour 1 : arrondi au-dessus (3 × 1/4 → 1 tas).
select is((public.recipe_basket((select post from _t), null, 1) ->> 'total_minor')::bigint, 8500::bigint,
  'pour 1 : au moins un tas');

select throws_ok(format($$select public.recipe_basket('%s', null, 0)$$, (select post from _t)),
  '22023', 'invalid_servings', 'portions invalides refusées');

select * from finish();
