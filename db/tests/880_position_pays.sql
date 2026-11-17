-- La position décide du pays (spec 110) : changer de lieu vers un autre pays, panier signalé et vidé.

select plan(7);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select z.id from public.zones z join public.cities c on c.id = z.city_id
        where c.country_code = 'FR' and z.is_active order by z.name limit 1) as fr_zone,
       null::uuid as store;
update _t set store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

-- La France est ouverte sur cet environnement de test : ville visible.
update public.countries set is_active = true where code = 'FR';
update public.cities set is_active = true where country_code = 'FR';

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');

-- Un produit de Lomé dans le panier.
select tests.logout();
insert into public.products (id, store_id, name, currency_code, status)
select '88000000-0000-4000-8000-000000000001', store, 'Tomates', 'XOF', 'published' from _t;
insert into public.product_variants (id, product_id, price_minor, stock_quantity)
values ('88000000-0000-4000-8000-000000000002', '88000000-0000-4000-8000-000000000001', 500, 10);
select tests.login_as((select awa from _t));
select public.cart_add('88000000-0000-4000-8000-000000000002', 1);

-- Awa est à Rouen : elle passe en France.
select is(public.set_my_place((select fr_zone from _t)) ->> 'country_code', 'FR', 'le pays suit le lieu');
select is((select country_code::text from public.profiles where user_id = (select awa from _t)), 'FR', 'profil en France');
select is(public.set_my_place((select fr_zone from _t)) ->> 'cart_country', 'TG', 'panier de Lomé signalé');
select tests.logout();
select is((select count(*)::int from public.events where name = 'place_changed'), 1, 'changement de pays tracé une fois');

-- Elle vide son panier de Lomé.
select tests.login_as((select awa from _t));
select public.cart_clear();
select is((public.set_my_place((select fr_zone from _t)) ->> 'cart_items')::int, 0, 'panier vidé');

select throws_ok($$select public.set_my_place(gen_random_uuid())$$, 'P0002', null, 'quartier inconnu refusé');
select tests.logout();
select throws_ok(format($$select public.set_my_place(%L)$$, (select be from _t)), '42501', null, 'session requise');

select * from finish();
