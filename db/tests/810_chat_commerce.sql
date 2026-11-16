-- Chat de commerce (spec 099) : position (ponctuelle et en direct), devis accepté en un geste,
-- coupon appliqué au panier puis consommé, demande de paiement, vidéo contrôlée.

select plan(14);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '81000000-0000-4000-8000-000000000001'::uuid as tomate,
       '81000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '81000000-0000-4000-8000-000000000003'::uuid as gombo,
       '81000000-0000-4000-8000-000000000004'::uuid as gombo_tas,
       null::uuid as store, null::uuid as conv, null::uuid as loc, null::uuid as quote, null::uuid as coupon;
update _t set store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));
select public.save_product(jsonb_build_object(
  'id', (select gombo from _t), 'name', 'Gombo', 'category_id', (select tomates from _t), 'price_minor', 1000,
  'photo_keys', jsonb_build_array('stores/' || (select store from _t) || '/products/' || (select gombo from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select gombo_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select gombo from _t));
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select tests.logout();
update _t set conv = (app.start_conversation((select awa from _t), (select store from _t)) ->> 'id')::uuid;

-- Position ponctuelle et en direct (15 min).
select tests.login_as((select awa from _t));
select is(public.chat_send_location((select conv from _t), 6.13, 1.22, 0, gen_random_uuid()) ->> 'kind',
  'location', 'position envoyée');
update _t set loc = (public.chat_send_location((select conv from _t), 6.13, 1.22, 15, gen_random_uuid()) ->> 'id')::uuid;
select is((public.chat_update_location((select loc from _t), 6.14, 1.23) -> 'payload' ->> 'latitude')::numeric,
  6.14, 'position en direct mise à jour');
select throws_ok($$select public.chat_send_location((select conv from _t), 99, 1, 0, gen_random_uuid())$$,
  'P0001', 'location_invalid', 'position impossible refusée');
select tests.login_as((select kodjo from _t));
select throws_ok(format($$select public.chat_update_location('%s', 6.15, 1.24)$$, (select loc from _t)),
  'P0001', 'not_live', 'seule l''autrice met à jour sa position');

-- Vidéo : clé de stockage de la conversation exigée.
select tests.logout();
select throws_ok(format($$select app.send_message('%s', '%s', 'video', null, 'ailleurs/x.mp4', null, gen_random_uuid(), 9000)$$,
  (select kodjo from _t), (select conv from _t)), 'P0001', 'media_invalid', 'vidéo hors conversation refusée');
select tests.login_as((select kodjo from _t));

-- Devis : 3 tas de tomates à 400 au lieu de 500 ; la cliente accepte en un geste.
update _t set quote = (public.send_quote((select conv from _t),
  jsonb_build_array(jsonb_build_object('variant_id', (select tomate_tas from _t), 'quantity', 3, 'price_minor', 400)),
  'Pour ta sauce', gen_random_uuid()) -> 'payload' ->> 'quote_id')::uuid;
select tests.logout();
select is((select total_minor from public.quotes where id = (select quote from _t))::int, 1200, 'devis : 1 200');
select tests.login_as((select kodjo from _t));
select throws_ok(format($$select public.send_quote('%s', '[{"variant_id": "%s", "quantity": 1, "price_minor": 900}]', null, gen_random_uuid())$$,
  (select conv from _t), (select tomate_tas from _t)), 'P0001', 'quote_invalid', 'prix au-dessus du prix affiché refusé');
select tests.login_as((select awa from _t));
select is(public.accept_quote((select quote from _t)) ->> 'status', 'accepted', 'devis accepté');
select is((public.my_cart() -> 'stores' -> 0 -> 'lines' -> 0 ->> 'unit_price_minor')::int, 400,
  'panier aux prix du devis');
select throws_ok(format($$select public.accept_quote('%s')$$, (select quote from _t)), 'P0001', 'quote_expired',
  'un devis ne s''accepte qu''une fois');

-- Coupon de 20 % : gardé par la cliente, appliqué au gombo (sans prix négocié).
select tests.login_as((select kodjo from _t));
update _t set coupon = (public.send_coupon((select conv from _t), 20, 7, gen_random_uuid()) -> 'payload' ->> 'coupon_id')::uuid;
select tests.login_as((select awa from _t));
select public.claim_coupon((select coupon from _t));
select public.cart_add((select gombo_tas from _t), 1);
select is((select (l ->> 'unit_price_minor')::int from jsonb_array_elements(public.my_cart() -> 'stores' -> 0 -> 'lines') l
           where (l ->> 'variant_id')::uuid = (select gombo_tas from _t)), 800, 'coupon : 1 000 − 20 % = 800');
select is((select l ->> 'price_source' from jsonb_array_elements(public.my_cart() -> 'stores' -> 0 -> 'lines') l
           where (l ->> 'variant_id')::uuid = (select gombo_tas from _t)), 'coupon', 'source du prix : coupon');

-- Demande de paiement dans le chat.
select tests.login_as((select kodjo from _t));
select is(public.send_payment_request((select conv from _t), 2500, 'Commande spéciale', gen_random_uuid())
          -> 'payload' ->> 'status', 'open', 'demande de paiement ouverte');
select tests.login_as((select awa from _t));
select throws_ok(format($$select public.send_coupon('%s', 10, 7, gen_random_uuid())$$, (select conv from _t)),
  'P0002', 'not_found', 'la cliente n''envoie pas de coupon');

select * from finish();
