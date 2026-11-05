-- Spec 019 : choix des produits, chiffrage serveur, flag, événements.

select plan(17);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('afi@example.com') as afi,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as cat,
       '31000000-0000-4000-8000-000000000001'::uuid as tomate,
       '31000000-0000-4000-8000-000000000002'::uuid as tomate_v,
       '32000000-0000-4000-8000-000000000001'::uuid as gombo_k,
       '32000000-0000-4000-8000-000000000002'::uuid as gombo_k_v,
       '33000000-0000-4000-8000-000000000001'::uuid as gombo_a,
       '33000000-0000-4000-8000-000000000002'::uuid as gombo_a_v,
       null::uuid as kodjo_store, null::uuid as afi_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be'),
              afi_store = tests.open_store(afi, 'Chez Afi', 'be');
grant select, update on _t to authenticated, anonymous;

create function pg_temp.product(p_store uuid, p_id uuid, p_variant uuid, p_name text, p_price int)
returns void language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', (select cat from _t), 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || p_store || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp.product(uuid, uuid, uuid, text, int) to authenticated;

select tests.login_as((select kodjo from _t));
select pg_temp.product((select kodjo_store from _t), (select tomate from _t), (select tomate_v from _t),
  'Tomates fraîches', 500);
select pg_temp.product((select kodjo_store from _t), (select gombo_k from _t), (select gombo_k_v from _t),
  'Gombo frais', 400);
select tests.login_as((select afi from _t));
select pg_temp.product((select afi_store from _t), (select gombo_a from _t), (select gombo_a_v from _t),
  'Gombo frais', 300);
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.logout();

-- Choix : boutique déjà retenue d'abord, puis le prix ; manquants nommés.
create temporary table _p as select app.copilot_pick((select be from _t), jsonb_build_array(
  jsonb_build_object('label', 'Tomates', 'query', 'tomates', 'quantity', 2),
  jsonb_build_object('label', 'Gombo', 'query', 'gombo', 'quantity', 1),
  jsonb_build_object('label', 'Crevettes séchées', 'query', 'crevettes séchées', 'quantity', 1))) as p;
grant select on _p to authenticated, anonymous;
select is((select (p ->> 'item_count')::int from _p), 2, 'deux besoins trouvés');
select is((select jsonb_array_length(p -> 'stores') from _p), 1, 'une seule boutique : regroupement');
select is((select p -> 'stores' -> 0 ->> 'name' from _p), 'Étal de Kodjo', 'boutique déjà retenue préférée');
select is((select p -> 'missing' from _p), '["Crevettes séchées"]'::jsonb, 'manquant nommé');
select is((select (p ->> 'total_minor')::int from _p), 2 * 500 + 400, 'total chiffré en base');
select is((select p -> 'stores' -> 0 -> 'items' -> 0 ->> 'need' from _p), 'Tomates', 'besoin conservé');

-- Seul besoin : le moins cher l'emporte.
select is(app.copilot_pick((select be from _t), '[{"label": "Gombo", "query": "gombo"}]') -> 'stores' -> 0 ->> 'name',
  'Chez Afi', 'à pertinence égale : le moins cher');
select is(app.copilot_pick((select be from _t), '[{"label": "Rien", "query": "zzzz"}]') ->> 'item_count',
  '0', 'rien trouvé : aucun article inventé');

-- Rechiffrage : quantité bornée, ligne invalide écartée, session requise.
select tests.login_as((select awa from _t));
select is((public.copilot_quote(jsonb_build_array(
  jsonb_build_object('variant_id', (select tomate_v from _t), 'quantity', 50),
  jsonb_build_object('variant_id', gen_random_uuid(), 'quantity', 1))) ->> 'total_minor')::int,
  10 * 500, 'quantité bornée à 10, inconnue écartée');
select throws_ok($$select public.copilot_quote((select jsonb_agg(jsonb_build_object('variant_id', gen_random_uuid()))
  from generate_series(1, 11)))$$, '22023', null, '10 lignes au plus');
select tests.logout();
update public.products set is_available = false where id = (select gombo_k from _t);
select tests.login_as((select awa from _t));
select is((public.copilot_quote(jsonb_build_array(
  jsonb_build_object('variant_id', (select gombo_k_v from _t), 'quantity', 1))) ->> 'item_count')::int,
  0, 'produit devenu indisponible écarté');
select tests.logout();
select throws_ok($$select public.copilot_quote('[]')$$, '42501', null, 'session requise');

-- Contexte : flag coupé par défaut, quartier d'un autre pays refusé.
-- Base partagée (staging) : seuls les flags globaux comptent ici.
delete from public.feature_flags where key = 'intent_copilot' and country_code is not null;
select throws_ok($$select app.copilot_context((select awa from _t), (select be from _t))$$,
  'P0001', 'feature_disabled', 'flag coupé : refusé');
update public.feature_flags set is_enabled = true where key = 'intent_copilot' and country_code is null;
select is(app.copilot_context((select awa from _t), (select be from _t)) -> 'model' ->> 'model',
  'gpt-5.4-mini', 'modèle configuré en base');
select throws_ok($$select app.copilot_context((select awa from _t), gen_random_uuid())$$,
  '22023', null, 'quartier inconnu');

-- Événement : comptes seulement.
select app.copilot_proposed((select awa from _t), (select p from _p), 900);
select is((select props from public.events where name = 'copilot_proposed' and actor_id = (select awa from _t)),
  '{"items_count": 2, "stores_count": 1, "missing_count": 1, "latency_ms": 900}'::jsonb, 'comptes sans texte');
select is((select outcome from public.ai_requests where user_id = (select awa from _t) and usage = 'intent_copilot'),
  'success', 'requête journalisée');

select * from finish();
