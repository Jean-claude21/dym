-- Spec 020 : publication, fil, stories, statistiques, signalements, modération.

select plan(26);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('afi@example.com') as afi,
       tests.create_user('ops@example.com') as admin,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as cat,
       '41000000-0000-4000-8000-000000000001'::uuid as tomate,
       '42000000-0000-4000-8000-000000000001'::uuid as story,
       '42000000-0000-4000-8000-000000000002'::uuid as video,
       null::uuid as kodjo_store, null::uuid as afi_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be'),
              afi_store = tests.open_store(afi, 'Chez Afi', 'be');
insert into public.user_roles (user_id, role) select admin, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

create function pg_temp.key(p_store uuid, p_id uuid, p_ext text) returns text
language sql immutable as $$ select 'stores/' || p_store || '/contents/' || p_id || '.' || p_ext $$;
grant execute on function pg_temp.key(uuid, uuid, text) to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates fraîches', 'category_id', (select cat from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', gen_random_uuid()))));
select public.publish_product((select tomate from _t));

-- Publication : média de sa boutique, produits à soi, 5 au plus.
select lives_ok($$select public.save_content(jsonb_build_object('id', (select story from _t), 'kind', 'story',
  'media_key', pg_temp.key((select kodjo_store from _t), (select story from _t), 'jpg'),
  'caption', 'Tomates du jour', 'product_ids', jsonb_build_array((select tomate from _t))))$$, 'story publiée');
select tests.logout();
select ok((select expires_at between now() + interval '23 hours' and now() + interval '25 hours'
           from public.contents where id = (select story from _t)) is not false, 'story : 24 h');
select tests.login_as((select kodjo from _t));
select lives_ok($$select public.save_content(jsonb_build_object('id', (select video from _t), 'kind', 'video',
  'media_key', pg_temp.key((select kodjo_store from _t), (select video from _t), 'mp4'),
  'product_ids', jsonb_build_array((select tomate from _t))))$$, 'vidéo publiée');
select throws_ok($$select public.save_content(jsonb_build_object('id', gen_random_uuid(), 'kind', 'video',
  'media_key', pg_temp.key((select afi_store from _t), gen_random_uuid(), 'mp4')))$$,
  '22023', null, 'média d''une autre boutique refusé');
select throws_ok($$select public.save_content(jsonb_build_object('id', gen_random_uuid(), 'kind', 'video',
  'media_key', pg_temp.key((select kodjo_store from _t), gen_random_uuid(), 'jpg')))$$,
  '23514', null, 'vidéo : un fichier vidéo');
select tests.login_as((select afi from _t));
select throws_ok($$select public.save_content(jsonb_build_object('id', gen_random_uuid(), 'kind', 'story',
  'media_key', pg_temp.key((select afi_store from _t), gen_random_uuid(), 'jpg'),
  'product_ids', jsonb_build_array((select tomate from _t))))$$, '22023', null, 'produit d''une autre boutique refusé');
select throws_ok($$select * from public.contents$$, '42501', null, 'table fermée');

-- Fil et stories : visiteuse comprise ; la story expire.
select tests.logout();
select is(jsonb_array_length(public.content_feed((select be from _t))), 1, 'fil : la vidéo seulement');
select is(public.content_feed((select be from _t)) -> 0 -> 'products' -> 0 ->> 'name', 'Tomates fraîches',
  'produit tagué');
select is(jsonb_array_length(public.content_stories((select be from _t)) -> 0 -> 'stories'), 1, 'story du quartier');
select is(jsonb_array_length(public.content_stories((select be from _t), now() + interval '25 hours')), 0,
  'story expirée');
select is(public.product_video_count((select tomate from _t)), 1, 'vidéo de la fiche produit');

-- Statistiques, j'aime.
select public.content_viewed((select video from _t));
select public.content_clicked((select video from _t), (select tomate from _t));
select is((select view_count + click_count from public.contents where id = (select video from _t)), 2,
  'vue et clic comptés');
select throws_ok($$select public.content_clicked((select video from _t), gen_random_uuid())$$, 'P0002', null,
  'produit non tagué');
select throws_ok($$select public.like_content((select video from _t), true)$$, '42501', null, 'j''aime : session');
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select is(public.like_content((select video from _t), true), 1, 'j''aime');
select is(jsonb_array_length(public.content_feed((select be from _t), 'following')), 0,
  'suivies : aucune commande, rien');

-- Signalement.
select lives_ok($$select public.report('content', (select video from _t), 'misleading', 'Pas les mêmes tomates')$$,
  'contenu signalé');
select public.report('content', (select video from _t), 'spam');
select throws_ok($$select public.report('content', (select video from _t), 'boring')$$, '22023', null, 'motif inconnu');

-- Vendeuse : mes contenus, archiver.
select tests.login_as((select kodjo from _t));
select is((public.my_contents() -> 0 ->> 'report_count')::int, 1, 'un signalement par personne');
select tests.login_as((select afi from _t));
select throws_ok($$select public.archive_content((select story from _t))$$, 'P0002', null,
  'archiver le contenu d''autrui : refusé');

-- Modération.
select throws_ok($$select public.admin_reports()$$, '42501', null, 'file réservée à l''équipe');
select tests.login_as((select admin from _t));
select is(public.admin_reports() -> 0 -> 'preview' ->> 'title', '', 'aperçu du contenu');
select throws_ok($$select public.admin_moderate('content', (select video from _t), 'removed', ' ')$$,
  'P0001', 'reason_required', 'raison obligatoire');
select public.admin_moderate('content', (select video from _t), 'removed', 'Contenu trompeur');
select tests.logout();
select is(jsonb_array_length(public.content_feed((select be from _t))), 0, 'contenu retiré : hors du fil');
select is((select count(*)::int from public.audit_log where action = 'content_removed'
           and entity_id = (select video from _t)::text), 1, 'décision journalisée');

select * from finish();
