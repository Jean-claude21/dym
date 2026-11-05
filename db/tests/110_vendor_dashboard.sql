-- Spec 014 : chiffres, isolation, périodes locales, encaissement et récap.
select no_plan();
create temporary table _t as select
  tests.create_user('dashboard-client@example.com') as client,
  tests.create_user('dashboard-vendor@example.com') as vendor,
  tests.create_user('dashboard-other@example.com') as other,
  null::uuid as store, null::uuid as other_store,
  gen_random_uuid() as product, gen_random_uuid() as variant,
  gen_random_uuid() as address, null::uuid as purchase, null::uuid as order_id,
  (select id from public.zones where slug = 'be') as zone;
update _t set store = tests.open_store(vendor, 'Dashboard shop', 'be'),
  other_store = tests.open_store(other, 'Other shop', 'be');
grant select on _t to authenticated, anonymous;
select tests.login_as((select vendor from _t));
select public.save_product(jsonb_build_object(
  'id', (select product from _t), 'name', 'Produit', 'price_minor', 500,
  'category_id', (select id from public.categories where slug = 'tomates'),
  'photo_keys', jsonb_build_array('stores/' || (select store from _t) || '/products/' || (select product from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select variant from _t), 'stock_quantity', 10))));
select public.publish_product((select product from _t));
select tests.login_as((select client from _t));
select public.complete_profile('Test', (select zone from _t), 'client');
select public.save_address(jsonb_build_object('id', (select address from _t), 'kind', 'home',
  'zone_id', (select zone from _t), 'landmark', 'Portail bleu', 'phone', '+228 90 00 00 00'));
select public.cart_add((select variant from _t), 2);
select throws_ok('select public.my_vendor_dashboard()', 'P0002', null, 'cliente sans boutique refusée');
select tests.logout();
update _t set purchase = (app.place_order(client, gen_random_uuid(), jsonb_build_object(
  'address_id', address, 'payment_method_id', (select id from public.payment_methods
  where country_code = 'TG' and provider_code = 'cash')), '2026-10-05 10:00:00Z')
  -> 'purchase' ->> 'id')::uuid;
update _t set order_id = (select o.id from public.orders o where o.purchase_id = _t.purchase);
update public.orders set created_at = '2026-10-05 10:00:00Z' where id = (select order_id from _t);

select tests.login_as((select other from _t));
select is(public.my_vendor_dashboard() ->> 'pending_orders', '0', 'autre vendeuse : aucune commande étrangère');
select throws_ok($$select app.vendor_dashboard((select store from _t), 'day', now())$$,
  '42501', null, 'le calcul interne n''est pas callable par la Data API');
select throws_ok($$select app.create_vendor_recaps(now())$$, '42501', null, 'cron interdit aux apps');
select tests.logout();
set local role anonymous;
select throws_ok('select public.my_vendor_dashboard()', '42501', null, 'anonyme refusé');
reset role;

select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'order_count',
  '1', 'commande du jour comptée');
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'revenue_minor',
  '0', 'cash non livré et non encaissé exclu');
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'pending_payments',
  '1', 'cash attendu');
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'pending_orders',
  '1', 'commande à accepter');
select throws_ok($$select app.vendor_dashboard((select store from _t), 'year', now())$$,
  '22023', 'invalid_period', 'période inconnue refusée');
select app.transition_order((select vendor from _t), (select order_id from _t), 'accepted', 'pending');
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'active_orders',
  '1', 'acceptée : en cours');
select app.transition_order((select vendor from _t), (select order_id from _t), 'ready', 'accepted');
select app.transition_order((select vendor from _t), (select order_id from _t), 'out_for_delivery', 'ready');
select app.transition_order((select vendor from _t), (select order_id from _t), 'delivered', 'out_for_delivery');
update public.orders set delivered_at = '2026-10-05 11:00Z' where id = (select order_id from _t);
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'revenue_minor',
  '0', 'livrée sans encaissement exclue');
select app.confirm_cash((select vendor from _t), (select order_id from _t));
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'revenue_minor',
  '1000', 'cash encaissé : articles seulement, livraison exclue');
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'pending_payments',
  '0', 'cash encaissé : aucun paiement attendu');
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-06 12:00Z') ->> 'revenue_minor',
  '0', 'pas de vente dans le jour suivant');
