-- Remplacement validé par photo et garantie fraîcheur (spec 034).

select plan(16);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       '2026-10-05 10:00:00+00'::timestamptz as morning,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '30000000-0000-4000-8000-000000000001'::uuid as tomate,
       '30000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       '30000000-0000-4000-8000-000000000003'::uuid as gombo,
       '30000000-0000-4000-8000-000000000004'::uuid as gombo_tas,
       '30000000-0000-4000-8000-000000000005'::uuid as piment,
       '30000000-0000-4000-8000-000000000006'::uuid as piment_tas,
       null::uuid as kodjo_store, null::uuid as order1, null::uuid as adj, null::uuid as adj2;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

create function pg_temp._publish(p_id uuid, p_variant uuid, p_name text, p_price bigint) returns void
language sql as $$
  select public.save_product(jsonb_build_object(
    'id', p_id, 'name', p_name, 'category_id', (select tomates from _t), 'price_minor', p_price,
    'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || p_id || '.jpg'),
    'variants', jsonb_build_array(jsonb_build_object('id', p_variant, 'stock_quantity', 20))));
  select public.publish_product(p_id);
$$;
grant execute on function pg_temp._publish(uuid, uuid, text, bigint) to authenticated;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select pg_temp._publish((select tomate from _t), (select tomate_tas from _t), 'Tomates', 500);
select pg_temp._publish((select gombo from _t), (select gombo_tas from _t), 'Gombo', 300);
select pg_temp._publish((select piment from _t), (select piment_tas from _t), 'Piment', 200);

select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');
select public.cart_add((select tomate_tas from _t), 2);
select public.cart_add((select gombo_tas from _t), 1);
select tests.logout();
update _t set order1 = (select (o ->> 'id')::uuid from jsonb_array_elements(
  app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
    'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
    'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')),
    (select morning from _t)) -> 'purchase' -> 'orders') o limit 1);
select app.transition_order((select kodjo from _t), (select order1 from _t), 'accepted', 'pending');

create function pg_temp._photo() returns text language sql as $$
  select 'orders/' || (select order1 from _t) || '/' || gen_random_uuid() || '.jpg'
$$;
grant execute on function pg_temp._photo() to authenticated;

-- Proposition : réservée à la vendeuse, photo obligatoire, produit de la boutique.
select tests.login_as((select awa from _t));
select throws_ok($$select public.propose_substitution((select order1 from _t), (select tomate_tas from _t),
  (select piment_tas from _t), pg_temp._photo())$$, 'P0002', null, 'la cliente ne propose pas');
select tests.login_as((select kodjo from _t));
select throws_ok($$select public.propose_substitution((select order1 from _t), (select tomate_tas from _t),
  (select piment_tas from _t), 'stores/x.jpg')$$, '22023', 'photo_required', 'photo obligatoire');
select throws_ok($$select public.propose_substitution((select order1 from _t), (select tomate_tas from _t),
  (select tomate_tas from _t), pg_temp._photo())$$, '22023', 'invalid_substitute', 'même produit refusé');
select is(public.propose_substitution((select order1 from _t), (select tomate_tas from _t),
  (select piment_tas from _t), pg_temp._photo(), 'Plus de tomates ce matin') -> 0 ->> 'status', 'pending',
  'remplacement proposé');
select public.propose_substitution((select order1 from _t), (select gombo_tas from _t),
  (select piment_tas from _t), pg_temp._photo());
select tests.logout();
update _t set adj = (select id from public.order_adjustments where variant_id = (select tomate_tas from _t)),
              adj2 = (select id from public.order_adjustments where variant_id = (select gombo_tas from _t));
select is((select count(*)::int from public.notifications where kind = 'substitution_proposed'
           and user_id = (select awa from _t)), 2, 'cliente prévenue');

-- Une autre personne ne répond pas.
select tests.login_as((select ama from _t));
select throws_ok(format($$select public.answer_substitution('%s', true)$$,
  (select adj from _t)), 'P0002', null, 'réponse d''autrui refusée');

-- Tomates refusées : montant rendu (2 × 500) ; gombo accepté : la ligne change, même prix.
select tests.login_as((select awa from _t));
select public.answer_substitution((select adj from _t), false);
select is((public.my_wallet() ->> 'balance_minor')::bigint, 1000::bigint, 'refus : 1 000 rendus sur le wallet');
select public.answer_substitution((select adj2 from _t), true);
select tests.logout();
select is((select product_name || ' · ' || amount_minor from public.order_items
           where order_id = (select order1 from _t) and variant_id = (select piment_tas from _t)),
  'Piment · 300', 'accepté : produit remplacé, prix inchangé');
select is((select total_minor from public.orders where id = (select order1 from _t)), 1300::bigint,
  'total de la commande inchangé');

-- Livrée : garantie fraîcheur sur la ligne remplacée.
select app.transition_order((select kodjo from _t), (select order1 from _t), 'preparing', 'accepted');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'ready', 'preparing');
select app.transition_order((select kodjo from _t), (select order1 from _t), 'delivered', 'ready');
update public.countries set freshness_claims_per_month = 0 where code = 'TG';
select tests.login_as((select awa from _t));
select throws_ok($$select public.claim_freshness((select order1 from _t), (select piment_tas from _t),
  pg_temp._photo())$$, '22023', 'claim_limit_reached', 'limite du mois atteinte');
select tests.logout();
update public.countries set freshness_claims_per_month = 3 where code = 'TG';
select tests.login_as((select awa from _t));
select is((select a ->> 'status' from jsonb_array_elements(public.claim_freshness((select order1 from _t),
  (select piment_tas from _t), pg_temp._photo(), 'Piment abîmé')) a where a ->> 'kind' = 'freshness'),
  'credited', 'fraîcheur : ligne remboursée');
select is((public.my_wallet() ->> 'balance_minor')::bigint, 1300::bigint, 'wallet : + 300');
select throws_ok($$select public.claim_freshness((select order1 from _t), (select piment_tas from _t),
  pg_temp._photo())$$, '22023', 'already_credited', 'une ligne n''est rendue qu''une fois');
select throws_ok($$select public.claim_freshness((select order1 from _t), (select tomate_tas from _t),
  pg_temp._photo())$$, '22023', 'already_credited', 'ligne refusée déjà rendue');
select tests.logout();

-- Délai dépassé ; grand livre équilibré.
update public.orders set delivered_at = now() - interval '3 days' where id = (select order1 from _t);
delete from public.order_adjustments where kind = 'freshness';
select tests.login_as((select awa from _t));
select throws_ok($$select public.claim_freshness((select order1 from _t), (select piment_tas from _t),
  pg_temp._photo())$$, '22023', 'claim_window_closed', 'délai dépassé');
select tests.logout();
select is((select sum(amount_minor)::bigint from public.ledger_entries), 0::bigint, 'grand livre équilibré');

select * from finish();
