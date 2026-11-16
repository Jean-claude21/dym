-- Carte DYM (spec 095) : boutiques d'un cadre, filtres ouvertes et catégorie, lecture publique.

select plan(7);

update public.countries set is_active = false where code <> 'TG';

create temporary table _t as
select tests.create_user('ama@example.com') as ama,
       tests.create_user('kossi@example.com') as kossi,
       null::uuid as store,
       null::uuid as other;
update _t set store = tests.open_store(ama, 'Chez Ama', 'tokoin');
update _t set other = tests.open_store(kossi, 'Chez Kossi', 'agoe');
-- Kossi ferme : sa boutique reste sur la carte, grisée, mais pas avec « ouvertes ».
update public.stores set is_open = false where id = (select other from _t);
grant select on _t to authenticated, anonymous;

-- Visiteuse sans compte : le cadre de Lomé montre les deux boutiques.
select tests.login_anonymous();
select is((select count(*)::int from jsonb_array_elements(public.map_stores(5.9, 1.0, 6.4, 1.5)) s
           where (s ->> 'id')::uuid in ((select store from _t), (select other from _t))), 2,
          'cadre de Lomé : deux boutiques, lecture sans compte');
select ok((select bool_and(s ? 'latitude' and s ? 'origin' and s ? 'open_now')
           from jsonb_array_elements(public.map_stores(5.9, 1.0, 6.4, 1.5)) s),
          'chaque boutique porte sa position, son origine et son état');
select is(jsonb_array_length(public.map_stores(48.0, 2.0, 49.0, 3.0)) , 0,
          'cadre sans boutique : liste vide');
select is(public.map_stores(10, 1, 5, 2), '[]'::jsonb, 'cadre invalide : liste vide');
select ok(not exists (select 1 from jsonb_array_elements(public.map_stores(5.9, 1.0, 6.4, 1.5, null, true)) s
                      where (s ->> 'id')::uuid = (select other from _t)),
          'filtre « ouvertes » : la boutique fermée disparaît');
select ok(exists (select 1 from jsonb_array_elements(public.map_stores(
                    5.9, 1.0, 6.4, 1.5, (select id from public.categories where slug = 'fait-maison'))) s
                  where (s ->> 'id')::uuid = (select store from _t)),
          'filtre catégorie : catégorie principale retenue');
select tests.logout();

-- Pays désactivé : ses boutiques quittent la carte.
update public.countries set is_active = false where code = 'TG';
select is(jsonb_array_length(public.map_stores(5.9, 1.0, 6.4, 1.5)), 0, 'pays inactif : rien sur la carte');

select * from finish();
