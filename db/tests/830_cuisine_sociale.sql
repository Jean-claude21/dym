-- Cuisine sociale (spec 101) : profils publics, fil « Près de moi », « Mes recettes »,
-- « J'ai fait la recette », vidéo adaptative suivie par les Functions.

select plan(11);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       '83000000-0000-4000-8000-000000000001'::uuid as recipe,
       '83000000-0000-4000-8000-000000000002'::uuid as store_video,
       null::uuid as kodjo_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.become_creator('Awa cuisine');
select tests.logout();
insert into public.contents (id, author_id, kind, media_key, media_type, caption, category_id, category_source)
select recipe, awa, 'video', 'creators/' || awa || '/contents/' || recipe || '.mp4', 'video', 'Sauce gombo',
       (select id from public.content_categories where slug = 'recettes'), 'chosen' from _t;
insert into public.contents (id, store_id, kind, media_key, media_type, caption)
select store_video, kodjo_store, 'video', 'stores/' || kodjo_store || '/contents/' || store_video || '.mp4', 'video',
       'Arrivage du jour' from _t;

-- Profil public de la créatrice : lisible sans compte.
select tests.login_anonymous();
select is(public.content_profile('creator', (select awa from _t)) ->> 'name', 'Awa cuisine', 'profil de créatrice');
select is(jsonb_array_length(public.content_profile('creator', (select awa from _t)) -> 'contents'), 1,
  'ses contenus');
select is(public.content_profile('store', (select kodjo_store from _t)) ->> 'name', 'Étal de Kodjo', 'profil de boutique');

-- Ama suit Awa, enregistre la recette et l'a faite.
select tests.login_as((select ama from _t));
select public.follow('creator', (select awa from _t), true);
select is((public.content_profile('creator', (select awa from _t)) ->> 'followers')::int, 1, 'une abonnée');
select is((public.toggle_save_content((select recipe from _t), true) ->> 'saved')::boolean, true, 'recette enregistrée');
select is(jsonb_array_length(public.my_saved_contents()), 1, '« Mes recettes »');
select is((public.i_cooked_it((select recipe from _t), 'Délicieux !') ->> 'cook_count')::int, 1,
  '« J''ai fait la recette »');
select tests.logout();
select is((select count(*)::int from public.notifications where user_id = (select awa from _t)
           and kind = 'recipe_cooked'), 1, 'la créatrice est prévenue');

-- « Près de moi » : la vidéo de la boutique qui livre le quartier, pas la créatrice.
select tests.login_as((select ama from _t));
select ok(not exists (select 1 from jsonb_array_elements(public.content_feed_ranked((select be from _t), 'near')) c
                      where (c ->> 'id')::uuid = (select recipe from _t))
          and exists (select 1 from jsonb_array_elements(public.content_feed_ranked((select be from _t), 'near')) c
                      where (c ->> 'id')::uuid = (select store_video from _t)),
          'près de moi : boutiques qui livrent ici');

-- Vidéo adaptative : en attente, puis prête avec son adresse HLS.
select tests.logout();
select ok(exists (select 1 from jsonb_array_elements(app.stream_pending(10)) s
                  where (s ->> 'id')::uuid = (select recipe from _t)), 'vidéo à envoyer au fournisseur');
select app.set_stream((select recipe from _t), '0f8fad5b-d9cb-469f-a165-70867728950e', 'ready',
  'https://cdn.example/0f8fad5b-d9cb-469f-a165-70867728950e/playlist.m3u8');
select is(app.content_json((select recipe from _t), null) ->> 'stream_url',
  'https://cdn.example/0f8fad5b-d9cb-469f-a165-70867728950e/playlist.m3u8', 'lecture HLS prête');

select * from finish();
