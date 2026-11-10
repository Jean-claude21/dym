-- Antifraude, modération et support assistés (spec 054).

select plan(16);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('awa@example.com') as awa,
       tests.create_user('efua@example.com') as efua,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('chef@example.com') as chef,
       (select id from public.zones where slug = 'be') as be,
       '50000000-0000-4000-8000-000000000001'::uuid as igname,
       '50000000-0000-4000-8000-000000000002'::uuid as igname_tas,
       '50000000-0000-4000-8000-0000000000ff'::uuid as device,
       null::uuid as kodjo_store, null::uuid as ticket, null::uuid as signal;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
insert into public.user_roles (user_id, role) select chef, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select public.save_product(jsonb_build_object(
  'id', (select igname from _t), 'name', 'Igname', 'category_id', (select id from public.categories where slug = 'tomates'),
  'price_minor', 1000,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select igname from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select igname_tas from _t)))));
select public.publish_product((select igname from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.report('product', (select igname from _t), 'misleading', 'Ce n''est pas de l''igname');
select tests.login_as((select efua from _t));
select public.complete_profile('Efua', (select be from _t), 'client');
select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.logout();

-- Trois comptes sur un même appareil : un signal par compte, une seule fois par jour.
insert into public.user_devices (user_id, install_id)
select u, (select device from _t) from (select awa as u from _t union all select efua from _t union all select ama from _t) x;
select is(app.detect_fraud_signals(), 3, 'appareil partagé : 3 signaux');
select is(app.detect_fraud_signals(), 0, 'pas de doublon le même jour');

select tests.login_as((select kodjo from _t));
select throws_ok($$select public.admin_fraud_signals('TG')$$, '42501', null, 'vendeuse : refusé');
select tests.login_as((select chef from _t));
select is(jsonb_array_length(public.admin_fraud_signals('TG')), 3, 'signaux du pays');
update _t set signal = (public.admin_fraud_signals('TG') -> 0 ->> 'id')::uuid;
select is(jsonb_array_length(public.admin_decide_fraud_signal((select signal from _t), false, 'Famille, même téléphone')),
  2, 'signal écarté');
select throws_ok(format($$select public.admin_decide_fraud_signal('%s', true)$$, (select signal from _t)), 'P0001',
  'already_decided', 'décision unique');
select is((public.ops_live('TG') ->> 'fraud_open')::int, 2, 'signaux ouverts dans la vue en direct');
select tests.logout();
select is((select count(*)::int from public.audit_log where action = 'fraud_dismissed'), 1, 'décision auditée');

-- Codes de remise faux : chaque essai est gardé.
select tests.login_as((select awa from _t));
select public.cart_add((select igname_tas from _t), 1);
select tests.logout();
select app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
  'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
  'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')), '2026-10-05 10:00:00+00'::timestamptz);
update public.orders set handover_attempts = handover_attempts + 1
where store_id = (select kodjo_store from _t);
select is((select count(*)::int from public.handover_failures), 1, 'essai faux gardé');

-- Tri des signalements : texte à juger, avis enregistré, montré à l'équipe.
select is(jsonb_array_length(app.reports_to_triage() -> 'items'), 1, 'signalement à trier');
select ok(app.reports_to_triage() -> 'items' -> 0 ->> 'text' like 'Igname%', 'texte du produit');
select app.record_report_triage('product', (select igname from _t), 'remove', 'Photo trompeuse', 'gpt');
select is(jsonb_array_length(app.reports_to_triage() -> 'items'), 0, 'déjà trié');
select tests.login_as((select chef from _t));
select is(public.admin_reports() -> 0 -> 'ai' ->> 'verdict', 'remove', 'avis visible par l''équipe');
select tests.logout();

-- Agent support : fil du ticket pour un admin seulement.
insert into public.support_tickets (user_id, app, subject) select awa, 'client', 'order' from _t;
update _t set ticket = (select id from public.support_tickets limit 1);
insert into public.support_messages (ticket_id, author_id, author_role, body)
select ticket, awa, 'user', 'Ma commande n''est pas arrivée' from _t;
select is(jsonb_array_length(app.support_draft_context((select chef from _t), (select ticket from _t)) -> 'messages'), 1,
  'fil du ticket');
select throws_ok(format($$select app.support_draft_context('%s', '%s')$$, (select awa from _t), (select ticket from _t)),
  '42501', null, 'réservé à l''équipe');
select ok(app.support_draft_context((select chef from _t), (select ticket from _t)) -> 'model' ->> 'model' is not null,
  'modèle configuré en base');

select * from finish();
