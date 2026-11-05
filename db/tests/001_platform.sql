-- Socle (migration 0001) : identité courante et horodatage.

select plan(6);

select has_function('app', 'current_user_id', 'app.current_user_id() existe');

-- Identité sous la Data API.
create temporary table _ids (awa uuid);
grant all on _ids to authenticated, anonymous;
insert into _ids values (tests.create_user('awa@example.com'));

select tests.login_as((select awa from _ids));
select is(
  app.current_user_id(),
  (select awa from _ids),
  'authenticated : identité = sub du jeton'
);
select is(current_user::text, 'authenticated', 'rôle authenticated');

select tests.login_anonymous();
select is(app.current_user_id(), null, 'anonymous : aucune identité');

select tests.logout();

-- Horodatage automatique.
create temporary table _stamp (id int primary key, v text, updated_at timestamptz);
create trigger _stamp_updated before update on _stamp
  for each row execute function app.set_updated_at();
insert into _stamp values (1, 'a', '2000-01-01');
update _stamp set v = 'b' where id = 1;
select isnt(
  (select updated_at from _stamp),
  '2000-01-01'::timestamptz,
  'updated_at mis à jour'
);

-- Les fonctions de public ne sont plus exécutables par tous par défaut.
create function public._probe() returns int language sql as 'select 1';
select ok(
  not has_function_privilege('anonymous', 'public._probe()', 'execute'),
  'nouvelle fonction de public : pas d''exécution par défaut'
);

select * from finish();
