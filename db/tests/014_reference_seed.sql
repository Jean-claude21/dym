-- Valeurs initiales (spec 004, FR-009) et ouverture d'un pays par configuration (SC-001).

select plan(11);

select is(
  (select currency_code::text from public.countries where code = 'TG'),
  'XOF', 'Togo en franc CFA'
);
select is((select minor_units::int from public.currencies where code = 'XOF'), 0, 'XOF sans décimale');
select is((select minor_units::int from public.currencies where code = 'GHS'), 2, 'GHS à 2 décimales');
select ok(not (select is_active from public.countries where code = 'GH'), 'Ghana inactif au lancement');
select ok(
  exists (select 1 from public.zones z join public.cities c on c.id = z.city_id
          where c.slug = 'lome' and z.slug in ('be', 'tokoin', 'adawlato')
          having count(*) = 3),
  'Lomé : Bè, Tokoin, Adawlato'
);
select results_eq(
  'select code from public.store_origins order by sort',
  array['marche', 'maison', 'magasin'],
  'trois origines de boutique'
);
select ok(
  exists (select 1 from public.units where country_code = 'GH' and code = 'olonka')
  and not exists (select 1 from public.units where country_code = 'TG' and code = 'olonka'),
  'olonka : unité du Ghana seulement'
);
select results_eq(
  $$select base_fee_minor, extra_pickup_fee_minor, free_threshold_minor
    from public.delivery_fee_defaults where country_code = 'TG'$$,
  $$values (500::bigint, 200::bigint, 4000::bigint)$$,
  'frais du Togo : ceux de la maquette validée'
);
select ok(
  (select bool_and(not is_enabled) from public.feature_flags where key in ('momo_payments', 'ai_product_suggestion')),
  'Mobile Money et IA désactivés au lancement'
);

-- Ouvrir le Ghana : une seule mise à jour de données.
update public.countries set is_active = true where code = 'GH';
select tests.login_anonymous();
select ok(
  exists (select 1 from public.countries where code = 'GH')
  and exists (select 1 from public.cities where slug = 'accra')
  and exists (select 1 from public.payment_methods where country_code = 'GH' and provider_code = 'cash'),
  'Ghana activé : pays, ville et cash visibles sans autre changement'
);
select is(
  (select currency_code::text from public.delivery_fee_defaults where country_code = 'GH'),
  'GHS', 'Ghana : frais en cedis'
);

select * from finish();
