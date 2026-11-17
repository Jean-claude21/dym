-- Finitions (spec 104) : rayons autorisés pour un enfant, mouvements « entre proches » nommés.

select plan(7);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('yao@example.com') as yao,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.categories where slug = 'fruits') as fruits,
       (select id from public.categories where slug = 'boissons') as boissons,
       '85000000-0000-4000-8000-000000000001'::uuid as product,
       '85000000-0000-4000-8000-000000000002'::uuid as purchase,
       null::uuid as store,
       null::text as h_yao;
update _t set store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select id from public.zones where slug = 'be'), 'client');
select tests.login_as((select yao from _t));
select public.complete_profile('Yao', (select id from public.zones where slug = 'be'), 'client');
select tests.logout();
insert into public.family_links (parent_id, child_id, status) select awa, yao, 'active' from _t;

-- Le parent n'autorise que les fruits.
select tests.login_as((select awa from _t));
select is(public.family_set_categories((select yao from _t), array[(select fruits from _t)])
          -> 'children' -> 0 -> 'allowed_categories' ->> 0,
          (select fruits from _t)::text, 'rayons autorisés enregistrés');
select throws_ok(format($$select public.family_set_categories(%L, array[gen_random_uuid()])$$, (select yao from _t)),
  '22023', null, 'rayon inconnu refusé');
select tests.login_as((select yao from _t));
select throws_ok(format($$select public.family_set_categories(%L, null)$$, (select awa from _t)),
  'P0002', null, 'l''enfant ne change pas les règles');
select tests.logout();

-- Commande de boissons de Yao : refusée ; de fruits : acceptée.
insert into public.products (id, store_id, name, currency_code, status, category_id)
select product, store, 'Jus de bissap', 'XOF', 'published', boissons from _t;
insert into public.product_variants (id, product_id)
select '85000000-0000-4000-8000-000000000004', product from _t;
insert into public.purchases (id, user_id, idempotency_key, country_code, currency_code, payment_method_id,
                              subtotal_minor, delivery_fee_minor, total_minor)
select purchase, yao, gen_random_uuid(), 'TG', 'XOF',
       (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'), 500, 0, 500
from _t;
insert into public.orders (id, purchase_id, store_id, fulfillment, currency_code, subtotal_minor,
                           delivery_fee_minor, total_minor, commission_minor)
select '85000000-0000-4000-8000-000000000003', purchase, store, 'pickup', 'XOF', 500, 0, 500, 0 from _t;
insert into public.order_items (order_id, product_id, variant_id, product_name, unit_price_minor, quantity, amount_minor)
select '85000000-0000-4000-8000-000000000003', product,
       '85000000-0000-4000-8000-000000000004',
       'Jus de bissap', 500, 1, 500
from _t;
select throws_ok(format($$select app.check_child_categories(%L, %L)$$, (select yao from _t), (select purchase from _t)),
  'P0001', 'child_category_blocked', 'rayon non autorisé : paiement refusé');
update public.products set category_id = (select fruits from _t) where id = (select product from _t);
select lives_ok(format($$select app.check_child_categories(%L, %L)$$, (select yao from _t), (select purchase from _t)),
  'rayon autorisé : paiement accepté');

-- Envoi entre proches : nommé dans les deux wallets.
select tests.login_as((select awa from _t));
select public.wallet_topup_simulated(5000, gen_random_uuid());
select tests.login_as((select yao from _t));
update _t set h_yao = public.my_wallet_handle() ->> 'handle';
select tests.login_as((select awa from _t));
select public.wallet_send((select h_yao from _t),
                          1000, 'Goûter', gen_random_uuid());
select is((select m ->> 'kind' || ':' || (m ->> 'counterpart')
           from jsonb_array_elements(public.my_wallet() -> 'movements') m where m ->> 'kind' like 'p2p%'),
          'p2p_sent:Yao', 'envoyé à Yao');
select tests.login_as((select yao from _t));
select is((select m ->> 'kind' || ':' || (m ->> 'counterpart')
           from jsonb_array_elements(public.my_wallet() -> 'movements') m where m ->> 'kind' like 'p2p%'),
          'p2p_received:Awa', 'reçu d''Awa');

select * from finish();
