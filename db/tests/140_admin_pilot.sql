-- Spec 017 : tableau de bord, flags, support, clientes, vendeuses, revenus.

select plan(31);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('afi@example.com') as afi,
       tests.create_user('ops@example.com') as admin,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       'a0000000-0000-4000-8000-000000000001'::uuid as home,
       null::uuid as kodjo_store, null::uuid as afi_store, null::uuid as o1, null::uuid as t1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be'),
              afi_store = tests.open_store(afi, 'Chez Afi', 'be');
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

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
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();
update _t set o1 = (app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
  'address_id', (select home from _t),
  'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash')),
  (select morning from _t)) -> 'purchase' -> 'orders' -> 0 ->> 'id')::uuid;
select app.transition_order((select kodjo from _t), (select o1 from _t), 'accepted', 'pending');
select app.transition_order((select kodjo from _t), (select o1 from _t), 'ready', 'accepted');
select app.transition_order((select kodjo from _t), (select o1 from _t), 'out_for_delivery', 'ready');
select app.transition_order((select kodjo from _t), (select o1 from _t), 'delivered', 'out_for_delivery');

-- Accès réservé.
select tests.login_as((select awa from _t));
select throws_ok($$select public.admin_dashboard()$$, '42501', null, 'cliente : pas de tableau de bord');
select throws_ok($$select public.admin_revenue()$$, '42501', null, 'cliente : pas de revenus');
select throws_ok($$select public.admin_client((select awa from _t))$$, '42501', null, 'cliente : pas de profils');
select throws_ok($$select public.admin_set_feature_flag('ai_search', null, true)$$, '42501', null,
  'cliente : pas de flags');
select throws_ok($$select app.admin_delete_vendor((select awa from _t), (select afi_store from _t), 'Test')$$,
  '42501', null, 'cliente : pas de suppression');

-- Revenus : cash non encaissé exclu, puis inclus ; commission déduite du net.
select tests.login_as((select admin from _t));
select is(jsonb_array_length(public.admin_revenue('30d') -> 'totals'), 0, 'cash non encaissé : pas de vente');
select tests.logout();
select app.confirm_cash((select kodjo from _t), (select o1 from _t));
create temporary table _c as select commission_minor as c from public.orders where id = (select o1 from _t);
grant select on _c to authenticated;
select tests.login_as((select admin from _t));
select is((public.admin_revenue('30d') -> 'totals' -> 0 ->> 'sales_minor')::int, 1000,
  'vente : articles hors livraison');
select is((public.admin_revenue('30d') -> 'totals' -> 0 ->> 'net_minor')::bigint,
  1000 - (select c from _c),
  'net = ventes − commission');
select is(public.admin_revenue('30d') -> 'stores' -> 0 ->> 'name', 'Étal de Kodjo', 'détail par boutique');
select throws_ok($$select public.admin_revenue('year')$$, '22023', null, 'période inconnue');

-- Tableau de bord.
select is((public.admin_dashboard('30d') -> 'revenue' -> 0 ->> 'orders')::int, 1, 'vente encaissée comptée');
select is((public.admin_dashboard('30d') -> 'deliveries' ->> 'delivered')::int, 1, 'livraison réussie');
select is(jsonb_array_length(public.admin_dashboard('30d') -> 'series_30d'), 30, 'série sur 30 jours');
select is(public.admin_dashboard('30d') -> 'top_stores' -> 0 ->> 'name', 'Étal de Kodjo', 'top boutique');
select is(public.admin_dashboard('30d') -> 'top_products' -> 0 ->> 'name', 'Tomates', 'top produit');
select ok((public.admin_dashboard('30d') ->> 'draft_stores')::int >= 0, 'brouillons comptés');

-- Feature flags.
select is((select is_enabled from public.feature_flags where key = 'ai_search' and country_code is null),
  false, 'phase 4 coupée par défaut');
select lives_ok($$select public.admin_set_feature_flag('ai_search', 'TG', true)$$, 'flag activé pour un pays');
select is((select is_enabled from public.feature_flags where key = 'ai_search' and country_code = 'TG'),
  true, 'surcharge du pays créée');
select throws_ok($$select public.admin_set_feature_flag('inconnu', null, true)$$, 'P0002', null, 'flag inconnu');
select tests.logout();
select is((select count(*)::int from public.audit_log where action = 'feature_flag_set'
  and occurred_at >= now()), 1, 'flag audité');

-- Support : réponse de l'équipe, délai de première réponse, clôture.
select tests.login_as((select awa from _t));
update _t set t1 = (public.open_ticket('client', 'order', 'Ma monnaie', (select o1 from _t)) ->> 'id')::uuid;
select tests.login_as((select admin from _t));
select is(public.admin_tickets('open') -> 0 ->> 'user_first_name', 'Awa', 'l''équipe voit la demande');
select tests.logout();
select is(app.admin_reply_ticket((select admin from _t), (select t1 from _t), 'On regarde') ->> 'status',
  'pending', 'réponse : en attente de la cliente');
select ok((select first_response_at is not null from public.support_tickets where id = (select t1 from _t)),
  'première réponse datée');
select is((select kind from public.notifications where user_id = (select awa from _t) and kind = 'support_replied'),
  'support_replied', 'la cliente est prévenue');
select tests.login_as((select admin from _t));
select is(public.admin_close_ticket((select t1 from _t)) ->> 'status', 'closed', 'demande close');

-- Profil d'une cliente : lecture auditée.
select is((public.admin_client((select awa from _t)) ->> 'order_count')::int, 1, 'commandes de la cliente');
select tests.logout();
select is((select count(*)::int from public.audit_log where action = 'client_viewed'
  and entity_id = (select awa from _t)::text), 1, 'consultation auditée');
select tests.login_as((select admin from _t));

-- Vendeuses : vue auditée ; suppression refusée avec des commandes, permise sinon.
select is(jsonb_array_length(public.admin_vendor_view((select kodjo_store from _t)) -> 'products'), 1,
  'produits de la vendeuse');
select tests.logout();
select throws_ok($$select app.admin_delete_vendor((select admin from _t), (select kodjo_store from _t), 'Fermeture')$$,
  'P0001', 'vendor_has_orders', 'historique de commandes : suppression refusée');
select app.admin_delete_vendor((select admin from _t), (select afi_store from _t), 'Demande de la vendeuse');
select is((select count(*)::int from public.stores where id = (select afi_store from _t)), 0,
  'boutique sans commande supprimée avec le compte');

select * from finish();
