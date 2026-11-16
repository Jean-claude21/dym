-- Notifications et appels (spec 097) : appel manqué notifié dans la bonne app, balayage des
-- sonneries, boîte de notifications par app avec le texte rendu.

select plan(7);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       null::uuid as store, null::uuid as conv, null::uuid as call;
update _t set store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.logout();
update _t set conv = (app.start_conversation((select awa from _t), (select store from _t)) ->> 'id')::uuid;

-- Awa appelle Kodjo ; personne ne décroche.
select tests.login_as((select awa from _t));
update _t set call = (public.start_call((select conv from _t), 'audio') ->> 'id')::uuid;
select tests.logout();
update public.calls set created_at = now() - interval '2 minutes' where id = (select call from _t);
select is(app.sweep_missed_calls(now()), 1, 'sonnerie dépassée : appel manqué');
select is((select count(*)::int from public.notifications
           where user_id = (select kodjo from _t) and kind = 'call_missed_vendor'), 1,
  'la vendeuse est prévenue de l''appel manqué');
select is(app.notification_app('call_missed_vendor'), 'vendor', 'dans l''app vendeuse');
select is(app.sweep_missed_calls(now()), 0, 'une seule fois');

-- Boîte de la vendeuse : ses notifications seulement, texte rendu avec le prénom.
select tests.login_as((select kodjo from _t));
select ok(not exists (select 1 from jsonb_array_elements(public.my_app_notifications('vendor')) n
                      where n ->> 'kind' in ('incoming_call', 'call_missed', 'mission_available')),
          'boîte : app vendeuse seulement');
select is(public.my_app_notifications('vendor') -> 0 -> 'text' ->> 'body', 'Awa a essayé de t''appeler.',
  'texte rendu avec le prénom');
select ok(public.unread_app_notifications('vendor') >= 1, 'non lues comptées');

select * from finish();
