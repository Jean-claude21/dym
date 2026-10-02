-- Référentiel : cohérence garantie par la base (spec 004, US3, FR-006).
-- Exécuté par le rôle propriétaire : la base refuse même une migration fautive.

select plan(12);

select throws_ok(
  $$insert into public.currencies values ('XAF', 4, 'F', 'fr')$$,
  '23514', null, 'devise : plus de 3 décimales refusée'
);
select throws_ok(
  $$insert into public.currencies values ('xaf', 0, 'F', 'fr')$$,
  '23514', null, 'devise : code non ISO refusé'
);
select throws_ok(
  $$insert into public.categories (slug, label) values ('sans-fr', '{"en": "No French"}')$$,
  '23514', null, 'libellé sans français refusé'
);
select throws_ok(
  $$insert into public.categories (slug, label) values ('fr-vide', '{"fr": "  "}')$$,
  '23514', null, 'libellé français vide refusé'
);
select throws_ok(
  $$insert into public.delivery_fee_defaults (country_code, currency_code, base_fee_minor)
    values ('TG', 'GHS', 500)$$,
  '23514', null, 'frais : devise différente de celle du pays refusée'
);
select throws_ok(
  $$insert into public.delivery_fee_defaults (country_code, city_id, currency_code, base_fee_minor)
    select 'TG', id, 'XOF', 500 from public.cities where slug = 'accra'$$,
  '23514', null, 'frais : ville hors du pays refusée'
);
select throws_ok(
  $$insert into public.delivery_fee_defaults (country_code, currency_code, base_fee_minor)
    values ('GH', 'GHS', -1)$$,
  '23514', null, 'frais : montant négatif refusé'
);
select throws_ok(
  $$insert into public.commission_rules (country_code, rate_bps) values ('TG', 10001)$$,
  '23514', null, 'commission : plus de 100 % refusée'
);
select throws_ok(
  $$insert into public.commission_rules (country_code, rate_bps) values ('TG', 500)$$,
  '23505', null, 'commission : deux règles ouvertes pour le même pays refusées'
);
select lives_ok(
  $$insert into public.commission_rules (country_code, category_id, rate_bps)
    select 'TG', id, 800 from public.categories where slug = 'pagnes-textile'$$,
  'commission : règle propre à un rayon acceptée'
);
select throws_ok(
  $$insert into public.categories (parent_id, slug, label)
    select id, 'trop-profond', '{"fr": "Trop profond"}' from public.categories where slug = 'tomates'$$,
  '23514', null, 'rayon : troisième niveau refusé'
);
select throws_ok(
  $$insert into public.units (country_code, code, label, kind) values ('TG', 'seau', '{"fr": "le seau"}', 'bucket')$$,
  '23514', null, 'unité : nature inconnue refusée'
);

select * from finish();
