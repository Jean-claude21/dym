-- Accueil de la vendeuse poussé (spec 098) : tendance, panier moyen, clientes nouvelles et
-- fidèles (prénom seulement), meilleurs produits, alertes de stock.

select plan(9);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('mia@example.com') as mia,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '80000000-0000-4000-8000-000000000001'::uuid as tomate,
       '80000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       null::uuid as store;
update _t set store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 12))));
select public.publish_product((select tomate from _t));

-- Awa commande deux fois (fidèle), Mia une fois ; la vendeuse accepte.
create function pg_temp.order_for(p_user uuid, p_qty int) returns uuid language plpgsql as $$
declare v_order uuid;
begin
  perform tests.login_as(p_user);
  perform public.cart_add((select tomate_tas from _t), p_qty);
  perform tests.logout();
  select (o ->> 'id')::uuid into v_order from jsonb_array_elements(
    app.place_order(p_user, gen_random_uuid(), jsonb_build_object(
      'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
      'modes', jsonb_build_object((select store from _t), 'pickup')),
      '2026-10-05 10:00:00+00'::timestamptz) -> 'purchase' -> 'orders') o limit 1;
  perform app.transition_order((select kodjo from _t), v_order, 'accepted', 'pending');
  return v_order;
end $$;
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.login_as((select mia from _t));
select public.complete_profile('Mia', (select be from _t), 'client');
select tests.logout();
update public.stores set offers_pickup = true where id = (select store from _t);
select pg_temp.order_for((select awa from _t), 2);
select pg_temp.order_for((select awa from _t), 3);
select pg_temp.order_for((select mia from _t), 4);

select tests.login_as((select kodjo from _t));
select is(jsonb_array_length(public.my_vendor_insights('week') -> 'days'), 7, 'semaine : 7 jours');
select is((public.my_vendor_insights('week') ->> 'order_count')::int, 3, 'trois commandes');
select is((public.my_vendor_insights('week') ->> 'customers')::int, 2, 'deux clientes');
select is((public.my_vendor_insights('week') -> 'top_products' -> 0 ->> 'quantity')::int, 9,
  'meilleur produit : 9 tas');
select is(public.my_vendor_insights('week') -> 'loyal_customers' -> 0 ->> 'first_name', 'Awa',
  'cliente fidèle : prénom seulement');
select ok(not (public.my_vendor_insights('week') -> 'loyal_customers' -> 0 ? 'phone'), 'jamais le téléphone');
select ok((public.my_vendor_insights('week') ->> 'average_basket_minor')::int > 0, 'panier moyen');
-- 12 - 9 = 3 tas : sous le seuil de 5.
select is((public.my_vendor_insights('week') -> 'low_stock' -> 0 ->> 'stock')::int, 3, 'alerte de stock');
select throws_ok($$select public.my_vendor_insights('année')$$, '22023', 'invalid_period', 'période inconnue');

select * from finish();
