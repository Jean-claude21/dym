-- Spec 018 : historique, suggestions, contexte et journal de la recherche IA.

select plan(24);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('mariam@example.com') as mariam,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       null::uuid as kodjo_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates fraîches', 'category_id', (select tomates from _t),
  'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t)))));
select public.publish_product((select tomate from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.login_as((select mariam from _t));
select public.complete_profile('Mariam', (select be from _t), 'client');

-- Historique : propre à chaque personne, remonté, borné, effaçable.
select tests.login_as((select awa from _t));
select lives_ok($$select public.remember_search('tomates', 'text')$$, 'recherche retenue');
select public.remember_search('  gombo   frais ', 'voice');
select public.remember_search('x', 'text');
select is(jsonb_array_length(public.my_searches()), 2, 'texte trop court ignoré');
select is(public.my_searches() -> 0 ->> 'query', 'gombo frais', 'espaces normalisés, plus récente d''abord');
select is(public.my_searches() -> 0 ->> 'source', 'voice', 'source conservée');
select public.remember_search('TOMATES', 'photo');
select is(jsonb_array_length(public.my_searches()), 2, 'doublon (casse) remonté, pas dupliqué');
select is(public.my_searches() -> 0 ->> 'query', 'TOMATES', 'doublon remonté en tête');
select throws_ok($$select public.remember_search('piment', 'radio')$$, '22023', null, 'source inconnue');
select tests.login_as((select mariam from _t));
select is(jsonb_array_length(public.my_searches()), 0, 'historique d''autrui invisible');
select throws_ok($$select * from public.search_history$$, '42501', null, 'table fermée');
select tests.login_as((select awa from _t));
do $$ begin
  for i in 1..25 loop perform public.remember_search('produit ' || i); end loop;
end $$;
select is(jsonb_array_length(public.my_searches(50)), 20, '20 recherches au plus');
select public.forget_searches();
select is(jsonb_array_length(public.my_searches()), 0, 'historique effacé');
select tests.logout();
select throws_ok($$select public.remember_search('tomates')$$, '42501', null, 'session requise');

-- Suggestions : rayons et produits en vente, pour un mot qui commence ainsi.
select ok(public.search_suggestions('tom', (select be from _t)) @> '[{"kind": "product", "label": {"fr": "Tomates fraîches"}}]',
  'produit suggéré (anonyme)');
select ok(public.search_suggestions('fra', (select be from _t)) @> '[{"label": {"fr": "Tomates fraîches"}}]',
  'mot intérieur reconnu');
select ok(public.search_suggestions('tom', (select be from _t)) @> '[{"kind": "category"}]', 'rayon suggéré');
select is(public.search_suggestions('', (select be from _t)), '[]'::jsonb, 'rien sans texte');
select is(public.search_suggestions('%', (select be from _t)), '[]'::jsonb, 'joker échappé');
select ok(jsonb_array_length(public.search_suggestions('t', null)) <= 8, '8 suggestions au plus');

-- Contexte IA : flag coupé par défaut, puis ouvert pour le pays.
-- Base partagée (staging) : seuls les flags globaux comptent ici.
delete from public.feature_flags where key = 'ai_search' and country_code is not null;
select throws_ok($$select app.search_ai_context((select awa from _t), 'search_transcription')$$,
  'P0001', 'feature_disabled', 'flag coupé : refusé');
update public.feature_flags set is_enabled = true where key = 'ai_search' and country_code is null;
select is(app.search_ai_context((select awa from _t), 'search_transcription') -> 'model' ->> 'model',
  'gpt-4o-mini-transcribe', 'modèle configuré en base');
insert into public.feature_flags (key, country_code, is_enabled, description)
values ('ai_search', 'TG', false, 'Coupé pour ce pays');
select throws_ok($$select app.search_ai_context((select awa from _t), 'search_from_photo')$$,
  'P0001', 'feature_disabled', 'flag du pays prioritaire');
select throws_ok($$select app.search_ai_context((select awa from _t), 'chat')$$, '22023', null, 'usage inconnu');

-- Journal des requêtes IA, sans contenu ; événement serveur.
select app.record_ai_request((select awa from _t), 'search_from_photo', 'no_result', 1200);
select is((select outcome from public.ai_requests where user_id = (select awa from _t)), 'no_result',
  'requête journalisée');
select is((select props ->> 'outcome' from public.events where name = 'photo_search_used'
           and actor_id = (select awa from _t)), 'no_result', 'événement serveur');

select * from finish();
