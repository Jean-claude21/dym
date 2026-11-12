-- Rayon de service par ville (spec 065) : position couverte ou non, rayon
-- réglé par l'équipe (journalisé), positions hors zone comptées par pays.

select plan(10);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('admin@example.com') as admin,
       (select id from public.cities where slug = 'lome') as lome;
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select on _t to authenticated, anonymous;

select tests.login_anonymous();

select is(public.nearest_zone(6.131, 1.240, 'TG') ->> 'covered', 'true',
  'à côté de Bè : position couverte');

-- Ouest de Lomé, à environ 19 km d'Adidogomé : hors du rayon par défaut (15 km).
select is(public.nearest_zone(6.13, 1.0, 'TG') ->> 'covered', 'false',
  'à 19 km du quartier le plus proche : hors zone');
select ok((public.nearest_zone(6.13, 1.0, 'TG') ->> 'distance_m')::int > 15000,
  'la distance est renvoyée');
select is(public.nearest_zone(6.13, 1.0, 'TG') ->> 'service_radius_m', '15000',
  'le rayon de la ville est renvoyé');

select tests.login_as((select awa from _t));
select throws_ok('select public.admin_coverage()', '42501', null,
  'sans rôle : pas de statistiques de couverture');
select lives_ok(
  $$select public.track_event('location_outside_coverage', 'client', '65000000-0000-4000-8000-000000000001',
      'TG', null, null, '{"distance_km": 19, "app": "client"}')$$,
  'l''app signale une position hors zone (sans coordonnées)');

select tests.login_as((select admin from _t));
select throws_ok(
  format($$select public.admin_save_city(jsonb_build_object('id', %L, 'service_radius_m', 500000))$$,
    (select lome from _t)),
  '23514', null, 'rayon au-delà de 200 km refusé');

select lives_ok(
  format($$select public.admin_save_city(jsonb_build_object('id', %L, 'service_radius_m', 20000))$$,
    (select lome from _t)),
  'l''équipe élargit le rayon de Lomé à 20 km');

select is(public.nearest_zone(6.13, 1.0, 'TG') ->> 'covered', 'true',
  'avec 20 km, la même position est couverte');

select is(public.admin_coverage('week') -> 'countries' -> 0,
  '{"country_code": "TG", "misses": 1, "median_km": 19}'::jsonb,
  'une position hors zone comptée pour le Togo, distance médiane');

select * from finish();
