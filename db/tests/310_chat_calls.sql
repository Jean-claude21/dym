-- Vocaux et appels (spec 035).

select plan(14);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       null::uuid as kodjo_store, null::uuid as conv, null::uuid as call1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.logout();
update _t set conv = (app.start_conversation((select awa from _t), (select kodjo_store from _t)) ->> 'id')::uuid;

-- Vocaux : clé de la conversation, durée bornée ; illisibles d'autrui.
select is(app.send_message((select awa from _t), (select conv from _t), 'audio', null,
  'chats/' || (select conv from _t) || '/' || gen_random_uuid() || '.wav', null, gen_random_uuid(), 4200)
  ->> 'duration_ms', '4200', 'vocal envoyé avec sa durée');
select throws_ok($$select app.send_message((select awa from _t), (select conv from _t), 'audio', null,
  'chats/autre/' || gen_random_uuid() || '.wav', null, gen_random_uuid(), 4200)$$, 'P0001', 'media_invalid',
  'clé d''une autre conversation refusée');
select throws_ok($$select app.send_message((select awa from _t), (select conv from _t), 'audio', null,
  'chats/' || (select conv from _t) || '/' || gen_random_uuid() || '.wav', null, gen_random_uuid(), 90000)$$,
  'P0001', 'media_invalid', 'vocal trop long refusé');
select is(app.chat_media_keys((select ama from _t), array(select id from public.messages where kind = 'audio')),
  '{}'::jsonb, 'vocal illisible hors de la conversation');

-- Appel : la cliente appelle, la vendeuse décroche puis raccroche.
select tests.login_as((select awa from _t));
update _t set call1 = (public.start_call((select conv from _t), 'video') ->> 'id')::uuid;
select is(public.call_state((select call1 from _t)) ->> 'status', 'ringing', 'appel vidéo qui sonne');
select throws_ok($$select public.start_call((select conv from _t), 'audio')$$, '22023', 'call_in_progress',
  'un seul appel actif par conversation');
select throws_ok($$select public.answer_call((select call1 from _t), true)$$, 'P0002', null,
  'on ne décroche pas son propre appel');
select tests.login_as((select kodjo from _t));
select is(public.my_incoming_call() ->> 'caller_name', 'Awa', 'appel entrant pour la vendeuse');
select is(public.answer_call((select call1 from _t), true) ->> 'status', 'ongoing', 'décroché');
select is(public.end_call((select call1 from _t)) ->> 'status', 'ended', 'raccroché');
select tests.logout();
select is((select count(*)::int from public.messages where kind = 'call' and call_id = (select call1 from _t)), 1,
  'résumé de l''appel dans la conversation');

-- Autrui ; sonnerie dépassée ; flag coupé.
select tests.login_as((select ama from _t));
select throws_ok($$select public.call_state((select call1 from _t))$$, 'P0002', null, 'appel d''autrui invisible');
select tests.login_as((select awa from _t));
update _t set call1 = (public.start_call((select conv from _t), 'audio') ->> 'id')::uuid;
select tests.logout();
update public.calls set created_at = clock_timestamp() - interval '2 minutes' where id = (select call1 from _t);
select tests.login_as((select kodjo from _t));
select is(public.my_incoming_call(), null, 'sans réponse en 60 s : plus de sonnerie (manqué)');
select tests.logout();
update public.feature_flags set is_enabled = false where key = 'calls_simulated' and country_code is null;
select tests.login_as((select awa from _t));
select throws_ok($$select public.start_call((select conv from _t), 'audio')$$, 'P0001', 'feature_disabled',
  'flag coupé : appels refusés');

select * from finish();
