-- Favoris et paniers enregistrés (spec 030).

select plan(18);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '26000000-0000-4000-8000-000000000001'::uuid as tomate,
       '26000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '26000000-0000-4000-8000-000000000003'::uuid as piment,
       '26000000-0000-4000-8000-000000000004'::uuid as piment_tas,
       null::uuid as kodjo_store, null::uuid as basket;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._publish(p_id uuid, p_variant uuid, p_name text, p_price bigint) returns void
language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', (select tomates from _t), 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', 20))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, text, bigint) to authenticated;

select tests.login_as((select kodjo from _t));
select pg_temp._publish((select tomate from _t), (select tomate_tas from _t), 'Tomates', 500);
select pg_temp._publish((select piment from _t), (select piment_tas from _t), 'Piment', 200);

select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');

-- Favoris : ajout, état, retrait.
select is(public.toggle_favorite('store', (select kodjo_store from _t)), true, 'boutique ajoutée aux favoris');
select is(public.toggle_favorite('product', (select tomate from _t)), true, 'produit ajouté aux favoris');
select is(public.my_favorites() -> 'stores' -> 0 ->> 'id', (select kodjo_store from _t)::text, 'boutique favorite affichée');
select is(public.my_favorites() -> 'products' -> 0 ->> 'id', (select tomate from _t)::text, 'produit favori affiché');
select ok(public.my_favorite_ids() -> 'product_ids' ? (select tomate from _t)::text, 'état du cœur');
select is(public.toggle_favorite('product', (select tomate from _t)), false, 'second geste : retiré');
select throws_ok($$select public.toggle_favorite('rayon', gen_random_uuid())$$, '22023', 'invalid_kind', 'type inconnu refusé');

-- Panier enregistré : refus du panier vide, puis enregistrement.
select throws_ok($$select public.save_cart_as_basket('Petit-déjeuner')$$, '22023', 'cart_empty', 'panier vide refusé');
select public.cart_add((select tomate_tas from _t), 2);
select public.cart_add((select piment_tas from _t), 1);
update _t set basket = (public.save_cart_as_basket('  Petit-déjeuner ') ->> 'id')::uuid;
select is(public.my_baskets() -> 0 ->> 'name', 'Petit-déjeuner', 'panier enregistré, nom nettoyé');
select is((public.my_baskets() -> 0 ->> 'total_minor')::bigint, 1200::bigint, 'total du jour calculé par la base');

-- Autre personne : rien de visible ni de modifiable.
select tests.login_as((select ama from _t));
select is(jsonb_array_length(public.my_baskets()), 0, 'Ama ne voit pas les paniers d''Awa');
select is(jsonb_array_length(public.my_favorites() -> 'stores'), 0, 'Ama ne voit pas les favoris d''Awa');
select is((select count(*)::int from public.saved_baskets) + (select count(*)::int from public.favorite_stores), 0,
  'lecture directe filtrée (RLS)');
select throws_ok(format($$select public.basket_to_cart('%s')$$, (select basket from _t)), 'P0002', null,
  'remise au panier d''autrui refusée');
select throws_ok($$insert into public.favorite_stores (user_id, store_id)
  values (app.current_user_id(), (select kodjo_store from _t))$$, '42501', null, 'écriture directe refusée');

-- Remise au panier : prix du jour, article en rupture nommé.
select tests.logout();
delete from public.cart_items;
update public.product_variants set stock_quantity = 0 where id = (select piment_tas from _t);
select tests.login_as((select awa from _t));
create temporary table _r as select public.basket_to_cart((select basket from _t)) as r;
select is((select (r ->> 'added')::int from _r), 1, 'article disponible remis au panier');
select is((select r -> 'skipped' from _r), '["Piment"]'::jsonb, 'article en rupture nommé');
select is((public.my_baskets() -> 0 ->> 'available_count')::int, 1, 'disponibilité du jour');

select * from finish();
