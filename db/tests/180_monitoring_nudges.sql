-- Spec 021 : suivi de l'IA et des paiements, relance des clientes, stock bas.

select plan(19);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('mariam@example.com') as mariam,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('afi@example.com') as afi,
       tests.create_user('ops@example.com') as admin,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '51000000-0000-4000-8000-000000000001'::uuid as tomate,
       '51000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '52000000-0000-4000-8000-000000000001'::uuid as afi_product,
       null::uuid as kodjo_store, null::uuid as afi_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be'),
              afi_store = tests.open_store(afi, 'Chez Afi', 'be');
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 10))));
select public.publish_product((select tomate from _t));
select tests.login_as((select afi from _t));
select public.save_product(jsonb_build_object(
  'id', (select afi_product from _t), 'name', 'Jus', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select afi_store from _t) || '/products/' || (select afi_product from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', gen_random_uuid()))));
select public.publish_product((select afi_product from _t));

-- Deux commandes d'Awa, une de Mariam.
create function pg_temp.order_for(p_user uuid, p_name text) returns void language plpgsql as $$
declare v_home uuid := gen_random_uuid();
begin
  perform tests.login_as(p_user);
  if not exists (select 1 from public.profiles where user_id = p_user) then
    perform public.complete_profile(p_name, (select be from _t), 'client');
  end if;
  perform public.save_address(jsonb_build_object('id', v_home, 'kind', 'other', 'zone_id', (select be from _t),
    'landmark', 'Repère', 'phone', '+000 00 00 00'));
  perform public.cart_add((select tomate_tas from _t), 1);
  perform tests.logout();
  perform app.place_order(p_user, gen_random_uuid(), jsonb_build_object('address_id', v_home,
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash')),
    '2026-10-05 10:00:00+00'::timestamptz);
end $$;
select pg_temp.order_for((select awa from _t), 'Awa');
select pg_temp.order_for((select awa from _t), 'Awa');
select pg_temp.order_for((select mariam from _t), 'Mariam');

-- Audience par segment.
select tests.login_as((select kodjo from _t));
select is((public.broadcast_audience() ->> 'regular')::int, 1, 'régulières : 2 commandes ou plus');
select is((public.broadcast_audience() ->> 'month')::int, 2, 'du mois');
select is((public.broadcast_audience() ->> 'all')::int, 2, 'toutes');
select tests.logout();

-- Relance : flag, message, produit, une par jour, préférences.
select throws_ok($$select app.send_broadcast((select kodjo from _t), 'all', 'Gombo frais !')$$,
  'P0001', 'feature_disabled', 'flag coupé : refusé');
delete from public.feature_flags where key = 'vendor_broadcast' and country_code is not null;
update public.feature_flags set is_enabled = true where key = 'vendor_broadcast' and country_code is null;
select throws_ok($$select app.send_broadcast((select kodjo from _t), 'all', ' ')$$,
  'P0001', 'broadcast_invalid', 'message vide refusé');
select throws_ok($$select app.send_broadcast((select kodjo from _t), 'all', 'Jus !', (select afi_product from _t))$$,
  '22023', null, 'produit d''une autre boutique refusé');
insert into public.notification_preferences (user_id, category, push_enabled)
select mariam, 'promotions', false from _t;
select is((app.send_broadcast((select kodjo from _t), 'all', 'Gombo frais arrivé ce matin !',
  (select tomate from _t)) ->> 'recipients')::int, 1, 'cliente qui a coupé les promotions exclue');
select is((select params ->> 'message' from public.notifications
           where user_id = (select awa from _t) and kind = 'store_broadcast'),
  'Gombo frais arrivé ce matin !', 'notification de la cliente');
select is(app.notification_app('store_broadcast'), 'client', 'reçue dans l''app cliente');
select throws_ok($$select app.send_broadcast((select kodjo from _t), 'regular', 'Encore !')$$,
  'P0001', 'broadcast_daily_limit', 'une relance par jour');
select lives_ok($$select app.send_broadcast((select kodjo from _t), 'regular', 'Demain',
  null, now() + interval '25 hours')$$, 'le lendemain : autorisée');

-- Stock bas : une alerte au passage sous le seuil.
select tests.login_as((select kodjo from _t));
select throws_ok($$select public.set_low_stock_threshold(0)$$, '22023', null, 'seuil invalide');
select public.set_low_stock_threshold(5);
select tests.logout();
update public.product_variants set stock_quantity = 4 where id = (select tomate_tas from _t);
update public.product_variants set stock_quantity = 3 where id = (select tomate_tas from _t);
select is((select count(*)::int from public.notifications where user_id = (select kodjo from _t) and kind = 'low_stock'),
  1, 'une seule alerte sous le seuil');
select is(app.notification_app('low_stock'), 'vendor', 'reçue dans l''app vendeuse');

-- Suivi de l'IA (77).
-- Base partagée (staging) : la transaction annulée repart d'un journal vide.
delete from public.ai_requests;
insert into public.ai_requests (usage, user_id, outcome, latency_ms)
select 'search_from_photo', awa, 'success', 1000 from _t
union all select 'search_transcription', awa, 'success', 2000 from _t
union all select 'search_transcription', awa, 'success', 3000 from _t;
select app.copilot_proposed((select awa from _t), '{"item_count": 0}'::jsonb, 2000, 'ablo');
select tests.login_as((select awa from _t));
select throws_ok($$select public.admin_ai_health()$$, '42501', null, 'réservé à l''équipe');
select tests.login_as((select admin from _t));
select is((public.admin_ai_health(now() + interval '1 minute') ->> 'understood_percent')::int, 75, 'requêtes comprises');
select is((public.admin_ai_health(now() + interval '1 minute') ->> 'fallback_percent')::int, 100, 'copilote sans proposition');
select is(public.admin_ai_health(now() + interval '1 minute') -> 'misses' -> 0 ->> 'query', 'ablo', 'requête non comprise, sans personne');
select is(jsonb_array_length(public.admin_ai_health(now() + interval '1 minute') -> 'series_7d'), 7, 'série sur 7 jours');

select * from finish();
