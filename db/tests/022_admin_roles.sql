-- Rôles sensibles et connexion admin (spec 005, US3, US6).

select plan(9);

create temporary table _t as
select tests.create_user('ops@dym.example') as ops,
       tests.create_user('kofi@example.com') as kofi,
       tests.create_user('awa@example.com') as awa;
grant select on _t to authenticated, anonymous;

-- Premier admin : donné par le propriétaire de la base (migration ou console).
select app.grant_role((select ops from _t), 'admin', 'équipe fondatrice');

select tests.login_as((select ops from _t));
select lives_ok(
  $$select app.grant_role((select kofi from _t), 'courier', 'livreur partenaire')$$,
  'un admin donne le rôle livreur'
);
select ok(
  exists (select 1 from public.user_roles where user_id = (select kofi from _t) and role = 'courier'),
  'rôle livreur actif'
);
select ok(
  (select count(*) from public.profiles) >= 0 and app.is_admin(),
  'l''admin est reconnu'
);
select lives_ok($$select public.record_sign_in('admin')$$, 'connexion admin enregistrée');
select lives_ok(
  $$select app.revoke_role((select kofi from _t), 'courier', 'fin de contrat')$$,
  'un admin retire le rôle livreur'
);

select tests.login_as((select awa from _t));
select throws_ok($$select public.record_sign_in('admin')$$, '42501', null,
  'non-admin : connexion à l''admin refusée');
select lives_ok($$select public.record_sign_in('client')$$, 'connexion cliente enregistrée');

select tests.logout();
select is(
  (select array_agg(action order by id) from public.audit_log
   where action in ('role_granted', 'role_revoked', 'admin_signed_in')
     -- Journal partagé (staging) : seulement les comptes du test.
     and entity_id in (select ops::text from _t union select kofi::text from _t)),
  array['role_granted', 'role_granted', 'admin_signed_in', 'role_revoked'],
  'audit : attributions, connexion admin et retrait'
);
select is(
  (select count(*)::int from public.events where name = 'user_signed_in'
     and occurred_at = now()),
  2, 'deux événements de connexion'
);

select * from finish();
