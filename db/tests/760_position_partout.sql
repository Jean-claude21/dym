-- Tout par position (spec 094) : distance, rayon de livraison, découverte par position,
-- couverture hors des villes configurées.

select plan(10);

update public.countries set is_active = false where code <> 'TG';

create temporary table _t as
select tests.create_user('ama@example.com') as ama,
       (select id from public.zones where slug = 'tokoin') as tokoin,
       (select id from public.zones where slug = 'agoe') as agoe,
       null::uuid as store;
update _t set store = tests.open_store(ama, 'Chez Ama', 'tokoin');
grant select on _t to authenticated, anonymous;

-- Distance : nulle sur place, Tokoin–Agoè entre 5 et 12 km.
select is(round(app.distance_m(6.152, 1.218, 6.152, 1.218))::int, 0, 'distance nulle sur place');
select ok((select app.distance_m(a.latitude, a.longitude, b.latitude, b.longitude) between 5000 and 12000
           from public.zones a, public.zones b where a.slug = 'tokoin' and b.slug = 'agoe'),
          'distance Tokoin–Agoè plausible');

-- Rayon par défaut et service par position.
select is((select delivery_radius_m from public.stores where id = (select store from _t)), 5000,
          'rayon de livraison : 5 km par défaut');
select ok(app.store_serves_point((select store from _t), 6.153, 1.219), 'point voisin servi');
select ok(not app.store_serves_point((select store from _t), 6.45, 1.218), 'point à 30 km non servi');
select ok(not app.store_serves((select store from _t), (select agoe from _t)),
          'Agoè (8 km, non coché) hors du rayon de 5 km');

-- La vendeuse élargit son rayon : Agoè est servi sans être coché.
select tests.login_as((select ama from _t));
select lives_ok($$ select public.update_store('{"delivery_radius_m": 20000}') $$, 'rayon porté à 20 km');
select throws_ok($$ select public.update_store('{"delivery_radius_m": 100}') $$, '23514', null,
                 'rayon trop petit refusé');
select tests.logout();
select ok(app.store_serves((select store from _t), (select agoe from _t)), 'Agoè servi par le rayon');

-- Visiteuse sans compte, position seule : la boutique apparaît avec sa distance.
select tests.login_anonymous();
select ok((select (s ->> 'distance_m')::int between 0 and 2000
           from jsonb_array_elements(
             public.discover_stores(null, 20, now(), 6.153, 1.219) -> 'stores') s
           where (s ->> 'id')::uuid = (select store from _t)),
          'découverte par position : boutique trouvée, distance donnée');
select tests.logout();

select * from finish();
