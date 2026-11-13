-- Appels audio seulement par défaut (spec 089) : la vidéo est refusée tant que le flag est coupé.

select plan(3);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       null::uuid as store, null::uuid as conv;
update _t set store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.logout();
update _t set conv = (app.start_conversation((select awa from _t), (select store from _t)) ->> 'id')::uuid;

select is((select is_enabled from public.feature_flags where key = 'calls_video' and country_code is null),
  false, 'vidéo fermée par défaut');
select tests.login_as((select awa from _t));
select throws_ok($$select public.start_call((select conv from _t), 'video')$$, 'P0001', 'video_disabled',
  'appel vidéo refusé');
select is(public.start_call((select conv from _t), 'audio') ->> 'kind', 'audio', 'appel audio accepté');

select * from finish();
