-- Messagerie (spec 015) : une conversation par cliente et boutique, accès
-- réservé aux participantes, idempotence, produits et images contrôlés,
-- non-lus, notifications sans contenu.

select plan(31);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('esi@example.com') as esi,
       (select id from public.categories where slug = 'tomates') as tomates,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       '33333333-3333-4333-8333-333333333333'::uuid as brouillon,
       '44444444-4444-4444-8444-444444444444'::uuid as jus,
       null::uuid as kodjo_store, null::uuid as esi_store, null::uuid as conv,
       null::uuid as m1, gen_random_uuid() as key1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be'),
              esi_store = tests.open_store(esi, 'Les jus d''Esi', 'tokoin');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._product(p_store uuid, p_id uuid, p_name text) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'name', p_name, 'category_id', (select tomates from _t),
    'price_minor', 500,
    'photo_keys', jsonb_build_array('stores/' || p_store || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', gen_random_uuid())))
$$;
grant execute on function pg_temp._product(uuid, uuid, text) to authenticated;
select tests.login_as((select kodjo from _t));
select public.save_product(pg_temp._product((select kodjo_store from _t), (select tomate from _t), 'Tomates'));
select public.publish_product((select tomate from _t));
select public.save_product(pg_temp._product((select kodjo_store from _t), (select brouillon from _t), 'Brouillon'));
select tests.login_as((select esi from _t));
select public.save_product(pg_temp._product((select esi_store from _t), (select jus from _t), 'Jus'));
select public.publish_product((select jus from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select id from public.zones where slug = 'be'), 'client');
select tests.logout();

-- Ouverture.
update _t set conv = (app.start_conversation(awa, kodjo_store) ->> 'id')::uuid;
select is((app.start_conversation((select awa from _t), (select kodjo_store from _t)) ->> 'id')::uuid,
  (select conv from _t), 'une seule conversation par cliente et boutique');
select throws_ok($$select app.start_conversation((select kodjo from _t), (select kodjo_store from _t))$$,
  'P0001', 'own_store', 'une vendeuse ne s''écrit pas');
select throws_ok($$select app.start_conversation(null, (select kodjo_store from _t))$$,
  '42501', null, 'session requise');

-- Envois.
update _t set m1 = (app.send_message(awa, conv, 'text', ' Vous avez encore du gombo ? ', null, null, key1)
  ->> 'id')::uuid;
select is((select body from public.messages where id = (select m1 from _t)), 'Vous avez encore du gombo ?',
  'texte enregistré, espaces retirés');
select is((app.send_message((select awa from _t), (select conv from _t), 'text', 'Rejeu', null, null,
  (select key1 from _t)) ->> 'id')::uuid, (select m1 from _t), 'rejeu : même message');
select is((select count(*)::int from public.messages where conversation_id = (select conv from _t)), 1,
  'aucun doublon');
select is((select count(*)::int from public.notifications where user_id = (select kodjo from _t)
           and kind = 'new_message_vendor'), 1, 'la vendeuse est prévenue une fois');
select is((select params ->> 'sender_name' from public.notifications where user_id = (select kodjo from _t)
           and kind = 'new_message_vendor'), 'Awa', 'notification : prénom seulement');
select ok(not ((select params from public.notifications where user_id = (select kodjo from _t)
           and kind = 'new_message_vendor') ? 'body'), 'notification sans contenu');
select throws_ok($$select app.send_message((select awa from _t), (select conv from _t), 'text', '  ', null, null,
  gen_random_uuid())$$, 'P0001', 'message_invalid', 'texte vide refusé');
select throws_ok($$select app.send_message((select awa from _t), (select conv from _t), 'sticker', 'x', null, null,
  gen_random_uuid())$$, 'P0001', 'message_invalid', 'type inconnu refusé');
select throws_ok(format($$select app.send_message('%s', '%s', 'image', null, 'stores/x/products/y.jpg', null,
  gen_random_uuid())$$, (select awa from _t), (select conv from _t)), 'P0001', 'media_invalid',
  'image hors de l''espace de la conversation refusée');
select lives_ok(format($$select app.send_message('%s', '%s', 'image', null, 'chats/%s/%s.jpg', null,
  gen_random_uuid())$$, (select awa from _t), (select conv from _t), (select conv from _t), gen_random_uuid()),
  'image de la conversation acceptée');
select throws_ok($$select app.send_message((select ama from _t), (select conv from _t), 'text', 'Intruse',
  null, null, gen_random_uuid())$$, 'P0002', null, 'une autre cliente n''écrit pas');
select throws_ok($$select app.send_message((select esi from _t), (select conv from _t), 'text', 'Intruse',
  null, null, gen_random_uuid())$$, 'P0002', null, 'une autre vendeuse n''écrit pas');

-- Produits.
select is(app.send_message((select kodjo from _t), (select conv from _t), 'product', null, null,
  (select tomate from _t), gen_random_uuid()) -> 'product' ->> 'name', 'Tomates', 'produit partagé : fiche');
select throws_ok($$select app.send_message((select kodjo from _t), (select conv from _t), 'product', null, null,
  (select brouillon from _t), gen_random_uuid())$$, 'P0001', 'product_invalid', 'brouillon refusé');
select throws_ok($$select app.send_message((select kodjo from _t), (select conv from _t), 'product', null, null,
  (select jus from _t), gen_random_uuid())$$, 'P0001', 'product_invalid', 'produit d''une autre boutique refusé');
select is((select params ->> 'sender_name' from public.notifications where user_id = (select awa from _t)
           and kind = 'new_message'), 'Étal de Kodjo', 'la cliente est prévenue avec le nom de la boutique');

-- Lectures et non-lus.
select tests.login_as((select awa from _t));
select is(public.unread_messages_count('client'), 1, 'Awa : 1 non lu');
select is((public.my_conversations('client') -> 0 ->> 'unread')::int, 1, 'liste : non-lus');
select is(jsonb_array_length(public.conversation((select conv from _t)) -> 'messages'), 3, 'fil complet');
select is(public.unread_messages_count('client'), 0, 'ouverte : lue');
select is(public.conversation((select conv from _t)) ->> 'role', 'client', 'rôle de la lectrice');
select tests.login_as((select kodjo from _t));
select is(public.unread_messages_count('vendor'), 0, 'la vendeuse a lu en répondant');
select is(jsonb_array_length(public.my_conversations('vendor')), 1, 'la vendeuse voit la conversation');
select tests.login_as((select esi from _t));
select throws_ok(format($$select public.conversation('%s')$$, (select conv from _t)), 'P0002', null,
  'une autre vendeuse ne lit pas');
select is(jsonb_array_length(public.my_conversations('vendor')), 0, 'aucune conversation étrangère');
select tests.login_as((select ama from _t));
select throws_ok(format($$select public.conversation('%s')$$, (select conv from _t)), 'P0002', null,
  'une autre cliente ne lit pas');
select tests.logout();

-- Images : clés seulement pour les participantes.
select is((select count(*)::int from jsonb_object_keys(app.chat_media_keys((select awa from _t),
  array(select id from public.messages where conversation_id = (select conv from _t))))), 1,
  'clé d''image pour la cliente');
select is(app.chat_media_keys((select ama from _t),
  array(select id from public.messages where conversation_id = (select conv from _t))), '{}'::jsonb,
  'aucune clé pour une autre');

select * from finish();
