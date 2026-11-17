-- Cuisine fluide (spec 103) : temps de visionnage, fin de lecture, ventes générées, miniature choisie.

select plan(10);

create temporary table _t as
select tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('yao@example.com') as yao,
       (select id from public.zones where slug = 'be') as be,
       '84000000-0000-4000-8000-000000000001'::uuid as video,
       '84000000-0000-4000-8000-000000000002'::uuid as product,
       '84000000-0000-4000-8000-000000000003'::uuid as variant,
       null::uuid as store;
update _t set store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

insert into public.products (id, store_id, name, currency_code, status)
select product, store, 'Tomates', 'XOF', 'published' from _t;
insert into public.product_variants (id, product_id) select variant, product from _t;
insert into public.contents (id, store_id, kind, media_key, media_type, caption)
select video, store, 'video', 'stores/' || store || '/contents/' || video || '.mp4', 'video', 'Arrivage' from _t;
insert into public.content_products (content_id, product_id, sort) select video, product, 0 from _t;
update public.contents set view_count = 4 where id = (select video from _t);

-- Ama regarde la vidéo jusqu'au bout ; une visiteuse en regarde un bout (compteurs seuls).
select tests.login_as((select ama from _t));
select public.content_watched((select video from _t), 8000, true);
select tests.login_anonymous();
select public.content_watched((select video from _t), 999999999, false);
select tests.logout();
select is((select watch_ms_total from public.contents where id = (select video from _t)), 608000::bigint,
  'temps cumulé, envoi borné à 10 minutes');
select is((select completion_count from public.contents where id = (select video from _t)), 1, 'une fin de lecture');
select is((select count(*)::int from public.content_watches where content_id = (select video from _t)), 1,
  'seule la personne connectée est retenue');

-- Commande livrée des tomates par Ama après la vidéo : vente générée. Yao n'a rien regardé.
insert into public.purchases (id, user_id, idempotency_key, country_code, currency_code, payment_method_id,
                              subtotal_minor, delivery_fee_minor, total_minor)
select '84000000-0000-4000-8000-000000000010', u, gen_random_uuid(), 'TG', 'XOF',
       (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'), 1000, 0, 1000
from (select ama as u, 'k-ama' as k from _t union all select yao, 'k-yao' from _t) x where x.k = 'k-ama';
insert into public.purchases (id, user_id, idempotency_key, country_code, currency_code, payment_method_id,
                              subtotal_minor, delivery_fee_minor, total_minor)
select '84000000-0000-4000-8000-000000000011', yao, gen_random_uuid(), 'TG', 'XOF',
       (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'), 1000, 0, 1000
from _t;
insert into public.orders (id, purchase_id, store_id, fulfillment, status, currency_code, subtotal_minor,
                           delivery_fee_minor, total_minor, commission_minor, created_at)
select o, p, store, 'pickup', 'delivered', 'XOF', 1000, 0, 1000, 0, now() + interval '1 hour'
from _t, (values ('84000000-0000-4000-8000-000000000020'::uuid, '84000000-0000-4000-8000-000000000010'::uuid),
                 ('84000000-0000-4000-8000-000000000021'::uuid, '84000000-0000-4000-8000-000000000011'::uuid)) v(o, p);
insert into public.order_items (order_id, product_id, variant_id, product_name, unit_price_minor, quantity, amount_minor)
select o, product, variant, 'Tomates', 500, 2, 1000
from _t, (values ('84000000-0000-4000-8000-000000000020'::uuid), ('84000000-0000-4000-8000-000000000021'::uuid)) v(o);

select tests.login_as((select kodjo from _t));
select is((public.my_contents() -> 0 -> 'stats' ->> 'sales_orders')::int, 1, 'une vente générée (pas celle de Yao)');
select is((public.my_contents() -> 0 -> 'stats' ->> 'sales_minor')::bigint, 1000::bigint, 'montant des ventes');
select is((public.my_contents() -> 0 -> 'stats' ->> 'completion_rate')::numeric, 0.25, 'fin de lecture : 1 sur 4');

-- Miniature : seulement une image existante d'une vidéo convertie, et seulement par sa propriétaire.
select throws_ok(format($$select public.set_content_cover(%L, 2::smallint)$$, (select video from _t)),
  '22023', null, 'pas d''image avant la conversion');
select tests.logout();
select app.set_stream((select video from _t), '0f8fad5b-d9cb-469f-a165-70867728950e', 'ready',
  'https://cdn.example/0f8fad5b-d9cb-469f-a165-70867728950e/playlist.m3u8', 8);
select tests.login_as((select kodjo from _t));
select is((public.set_content_cover((select video from _t), 3::smallint) ->> 'cover_frame')::int, 3,
  'troisième image choisie');
select tests.login_as((select ama from _t));
select throws_ok(format($$select public.set_content_cover(%L, 1::smallint)$$, (select video from _t)),
  'P0002', null, 'pas pour une autre personne');
select is((public.content_feed_ranked((select be from _t), 'near') -> 0 ->> 'stream_thumb_count')::int, 8,
  'le fil connaît les images disponibles');

select * from finish();
