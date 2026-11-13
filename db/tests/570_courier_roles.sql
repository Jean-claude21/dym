-- Rôles de la livraison (spec 068) : livreur visible, la vendeuse ne remet
-- pas une commande confiée à un livreur DYM.

select plan(7);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('kofi@example.com') as kofi,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '57000000-0000-4000-8000-000000000001'::uuid as tomate,
       '57000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '57200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as order1, null::uuid as order2;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));

select tests.login_as((select kofi from _t));
select public.complete_profile('Kofi', (select be from _t), 'delivery');
select public.become_courier('Kofi', '+228 90 11 22 33', 'moto', array[(select be from _t)]);
select public.set_courier_online(true);

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.logout();
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone)
values ((select address from _t), (select awa from _t), 'home', (select be from _t), 'Derrière la pharmacie', '+228 91 00 00 01');

create function pg_temp._order() returns uuid language plpgsql as $$
begin
  perform tests.login_as((select awa from _t));
  perform public.cart_add((select tomate_tas from _t), 1);
  perform tests.logout();
  return (select (o ->> 'id')::uuid from jsonb_array_elements(
    app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
      'address_id', (select address from _t),
      'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
      'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
      (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
end
$$;

-- Commande confiée à Kofi, livreur DYM.
update _t set order1 = pg_temp._order();
select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');
select tests.login_as((select kofi from _t));
select public.accept_mission((select order1 from _t));
select tests.logout();
select app.transition_order((select kodjo from _t), (select order1 from _t), 'ready', 'accepted');

select is(app.order_json((select order1 from _t), 'vendor') -> 'courier' ->> 'name', 'Kofi',
  'la vendeuse voit le livreur');
select is(app.order_json((select order1 from _t), 'vendor') -> 'courier' ->> 'is_dym', 'true',
  'livreur DYM');
select is(app.order_json((select order1 from _t), 'client') -> 'courier' ->> 'phone', '+228 90 11 22 33',
  'la cliente peut appeler le livreur');
select ok(not (app.order_json((select order1 from _t), 'vendor') -> 'next_statuses') ? 'out_for_delivery',
  'pas de « Partir livrer » pour la vendeuse');
select throws_ok(
  format($$select app.transition_order(%L, %L, 'out_for_delivery', 'ready')$$, (select kodjo from _t), (select order1 from _t)),
  'P0001', 'courier_assigned', 'la vendeuse ne peut pas faire partir la commande');

-- Sans livreur DYM (livraison par la boutique) : rien ne change.
update _t set order2 = pg_temp._order();
select app.transition_order((select kodjo from _t), (select order2 from _t), 'accepted', 'pending');
select app.transition_order((select kodjo from _t), (select order2 from _t), 'ready', 'accepted');
select ok((app.order_json((select order2 from _t), 'vendor') -> 'next_statuses') ? 'out_for_delivery',
  'sans livreur DYM : « Partir livrer » reste proposé');
select lives_ok(
  format($$select app.transition_order(%L, %L, 'out_for_delivery', 'ready')$$, (select kodjo from _t), (select order2 from _t)),
  'la vendeuse livre elle-même');

select * from finish();
