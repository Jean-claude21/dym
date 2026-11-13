-- Statistiques admin des échanges (specs 070 à 072).

select plan(6);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('admin@example.com') as admin,
       null::uuid as kodjo_store, null::uuid as conv;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select id from public.zones where slug = 'be'), 'client');
select public.set_notification_preference('quiet_night', true);
select tests.logout();
update _t set conv = (app.start_conversation(awa, kodjo_store) ->> 'id')::uuid;
select app.send_message((select awa from _t), (select conv from _t), 'text', 'Bonjour', null, null, gen_random_uuid());
select app.send_message((select kodjo from _t), (select conv from _t), 'text', 'Bonjour Awa', null, null, gen_random_uuid());

select tests.login_as((select awa from _t));
select throws_ok($$select public.admin_exchanges()$$, '42501', null, 'réservé à l''équipe');

select tests.login_as((select admin from _t));
select is((public.admin_exchanges() ->> 'messages')::int, 2, 'messages du jour');
select is((public.admin_exchanges('day', now() + interval '1 minute') ->> 'conversations_active')::int, 1,
  'conversations actives');
select is((select (o ->> 'stores')::int from jsonb_array_elements(public.admin_exchanges() -> 'stores_by_origin') o
           where o ->> 'code' = 'maison'), 1, 'boutiques actives par origine');
select ok(exists (select 1 from jsonb_array_elements(public.admin_exchanges() -> 'stores_by_origin') o
                  where o ->> 'code' = 'supermarche'), 'supermarchés listés');
select is((public.admin_exchanges() ->> 'quiet_night_users')::int, 1, 'nuit calme activée');

select * from finish();
