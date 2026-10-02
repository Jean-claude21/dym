-- Adresses de livraison (spec 009, US2) : privées, une seule par défaut.

select plan(16);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.zones where slug = 'tokoin') as tokoin,
       (select id from public.zones where slug = 'osu') as osu,
       'a0000000-0000-4000-8000-000000000001'::uuid as home,
       'a0000000-0000-4000-8000-000000000002'::uuid as work;
grant select on _t to authenticated, anonymous;

create function pg_temp._address(p_id uuid, p_kind text, p_extra jsonb default '{}') returns jsonb
language sql as $$
  select jsonb_build_object(
    'id', p_id, 'kind', p_kind, 'zone_id', (select be from _t),
    'landmark', 'Portail bleu après la pharmacie', 'phone', '+228 90 00 00 00') || p_extra
$$;
grant execute on function pg_temp._address(uuid, text, jsonb) to authenticated;

select tests.login_as((select awa from _t));

select lives_ok(format($$select public.save_address(pg_temp._address('%s', 'home',
  '{"latitude": 6.13, "longitude": 1.239}'))$$, (select home from _t)), 'adresse créée');
select is((public.my_addresses() -> 0 ->> 'is_default')::boolean, true, 'la première est par défaut');
select is(public.my_addresses() -> 0 ->> 'zone_name', 'Bè', 'quartier servi');
select is((public.my_addresses() -> 0 ->> 'latitude')::numeric, 6.13, 'position conservée');
select lives_ok(format($$select public.save_address(pg_temp._address('%s', 'home'))$$, (select home from _t)),
  'même identifiant : modifiée, sans doublon');
select is(jsonb_array_length(public.my_addresses()), 1, 'une seule adresse');

select lives_ok(format($$select public.save_address(pg_temp._address('%s', 'work',
  jsonb_build_object('zone_id', '%s', 'is_default', true)))$$, (select work from _t), (select tokoin from _t)),
  'bureau par défaut');
select is((select count(*)::int from public.customer_addresses where is_default), 1, 'une seule par défaut');
select is(public.my_addresses() -> 0 ->> 'kind', 'work', 'le défaut en tête');

select throws_ok(format($$select public.save_address(pg_temp._address('%s', 'home', '{"phone": "abc"}'))$$,
  gen_random_uuid()), '23514', null, 'téléphone invalide refusé');
select throws_ok(format($$select public.save_address(pg_temp._address('%s', 'home', '{"latitude": 6.1}'))$$,
  gen_random_uuid()), '23514', null, 'position incomplète refusée');
select throws_ok(format($$select public.save_address(pg_temp._address('%s', 'home', jsonb_build_object('zone_id', '%s')))$$,
  gen_random_uuid(), (select osu from _t)), '22023', null, 'quartier d''un pays inactif refusé');

select lives_ok(format($$select public.delete_address('%s')$$, (select work from _t)), 'défaut supprimé');
select is((public.my_addresses() -> 0 ->> 'is_default')::boolean, true, 'la restante devient le défaut');

-- Une autre cliente.
select tests.login_as((select ama from _t));
select is(jsonb_array_length(public.my_addresses()), 0, 'Ama ne voit pas les adresses d''Awa');
select throws_ok(format($$select public.save_address(pg_temp._address('%s', 'other'))$$, (select home from _t)),
  '42501', null, 'Ama ne modifie pas l''adresse d''Awa');

select * from finish();
