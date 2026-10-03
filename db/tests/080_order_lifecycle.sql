-- Cycle de vie des commandes (spec 011) : règles par rôle et par mode,
-- conflit d'état, stock rendu, remboursement marqué, encaissement, accès.

select plan(45);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('esi@example.com') as esi,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'boissons') as boissons,
       (select id from public.categories where slug = 'tomates') as tomates,
       '11111111-1111-4111-8111-111111111111'::uuid as bissap,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'b1000000-0000-4000-8000-000000000001'::uuid as bissap_1l,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       'a0000000-0000-4000-8000-000000000001'::uuid as home,
       null::uuid as esi_store, null::uuid as kodjo_store,
       null::uuid as k1, null::uuid as e1, null::uuid as e2, null::uuid as e3, null::uuid as k4;
update _t set esi_store = tests.open_store(esi, 'Les jus d''Esi', 'tokoin'),
              kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select on _t to authenticated, anonymous;

create function pg_temp._product(p_store uuid, p_id uuid, p_variant uuid, p_category uuid, p_price bigint,
  p_stock int) returns jsonb language sql as $$
  select jsonb_build_object(
    'id', p_id, 'name', 'Produit', 'category_id', p_category, 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || p_store || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', p_stock)))
$$;
grant execute on function pg_temp._product(uuid, uuid, uuid, uuid, bigint, int) to authenticated;

select tests.login_as((select esi from _t));
select public.set_store_delivery_zones(array[(select id from public.zones where slug = 'tokoin'), (select be from _t)]);
select public.update_store('{"offers_pickup": true}');
select public.save_product(pg_temp._product((select esi_store from _t), (select bissap from _t), (select bissap_1l from _t),
  (select boissons from _t), 700, 10));
select public.publish_product((select bissap from _t));
select tests.login_as((select kodjo from _t));
select public.save_product(pg_temp._product((select kodjo_store from _t), (select tomate from _t), (select tomate_tas from _t),
  (select tomates from _t), 500, null));
select public.publish_product((select tomate from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.save_address(jsonb_build_object('id', (select home from _t), 'kind', 'home', 'zone_id', (select be from _t),
  'landmark', 'Portail bleu', 'phone', '+228 90 00 00 00'));
select tests.logout();

-- Commande cash : [p_lines] {variant: quantité}, [p_pickup] boutiques en retrait.
create function pg_temp._order(p_lines jsonb, p_pickup uuid[] default '{}') returns jsonb language plpgsql as $$
declare
  v record;
begin
  perform tests.login_as((select awa from _t));
  for v in select key::uuid as variant, value::int as q from jsonb_each_text(p_lines) loop
    perform public.cart_add(v.variant, v.q);
  end loop;
  perform tests.logout();
  return app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select home from _t),
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', (select coalesce(jsonb_object_agg(s, 'pickup'), '{}'::jsonb) from unnest(p_pickup) s)),
    (select morning from _t));
end
$$;
create function pg_temp._go(p_user uuid, p_order uuid, p_to text, p_reason text default null) returns jsonb
language sql as $$
  select app.transition_order(p_user, p_order, p_to, (select status from public.orders where id = p_order), p_reason)
$$;
create function pg_temp._stock() returns int language sql as $$
  select stock_quantity from public.product_variants where id = (select bissap_1l from _t)
$$;

-- Règles : toutes les paires, par rôle et par mode.
create function pg_temp._pairs(p_role text, p_mode text) returns text[] language sql as $$
  select array_agg(f || '>' || t order by f, t)
  from unnest(array['pending', 'accepted', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'refused', 'cancelled']) f,
       unnest(array['pending', 'accepted', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'refused', 'cancelled']) t
  where app.order_transition_allowed(p_role, p_mode, f, t)
$$;
select is(pg_temp._pairs('vendor', 'delivery'),
  array['accepted>preparing', 'accepted>ready', 'out_for_delivery>delivered', 'pending>accepted', 'pending>refused',
        'preparing>ready', 'ready>out_for_delivery'], 'vendeuse, livraison : 7 transitions');
select is(pg_temp._pairs('vendor', 'pickup'),
  array['accepted>preparing', 'accepted>ready', 'pending>accepted', 'pending>refused', 'preparing>ready',
        'ready>delivered'], 'vendeuse, retrait : 6 transitions');
select is(pg_temp._pairs('client', 'delivery'), array['accepted>cancelled', 'pending>cancelled'],
  'cliente : annuler avant la préparation');
select is(pg_temp._pairs('admin', 'delivery'), null, 'aucun autre rôle ici');

-- Achat 1 : Kodjo (livraison) et Esi (retrait).
select pg_temp._order(jsonb_build_object((select tomate_tas from _t), 2, (select bissap_1l from _t), 3),
        array[(select esi_store from _t)]);
update _t set k1 = (select id from public.orders where store_id = (select kodjo_store from _t)),
              e1 = (select id from public.orders where store_id = (select esi_store from _t));
select is(pg_temp._stock(), 7, 'stock décrémenté à la commande');

select throws_ok($$select pg_temp._go((select kodjo from _t), (select k1 from _t), 'delivered')$$,
  'P0001', 'transition_not_allowed', 'saut d''étape refusé');
select throws_ok($$select app.transition_order((select kodjo from _t), (select k1 from _t), 'accepted', 'preparing')$$,
  'P0001', 'status_changed', 'état changé entre-temps : refusé');
select throws_ok($$select pg_temp._go((select ama from _t), (select k1 from _t), 'cancelled')$$,
  'P0002', null, 'une autre cliente ne touche pas la commande');
select throws_ok($$select pg_temp._go((select esi from _t), (select k1 from _t), 'accepted')$$,
  'P0002', null, 'une autre vendeuse non plus');

select is(pg_temp._go((select kodjo from _t), (select k1 from _t), 'accepted') ->> 'status', 'accepted', 'acceptée');
select ok((select accepted_at is not null from public.orders where id = (select k1 from _t)), 'heure d''acceptation');
select ok(app.order_json((select k1 from _t), 'client') ->> 'eta_at' is not null, 'heure estimée');
select is(app.order_json((select k1 from _t), 'client') -> 'next_statuses', '["cancelled"]', 'la cliente peut encore annuler');
select is(pg_temp._go((select kodjo from _t), (select k1 from _t), 'preparing') -> 'next_statuses', '["ready"]',
  'en préparation : prochaine étape prête');
select throws_ok($$select pg_temp._go((select awa from _t), (select k1 from _t), 'cancelled')$$,
  'P0001', 'transition_not_allowed', 'annulation refusée après le début de la préparation');
select is(pg_temp._go((select kodjo from _t), (select k1 from _t), 'ready') ->> 'status', 'ready', 'prête');
select throws_ok($$select app.confirm_cash((select kodjo from _t), (select k1 from _t))$$,
  'P0001', 'not_delivered', 'encaissement avant la livraison refusé');
select is(pg_temp._go((select kodjo from _t), (select k1 from _t), 'out_for_delivery') ->> 'status', 'out_for_delivery', 'en route');
select is(pg_temp._go((select kodjo from _t), (select k1 from _t), 'delivered') ->> 'status', 'delivered', 'livrée');
select ok(app.order_json((select k1 from _t), 'client') ->> 'eta_at' is null, 'plus d''heure estimée une fois livrée');
select ok(app.confirm_cash((select kodjo from _t), (select k1 from _t)) ->> 'cash_collected_at' is not null, 'encaissement confirmé');
select is(app.confirm_cash((select kodjo from _t), (select k1 from _t)) ->> 'cash_collected_at',
  (select to_jsonb(cash_collected_at) #>> '{}' from public.orders where id = (select k1 from _t)), 'encaissement une seule fois');
select is((select count(*)::int from public.order_status_events where order_id = (select k1 from _t)), 5,
  'historique : 5 étapes');

-- Esi refuse : raison obligatoire, stock rendu.
select throws_ok($$select pg_temp._go((select esi from _t), (select e1 from _t), 'refused')$$,
  'P0001', 'reason_required', 'refus sans raison refusé');
select is(pg_temp._go((select esi from _t), (select e1 from _t), 'refused', 'out_of_stock') ->> 'status_reason', 'out_of_stock',
  'refusée avec sa raison');
select is(pg_temp._stock(), 10, 'stock rendu après le refus');
select is((select refund_due from public.orders where id = (select e1 from _t)), false, 'cash : rien à rembourser');

-- Achat 2 : Esi en retrait, la cliente annule avant acceptation.
select pg_temp._order(jsonb_build_object((select bissap_1l from _t), 4), array[(select esi_store from _t)]);
update _t set e2 = (select id from public.orders where store_id = (select esi_store from _t) and status = 'pending');
select is(pg_temp._stock(), 6, 'stock décrémenté');
select is(pg_temp._go((select awa from _t), (select e2 from _t), 'cancelled') ->> 'cancelled_by', 'client', 'annulée par la cliente');
select is(pg_temp._stock(), 10, 'stock rendu après l''annulation');

-- Achat 3 : retrait jusqu'à « récupérée ».
select pg_temp._order(jsonb_build_object((select bissap_1l from _t), 1), array[(select esi_store from _t)]);
update _t set e3 = (select id from public.orders where store_id = (select esi_store from _t) and status = 'pending');
select lives_ok($$select pg_temp._go((select esi from _t), (select e3 from _t), 'accepted')$$, 'retrait acceptée');
select lives_ok($$select pg_temp._go((select esi from _t), (select e3 from _t), 'ready')$$, 'retrait prête (sans préparation)');
select throws_ok($$select pg_temp._go((select esi from _t), (select e3 from _t), 'out_for_delivery')$$,
  'P0001', 'transition_not_allowed', 'pas d''« en route » pour un retrait');
select is(pg_temp._go((select esi from _t), (select e3 from _t), 'delivered') ->> 'status', 'delivered', 'retrait récupérée');

-- Achat 4 : payé en ligne (simulateur), puis refusé : remboursement à faire.
insert into public.payment_methods (country_code, provider_code, label, sort, is_active)
values ('TG', 'simulator', '{"fr": "Simulé"}', 9, true);
insert into public.store_payment_methods (store_id, payment_method_id)
select (select kodjo_store from _t), id from public.payment_methods where provider_code = 'simulator';
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 1);
select tests.logout();
create temporary table _p4 as
select app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
  'address_id', (select home from _t),
  'payment_method_id', (select id from public.payment_methods where provider_code = 'simulator')),
  (select morning from _t), '{simulator}') as r;
