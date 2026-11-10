-- Créateurs et contenus de tous (spec 036).

select plan(14);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       (select id from public.content_categories where slug = 'recettes') as recettes,
       '32000000-0000-4000-8000-000000000001'::uuid as tomate,
       '32000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '32100000-0000-4000-8000-000000000001'::uuid as post1,
       '32100000-0000-4000-8000-000000000002'::uuid as post2,
       null::uuid as kodjo_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 10))));
select public.publish_product((select tomate from _t));

select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');

-- Pas encore créatrice : publication refusée ; puis profil ouvert.
select throws_ok($$select public.save_creator_content(jsonb_build_object('id', (select post1 from _t),
  'media_key', 'creators/' || (select awa from _t) || '/contents/' || (select post1 from _t) || '.jpg'))$$,
  '42501', 'not_creator', 'il faut un profil créateur');
select throws_ok($$select public.become_creator('A')$$, '22023', 'invalid_name', 'nom trop court refusé');
select is(public.become_creator('  Awa   cuisine ', 'Recettes de Lomé') ->> 'display_name', 'Awa cuisine',
  'profil créateur ouvert');
select tests.logout();
select ok(exists (select 1 from public.user_roles where user_id = (select awa from _t) and role = 'creator'),
  'rôle créateur accordé');

-- Publication : média dans son dossier, catégorie choisie, produit d'une autre boutique tagué.
select tests.login_as((select awa from _t));
select throws_ok($$select public.save_creator_content(jsonb_build_object('id', (select post1 from _t),
  'media_key', 'creators/' || (select ama from _t) || '/contents/' || (select post1 from _t) || '.jpg'))$$,
  '22023', 'invalid_media', 'dossier d''une autre personne refusé');
select is(public.save_creator_content(jsonb_build_object('id', (select post1 from _t), 'kind', 'post',
  'media_key', 'creators/' || (select awa from _t) || '/contents/' || (select post1 from _t) || '.jpg',
  'caption', 'Sauce tomate de grand-mère', 'category_id', (select recettes from _t),
  'product_ids', jsonb_build_array((select tomate from _t)))) -> 'author' ->> 'display_name', 'Awa cuisine',
  'post publié au nom de la créatrice');
select is(public.save_creator_content(jsonb_build_object('id', (select post2 from _t), 'kind', 'video',
  'media_key', 'creators/' || (select awa from _t) || '/contents/' || (select post2 from _t) || '.mp4',
  'caption', 'Au marché')) -> 'category' ->> 'slug', 'autre', 'sans catégorie : « Autre »');
select throws_ok($$select public.save_creator_content(jsonb_build_object('id', gen_random_uuid(),
  'media_key', 'creators/' || (select awa from _t) || '/contents/x.jpg', 'category_id', gen_random_uuid()))$$,
  '22023', null, 'catégorie ou clé inconnue refusée');
select is(jsonb_array_length(public.my_creator_contents()), 2, 'mes posts');

-- Fil : visibles dans le pays, avec le produit tagué ; un post photo est accepté.
select tests.login_as((select ama from _t));
select is((select count(*)::int from jsonb_array_elements(public.content_feed((select be from _t))) f
           where f -> 'author' ->> 'display_name' = 'Awa cuisine'), 2, 'posts dans le fil du quartier');
select is((select f -> 'products' -> 0 ->> 'id' from jsonb_array_elements(public.content_feed((select be from _t))) f
           where f ->> 'id' = (select post1 from _t)::text), (select tomate from _t)::text, 'produit tagué achetable');
select throws_ok(format($$select public.archive_content('%s')$$, (select post1 from _t)), 'P0002', null,
  'archive d''autrui refusée');

-- L'autrice archive ; la modération voit le nom de la créatrice.
select tests.login_as((select awa from _t));
select public.archive_content((select post2 from _t));
select tests.logout();
select is((select status from public.contents where id = (select post2 from _t)), 'archived', 'archivé par l''autrice');
select is(app.content_classifier_context((select awa from _t)) -> 'categories' -> 0 ->> 'slug', 'recettes',
  'classement IA : catégories du référentiel');

select * from finish();
