-- Spec 016 : avis après livraison, réponse, note ; réachat ; demandes d'aide.

select plan(31);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('esi@example.com') as esi,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '22222222-2222-4222-8222-222222222222'::uuid as tomate,
       'c1000000-0000-4000-8000-000000000001'::uuid as tomate_tas,
       'a0000000-0000-4000-8000-000000000001'::uuid as home,
       null::uuid as kodjo_store, null::uuid as o1, null::uuid as o2, null::uuid as r1, null::uuid as t1;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
select tests.open_store((select esi from _t), 'Les jus d''Esi', 'tokoin');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t)))));
select public.publish_product((select tomate from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.save_address(jsonb_build_object('id', (select home from _t), 'kind', 'home', 'zone_id', (select be from _t),
  'landmark', 'Portail bleu', 'phone', '+228 90 00 00 00'));
select tests.logout();

create function pg_temp._order() returns uuid language plpgsql as $$
declare
  v jsonb;
begin
  perform tests.login_as((select awa from _t));
  perform public.cart_add((select tomate_tas from _t), 2);
  perform tests.logout();
  v := app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'address_id', (select home from _t),
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash')),
    (select morning from _t));
  return (v -> 'purchase' -> 'orders' -> 0 ->> 'id')::uuid;
end
$$;
update _t set o1 = pg_temp._order();
update _t set o2 = pg_temp._order();

-- Avis : seulement après livraison, une fois, par la cliente de la commande.
select throws_ok($$select app.leave_review((select awa from _t), (select o1 from _t), 5, '{}', null)$$,
  'P0001', 'review_not_allowed', 'pas d''avis avant la livraison');
select app.transition_order((select kodjo from _t), (select o1 from _t), 'accepted', 'pending');
select app.transition_order((select kodjo from _t), (select o1 from _t), 'ready', 'accepted');
select app.transition_order((select kodjo from _t), (select o1 from _t), 'out_for_delivery', 'ready');
select app.transition_order((select kodjo from _t), (select o1 from _t), 'delivered', 'out_for_delivery');
select throws_ok($$select app.leave_review((select ama from _t), (select o1 from _t), 5, '{}', null)$$,
  'P0002', null, 'une autre cliente ne note pas');
select throws_ok($$select app.leave_review((select awa from _t), (select o1 from _t), 6, '{}', null)$$,
  '22023', null, 'note hors 1..5 refusée');
select throws_ok($$select app.leave_review((select awa from _t), (select o1 from _t), 5, '{inventee}', null)$$,
  '23514', null, 'étiquette inconnue refusée');
update _t set r1 = (app.leave_review((select awa from _t), (select o1 from _t), 4,
  '{fresh,fresh,fast}', ' Très frais ! ') ->> 'id')::uuid;
select is((select tags from public.reviews where id = (select r1 from _t)), '{fast,fresh}'::text[],
  'étiquettes dédoublonnées');
select is((select comment from public.reviews where id = (select r1 from _t)), 'Très frais !', 'commentaire nettoyé');
select throws_ok($$select app.leave_review((select awa from _t), (select o1 from _t), 5, '{}', null)$$,
  'P0001', 'review_exists', 'un seul avis par commande');
select is((select kind from public.notifications where user_id = (select kodjo from _t) and kind = 'review_received'),
  'review_received', 'la vendeuse est prévenue');
select is((select count(*)::int from public.events where name = 'review_left' and entity_id = (select r1 from _t)::text),
  1, 'review_left');

-- Réponse : la vendeuse de la boutique seulement.
select throws_ok($$select app.reply_review((select esi from _t), (select r1 from _t), 'Merci')$$,
  'P0002', null, 'une autre vendeuse ne répond pas');
select throws_ok($$select app.reply_review((select kodjo from _t), (select r1 from _t), '  ')$$,
  'P0001', 'reply_invalid', 'réponse vide refusée');
select is(app.reply_review((select kodjo from _t), (select r1 from _t), 'Merci Awa !') ->> 'reply',
  'Merci Awa !', 'réponse publiée');
select is((select params ->> 'store_name' from public.notifications
           where user_id = (select awa from _t) and kind = 'review_replied'), 'Étal de Kodjo', 'la cliente est prévenue');

-- Lectures.
select tests.login_anonymous();
select is((public.store_reviews((select kodjo_store from _t)) ->> 'review_count')::int, 1, 'avis publics');
select is((public.store_reviews((select kodjo_store from _t)) ->> 'rating')::numeric, 4.0, 'note moyenne');
select ok(not (public.store_reviews((select kodjo_store from _t)) -> 'reviews' -> 0 ? 'author_id'),
  'aucun identifiant d''autrice servi');
select is((public.store_page((select kodjo_store from _t)) ->> 'review_count')::int, 1, 'note sur la page boutique');
select tests.login_as((select kodjo from _t));
select is(jsonb_array_length(public.my_store_reviews() -> 'reviews'), 1, 'la vendeuse lit ses avis');
select tests.login_as((select awa from _t));
select is(public.order_review((select o1 from _t)) ->> 'rating', '4', 'la cliente retrouve son avis');
select is(public.order_review((select o2 from _t)), null, 'pas d''avis sur l''autre commande');
select tests.login_as((select ama from _t));
select throws_ok($$select public.order_review((select o1 from _t))$$, 'P0002', null,
  'une autre cliente ne lit pas l''avis par commande');
select tests.logout();
update public.reviews set status = 'removed' where id = (select r1 from _t);
select is((public.store_reviews((select kodjo_store from _t)) ->> 'review_count')::int, 0, 'avis retiré masqué');

-- Réachat : articles remis au panier, une rupture écartée.
select tests.login_as((select awa from _t));
select is((public.reorder((select o1 from _t)) ->> 'added')::int, 1, 'article remis au panier');
select tests.logout();
update public.product_variants set stock_quantity = 0 where id = (select tomate_tas from _t);
select tests.login_as((select awa from _t));
select is(public.reorder((select o1 from _t)) -> 'skipped' ->> 0, 'Tomates', 'article en rupture écarté');
select tests.login_as((select ama from _t));
select throws_ok($$select public.reorder((select o1 from _t))$$, 'P0002', null, 'pas de réachat d''autrui');

-- Demandes d'aide.
select tests.login_as((select awa from _t));
update _t set t1 = (public.open_ticket('client', 'order', 'Je n''ai pas reçu ma monnaie', (select o1 from _t)) ->> 'id')::uuid;
select is(public.my_tickets('client') -> 0 ->> 'status', 'open', 'demande ouverte');
select throws_ok($$select public.open_ticket('client', 'order', '  ', null)$$, 'P0001', 'ticket_invalid',
  'demande vide refusée');
select tests.login_as((select ama from _t));
select throws_ok($$select public.open_ticket('client', 'order', 'Pas à moi', (select o1 from _t))$$,
  'P0002', null, 'commande d''autrui refusée');
select throws_ok($$select public.reply_ticket((select t1 from _t), 'Je m''en mêle')$$, 'P0002', null,
  'une autre utilisatrice n''écrit pas');
select is(jsonb_array_length(public.my_tickets('client')), 0, 'aucune demande d''autrui listée');
select tests.login_as((select kodjo from _t));
select lives_ok($$select public.open_ticket('vendor', 'store', 'Changer mes horaires', (select o1 from _t))$$,
  'la vendeuse ouvre une demande sur sa commande');

select * from finish();
