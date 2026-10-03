-- Admin des opérations (spec 013) : accès réservé, commandes (bloquées,
-- recherche, statut forcé, annulation et remboursement, livreur), exécution
-- des remboursements, boutiques, réglages d'un pays, journal d'audit.

select plan(78);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('admin@example.com') as admin,
       tests.create_user('mallory@example.com') as mallory,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       'a0000000-0000-4000-8000-000000000001'::uuid as home,
       null::uuid as kodjo_store, null::uuid as sim, null::uuid as cash,
       null::uuid as o1, null::uuid as o2, null::uuid as o3, null::uuid as r1, null::uuid as r2,
       null::uuid as city, null::uuid as zone, null::uuid as category;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

-- Moyen simulé (paiement en ligne) accepté par la boutique.
insert into public.payment_methods (country_code, provider_code, label, sort, is_active)
values ('TG', 'simulator', '{"fr": "Mobile Money (simulé)"}', 9, true)
on conflict do nothing;
update public.payment_methods set is_active = true where provider_code = 'simulator' and country_code = 'TG';
update _t set sim = (select id from public.payment_methods where provider_code = 'simulator' and country_code = 'TG'),
              cash = (select id from public.payment_methods where provider_code = 'cash' and country_code = 'TG');
insert into public.store_payment_methods (store_id, payment_method_id)
select kodjo_store, sim from _t;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t)))));
select public.publish_product((select tomate from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.save_address(jsonb_build_object('id', (select home from _t), 'kind', 'home', 'zone_id', (select be from _t),
  'landmark', 'Portail bleu', 'phone', '+228 90 00 00 00'));
select tests.logout();

-- Commande d'Awa (cash, ou payée en ligne par le simulateur).
create function pg_temp._order(p_paid boolean) returns uuid language plpgsql as $$
declare
  v jsonb;
  v_payment uuid;
begin
  perform tests.login_as((select awa from _t));
  perform public.cart_add((select tomate_tas from _t), 2);
  perform tests.logout();
  v := app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select home from _t),
    'payment_method_id', case when p_paid then (select sim from _t) else (select cash from _t) end),
    (select morning from _t), '{simulator}');
  v_payment := (v -> 'purchase' -> 'payment' ->> 'id')::uuid;
  if p_paid then
    perform app.apply_payment_event('simulator', 'evt-' || v_payment, '{}'::jsonb, true, v_payment,
      'succeeded', (v -> 'purchase' ->> 'total_minor')::bigint, 'XOF');
  end if;
  return (v -> 'purchase' -> 'orders' -> 0 ->> 'id')::uuid;
end
$$;

update _t set o1 = pg_temp._order(false);
select app.transition_order((select kodjo from _t), (select o1 from _t), 'accepted', 'pending');
select app.transition_order((select kodjo from _t), (select o1 from _t), 'preparing', 'accepted');
-- En préparation depuis 2 h : bloquée.
update public.orders set created_at = now() - interval '3 hours', accepted_at = now() - interval '170 minutes',
  preparing_at = now() - interval '2 hours'
where id = (select o1 from _t);

-- ------------------------------------------------------------------ accès

select tests.login_as((select mallory from _t));
select throws_ok('select public.admin_orders()', '42501', null, 'sans rôle : pas de liste des commandes');
select throws_ok('select public.admin_countries()', '42501', null, 'sans rôle : pas de réglages');
select throws_ok('select public.admin_audit()', '42501', null, 'sans rôle : pas de journal');
select throws_ok($$select public.admin_set_country_active('TG', false)$$, '42501', null,
  'sans rôle : pas d''activation');
select tests.logout();
select throws_ok($$select app.admin_force_status((select mallory from _t), (select o1 from _t), 'ready',
  'preparing', 'Essai')$$, '42501', null, 'sans rôle : pas de statut forcé');

-- ------------------------------------------------------------------ commandes

select tests.login_as((select admin from _t));
select ok(public.admin_orders('stuck') -> 'orders' @> jsonb_build_array(jsonb_build_object(
  'id', (select o1 from _t), 'stuck', true)), 'commande bloquée listée');
select ok((public.admin_orders() ->> 'stuck_count')::int >= 1, 'compteur des bloquées');
select is(jsonb_array_length(public.admin_orders('all', 'kodjo') -> 'orders'), 1, 'recherche par boutique');
select is(public.admin_orders('all', (select upper(left(o1::text, 8)) from _t)) -> 'orders' -> 0 ->> 'id',
  (select o1 from _t)::text, 'recherche par référence');
