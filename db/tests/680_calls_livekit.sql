-- Appels réels (LiveKit) : fournisseur choisi par le flag, accès au média réservé (spec 084).

select plan(9);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       null::uuid as kodjo_store, null::uuid as conv, null::uuid as call1, null::uuid as call2;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;
-- Appels vidéo ouverts pour ces essais (fermés par défaut, spec 089).
update public.feature_flags set is_enabled = true where key = 'calls_video' and country_code is null;

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.logout();
update _t set conv = (app.start_conversation((select awa from _t), (select kodjo_store from _t)) ->> 'id')::uuid;

-- Flag coupé : appel simulé, aucun accès au média.
update public.feature_flags set is_enabled = false where key = 'calls_livekit';
select tests.login_as((select awa from _t));
update _t set call1 = (public.start_call((select conv from _t), 'audio') ->> 'id')::uuid;
select is(public.call_state((select call1 from _t)) ->> 'provider', 'simulated', 'sans flag : appel simulé');
select public.end_call((select call1 from _t));
select tests.logout();
select throws_ok($$select app.call_media_access((select awa from _t), (select call1 from _t))$$,
  '22023', 'call_simulated', 'appel simulé : pas de jeton');

-- Flag actif : appel LiveKit ; média seulement une fois décroché, seulement pour les deux parties.
update public.feature_flags set is_enabled = true where key = 'calls_livekit' and country_code is null;
select tests.login_as((select awa from _t));
update _t set call2 = (public.start_call((select conv from _t), 'video') ->> 'id')::uuid;
select is(public.call_state((select call2 from _t)) ->> 'provider', 'livekit', 'flag actif : appel LiveKit');
select tests.logout();
select throws_ok($$select app.call_media_access((select awa from _t), (select call2 from _t))$$,
  '22023', 'call_not_active', 'pas de média avant le décroché');
select tests.login_as((select kodjo from _t));
select public.answer_call((select call2 from _t), true);
select tests.logout();
select is(app.call_media_access((select awa from _t), (select call2 from _t)) ->> 'room',
  'call-' || (select call2 from _t), 'la cliente rejoint la salle de l''appel');
select is(app.call_media_access((select kodjo from _t), (select call2 from _t)) ->> 'name',
  'Étal de Kodjo', 'la vendeuse rejoint sous le nom de sa boutique');
select is((app.call_media_access((select awa from _t), (select call2 from _t)) ->> 'video')::boolean, true,
  'appel vidéo');
select throws_ok($$select app.call_media_access((select ama from _t), (select call2 from _t))$$,
  'P0002', null, 'personne hors de la conversation refusée');
select tests.login_as((select kodjo from _t));
select public.end_call((select call2 from _t));
select tests.logout();
select throws_ok($$select app.call_media_access((select awa from _t), (select call2 from _t))$$,
  '22023', 'call_not_active', 'appel terminé : plus de jeton');

select * from finish();
