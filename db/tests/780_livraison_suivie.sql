-- Livraison suivie (spec 096) : frais par distance, suivi et lien partagé, code de récupération,
-- injoignable et SOS, livreurs de la boutique, validation des comptes.

select plan(31);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('kofi@example.com') as kofi,
       tests.create_user('yao@example.com') as yao,
       tests.create_user('admin@example.com') as admin,
       tests.create_user('mia@example.com') as mia,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.zones where slug = 'tokoin') as tokoin,
       (select id from public.categories where slug = 'tomates') as tomates,
       '78000000-0000-4000-8000-000000000001'::uuid as tomate,
       '78000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '78200000-0000-4000-8000-000000000001'::uuid as address,
       null::uuid as kodjo_store, null::uuid as order1, null::text as token, null::text as code;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
insert into public.user_roles (user_id, role) values ((select admin from _t), 'admin');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));

-- Frais par tranches : l'admin les règle, le panier les applique selon la distance de la porte.
select tests.login_as((select kodjo from _t));
select throws_ok($$select public.admin_set_delivery_fee_bands('TG', null, '[]')$$, '42501', null,
  'tranches : réservé à l''admin');
select tests.login_as((select admin from _t));
select is(jsonb_array_length(public.admin_set_delivery_fee_bands('TG', null,
  '[{"max_distance_m": 2000, "fee_minor": 300}, {"max_distance_m": 6000, "fee_minor": 700}]')), 2,
  'deux tranches enregistrées');
select tests.logout();
select ok(exists (select 1 from public.audit_log where action = 'delivery_fee_bands_set'), 'tranches auditées');

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select tokoin from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();
update public.stores set delivery_fee_minor = null where id = (select kodjo_store from _t);
-- Porte à ~1 km de la boutique (dans son rayon de 5 km).
insert into public.customer_addresses (id, user_id, kind, zone_id, landmark, phone, latitude, longitude)
select (select address from _t), (select awa from _t), 'home', (select be from _t), 'Derrière la pharmacie',
       '+228 91 00 00 01', sp.lat + 0.009, sp.lng
from app.store_point((select kodjo_store from _t)) sp;
select tests.login_as((select awa from _t));
select is((public.my_cart((select address from _t)) -> 'stores' -> 0 ->> 'delivery_fee_minor')::int, 300,
  'porte à 1 km : tranche de 2 km');
select ok((public.my_cart((select address from _t)) -> 'stores' -> 0 ->> 'distance_m')::int between 900 and 1100,
  'distance de la boutique à la porte donnée');
select tests.logout();
update public.customer_addresses set latitude = latitude + 0.027 where id = (select address from _t);
select tests.login_as((select awa from _t));
select is((public.my_cart((select address from _t)) -> 'stores' -> 0 ->> 'delivery_fee_minor')::int, 700,
  'porte à 4 km : tranche de 6 km');
select tests.logout();
update public.customer_addresses set latitude = latitude - 0.027 where id = (select address from _t);

-- Commande, livreur de la boutique.
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select address from _t),
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'delivery')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
select is((select delivery_fee_minor from public.orders where id = (select order1 from _t))::int, 300,
  'commande : frais par distance');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');

select tests.login_as((select kofi from _t));
select public.complete_profile('Kofi', (select be from _t), 'delivery');
select public.become_courier('Kofi Mensah', '+228 90 11 22 33', 'moto', array[(select be from _t)]);

select tests.login_as((select kodjo from _t));
select throws_ok($$select public.store_add_courier('+228 99 99 99 99')$$, 'P0002', 'courier_not_found',
  'numéro inconnu');
select is(jsonb_array_length(public.store_add_courier('90 11 22 33')), 1, 'livreur ajouté par son numéro');
select is((public.store_assign_courier((select order1 from _t), (select kofi from _t)) ->> 'ok')::boolean, true,
  'commande confiée à son livreur');
select throws_ok(format($$select public.store_assign_courier('%s', '%s')$$, (select order1 from _t), (select kofi from _t)),
  'P0001', 'courier_already_assigned', 'déjà confiée');
select tests.login_as((select kofi from _t));
select is(jsonb_array_length(public.my_missions()), 1, 'la course apparaît chez le livreur');

