-- Boutique partageable, prix de fin de marché (spec 048).

select plan(11);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('awa@example.com') as awa,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       '44000000-0000-4000-8000-000000000001'::uuid as tomate,
       '44000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '44000000-0000-4000-8000-000000000003'::uuid as gombo,
       '44000000-0000-4000-8000-000000000004'::uuid as gombo_tas,
       null::uuid as kodjo_store, null::uuid as order1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._publish(p_id uuid, p_variant uuid, p_name text, p_price bigint) returns void
language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', (select id from public.categories where slug = 'tomates'),
    'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', 20))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, text, bigint) to authenticated;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select pg_temp._publish((select tomate from _t), (select tomate_tas from _t), 'Tomates', 500);
select pg_temp._publish((select gombo from _t), (select gombo_tas from _t), 'Gombo', 300);
select throws_ok($$select public.set_end_of_market(90)$$, '22023', 'invalid_percent', 'pourcentage hors bornes');
select throws_ok($$select public.set_end_of_market(20, 24)$$, '22023', 'invalid_hours', 'durée hors bornes');
select is((public.set_end_of_market(20, 3, array[(select tomate from _t)]) ->> 'products')::int, 1,
  'fin de marché sur un produit');
select tests.logout();

-- Prix réduit partout : catalogue, fiche, commande ; l'autre produit ne bouge pas.
select is((app.catalog_item((select tomate from _t)) ->> 'price_minor')::bigint, 400::bigint, 'catalogue : 400');
select is((app.catalog_item((select tomate from _t)) -> 'end_of_market' ->> 'original_price_minor')::bigint, 500::bigint,
  'prix d''origine affiché');
select is((app.catalog_item((select gombo from _t)) ->> 'price_minor')::bigint, 300::bigint, 'autre produit inchangé');
select is((public.product_page((select tomate from _t), (select be from _t)) -> 'variants' -> 0 ->> 'price_minor')::bigint,
  400::bigint, 'fiche : 400');

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
select is((select subtotal_minor from public.orders where id = (select order1 from _t)), 800::bigint,
  'commande au prix de fin de marché');

-- Fin anticipée : prix normal.
select tests.login_as((select kodjo from _t));
select is(public.clear_end_of_market() ->> 'active', 'false', 'fin de marché arrêtée');
select tests.logout();
select is((app.catalog_item((select tomate from _t)) ->> 'price_minor')::bigint, 500::bigint, 'prix normal revenu');

-- Partage : aperçu public de la boutique.
select is(app.store_share_preview((select kodjo_store from _t)) ->> 'name', 'Étal de Kodjo', 'aperçu de partage');

select * from finish();
