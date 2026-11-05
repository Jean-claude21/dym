-- Profils et rôles (spec 005, US1, US3, US4).

select plan(19);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('fatou@example.com') as fatou,
       (select z.id from public.zones z join public.cities c on c.id = z.city_id
        where c.slug = 'lome' and z.slug = 'be') as be,
       (select z.id from public.zones z join public.cities c on c.id = z.city_id
        where c.slug = 'accra' and z.slug = 'osu') as osu;
grant select on _t to authenticated, anonymous;

-- ------------------------------------------------------------------ Awa, cliente
select tests.login_as((select awa from _t));

select is(
  (public.me() -> 'profile'),
  'null'::jsonb,
  'nouvelle utilisatrice : profil à compléter'
);
select lives_ok(
  format($$select public.complete_profile('  Awa ', %L, 'client')$$, (select be from _t)),
  'complétion du profil'
);
select is((public.me() -> 'profile' ->> 'first_name'), 'Awa', 'prénom nettoyé');
select is((public.me() -> 'profile' ->> 'country_code'), 'TG', 'pays déduit du quartier');
select is((public.me() -> 'roles'), '["client"]'::jsonb, 'rôle cliente donné');
select lives_ok(
  format($$select public.complete_profile('Awa', %L, 'client')$$, (select be from _t)),
  'complétion rejouable'
);

select throws_ok(
  format($$select public.complete_profile('Awa', %L, 'client')$$, (select osu from _t)),
  '22023', null, 'quartier d''un pays inactif refusé'
);
select throws_ok(
  format($$select public.complete_profile('', %L, 'client')$$, (select be from _t)),
  '22023', null, 'prénom vide refusé'
);
select throws_ok(
  format($$select public.complete_profile('Awa', %L, 'admin')$$, (select be from _t)),
  '22023', null, 'app « admin » refusée (aucun rôle sensible par complétion)'
);
select throws_ok(
  $$insert into public.user_roles (user_id, role) select awa, 'admin' from _t$$,
  '42501', null, 'auto-attribution du rôle admin refusée'
);
select throws_ok(
  $$select app.grant_role((select awa from _t), 'admin')$$,
  '42501', null, 'app.grant_role refusé à une non-admin'
);
select throws_ok(
  $$update public.profiles set country_code = 'GH'$$,
  '42501', null, 'pays non modifiable directement'
);
select lives_ok(
  $$update public.profiles set first_name = 'Awa M.' where user_id = (select awa from _t)$$,
  'prénom modifiable par sa propriétaire'
);

-- ------------------------------------------------------------------ Fatou, vendeuse
select tests.login_as((select fatou from _t));
select is(
  (select count(*)::int from public.profiles),
  0,
  'Fatou ne voit pas le profil d''Awa'
);
select is(
  (select count(*)::int from public.user_roles),
  0,
  'Fatou ne voit pas les rôles d''Awa'
);
update public.profiles set first_name = 'Piraté';
select lives_ok(
  format($$select public.complete_profile('Fatou', %L, 'vendor')$$, (select be from _t)),
  'Fatou complète son profil depuis l''app vendeuse'
);
select is((public.me() -> 'roles'), '["vendor"]'::jsonb, 'rôle vendeuse donné');

-- ------------------------------------------------------------------ vérification (propriétaire)
select tests.logout();
select is(
  (select first_name from public.profiles where user_id = (select awa from _t)),
  'Awa M.',
  'la mise à jour de Fatou n''a pas touché Awa'
);
select is(
  (select count(*)::int from public.events where name = 'user_signed_up'
     and actor_id in ((select awa from _t), (select fatou from _t))),
  2,
  'un seul événement d''inscription par personne (rejeu sans doublon)'
);

select * from finish();