select is(jsonb_array_length(public.admin_orders('all', 'zzz') -> 'orders'), 0, 'recherche sans résultat');
select throws_ok($$select public.admin_orders('bizarre')$$, '22023', null, 'filtre inconnu');
select is(jsonb_array_length(public.admin_order((select o1 from _t)) -> 'timeline'), 2, 'chronologie');
select is(public.admin_order((select o1 from _t)) -> 'customer' ->> 'phone', '+228 90 00 00 00',
  'téléphone de livraison');
select ok(public.admin_order((select o1 from _t)) -> 'forceable_statuses' ? 'ready'
  and not (public.admin_order((select o1 from _t)) -> 'forceable_statuses' ? 'preparing'), 'statuts forçables');
select tests.logout();

select throws_ok($$select app.admin_force_status((select admin from _t), (select o1 from _t), 'ready',
  'accepted', 'Vendeuse injoignable')$$, 'P0001', 'status_changed', 'statut vu périmé');
select throws_ok($$select app.admin_force_status((select admin from _t), (select o1 from _t), 'ready',
  'preparing', ' ')$$, 'P0001', 'reason_required', 'raison obligatoire');
select throws_ok($$select app.admin_force_status((select admin from _t), (select o1 from _t), 'refused',
  'preparing', 'Essai')$$, 'P0001', 'transition_not_allowed', 'refus : par l''annulation');
select is(app.admin_force_status((select admin from _t), (select o1 from _t), 'ready', 'preparing',
  'Vendeuse injoignable') ->> 'status', 'ready', 'statut forcé');
select is((select actor_role || ':' || note from public.order_status_events
           where order_id = (select o1 from _t) order by id desc limit 1),
  'admin:Vendeuse injoignable', 'chronologie : l''équipe et sa raison');
select ok(exists (select 1 from public.notifications where user_id = (select awa from _t) and kind = 'order_ready'),
  'la cliente est prévenue');
select ok(exists (select 1 from public.notifications where user_id = (select kodjo from _t)
                  and kind = 'order_status_forced'), 'la vendeuse est prévenue');
select is((select reason from public.audit_log where action = 'order_status_forced'
           and entity_id = (select o1 from _t)::text), 'Vendeuse injoignable', 'audit avec raison');
select is((select after ->> 'status' from public.audit_log where action = 'order_status_forced'
           and entity_id = (select o1 from _t)::text), 'ready', 'audit : après');
select ok(exists (select 1 from public.events where name = 'admin_action_performed'
                  and entity_id = (select o1 from _t)::text and props ->> 'action' = 'order_status_forced'),
  'admin_action_performed');
select is(app.admin_force_status((select admin from _t), (select o1 from _t), 'delivered', 'ready',
  'Livrée par téléphone') ->> 'status', 'delivered', 'livrée forcée');
select throws_ok($$select app.admin_force_status((select admin from _t), (select o1 from _t), 'ready',
  'delivered', 'Retour')$$, 'P0001', 'order_closed', 'une commande terminée ne se rouvre pas');
select throws_ok($$select app.admin_cancel_order((select admin from _t), (select o1 from _t), 'delivered',
  'Trop tard')$$, 'P0001', 'order_closed', 'livrée : pas d''annulation (litige)');

-- Commande payée en ligne : livreur puis annulation et remboursement.
update _t set o2 = pg_temp._order(true);
select app.transition_order((select kodjo from _t), (select o2 from _t), 'accepted', 'pending');
select is(app.admin_assign_courier((select admin from _t), (select o2 from _t), 'Yao', '+228 91 00 00 00')
  -> 'courier' ->> 'name', 'Yao', 'livreur assigné');
select is((select params ->> 'courier_phone' from public.notifications where user_id = (select kodjo from _t)
           and kind = 'delivery_assigned'), '+228 91 00 00 00', 'la vendeuse reçoit le livreur');
select throws_ok($$select app.admin_assign_courier((select admin from _t), (select o2 from _t), 'Yao', 'abc')$$,
  '23514', null, 'téléphone invalide');
select is(app.admin_cancel_order((select admin from _t), (select o2 from _t), 'accepted', 'Boutique fermée')
  ->> 'cancelled_by', 'admin', 'annulée par l''équipe');
update _t set r1 = (select id from public.refunds where order_id = (select o2 from _t));
select is((select method || ':' || status || ':' || amount_minor from public.refunds where id = (select r1 from _t)),
  'provider:pending:' || (select total_minor from public.orders where id = (select o2 from _t)),
  'remboursement du total à exécuter');
select ok((select refund_due from public.orders where id = (select o2 from _t)), 'remboursement dû');
select is((select params ->> 'refund' from public.notifications where user_id = (select awa from _t)
           and kind = 'order_cancelled'), 'true', 'la cliente est prévenue du remboursement');
