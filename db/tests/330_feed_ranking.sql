-- Fil classé, abonnements et commentaires (spec 037).

select plan(15);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('admin@example.com') as admin,
       (select id from public.zones where slug = 'be') as be,
       '33000000-0000-4000-8000-000000000001'::uuid as a_post,
       '33000000-0000-4000-8000-000000000002'::uuid as b_video,
       null::uuid as kodjo_store, null::uuid as comment1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'tokoin');
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.set_store_delivery_zones(array[(select id from public.zones where slug = 'tokoin'), (select be from _t)]);
select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.become_creator('Awa cuisine');
select tests.logout();

-- A : post de créatrice, ancien (10 jours) mais engageant ; B : vidéo de boutique, 3 jours, sans interaction.
insert into public.contents (id, author_id, kind, media_key, media_type, caption, category_id, category_source,
                             created_at, view_count, click_count)
select a_post, awa, 'video', 'creators/' || awa || '/contents/' || a_post || '.mp4', 'video', 'Sauce gombo',
       (select id from public.content_categories where slug = 'recettes'), 'chosen',
       now() - interval '10 days', 10, 2 from _t;
insert into public.contents (id, store_id, kind, media_key, media_type, caption, created_at)
select b_video, kodjo_store, 'video', 'stores/' || kodjo_store || '/contents/' || b_video || '.mp4', 'video',
       'Arrivage', now() - interval '3 days' from _t;
insert into public.content_likes (content_id, user_id) select a_post, kodjo from _t;
insert into public.content_likes (content_id, user_id) select a_post, admin from _t;

-- Abonnement : Ama suit Awa ; on ne se suit pas soi-même.
select tests.login_as((select ama from _t));
select is(public.follow('creator', (select awa from _t), true), true, 'abonnée à la créatrice');
select tests.login_as((select awa from _t));
select throws_ok($$select public.follow('creator', (select awa from _t), true)$$, '22023', 'self_follow',
  'pas d''abonnement à soi-même');

-- Classement : suivi et engageant passe devant l'ancien sans interaction.
select tests.login_as((select ama from _t));
select is(public.content_feed_ranked((select be from _t)) -> 0 ->> 'id', (select a_post from _t)::text,
  'pour toi : contenu suivi et engageant en tête');
select is((public.content_feed_ranked((select be from _t)) -> 0 ->> 'followed')::boolean, true,
  'abonnement signalé dans le fil');
select is(jsonb_array_length(public.content_feed_ranked((select be from _t), 'following')), 1,
  'abonnements : seulement les contenus suivis');
select is(public.content_feed_ranked((select be from _t), 'for_you', 'recettes') -> 0 ->> 'id',
  (select a_post from _t)::text, 'filtre par catégorie');
select is(jsonb_array_length(public.content_feed_ranked((select be from _t), 'for_you', 'astuces')), 0,
  'catégorie vide');
select is(jsonb_array_length(public.content_feed_ranked((select be from _t), 'for_you', null, 1)), 1,
  'pagination par décalage');

-- Poids : tout sur la fraîcheur, le plus récent passe devant.
select tests.logout();
update public.feed_ranking_rules set weight_engagement = 0, weight_followed = 0, weight_local = 0,
  weight_affinity = 0, weight_shoppable = 0 where country_code is null;
select tests.login_as((select ama from _t));
select is(public.content_feed_ranked((select be from _t)) -> 0 ->> 'id', (select b_video from _t)::text,
  'poids réglés : la fraîcheur l''emporte');

-- Commentaires : un seul par clé, compté, supprimable par son autrice seulement.
select public.add_comment((select a_post from _t), 'Merci pour la recette !', '33100000-0000-4000-8000-000000000001');
select is(jsonb_array_length(public.add_comment((select a_post from _t), 'Merci pour la recette !',
  '33100000-0000-4000-8000-000000000001')), 1, 'même clé : un seul commentaire');
select is((select (f ->> 'comment_count')::int from jsonb_array_elements(public.content_feed_ranked((select be from _t))) f
           where f ->> 'id' = (select a_post from _t)::text), 1, 'commentaire compté dans le fil');
select tests.logout();
update _t set comment1 = (select id from public.content_comments limit 1);
select tests.login_as((select awa from _t));
select throws_ok(format($$select public.delete_comment('%s')$$, (select comment1 from _t)), 'P0002', null,
  'commentaire d''autrui non supprimable');

-- Signalé puis retiré par l'équipe : invisible.
select public.report('comment', (select comment1 from _t), 'offensive');
select tests.login_as((select admin from _t));
select public.admin_moderate('comment', (select comment1 from _t), 'removed', 'Propos déplacé');
select tests.login_as((select ama from _t));
select is(jsonb_array_length(public.content_comments_list((select a_post from _t))), 0, 'commentaire retiré invisible');
select is(public.follow('creator', (select awa from _t), false), false, 'désabonnée');
select is(jsonb_array_length(public.content_feed_ranked((select be from _t), 'following')), 0,
  'plus rien dans les abonnements');

select * from finish();
