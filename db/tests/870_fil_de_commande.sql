-- Fil de commande (spec 109) : cliente, boutique et livreur dans une même conversation liée à la
-- commande ; fermé 24 h après la remise ; la conversation directe cliente-boutique reste à part.

select plan(12);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('kofi@example.com') as kofi,
       tests.create_user('yao@example.com') as yao,
       '87000000-0000-4000-8000-000000000001'::uuid as purchase,
       '87000000-0000-4000-8000-000000000002'::uuid as order1,
       null::uuid as store, null::uuid as thread;
update _t set store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select id from public.zones where slug = 'be'), 'client');
select tests.logout();
insert into public.courier_profiles (user_id, display_name, phone, vehicle, country_code, status)
select kofi, 'Kofi Mensah', '+228 90 11 22 33', 'moto', 'TG', 'active' from _t;
insert into public.purchases (id, user_id, idempotency_key, country_code, currency_code, payment_method_id,
                              subtotal_minor, delivery_fee_minor, total_minor)
select purchase, awa, gen_random_uuid(), 'TG', 'XOF',
       (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'), 1000, 300, 1300
from _t;
insert into public.orders (id, purchase_id, store_id, fulfillment, status, currency_code, subtotal_minor,
                           delivery_fee_minor, total_minor, commission_minor)
select order1, purchase, store, 'delivery', 'ready', 'XOF', 1000, 300, 1300, 0 from _t;

-- Pas de livreur : pas encore de fil.
select tests.login_as((select awa from _t));
select throws_ok(format($$select public.order_thread(%L)$$, (select order1 from _t)), 'P0001', 'no_courier',
  'fil ouvert seulement avec un livreur');
select tests.logout();
insert into public.order_couriers (order_id, name, phone, courier_id, accepted_at)
select order1, 'Kofi', '+228 90 11 22 33', kofi, now() from _t;

-- La cliente ouvre le fil ; le livreur et la boutique retrouvent le même.
select tests.login_as((select awa from _t));
update _t set thread = (public.order_thread((select order1 from _t)) ->> 'id')::uuid;
select is(public.order_thread((select order1 from _t)) ->> 'courier_name', 'Kofi', 'le livreur est dans le fil');
select tests.login_as((select kofi from _t));
select is((public.order_thread((select order1 from _t)) ->> 'id')::uuid, (select thread from _t), 'même fil pour le livreur');
select tests.login_as((select yao from _t));
select throws_ok(format($$select public.order_thread(%L)$$, (select order1 from _t)), 'P0002', null,
  'une autre personne n''y a pas accès');

-- Le livreur écrit (envoi par les Functions) : la cliente et la boutique sont prévenues.
select tests.logout();
select is(app.send_message((select kofi from _t), (select thread from _t), 'text', 'Je suis devant le portail',
                           null, null, gen_random_uuid()) ->> 'author_role', 'courier', 'message du livreur');
select throws_ok(format($$select app.send_message(%L, %L, 'product', null, null, null, gen_random_uuid())$$,
                        (select kofi from _t), (select thread from _t)), 'P0001', 'message_invalid',
  'le livreur n''envoie ni fiche ni devis');
select is((select count(*)::int from public.notifications
           where kind in ('new_message', 'new_message_vendor') and params ->> 'conversation_id' = (select thread from _t)::text),
          2, 'cliente et boutique prévenues');
select tests.login_as((select awa from _t));
select is(public.unread_messages_count('client')::int, 1, 'non lu pour la cliente');
select is(jsonb_array_length(public.my_conversations('client')), 1, 'le fil apparaît dans ses messages');
select tests.login_as((select kofi from _t));
select is(jsonb_array_length(public.my_conversations('courier')), 1, 'et dans ceux du livreur');

-- La conversation directe cliente-boutique reste distincte du fil (ouverte par les Functions).
select tests.logout();
select isnt((app.start_conversation((select awa from _t), (select store from _t)) ->> 'id')::uuid,
            (select thread from _t), 'conversation directe à part');

-- Remise depuis plus de 24 h : fil en lecture seule.
select tests.logout();
update public.orders set status = 'delivered', delivered_at = now() - interval '25 hours'
where id = (select order1 from _t);
select throws_ok(format($$select app.send_message(%L, %L, 'text', 'Merci', null, null, gen_random_uuid())$$,
                        (select awa from _t), (select thread from _t)), 'P0001', 'conversation_closed',
  'fil fermé 24 h après la remise');

select * from finish();