-- Position et suivi.
select public.courier_ping(6.140, 1.230);
select tests.login_as((select awa from _t));
select ok(public.order_tracking((select order1 from _t)) -> 'courier' ->> 'latitude' is not null,
  'la cliente voit son livreur');
select ok((public.order_tracking((select order1 from _t)) ->> 'eta_minutes')::int > 0, 'minutes restantes');
select is(public.order_tracking((select order1 from _t)) -> 'courier' ->> 'name', 'Kofi', 'prénom seul');
select tests.login_as((select mia from _t));
select throws_ok(format($$select public.order_tracking('%s')$$, (select order1 from _t)), 'P0002', 'not_found',
  'une autre personne ne suit pas la commande');

-- Lien partagé : lecture sans compte, porte arrondie, aucun nom de la cliente.
select tests.login_as((select awa from _t));
update _t set token = public.share_tracking((select order1 from _t)) ->> 'token';
select is(public.share_tracking((select order1 from _t)) ->> 'token', (select token from _t), 'même lien repris');
select tests.login_anonymous();
select is(public.tracking_by_token((select token from _t)) ->> 'status', 'accepted', 'lien lu sans compte');
select ok(length(public.tracking_by_token((select token from _t)) -> 'destination' ->> 'latitude') <= 7,
  'porte arrondie dans le lien');
select is(public.tracking_by_token('inconnu-inconnu-inconnu'), null, 'jeton inconnu : rien');

-- Code de récupération : le livreur le montre, la vendeuse le scanne.
select tests.logout();
select app.transition_order((select kodjo from _t), (select order1 from _t), 'ready', 'accepted');
select tests.login_as((select kofi from _t));
select throws_ok(format($$select public.courier_transition('%s', 'out_for_delivery', 'ready')$$, (select order1 from _t)),
  'P0001', 'pickup_code_required', 'récupération sans scan refusée');
update _t set code = public.my_pickup_code((select order1 from _t));
select tests.login_as((select kodjo from _t));
select is((public.store_confirm_pickup((select order1 from _t), '000000') ->> 'ok')::boolean
          or (select code from _t) = '000000', (select code from _t) = '000000', 'mauvais code refusé');
select is(public.store_confirm_pickup((select order1 from _t), (select code from _t)) ->> 'status',
  'out_for_delivery', 'scan : la commande part avec le livreur');

-- Injoignable et SOS.
select tests.login_as((select kofi from _t));
select is((public.courier_report_unreachable((select order1 from _t)) ->> 'wait_minutes')::int, 10,
  'injoignable signalé');
select tests.logout();
select is((select count(*)::int from public.notifications where kind = 'courier_at_door'
           and user_id = (select awa from _t)), 1, 'la cliente est prévenue');
select tests.login_as((select kofi from _t));
select ok(public.courier_sos((select order1 from _t), 6.14, 1.23, 'Agression') ->> 'id' is not null, 'SOS envoyé');
select tests.login_as((select admin from _t));
select is(public.admin_delivery_incidents() -> 0 ->> 'kind', 'sos', 'SOS en tête pour l''équipe');

-- Validation des comptes : livreur en attente, mise en ligne refusée, puis validé.
select tests.logout();
update public.feature_flags set is_enabled = true where key = 'account_review' and country_code is null;
select tests.login_as((select yao from _t));
select public.complete_profile('Yao', (select be from _t), 'delivery');
select is(public.become_courier('Yao', '+228 92 00 00 00', 'bike', array[(select be from _t)]) ->> 'status',
  'pending', 'compte livreur en attente');
select throws_ok($$select public.set_courier_online(true)$$, '42501', 'courier_pending', 'pas de mise en ligne');
select tests.login_as((select admin from _t));
select throws_ok(format($$select public.admin_review_account('courier', '%s', false)$$, (select yao from _t)),
  'P0001', 'reason_required', 'refus sans motif impossible');
select public.admin_review_account('courier', (select yao from _t), true);
select tests.login_as((select yao from _t));
select is(public.set_courier_online(true) ->> 'is_online', 'true', 'validé : en ligne');

select * from finish();
