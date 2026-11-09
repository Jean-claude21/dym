-- Événements de mesure et audit (spec 004, US4, FR-007, FR-008).

select plan(15);

create temporary table _ids as select tests.create_user('awa@example.com') as awa;
grant select on _ids to authenticated, anonymous;

-- ------------------------------------------------------------------ client
select tests.login_as((select awa from _ids));

select lives_ok(
  $$select public.track_event('search_performed', 'client', '00000000-0000-4000-8000-000000000001',
      'TG', null, null, '{"query": "tomates", "results": 12}')$$,
  'événement client autorisé'
);
select lives_ok(
  $$select public.track_event('search_performed', 'client', '00000000-0000-4000-8000-000000000001',
      'TG', null, null, '{"query": "tomates", "results": 12}')$$,
  'rejeu du même identifiant : accepté sans doublon'
);
select throws_ok(
  $$select public.track_event('order_created', 'client', gen_random_uuid(), 'TG')$$,
  '22023', null, 'événement serveur refusé côté client'
);
select throws_ok(
  $$select public.track_event('hacked_something', 'client', gen_random_uuid())$$,
  '22023', null, 'événement inconnu refusé'
);
select throws_ok(
  $$select public.track_event('cart_item_added', 'client', gen_random_uuid(), 'TG', 'product', 'p1',
      '{"email": "awa@example.com"}')$$,
  '22023', null, 'clé email refusée'
);
select throws_ok(
  $$select public.track_event('cart_item_added', 'client', gen_random_uuid(), 'TG', 'product', 'p1',
      '{"note": "écris-moi à awa@example.com"}')$$,
  '22023', null, 'valeur contenant un email refusée'
);
select throws_ok(
  $$select public.track_event('cart_item_added', 'client', gen_random_uuid(), 'TG', 'product', 'p1',
      '{"meta": {"contact": "+228 90 00 00 00"}}')$$,
  '22023', null, 'numéro de téléphone imbriqué refusé'
);
select throws_ok(
  format(
    $$select public.track_event('search_performed', 'client', gen_random_uuid(), 'TG', null, null, %L)$$,
    jsonb_build_object('blob', repeat('x', 5000))
  ),
  '22023', null, 'propriétés de plus de 4 Ko refusées'
);
select lives_ok(
  $$select public.track_event('cart_item_added', 'client', gen_random_uuid(), 'TG', 'product', 'p1',
      '{"product_name": "Tomates", "quantity": 2, "store_origin": "marche"}')$$,
  'nom de produit accepté (pas une donnée personnelle)'
);

select tests.login_anonymous();
select lives_ok(
  $$select public.track_event('product_viewed', 'client', gen_random_uuid(), 'TG', 'product', 'p1')$$,
  'événement anonyme accepté'
);

-- ------------------------------------------------------------------ vérification (propriétaire)
select tests.logout();

select is(
  (select count(*)::int from public.events where occurred_at = now() and name = 'search_performed'
     and occurred_at = now()),
  1,
  'un seul événement pour deux envois du même identifiant'
);
select is(
  (select actor_id from public.events where occurred_at = now() and name = 'search_performed'),
  (select awa from _ids),
  'auteur imposé par le jeton'
);
select is(
  (select actor_role from public.events where occurred_at = now() and name = 'product_viewed'),
  'anonymous',
  'rôle anonyme enregistré'
);

-- ------------------------------------------------------------------ audit
select app.audit(
  (select awa from _ids), 'store_suspended', 'store', 's1',
  '{"status": "open"}', '{"status": "suspended"}', 'fraude signalée'
);
select throws_ok(
  $$update public.audit_log set reason = 'effacé'$$,
  '42501', null, 'audit non modifiable, même par le propriétaire'
);
select throws_ok(
  $$delete from public.audit_log$$,
  '42501', null, 'audit non supprimable'
);

select * from finish();
