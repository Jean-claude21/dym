-- Suppression de compte (spec 005, US5, SC-003).

select plan(9);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       (select z.id from public.zones z where z.slug = 'tokoin') as tokoin;
grant select on _t to authenticated, anonymous;

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select tokoin from _t), 'client');
select lives_ok('select public.delete_my_account()', 'suppression demandée');
select lives_ok('select public.delete_my_account()', 'seconde demande sans effet');

select tests.logout();
select is(
  (select count(*)::int from neon_auth."user" where id = (select awa from _t)),
  0, 'utilisateur supprimé'
);
select is(
  (select count(*)::int from public.profiles where user_id = (select awa from _t)),
  0, 'profil supprimé'
);
select is(
  (select count(*)::int from public.user_roles where user_id = (select awa from _t)),
  0, 'rôles supprimés'
);
select is(
  (select count(*)::int from public.audit_log
   where action = 'account_deleted' and entity_id = (select awa from _t)::text),
  1, 'audit : suppression tracée'
);
select ok(
  not exists (
    select 1 from public.audit_log
    where entity_id = (select awa from _t)::text
      and (coalesce(before::text, '') || coalesce(after::text, '')) ~* '(awa@|Awa)'
  ),
  'audit : aucune donnée personnelle (ni email ni prénom)'
);
select is(
  (select count(*)::int from public.events where name = 'account_deleted'),
  1, 'événement de suppression'
);

-- Sans session : refus.
select tests.login_anonymous();
select throws_ok('select public.delete_my_account()', '42501', null, 'anonyme : refusé');

select * from finish();
