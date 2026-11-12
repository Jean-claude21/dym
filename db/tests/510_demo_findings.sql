-- Corrections de la démonstration web (phases 7 à 13).

select plan(12);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('awa@example.com') as awa,
       tests.create_user('efua@example.com') as efua,
       tests.create_user('chef@example.com') as chef,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       '51000000-0000-4000-8000-000000000001'::uuid as gari,
       '51000000-0000-4000-8000-000000000002'::uuid as gari_tas,
       '51000000-0000-4000-8000-000000000003'::uuid as farine,
       '51000000-0000-4000-8000-000000000004'::uuid as farine_kg,
       '51000000-0000-4000-8000-000000000005'::uuid as post,
       null::uuid as kodjo_store, null::uuid as offer, null::text as code, null::text as qr, null::uuid as order1,
       (select id from public.membership_plans where country_code = 'TG' and code = 'featured_week') as featured;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
insert into public.user_roles (user_id, role) select chef, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

create function pg_temp._publish(p_id uuid, p_variant uuid, p_name text) returns void
language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', (select id from public.categories where slug = 'tomates'),
    'price_minor', 1000,
    'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', 20))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, text) to authenticated;

create function pg_temp._source(p_variant uuid) returns text language sql as $$
  select l ->> 'price_source'
  from jsonb_array_elements(public.my_cart(p_at => (select morning from _t)) -> 'stores') s,
       jsonb_array_elements(s -> 'lines') l
  where (l ->> 'variant_id')::uuid = p_variant
$$;
grant execute on function pg_temp._source(uuid) to authenticated;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select pg_temp._publish((select gari from _t), (select gari_tas from _t), 'Gari');
select pg_temp._publish((select farine from _t), (select farine_kg from _t), 'Farine de gari');
select public.set_haggle_limit(20);
update _t set offer = (public.create_group_offer((select farine from _t), 700, 2) ->> 'id')::uuid;

-- 1. Source du prix : marché conclu d'un côté, prix de groupe de l'autre.
select tests.login_as((select efua from _t));
select public.complete_profile('Efua', (select be from _t), 'client');
select public.join_group_offer((select offer from _t), 1);
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.propose_haggle((select gari_tas from _t), 1, 900);
select public.join_group_offer((select offer from _t), 1);
select public.cart_add((select farine_kg from _t), 1);
select is(pg_temp._source((select gari_tas from _t)), 'haggle', 'prix marchandé');
select is(pg_temp._source((select farine_kg from _t)), 'group', 'prix de groupe');

-- 4. Recherche : le nom exact passe devant.
select is(public.search_catalog('gari', (select be from _t)) -> 'products' -> 0 ->> 'name', 'Gari',
  'nom exact en tête');

-- 2. Lien de partage : vue ; ajout au panier depuis le post : clic.
select public.become_creator('Awa cuisine');
select public.save_creator_content(jsonb_build_object('id', (select post from _t), 'kind', 'post',
  'media_key', 'creators/' || (select awa from _t) || '/contents/' || (select post from _t) || '.jpg',
  'caption', 'Gari du matin'));
update _t set code = public.create_share_link((select post from _t));
select tests.login_as((select efua from _t));
select public.open_share_link((select code from _t));
select public.content_touch((select post from _t), array[(select gari_tas from _t)]);
select tests.logout();
select is((select view_count from public.contents where id = (select post from _t)), 1, 'ouverture : une vue');
select is((select click_count from public.contents where id = (select post from _t)), 1, 'ajout au panier : un clic');

-- 3. Mission du livreur : cash à encaisser (paiement à la livraison).
create temporary table _p as select app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')), (select morning from _t)) as r;
update _t set order1 = (select id from public.orders where purchase_id = (select (r -> 'purchase' ->> 'id')::uuid from _p));
select ok((select order1 from _t) is not null, 'commande cash créée');
select is((app.mission_json((select order1 from _t), null) ->> 'cash_to_collect_minor')::bigint,
  (select total_minor from public.orders where id = (select order1 from _t)), 'cash à encaisser');
select ok(app.mission_json((select order1 from _t), null) ? 'scheduled_start', 'créneau exposé');

-- 5. Formule vendeuse payée depuis le solde de la boutique (vente QR), wallet intact.
select tests.login_as((select kodjo from _t));
update _t set qr = public.create_payment_request(3000, gen_random_uuid()) ->> 'code';
select tests.login_as((select awa from _t));
select public.wallet_topup_simulated(3000, gen_random_uuid());
select public.pay_payment_request((select qr from _t), gen_random_uuid());
select tests.login_as((select kodjo from _t));
select is((public.membership_offer('vendor') ->> 'store_balance_minor')::bigint, 3000::bigint, 'solde de la boutique');
select ok(public.subscribe_plan((select featured from _t), gen_random_uuid()) ->> 'store_balance_minor' = '2000', 'payée depuis la boutique');
select is((public.membership_offer('vendor') ->> 'wallet_balance_minor')::bigint, 0::bigint, 'wallet intact');

-- 6. Admins : l'admin connecté est signalé.
select tests.login_as((select chef from _t));
select is((select a ->> 'is_me' from jsonb_array_elements(public.admin_admins()) a
           where (a ->> 'user_id')::uuid = (select chef from _t)), 'true', 'admin connecté signalé');
select tests.logout();

select * from finish();
