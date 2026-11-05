-- Boutiques : ouverture, accès public, protection (spec 006, US3, US4).

select plan(20);

create temporary table _t as
select tests.create_user('esi@example.com') as esi,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('awa@example.com') as awa,
       (select z.id from public.zones z where z.slug = 'tokoin') as tokoin,
       (select id from public.categories where slug = 'fait-maison') as fait_maison,
       (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash') as cash_tg;
grant select on _t to authenticated, anonymous;

-- Boutique complète d'Esi.
select tests.login_as((select esi from _t));
select public.complete_profile('Esi', (select tokoin from _t), 'vendor');
select public.start_store('Les jus d''Esi');
select public.update_store(jsonb_build_object(
  'origin', 'maison', 'zone_id', (select tokoin from _t), 'main_category_id', (select fait_maison from _t)));
select public.set_store_pickup_address('Rue des Hibiscus', 'Derrière la pharmacie', 6.1375, 1.2123, '+228 90 00 00 00');
select public.set_store_delivery_zones(array[(select tokoin from _t)]);
select public.set_store_payment_methods(array[(select cash_tg from _t)]);
select public.set_store_hours(
  '[{"weekday": 1, "opens_at": "07:00", "closes_at": "19:00"},
    {"weekday": 2, "opens_at": "07:00", "closes_at": "19:00"}]');

select is((public.my_store() -> 'missing'), '[]'::jsonb, 'boutique complète');
select lives_ok('select public.publish_store()', 'ouverture');
select is((public.my_store() ->> 'status'), 'active', 'boutique active');
select ok((public.my_store() ->> 'is_open')::boolean, 'boutique ouverte');

-- Statut et données sensibles non modifiables directement.
select throws_ok($$update public.stores set status = 'active'$$, '42501', null,
  'mise à jour directe refusée');
select throws_ok($$select public.update_store('{"status": "active"}')$$, '22023', null,
  'statut absent de la liste blanche');
select throws_ok($$insert into public.store_pickup_addresses (store_id, address) values (gen_random_uuid(), 'x')$$,
  '42501', null, 'écriture directe de l''adresse refusée');

-- Fermer puis rouvrir en un geste.
select lives_ok('select public.set_store_open(false)', 'fermeture');
select ok(not (public.my_store() ->> 'is_open')::boolean, 'boutique fermée');
select lives_ok('select public.set_store_open(true)', 'réouverture');

-- Cliente connectée et visiteur anonyme.
select tests.login_as((select awa from _t));
select is((select count(*)::int from public.stores where name = 'Les jus d''Esi'), 1,
  'cliente : boutique active visible');
select throws_ok('select owner_id from public.stores', '42501', null,
  'cliente : propriétaire illisible');
select is((select count(*)::int from public.store_pickup_addresses), 0,
  'cliente : adresse de ramassage invisible');
select is((select count(*)::int from public.store_hours), 2, 'cliente : horaires visibles');

select tests.login_anonymous();
select is((select origin from public.stores where name = 'Les jus d''Esi'), 'maison',
  'anonyme : origine visible');

-- Kodjo, autre vendeuse : brouillon invisible, boutique d'Esi intouchable.
select tests.login_as((select kodjo from _t));
select public.complete_profile('Kodjo', (select tokoin from _t), 'vendor');
select public.start_store('Alimentation Kodjo');
select tests.login_as((select awa from _t));
select is((select count(*)::int from public.stores where name = 'Alimentation Kodjo'), 0,
  'brouillon invisible des clientes');
select tests.login_as((select kodjo from _t));
select public.update_store('{"name": "Piraté"}');

-- Suspension par l'équipe : Esi ne peut pas rouvrir.
select tests.logout();
select is((select name from public.stores where owner_id = (select esi from _t)),
  'Les jus d''Esi', 'la mise à jour de Kodjo n''a touché que sa boutique');
update public.stores set status = 'suspended', is_open = false where owner_id = (select esi from _t);
select tests.login_as((select esi from _t));
select throws_ok('select public.set_store_open(true)', '42501', null, 'suspendue : réouverture refusée');
select throws_ok('select public.publish_store()', '42501', null, 'suspendue : ouverture refusée');

select tests.logout();
select is(
  (select array_agg(name order by id) from public.events
   where name like 'store_%' and occurred_at = now()),
  array['store_created', 'store_opened', 'store_closed', 'store_opened'],
  'événements : création, ouverture, fermeture, réouverture'
);

select * from finish();
