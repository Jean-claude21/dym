-- Pilotage admin (spec 073) : période comparée, courbe, entonnoir, issues.

select plan(9);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('admin@example.com') as admin,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '62000000-0000-4000-8000-000000000001'::uuid as tomate,
       '62000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '62200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone)
values ((select address from _t), (select awa from _t), 'home', (select be from _t), 'Derrière la pharmacie', '+00 00 00 00 01');
select app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
  'address_id', (select address from _t),
  'payment_method_id', (select id from public.payment_methods where provider_code = 'cash'
                        and country_code = (select country_code from public.profiles where user_id = (select awa from _t))),
  'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')), (select morning from _t));

select tests.login_as((select awa from _t));
select throws_ok($$select public.admin_overview()$$, '42501', null, 'réservé à l''équipe');

select tests.login_as((select admin from _t));
create temporary table _o as select public.admin_overview('day', now() + interval '1 minute') as o;
grant select on _o to authenticated;
select is(((select o from _o) -> 'current' ->> 'orders')::int, 1, 'commande du jour comptée');
select is(((select o from _o) -> 'previous' ->> 'orders')::int, 0, 'hier au même moment : aucune');
select ok(jsonb_array_length((select o from _o) -> 'series') between 1 and 24, 'courbe par heure');
select is((select sum((p ->> 'orders')::int)::int from jsonb_array_elements((select o from _o) -> 'series') p), 1,
  'la courbe additionne les commandes du jour');
select is(((select o from _o) -> 'funnel' ->> 'ordered')::int, 1, 'entonnoir : une cliente a commandé');
select is(((select o from _o) -> 'outcomes' ->> 'in_progress')::int, 1, 'issue : en cours');
select is(jsonb_array_length(public.admin_overview('week', now()) -> 'series')
          between 1 and 7, true, 'semaine : un point par jour');
select throws_ok($$select public.admin_overview('30d')$$, '22023', null, 'période inconnue refusée');

select * from finish();
