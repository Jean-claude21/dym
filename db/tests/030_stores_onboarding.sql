-- Onboarding de la boutique (spec 006, US1, US2, FR-001 à FR-006).

select plan(23);

create temporary table _t as
select tests.create_user('esi@example.com') as esi,
       tests.create_user('awa@example.com') as awa,
       (select z.id from public.zones z where z.slug = 'tokoin') as tokoin,
       (select z.id from public.zones z where z.slug = 'be') as be,
       (select z.id from public.zones z where z.slug = 'osu') as osu,
       (select id from public.categories where slug = 'fait-maison') as fait_maison,
       (select id from public.categories where slug = 'jus-maison') as sous_rayon,
       (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash') as cash_tg,
       (select id from public.payment_methods where country_code = 'GH' and provider_code = 'cash') as cash_gh,
       (select id from public.payment_methods where country_code = 'TG' and operator_code = 'tmoney') as tmoney;
grant select on _t to authenticated, anonymous;

-- Awa est cliente : pas de boutique.
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select throws_ok($$select public.start_store('Chez Awa')$$, '42501', null,
  'cliente sans rôle vendeuse : création refusée');

-- Esi est vendeuse.
select tests.login_as((select esi from _t));
select public.complete_profile('Esi', (select tokoin from _t), 'vendor');

select is(public.my_store(), null, 'pas encore de boutique');
select lives_ok($$select public.start_store('Les jus d''Esi', 'Jus préparés chaque matin')$$,
  'étape 1 : boutique en brouillon');
select is((public.my_store() ->> 'status'), 'draft', 'statut brouillon');
select is((public.my_store() ->> 'onboarding_step')::int, 2, 'reprise : étape 2');
select lives_ok($$select public.start_store('Les jus d''Esi')$$,
  'seconde création : reprend la même boutique');

select throws_ok($$select public.publish_store()$$, 'P0001', null,
  'ouverture incomplète refusée');

select lives_ok($$select public.update_store('{"origin": "maison", "onboarding_step": 3}')$$,
  'étape 2 : origine');
select throws_ok($$select public.update_store('{"origin": "inventee"}')$$, '22023', null,
  'origine inconnue refusée');
select lives_ok(format($$select public.update_store('{"zone_id": "%s", "onboarding_step": 4}')$$,
  (select tokoin from _t)), 'étape 3 : quartier');
select is((public.my_store() ->> 'country_code'), 'TG', 'pays déduit du quartier');
select is((public.my_store() ->> 'currency_code'), 'XOF', 'devise déduite du pays');
select lives_ok($$select public.set_store_pickup_address('Rue des Hibiscus, maison bleue', 'Derrière la pharmacie')$$,
  'étape 3 : adresse de ramassage');

select throws_ok(format($$select public.update_store('{"main_category_id": "%s"}')$$,
  (select sous_rayon from _t)), '22023', null, 'sous-rayon refusé comme rayon principal');
select lives_ok(format($$select public.update_store('{"main_category_id": "%s", "onboarding_step": 5}')$$,
  (select fait_maison from _t)), 'étape 4 : rayon principal');

select throws_ok(format($$select public.set_store_delivery_zones(array['%s'::uuid])$$,
  (select osu from _t)), '22023', null, 'quartier d''une autre ville refusé');
select lives_ok(format($$select public.set_store_delivery_zones(array['%s'::uuid, '%s'::uuid])$$,
  (select tokoin from _t), (select be from _t)), 'étape 5 : quartiers desservis');

select throws_ok(format($$select public.set_store_payment_methods(array['%s'::uuid])$$,
  (select tmoney from _t)), '22023', null, 'Mobile Money inactif refusé');
select throws_ok(format($$select public.set_store_payment_methods(array['%s'::uuid])$$,
  (select cash_gh from _t)), '22023', null, 'moyen de paiement d''un autre pays refusé');

select is(jsonb_array_length(public.store_payment_options()), 3,
  'étape 6 : les 3 moyens du Togo, inactifs compris');
select is((select o->>'is_available' from jsonb_array_elements(public.store_payment_options()) o
            where o->>'operator_code' = 'tmoney'), 'false', 'T-Money proposé « Bientôt »');
select is((select o->>'is_available' from jsonb_array_elements(public.store_payment_options()) o
            where o->>'provider_code' = 'cash'), 'true', 'cash disponible');

select throws_ok(
  $$select public.set_store_hours('[{"weekday": 1, "opens_at": "19:00", "closes_at": "07:00"}]')$$,
  '23514', null, 'horaires inversés refusés');

select * from finish();