update _t set k4 = (select id from public.orders where purchase_id = (select (r -> 'purchase' ->> 'id')::uuid from _p4));
select throws_ok($$select pg_temp._go((select kodjo from _t), (select k4 from _t), 'accepted')$$,
  'P0002', null, 'non payée : invisible et intouchable pour la vendeuse');
select is(app.apply_payment_event('simulator', 'evt-k4', '{}', true,
  (select (r -> 'purchase' -> 'payment' ->> 'id')::uuid from _p4), 'succeeded',
  (select (r -> 'purchase' -> 'payment' ->> 'amount_minor')::bigint from _p4), 'XOF'), 'applied', 'payée');
select is(pg_temp._go((select kodjo from _t), (select k4 from _t), 'refused', 'too_busy') ->> 'refund_due', 'true',
  'refusée après paiement : remboursement à faire');
select throws_ok($$select app.confirm_cash((select kodjo from _t), (select k4 from _t))$$,
  'P0001', 'not_cash', 'pas d''encaissement pour un paiement en ligne');

-- Lectures.
select tests.login_as((select awa from _t));
select is(jsonb_array_length(public.my_orders()), 5, 'mes commandes : 5');
select is(public.my_order((select k1 from _t)) -> 'address' ->> 'landmark', 'Portail bleu', 'suivi avec mon adresse');
select tests.login_as((select kodjo from _t));
select is(jsonb_array_length(public.my_store_orders('done')), 2, 'Kodjo : 2 terminées (livrée, refusée)');
select is(jsonb_array_length(public.my_store_order((select k1 from _t)) -> 'history'), 5, 'détail vendeuse : historique');
select tests.login_as((select ama from _t));
select is((select count(*)::int from public.order_status_events), 0, 'historique invisible pour une autre personne');
select tests.logout();

-- Événements.
select is((select count(*)::int from public.events where name = 'order_status_changed'
           and occurred_at = now()), 11, 'order_status_changed à chaque étape (5 + 1 + 1 + 3 + 1)');
select is(array(select name from public.events
                where name in ('order_accepted', 'order_rejected', 'order_delivered', 'order_cancelled')
                  and occurred_at = now() order by name),
  array['order_accepted', 'order_accepted', 'order_cancelled', 'order_delivered', 'order_delivered',
        'order_rejected', 'order_rejected'], 'événements métier');

select * from finish();
