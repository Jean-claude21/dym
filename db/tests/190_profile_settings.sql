-- Spec 022 : prénom et langue modifiables par leur propriétaire seulement.

select plan(9);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('mariam@example.com') as mariam,
       (select id from public.zones where slug = 'be') as be;
grant select on _t to authenticated, anonymous;

select tests.login_as((select mariam from _t));
select throws_ok($$select public.update_my_profile('Mariam')$$, 'P0002', null, 'profil à compléter d''abord');

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select is(public.update_my_profile('  Awa Marie ') -> 'profile' ->> 'first_name', 'Awa Marie',
  'prénom modifié, espaces retirés');
select is(public.update_my_profile(null, 'en') -> 'profile' ->> 'locale', 'en', 'langue modifiée');
select is(public.update_my_profile(null, null) -> 'profile' ->> 'first_name', 'Awa Marie',
  'rien à changer : inchangé');
select throws_ok($$select public.update_my_profile(' ')$$, '22023', null, 'prénom vide refusé');
select throws_ok($$select public.update_my_profile(repeat('a', 41))$$, '22023', null, 'prénom trop long refusé');
select throws_ok($$select public.update_my_profile(null, 'zz')$$, '22023', null,
  'langue sans notifications refusée');
select ok(public.supported_locales() @> '["fr", "en"]', 'langues issues de la configuration');

select tests.logout();
select throws_ok($$select public.update_my_profile('Intrus')$$, '42501', null, 'session requise');

select * from finish();