select is(app.vendor_dashboard((select store from _t), 'week', '2026-10-11 12:00Z') ->> 'revenue_minor',
  '1000', 'semaine lundi à dimanche');
select is(app.vendor_dashboard((select store from _t), 'week', '2026-10-12 12:00Z') ->> 'revenue_minor',
  '0', 'semaine suivante exclut la précédente');
select is(app.vendor_dashboard((select store from _t), 'month', '2026-10-31 12:00Z') ->> 'revenue_minor',
  '1000', 'mois courant');
select is(app.vendor_dashboard((select store from _t), 'month', '2026-11-01 12:00Z') ->> 'revenue_minor',
  '0', 'mois suivant');
update public.purchases set payment_status = 'paid' where id = (select purchase from _t);
update public.orders set cash_collected_at = null where id = (select order_id from _t);
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'revenue_minor',
  '1000', 'livrée payée en ligne incluse');
insert into public.refunds(order_id, amount_minor, currency_code, method, requested_by, status)
select order_id, o.total_minor, 'XOF', 'provider', vendor, 'succeeded'
from _t join public.orders o on o.id = _t.order_id;
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'revenue_minor',
  '0', 'remboursement réussi déduit sans compter les frais');
update public.refunds set status = 'failed' where order_id = (select order_id from _t);
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 12:00Z') ->> 'revenue_minor',
  '1000', 'remboursement échoué ne réduit pas le CA');
update public.product_variants set stock_quantity = 0 where id = (select variant from _t);
select is(app.vendor_dashboard((select store from _t), 'day', now()) ->> 'out_of_stock', '1', 'stock zéro signalé');
update public.product_variants set stock_quantity = null where id = (select variant from _t);
select is(app.vendor_dashboard((select store from _t), 'day', now()) ->> 'out_of_stock', '0', 'stock non suivi exclu');
update public.products set is_available = false where id = (select product from _t);
select is(app.vendor_dashboard((select store from _t), 'day', now()) ->> 'out_of_stock', '1', 'indisponible signalé');
update public.products set status = 'archived' where id = (select product from _t);
select is(app.vendor_dashboard((select store from _t), 'day', now()) ->> 'out_of_stock', '0', 'archivé exclu');

-- Fuseau non lié à un pays codé en dur ; frontière UTC ≠ journée locale.
update public.countries set timezone = 'Asia/Tokyo' where code = 'TG';
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 16:00Z') ->> 'local_date',
  '2026-10-06', 'date locale calculée selon le référentiel');
select is(app.vendor_dashboard((select store from _t), 'day', '2026-10-05 16:00Z') ->> 'revenue_minor',
  '0', 'ventes de la veille locale exclues');
select app.create_vendor_recaps('2026-10-05 09:59Z');
select is((select count(*) from app.vendor_daily_recaps where store_id = (select store from _t)),
  0::bigint, '18 h 59 locales : pas de récap');
select app.create_vendor_recaps('2026-10-05 10:00Z');
select is((select count(*) from app.vendor_daily_recaps where store_id = (select store from _t)),
  1::bigint, '19 h locales : un récap');
select app.create_vendor_recaps('2026-10-05 11:00Z');
select is((select count(*) from public.notifications where user_id = (select vendor from _t)
  and kind = 'vendor_daily_recap'), 1::bigint, 'replay : pas de notification dupliquée');
select app.create_vendor_recaps('2026-10-06 10:00Z');
select is((select count(*) from app.vendor_daily_recaps where store_id = (select store from _t)),
  2::bigint, 'jour suivant : nouveau récap');
select app.create_vendor_recaps('2100-01-01 12:00Z');
select is((select count(*) from app.vendor_daily_recaps where local_date > current_date + 1),
  0::bigint, 'date future forgée : jamais de récap en avance');
select is(app.notification_app('vendor_daily_recap'), 'vendor', 'push vers app vendeuse');
select is(app.notification_app('order_ready'), 'client', 'anciens types conservés');
select * from finish();
