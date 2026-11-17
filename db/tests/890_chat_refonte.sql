-- Chat refait (spec 111) : réponse, document, réactions, suppression, transfert, « reçu », « écrit… ».

select plan(19);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('yao@example.com') as yao,
       null::uuid as store, null::uuid as conv, null::uuid as conv2,
       null::uuid as m1, null::uuid as m2, null::uuid as photo;
update _t set store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select id from public.zones where slug = 'be'), 'client');
select tests.logout();
update _t set conv = (app.start_conversation(awa, store) ->> 'id')::uuid;
update _t set conv2 = (app.start_conversation(awa, tests.open_store(yao, 'Étal de Yao', 'be')) ->> 'id')::uuid;
update _t set m1 = (app.send_message(awa, conv, 'text', 'Vous avez des tomates ?', null, null, gen_random_uuid()) ->> 'id')::uuid;

-- Répondre à un message.
update _t set m2 = (app.send_message(kodjo, conv, 'text', 'Oui, 500 F le tas', null, null, gen_random_uuid(),
                                     null, null, m1) ->> 'id')::uuid;
select is(app.message_json((select m2 from _t)) -> 'reply_to' ->> 'body', 'Vous avez des tomates ?', 'réponse citée');
select throws_ok(format($$select app.send_message(%L, %L, 'text', 'x', null, null, gen_random_uuid(), null, null, %L)$$,
                        (select awa from _t), (select conv2 from _t), (select m1 from _t)),
  'P0001', 'reply_invalid', 'réponse à un message d''une autre conversation refusée');

-- Document : nom et taille, clé privée de la conversation.
select is(app.send_message((select awa from _t), (select conv from _t), 'file', null,
                           'chats/' || (select conv from _t) || '/' || gen_random_uuid() || '.pdf', null,
                           gen_random_uuid(), null, '{"name": "facture.pdf", "size": 52000}'::jsonb) -> 'payload' ->> 'name',
          'facture.pdf', 'document envoyé');
select throws_ok(format($$select app.send_message(%L, %L, 'file', null, %L, null, gen_random_uuid(), null, '{"name": "x.exe", "size": 1}'::jsonb)$$,
                        (select awa from _t), (select conv from _t), 'chats/' || (select conv from _t) || '/' || gen_random_uuid() || '.exe'),
  'P0001', 'media_invalid', 'type de document refusé');

-- Réactions : une par personne, retirée par null.
select tests.login_as((select kodjo from _t));
select is(public.react_message((select m1 from _t), '👍') -> 'reactions' -> 0 ->> 'emoji', '👍', 'réaction posée');
select tests.login_as((select awa from _t));
select is((public.react_message((select m1 from _t), '👍') -> 'reactions' -> 0 ->> 'count')::int, 2, 'deux réactions');
select is(jsonb_array_length(public.react_message((select m1 from _t), null) -> 'reactions'), 1, 'réaction retirée');

-- Supprimer pour soi : le message disparaît pour Awa seulement.
select public.delete_message((select m2 from _t), false);
select ok(not exists (select 1 from jsonb_array_elements(public.conversation((select conv from _t)) -> 'messages') m
                      where (m ->> 'id')::uuid = (select m2 from _t)), 'supprimé pour moi');
select tests.login_as((select kodjo from _t));
select ok(exists (select 1 from jsonb_array_elements(public.conversation((select conv from _t)) -> 'messages') m
                  where (m ->> 'id')::uuid = (select m2 from _t)), 'toujours là pour l''autre');

-- Pour tout le monde : son propre message, dans l'heure ; plus rien n'est exposé.
select tests.login_as((select awa from _t));
select throws_ok(format($$select public.delete_message(%L, true)$$, (select m2 from _t)), '42501', null,
  'pas le message d''un autre');
select public.delete_message((select m1 from _t), true);
select tests.logout();
select is(app.message_json((select m1 from _t)) ->> 'body', null, 'contenu effacé pour tous');
update public.messages set created_at = now() - interval '2 hours' where id = (select m2 from _t);
select tests.login_as((select kodjo from _t));
select throws_ok(format($$select public.delete_message(%L, true)$$, (select m2 from _t)), 'P0001', 'too_late',
  'plus d''une heure : trop tard');

-- Transférer : texte oui, photo non.
select tests.logout();
update _t set photo = (app.send_message(awa, conv, 'image', null, 'chats/' || conv || '/' || gen_random_uuid() || '.jpg',
                                        null, gen_random_uuid()) ->> 'id')::uuid;
select tests.login_as((select kodjo from _t));
select is((public.forward_message((select m2 from _t), (select conv from _t), gen_random_uuid()) ->> 'forwarded')::boolean,
          true, 'texte transféré, marqué');
select throws_ok(format($$select public.forward_message(%L, %L, gen_random_uuid())$$, (select photo from _t), (select conv from _t)),
  'P0001', 'forward_not_allowed', 'une photo reste dans sa conversation');

-- « Reçu » et « écrit… ».
select tests.login_as((select awa from _t));
select public.mark_delivered('client');
select tests.login_as((select kodjo from _t));
select isnt(public.conversation((select conv from _t)) ->> 'peer_delivered_at', null, 'reçu par la cliente');
select isnt(public.conversation((select conv from _t)) ->> 'my_read_at', null, 'lecture précédente rendue');
select public.chat_typing((select conv from _t));
select public.chat_typing((select conv from _t));
select tests.logout();
select is((select count(*)::int from public.live_events where kind = 'typing' and user_id = (select awa from _t)), 1,
  '« écrit… » envoyé une fois en 3 secondes');

-- Mesure : réaction et transfert tracés côté serveur, sans contenu.
select ok(exists (select 1 from public.events where name = 'chat_reaction_added'
                  and props ->> 'emoji' = '👍'), 'réaction mesurée');
select ok(exists (select 1 from public.events where name = 'chat_message_forwarded'
                  and props ->> 'kind' = 'text' and not props ? 'body'), 'transfert mesuré, sans texte');

select * from finish();
