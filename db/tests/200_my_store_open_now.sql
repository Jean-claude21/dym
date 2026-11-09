-- État réel de sa boutique (spec 023, FR-012).

select plan(2);

create temporary table _t as select tests.create_user('awa@example.com') as awa;
grant select on _t to authenticated, anonymous;

select tests.login_as((select awa from _t));
select is(public.my_store_open_now(), false, 'sans boutique : pas ouverte');
select tests.logout();

select tests.login_anonymous();
select throws_ok($$select public.my_store_open_now()$$, '42501', null, 'anonyme refusé');
select tests.logout();

select * from finish();