select ok(exists (select 1 from public.notifications where user_id = (select kodjo from _t)
                  and kind = 'order_cancelled_vendor'), 'la vendeuse est prévenue de l''annulation');
select throws_ok($$select app.admin_assign_courier((select admin from _t), (select o2 from _t), 'Yao', '+228 91 00 00 00')$$,
  'P0001', 'courier_not_allowed', 'pas de livreur sur une commande annulée');

-- ------------------------------------------------------------------ remboursements

select tests.login_as((select admin from _t));
select ok(public.admin_refunds() @> jsonb_build_array(jsonb_build_object('id', (select r1 from _t),
  'reason', 'cancellation', 'provider_code', 'simulator')), 'remboursement à exécuter listé');
select tests.logout();
select throws_ok($$select app.refund_mark_cash((select admin from _t), (select r1 from _t))$$,
  'P0001', 'refund_not_cash', 'remboursement en ligne : pas en main propre');
select is(app.refund_claim((select admin from _t), (select r1 from _t)) ->> 'provider_code', 'simulator',
  'réservé pour le fournisseur');
select throws_ok($$select app.refund_claim((select admin from _t), (select r1 from _t))$$,
  'P0001', 'refund_not_pending', 'une seule exécution à la fois');
select is(app.refund_result((select admin from _t), (select r1 from _t), false, null, 'solde insuffisant')
  ->> 'status', 'failed', 'échec enregistré');
select lives_ok($$select app.refund_claim((select admin from _t), (select r1 from _t))$$, 'relance après échec');
select is(app.refund_result((select admin from _t), (select r1 from _t), true, 'ref-1', null) ->> 'status',
  'succeeded', 'remboursement effectué');
select ok(not (select refund_due from public.orders where id = (select o2 from _t)), 'plus rien de dû');
select ok(exists (select 1 from public.notifications where user_id = (select awa from _t)
                  and kind = 'refund_succeeded'), 'la cliente est prévenue');
select is((select count(*)::int from public.events where name = 'refund_completed'
           and entity_id = (select r1 from _t)::text), 2, 'refund_completed : échec puis réussite');
select throws_ok($$select app.refund_result((select admin from _t), (select r1 from _t), true, 'ref-2', null)$$,
  'P0001', 'refund_not_processing', 'pas de second résultat');
insert into public.refunds (order_id, amount_minor, currency_code, method)
select o1, 300, 'XOF', 'cash' from _t;
update _t set r2 = (select id from public.refunds where method = 'cash' and order_id = (select o1 from _t));
select is(app.refund_mark_cash((select admin from _t), (select r2 from _t)) ->> 'status', 'succeeded',
  'cash remis en main propre');

-- Paiement en attente.
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
select app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
  'address_id', (select home from _t), 'payment_method_id', (select sim from _t)), (select morning from _t), '{simulator}');
select tests.login_as((select admin from _t));
select is(jsonb_array_length(public.admin_pending_payments()), 1, 'paiement en attente listé');

-- ------------------------------------------------------------------ boutiques

select ok((public.admin_stores('active') -> 'counts' ->> 'active')::int >= 1
  and public.admin_stores('active', 'kodjo') -> 'stores' -> 0 ->> 'name' = 'Étal de Kodjo', 'liste et recherche');
select is((public.admin_store((select kodjo_store from _t)) ->> 'published_products')::int, 1, 'profil : produits');
select tests.logout();
select throws_ok($$select app.admin_set_store_status((select admin from _t), (select kodjo_store from _t),
  'suspended', '')$$, 'P0001', 'reason_required', 'suspension : raison obligatoire');
select is(app.admin_set_store_status((select admin from _t), (select kodjo_store from _t), 'suspended',
  'Produits non conformes') ->> 'status', 'suspended', 'boutique suspendue');
select is((select params ->> 'reason' from public.notifications where user_id = (select kodjo from _t)
           and kind = 'store_suspended'), 'Produits non conformes', 'la vendeuse connaît la raison');
select throws_ok($$select app.admin_set_store_status((select admin from _t), (select kodjo_store from _t),
  'suspended', 'Encore')$$, 'P0001', 'store_status_unchanged', 'déjà suspendue');
select tests.login_as((select kodjo from _t));
select throws_ok('select public.publish_store()', '42501', null, 'la vendeuse ne rouvre pas');
select tests.logout();
select is(app.admin_set_store_status((select admin from _t), (select kodjo_store from _t), 'active',
  'Corrigé') ->> 'is_open', 'false', 'réactivée, fermée');
