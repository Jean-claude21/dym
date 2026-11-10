-- Recherche et classement réglables (spec 028) : noms locaux, poids, raison du choix, admin.

select plan(10);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('esi@example.com') as esi,
       tests.create_user('admin@example.com') as admin,
       tests.create_user('awa@example.com') as awa,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       null::uuid as kodjo_store, null::uuid as esi_store,
       '31000000-0000-4000-8000-000000000001'::uuid as epinard,
       '32000000-0000-4000-8000-000000000001'::uuid as tomate_k,
       '33000000-0000-4000-8000-000000000001'::uuid as tomate_e;
-- Kodjo est dans le quartier de la cliente (Bè) ; Esi livre Bè depuis Tokoin.
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be'),
              esi_store = tests.open_store(esi, 'Chez Esi', 'tokoin');
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select on _t to authenticated, anonymous;

create function pg_temp._publish(p_store uuid, p_id uuid, p_name text, p_price bigint) returns void
language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', (select tomates from _t), 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || p_store || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', gen_random_uuid(), 'stock_quantity', 10))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, text, bigint) to authenticated;

select tests.login_as((select kodjo from _t));
select pg_temp._publish((select kodjo_store from _t), (select epinard from _t), 'Épinards du jardin', 300);
select pg_temp._publish((select kodjo_store from _t), (select tomate_k from _t), 'Tomates fraîches', 900);
select tests.login_as((select esi from _t));
select public.set_store_delivery_zones(array[(select id from public.zones where slug = 'tokoin'), (select be from _t)]);
select pg_temp._publish((select esi_store from _t), (select tomate_e from _t), 'Tomates du marché', 400);
select tests.logout();

-- Nom local : « gboma » trouve les épinards.
select tests.login_anonymous();
select is(public.search_catalog('gboma', (select be from _t)) -> 'products' -> 0 ->> 'id',
  (select epinard from _t)::text, 'nom local : gboma trouve les épinards');
select is((public.search_catalog('tomate', (select be from _t)) ->> 'total')::int, 2, 'recherche classique inchangée');
select tests.logout();

-- Poids par défaut : le texte et la proximité l'emportent ; une raison est donnée.
create temporary table _pick as
select app.copilot_pick((select be from _t), '[{"label": "Tomates", "query": "tomate", "quantity": 1}]') as r;
select ok((select r -> 'stores' -> 0 -> 'items' -> 0 ->> 'reason' from _pick) is not null, 'raison du choix renvoyée');

-- Tout sur le prix : la moins chère (Esi), raison « best_price ».
update public.ranking_rules set weight_text = 0, weight_same_store = 0, weight_open = 0,
  weight_rating = 0, weight_same_zone = 0, weight_price = 100 where country_code is null;
create temporary table _cheap as
select app.copilot_pick((select be from _t), '[{"label": "Tomates", "query": "tomate", "quantity": 1}]') as r;
select is((select r -> 'stores' -> 0 ->> 'id' from _cheap), (select esi_store from _t)::text, 'poids prix : la moins chère');
select is((select r -> 'stores' -> 0 -> 'items' -> 0 ->> 'reason' from _cheap), 'best_price', 'raison : meilleur prix');

-- Tout sur la proximité : celle du quartier (Kodjo).
update public.ranking_rules set weight_price = 0, weight_same_zone = 100 where country_code is null;
select is((app.copilot_pick((select be from _t), '[{"label": "Tomates", "query": "tomate", "quantity": 1}]')
           -> 'stores' -> 0 ->> 'id'), (select kodjo_store from _t)::text, 'poids quartier : la plus proche');

-- Admin : réservé, audité.
select tests.login_as((select awa from _t));
select throws_ok($$select public.admin_set_synonym('TG', 'lanman', array['oseille'])$$, '42501', null,
  'réglages de recherche réservés aux admins');
select tests.login_as((select admin from _t));
select ok(public.admin_set_synonym('TG', 'Lanman', array['oseille']) -> 'synonyms' @>
  '[{"term": "lanman"}]'::jsonb, 'synonyme ajouté (terme normalisé)');
select is((public.admin_set_ranking('TG', '{"weight_price": 70}') -> 'rules' -> 1 ->> 'weight_price')::int, 70,
  'poids du pays réglé');
select tests.logout();
select is((select count(*)::int from public.audit_log where action in ('ranking_set', 'synonym_set')), 2,
  'réglages audités');

select * from finish();
