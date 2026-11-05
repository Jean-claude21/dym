-- Litiges (spec 012) : fenêtre de signalement, un seul ouvert, conversation à
-- trois, accès croisés, décision réservée à l'équipe, audit, remboursement.

select plan(26);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('esi@example.com') as esi,
       tests.create_user('admin@example.com') as admin,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       'a0000000-0000-4000-8000-000000000001'::uuid as home,
       null::uuid as kodjo_store, null::uuid as o1, null::uuid as o2, null::uuid as d1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
select tests.open_store((select esi from _t), 'Les jus d''Esi', 'tokoin');
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select on _t to authenticated, anonymous;

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

create function pg_temp._order() returns uuid language plpgsql as $$
declare
  v jsonb;
begin
  perform tests.login_as((select awa from _t));
  perform public.cart_add((select tomate_tas from _t), 2);
  perform tests.logout();
  v := app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select home from _t),
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash')),
    (select morning from _t));
  return (v -> 'purchase' -> 'orders' -> 0 ->> 'id')::uuid;
end
$$;
select pg_temp._order();
update _t set o1 = (select id from public.orders order by created_at limit 1);

-- Fenêtre : pas avant l'acceptation.
select throws_ok($$select app.open_dispute((select awa from _t), (select o1 from _t), 'missing_item', 'Il manque le gombo.')$$,
  'P0001', 'dispute_not_allowed', 'commande en attente : signalement refusé');
select app.transition_order((select kodjo from _t), (select o1 from _t), 'accepted', 'pending');
select throws_ok($$select app.open_dispute((select ama from _t), (select o1 from _t), 'missing_item', 'Pas à moi.')$$,
  'P0002', null, 'une autre cliente ne signale pas');
select throws_ok($$select app.open_dispute((select awa from _t), (select o1 from _t), 'fâchée', 'Raison inventée.')$$,
  '22023', null, 'raison inconnue refusée');

-- Ouverture.
update _t set d1 = (app.open_dispute((select awa from _t), (select o1 from _t), 'missing_item',
  ' Il manquait le gombo dans le sac. ') ->> 'id')::uuid;
select is((select status from public.disputes where id = (select d1 from _t)), 'open', 'litige ouvert');
select is((select body from public.dispute_messages where dispute_id = (select d1 from _t)),
  'Il manquait le gombo dans le sac.', 'premier message : le récit');
select throws_ok($$select app.open_dispute((select awa from _t), (select o1 from _t), 'damaged', 'Encore.')$$,
  'P0001', 'dispute_already_open', 'un seul litige ouvert par commande');
select is((select kind from public.notifications where user_id = (select kodjo from _t) and kind like 'dispute%'),
  'dispute_opened', 'la vendeuse est prévenue');
select is((select count(*)::int from public.events where name = 'dispute_opened'
           and entity_id = (select d1 from _t)::text), 1, 'dispute_opened');

-- Conversation.
select ok(jsonb_array_length(app.dispute_reply((select kodjo from _t), (select d1 from _t), 'Désolé, je rembourse.')
  -> 'messages') = 2, 'la vendeuse répond');
select is((select params ->> 'author' from public.notifications where user_id = (select awa from _t)
           and kind = 'dispute_replied'), 'Étal de Kodjo', 'la cliente est prévenue de la réponse');
select throws_ok($$select app.dispute_reply((select esi from _t), (select d1 from _t), 'Je m''en mêle.')$$,
  'P0002', null, 'une autre vendeuse n''écrit pas');
select lives_ok($$select app.dispute_reply((select admin from _t), (select d1 from _t), 'L''équipe regarde.')$$,
  'l''équipe écrit');

-- Lectures.
select tests.login_as((select awa from _t));
select is(jsonb_array_length(public.order_dispute((select o1 from _t)) -> 'messages'), 3, 'la cliente lit le fil');
select ok(not (public.order_dispute((select o1 from _t)) ? 'internal_note'), 'sans note interne');
select throws_ok('select public.admin_disputes()', '42501', null, 'la cliente ne liste pas les litiges');
select tests.login_as((select ama from _t));
select throws_ok(format($$select public.order_dispute('%s')$$, (select o1 from _t)), 'P0002', null,
  'une autre personne ne lit pas');
select throws_ok('select * from public.disputes', '42501', null, 'table fermée');
select tests.login_as((select admin from _t));
select is(jsonb_array_length(public.admin_disputes()), 1, 'l''équipe liste les litiges ouverts');
select is(public.admin_dispute((select d1 from _t)) -> 'order' ->> 'id', (select o1 from _t)::text,
  'détail avec la commande');
select tests.logout();

-- Décision.
select throws_ok($$select app.resolve_dispute((select kodjo from _t), (select d1 from _t), 'full_refund')$$,
  '42501', null, 'seule l''équipe tranche');
select throws_ok($$select app.resolve_dispute((select admin from _t), (select d1 from _t), 'partial_refund', 999999)$$,
  'P0001', 'refund_amount_invalid', 'montant supérieur au total refusé');
select is(app.resolve_dispute((select admin from _t), (select d1 from _t), 'partial_refund', 300,
  'Gombo manquant confirmé', true) -> 'refunds' -> 0 ->> 'method', 'cash', 'remboursement en cash à exécuter');
select is((select refund_due from public.orders where id = (select o1 from _t)), true, 'remboursement marqué sur la commande');
select is((select action from public.audit_log where entity_id = (select d1 from _t)::text), 'dispute_resolved',
  'décision dans le journal d''audit');
select throws_ok($$select app.dispute_reply((select awa from _t), (select d1 from _t), 'Merci.')$$,
  'P0001', 'dispute_closed', 'plus de messages après la décision');
select is((select props ->> 'resolution' from public.events where name = 'dispute_resolved'
           and entity_id = (select d1 from _t)::text), 'partial_refund', 'dispute_resolved');

select * from finish();