select tests.login_as((select admin from _t));
select is(public.admin_update_store((select kodjo_store from _t), '{"name": "Étal Kodjo"}', 'Faute de frappe')
  -> 'audit' -> 0 -> 'after' ->> 'name', 'Étal Kodjo', 'correction auditée');
select throws_ok(format($$select public.admin_update_store('%s', '{"zone_id": "%s"}', 'Essai')$$,
  (select kodjo_store from _t), gen_random_uuid()), '22023', null, 'quartier inconnu refusé');

-- ------------------------------------------------------------------ réglages

select tests.logout();
insert into public.countries (code, name, currency_code, dial_code, default_locale, timezone)
values ('ZZ', '{"fr": "Pays test", "en": "Test country"}', 'XOF', '+999', 'fr', 'UTC');
insert into public.payment_providers (code, label, kind, is_active)
values ('testpay', '{"fr": "Test", "en": "Test"}', 'mobile_money', false);
select tests.login_as((select admin from _t));
select throws_ok($$select public.admin_set_country_active('ZZ', true)$$, 'P0001', 'country_not_ready',
  'pays incomplet : refus');
select is((select c -> 'missing' from jsonb_array_elements(public.admin_countries()) c where c ->> 'code' = 'ZZ'),
  '["zones", "payment_methods", "delivery_fees"]'::jsonb, 'ce qui manque');
select is(public.admin_save_city('{"country_code": "ZZ", "name": "Ville Á"}') -> 0 ->> 'name', 'Ville Á', 'ville créée');
select tests.logout();
select is((select slug from public.cities where country_code = 'ZZ'), 'ville-a', 'slug sans accent');
update _t set city = (select id from public.cities where country_code = 'ZZ');
select tests.login_as((select admin from _t));
select is(public.admin_save_zone(jsonb_build_object('city_id', (select city from _t), 'name', 'Quartier 1',
  'latitude', 1.5, 'longitude', 2.5)) -> 0 -> 'zones' -> 0 ->> 'name', 'Quartier 1', 'quartier créé');
select lives_ok($$select public.admin_save_payment_method('{"country_code": "ZZ", "provider_code": "cash",
  "label": {"fr": "Cash", "en": "Cash"}, "is_active": true}')$$, 'moyen de paiement créé');
select throws_ok($$select public.admin_save_payment_method('{"country_code": "ZZ", "provider_code": "testpay",
  "label": {"fr": "Test", "en": "Test"}, "is_active": true}')$$, 'P0001', 'provider_inactive',
  'fournisseur inactif : refus');
select lives_ok($$select public.admin_set_delivery_fee('ZZ', null, 500, 100, 5000)$$, 'frais par défaut');
select is(public.admin_set_country_active('ZZ', true) @> '[{"code": "ZZ", "is_active": true}]', true, 'pays activé');
select lives_ok($$select public.admin_set_commission('ZZ', null, 1000)$$, 'commission');
select is(jsonb_array_length(public.admin_set_commission('ZZ', null, 1200) -> 'commissions'), 1,
  'une seule règle ouverte');
select is((public.admin_pricing('ZZ') -> 'commissions' -> 0 ->> 'rate_bps')::int, 1200, 'nouveau taux');
select tests.logout();
select is((select count(*)::int from public.commission_rules where country_code = 'ZZ'), 2, 'ancienne règle close');
select tests.login_as((select admin from _t));
select is(jsonb_array_length(public.admin_set_delivery_fee('ZZ', null, 600, 100, 5000) -> 'delivery_fees'), 1,
  'un seul frais ouvert');
update _t set category = (select (c ->> 'id')::uuid from jsonb_array_elements(public.admin_save_category(
  '{"label": {"fr": "Épices fines", "en": "Fine spices"}}')) c where c ->> 'slug' = 'epices-fines');
select tests.logout();
select is((select is_active from public.categories where id = (select category from _t)), true, 'catégorie créée');
select tests.login_as((select admin from _t));
select is((select c ->> 'is_active' from jsonb_array_elements(public.admin_save_category(jsonb_build_object(
  'id', (select category from _t), 'is_active', false))) c where (c ->> 'id')::uuid = (select category from _t)),
  'false', 'catégorie désactivée');

-- ------------------------------------------------------------------ journal

select is((public.admin_audit(p_action => 'order_status_forced') ->> 'total')::int, 2, 'filtre par action');
select is(public.admin_audit('injoignable') -> 'entries' -> 0 ->> 'actor_first_name' is null
  and (public.admin_audit('injoignable') ->> 'total')::int = 1, true, 'recherche dans les raisons');
select ok(public.admin_audit() -> 'actions' ? 'country_activated', 'actions disponibles pour le filtre');

select * from finish();
