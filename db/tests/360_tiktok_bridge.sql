-- Pont TikTok (spec 040).

select plan(14);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       (select id from public.zones where slug = 'be') as be,
       '36100000-0000-4000-8000-000000000001'::uuid as post,
       null::text as code;
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select throws_ok($$select public.set_tiktok_handle('awa')$$, '42501', 'not_creator', 'compte TikTok : créatrices seulement');
select public.become_creator('Awa cuisine');
select throws_ok($$select public.set_tiktok_handle('awa cuisine!')$$, '22023', 'invalid_handle', 'compte invalide refusé');
select is(public.set_tiktok_handle(' @Awa.Cuisine ') ->> 'tiktok_handle', 'awa.cuisine', 'compte déclaré, normalisé');
select tests.logout();
select is(app.creator_tiktok_handle((select awa from _t)), 'awa.cuisine', 'lu par la Function');
select tests.login_as((select awa from _t));

select public.save_creator_content(jsonb_build_object('id', (select post from _t), 'kind', 'post',
  'media_key', 'creators/' || (select awa from _t) || '/contents/' || (select post from _t) || '.jpg',
  'caption', 'Sauce gombo'));
select throws_ok(format($$select public.set_content_source('%s', 'https://example.com/video')$$, (select post from _t)),
  '23514', null, 'lien hors TikTok refusé');
select is(public.set_content_source((select post from _t), 'https://www.tiktok.com/@awa.cuisine/video/7300000000000000001')
  ->> 'source', 'tiktok', 'post importé de TikTok');
select tests.logout();
select is((app.content_json((select post from _t), null) ->> 'source_url'),
  'https://www.tiktok.com/@awa.cuisine/video/7300000000000000001', 'lien d''origine exposé');
select tests.login_as((select awa from _t));

-- Partage : un lien par personne et contenu.
update _t set code = public.create_share_link((select post from _t));
select ok((select code ~ '^[a-z0-9]{8}$' from _t), 'code court');
select is(public.create_share_link((select post from _t)), (select code from _t), 'même lien au second partage');

select tests.login_as((select ama from _t));
select throws_ok(format($$select public.set_content_source('%s', 'https://www.tiktok.com/@x/video/1')$$, (select post from _t)),
  '22023', 'tiktok_handle_required', 'pas créatrice : refusé');
select isnt(public.create_share_link((select post from _t)), (select code from _t), 'autre personne, autre lien');

-- Ouverture sans compte : le contenu, compteur incrémenté.
select tests.logout();
select is(public.open_share_link(upper((select code from _t))) ->> 'id', (select post from _t)::text, 'lien ouvert sans compte');
select is((select opens from public.share_links where code = (select code from _t)), 1, 'ouverture comptée');
select throws_ok($$select public.open_share_link('zzzzzzzz')$$, 'P0002', null, 'lien inconnu');

select * from finish();
