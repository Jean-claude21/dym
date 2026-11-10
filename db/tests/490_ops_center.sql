-- Centre d'opérations (spec 053).

select plan(15);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('awa@example.com') as awa,
       tests.create_user('chef@example.com') as chef,
       tests.create_user('agent@example.com') as agent,
       '49000000-0000-4000-8000-000000000001'::uuid as igname,
       '49000000-0000-4000-8000-000000000002'::uuid as igname_tas,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.membership_plans where country_code = 'TG' and code = 'dym_plus') as plus,
       null::uuid as kodjo_store, null::uuid as order1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
insert into public.user_roles (user_id, role) select chef, 'admin' from _t;
insert into public.user_roles (user_id, role) select agent, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

-- Une commande en attente depuis 30 minutes : en retard (seuil 10 min).
select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select public.save_product(jsonb_build_object(
  'id', (select igname from _t), 'name', 'Igname', 'category_id', (select id from public.categories where slug = 'tomates'),
  'price_minor', 1000,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select igname from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select igname_tas from _t), 'stock_quantity', 20))));
select public.publish_product((select igname from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select igname_tas from _t), 1);
select tests.logout();
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')),
    '2026-10-05 10:00:00+00'::timestamptz) -> 'purchase' -> 'orders') o limit 1);
update public.orders set created_at = now() - interval '30 minutes' where id = (select order1 from _t);

-- Accès : admins seulement, dans leur périmètre.
select tests.login_as((select kodjo from _t));
select throws_ok($$select public.ops_live('TG')$$, '42501', null, 'vendeuse : refusé');
select tests.login_as((select chef from _t));
select is((public.ops_live('TG') -> 'orders_by_status' ->> 'pending')::int, 1, 'commandes par statut');
select is(public.ops_live('TG') -> 'alerts' -> 0 ->> 'store_name', 'Étal de Kodjo', 'commande en retard signalée');
select ok((public.ops_live('TG') -> 'alerts' -> 0 ->> 'minutes')::int >= 30, 'minutes d''attente');

-- Seuil relevé : plus d'alerte.
select is((public.admin_set_ops_thresholds('TG', '{"pending": 60}') -> 'thresholds' ->> 'pending')::int, 60,
  'seuil modifié');
select is(jsonb_array_length(public.ops_live('TG') -> 'alerts'), 0, 'plus d''alerte sous le seuil');
select throws_ok($$select public.admin_set_ops_thresholds('TG', '{"pending": 900}')$$, '23514', null,
  'seuil hors bornes');

-- Réglages : poids du fil et formules.
select is((public.admin_set_feed_weights('TG', '{"weight_local": 7}') -> 'feed_weights' ->> 'weight_local')::int, 7,
  'poids du fil');
select is((public.admin_save_membership_plan(jsonb_build_object('country_code', 'TG',
  'id', (select plus from _t),
  'price_minor', 2000)) -> 'plans' -> 0 ->> 'price_minor')::bigint, 2000::bigint, 'prix de formule modifié');

-- Rôles par pays : l'agent limité au Ghana ne voit plus le Togo.
select is(jsonb_array_length(public.admin_set_scope('agent@example.com', 'GH', true) -> 'scopes'), 1, 'agent limité');
select tests.login_as((select agent from _t));
select is(public.ops_live('GH') ->> 'countries', '["GH"]', 'périmètre : Ghana seulement');
select is(public.ops_countries() ->> 0, 'GH', 'pays pilotables');
select throws_ok($$select public.ops_live('TG')$$, '42501', 'country_out_of_scope', 'Togo hors périmètre');
select throws_ok($$select public.admin_set_scope('chef@example.com', 'TG', true)$$, '42501', 'scoped_admin',
  'un admin limité ne gère pas les limites');
select tests.logout();
select is((select count(*)::int from public.audit_log where action in ('ops_thresholds_set', 'admin_scope_added',
  'membership_plan_saved', 'feed_ranking_set')), 4, 'réglages audités');

select * from finish();
