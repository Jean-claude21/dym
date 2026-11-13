-- Supermarchés (spec 071) : origine proposée, choisie par une vendeuse,
-- visible et filtrable côté cliente.

select plan(4);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo, null::uuid as store;
update _t set store = tests.open_store(kodjo, 'Super Frais', 'be');
grant select, update on _t to authenticated, anonymous;

select ok(exists (select 1 from public.store_origins where code = 'supermarche' and is_active),
  'origine « supermarché » active');
select is((select label ->> 'fr' from public.store_origins where code = 'supermarche'), 'Supermarché',
  'libellé français');

select tests.login_as((select kodjo from _t));
select lives_ok($$select public.update_store('{"origin": "supermarche"}'::jsonb)$$,
  'une vendeuse choisit « supermarché »');
select tests.logout();
select is((select origin from public.stores where id = (select store from _t)), 'supermarche',
  'origine enregistrée');

select * from finish();
