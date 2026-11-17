-- Groupes de discussion (spec 112) : espace famille et achat groupé.

select plan(25);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('mia@example.com') as mia,
       tests.create_user('yao@example.com') as yao,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       '47000000-0000-4000-8000-000000000001'::uuid as igname,
       '47000000-0000-4000-8000-000000000002'::uuid as igname_tas,
       null::uuid as store, null::uuid as fam, null::uuid as offer, null::uuid as deal, null::uuid as direct,
       null::text as h_mia, null::text as h_yao, null::uuid as m1;
update _t set store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select mia from _t));
select public.complete_profile('Mia', (select be from _t), 'client');
update _t set h_mia = public.my_wallet_handle() ->> 'handle';
select tests.login_as((select yao from _t));
select public.complete_profile('Yao', (select be from _t), 'client');
update _t set h_yao = public.my_wallet_handle() ->> 'handle';

-- Espace famille : créé par Awa, qui en est l'administratrice.
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.logout();
update _t set direct = (app.start_conversation(awa, store) ->> 'id')::uuid;
select tests.login_as((select awa from _t));
update _t set fam = (public.create_family_group('Famille Mensah') ->> 'id')::uuid;
select is((public.group_info((select fam from _t)) ->> 'me_admin')::boolean, true, 'créatrice administratrice');
select is((select c ->> 'store_id' from jsonb_array_elements(public.my_conversations('client')) c
           where c ->> 'kind' = 'family'), '', 'pas de boutique : identifiant vide (apps installées)');
select throws_ok($$select public.create_family_group('  ')$$, 'P0001', 'title_invalid', 'nom vide refusé');
select is(jsonb_array_length(public.group_add_member((select fam from _t), (select h_mia from _t)) -> 'members'), 2,
  'Mia ajoutée par son code');
select throws_ok($$select public.group_add_member((select fam from _t), 'INCONNU')$$, 'P0002', 'recipient_unknown',
  'code inconnu refusé');
select tests.logout();
select is((select count(*)::int from public.notifications where user_id = (select mia from _t) and kind = 'group_added'), 1,
  'Mia prévenue');
select tests.login_as((select awa from _t));

-- Awa écrit ; Mia est prévenue sans le texte, son fil compte un non lu, le prénom est sur le message.
select tests.logout();
update _t set m1 = (app.send_message(awa, fam, 'text', 'Qui passe au marché samedi ?', null, null, gen_random_uuid())
                    ->> 'id')::uuid;
select is((select params ->> 'group' from public.notifications where user_id = (select mia from _t)
           and kind = 'new_message_group'), 'Famille Mensah', 'notification au nom du groupe, sans le texte');
select tests.login_as((select mia from _t));
select is((select (c ->> 'unread')::int from jsonb_array_elements(public.my_conversations('client')) c
           where c ->> 'kind' = 'family'), 1, 'un non lu pour Mia');
select is((public.conversation((select fam from _t)) -> 'messages' -> 0 ->> 'author_name'), 'Awa', 'prénom de l''autrice');
select is((public.conversation((select fam from _t)) -> 'messages' -> 0 ->> 'mine')::boolean, false, 'pas le mien');
select is((select (c ->> 'unread')::int from jsonb_array_elements(public.my_conversations('client')) c
           where c ->> 'kind' = 'family'), 0, 'lu en ouvrant');
select is(public.unread_messages_count('client'), 0, 'compteur global à zéro');

-- « Vu » quand toutes les autres personnes ont lu.
select tests.login_as((select awa from _t));
select isnt(public.conversation((select fam from _t)) ->> 'peer_read_at', null, 'vu par tout le groupe');
-- La conversation directe d'Awa reste à part.
select is((select count(*)::int from jsonb_array_elements(public.my_conversations('client'))), 2,
  'fil direct et groupe, sans doublon');

-- Produit d'une boutique quelconque dans la famille.
select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select igname from _t), 'name', 'Igname', 'category_id', (select id from public.categories where slug = 'tomates'),
  'price_minor', 1000,
  'photo_keys', jsonb_build_array('stores/' || (select store from _t) || '/products/' || (select igname from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select igname_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select igname from _t));
select tests.logout();
select is(app.send_message((select mia from _t), (select fam from _t), 'product', null, null, (select igname from _t),
                           gen_random_uuid()) ->> 'kind', 'product', 'produit partagé en famille');

-- Personne d'autre ne lit ni n'écrit.
select tests.login_as((select yao from _t));
select throws_ok($$select public.conversation((select fam from _t))$$, 'P0002', null, 'Yao ne lit pas le groupe');
select throws_ok($$select public.group_add_member((select fam from _t), (select h_yao from _t))$$, '42501', 'not_admin',
  'pas administratrice : refusé');

-- Quitter, retirer.
select tests.login_as((select mia from _t));
select throws_ok($$select public.group_remove_member((select fam from _t), (select awa from _t))$$, '42501', 'not_admin',
  'Mia ne retire pas Awa');
select public.group_remove_member((select fam from _t), (select mia from _t));
select throws_ok($$select public.conversation((select fam from _t))$$, 'P0002', null, 'Mia partie : plus d''accès');
select tests.login_as((select awa from _t));
select throws_ok($$select public.group_remove_member((select fam from _t), (select awa from _t))$$, 'P0001',
  'admin_cannot_leave', 'l''administratrice ne part pas');

-- Achat groupé : un fil par offre, membres et boutique.
select tests.login_as((select kodjo from _t));
update _t set offer = (public.create_group_offer((select igname from _t), 800, 5, 3, 200) ->> 'id')::uuid;
select tests.login_as((select yao from _t));
select public.join_group_offer((select offer from _t), 2);
update _t set deal = (public.group_offer_thread((select offer from _t)) ->> 'id')::uuid;
select is(public.group_offer_thread((select offer from _t)) ->> 'id', (select deal::text from _t), 'un seul fil par offre');
select is(public.group_offer_thread((select offer from _t)) ->> 'title', 'Igname', 'nommé d''après le produit');
select tests.login_as((select awa from _t));
select throws_ok($$select public.group_offer_thread((select offer from _t))$$, 'P0002', null,
  'pas membre de l''offre : pas de fil');
select tests.logout();
select is(app.conversation_role((select kodjo from _t), (select deal from _t)), 'vendor', 'la boutique y écrit');
select tests.login_as((select kodjo from _t));
select ok(exists (select 1 from jsonb_array_elements(public.my_conversations('vendor')) c
                  where c ->> 'kind' = 'group_buy'), 'dans la liste de la boutique');

select * from finish();
