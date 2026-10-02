-- Référentiel : accès des apps (spec 004, US1, US2, FR-003 à FR-005).

select plan(22);

create temporary table _ids as select tests.create_user('awa@example.com') as awa;
grant select on _ids to authenticated, anonymous;

-- ------------------------------------------------------------------ anonyme
select tests.login_anonymous();

select results_eq(
  'select code::text from public.countries order by code',
  array['TG'],
  'anonyme : seuls les pays actifs (Ghana inactif invisible)'
);
select ok((select count(*) from public.cities where country_code = 'GH') = 0, 'anonyme : villes du Ghana invisibles');
select ok(
  (select count(*) from public.zones z join public.cities c on c.id = z.city_id where c.slug = 'lome') >= 10,
  'anonyme : quartiers de Lomé visibles'
);
select ok((select count(*) from public.units where country_code = 'GH') = 0, 'anonyme : unités du Ghana invisibles');
select results_eq(
  $$select provider_code from public.payment_methods where country_code = 'TG' order by sort$$,
  array['cash'],
  'anonyme : seul le cash est proposé (Mobile Money inactif)'
);
select is((select count(*)::int from public.store_origins), 3, 'anonyme : trois origines de boutique');
select ok((select count(*) from public.delivery_fee_defaults) = 1, 'anonyme : frais de livraison du Togo');
select throws_ok('select * from public.commission_rules', '42501', null, 'anonyme : commissions illisibles');
select throws_ok('select * from public.ai_models', '42501', null, 'anonyme : modèles d''IA illisibles');

select throws_ok(
  $$insert into public.countries (code, name, currency_code, dial_code, default_locale, timezone)
    values ('BJ', '{"fr": "Bénin"}', 'XOF', '+229', 'fr', 'Africa/Porto-Novo')$$,
  '42501', null, 'anonyme : création de pays refusée'
);

-- ------------------------------------------------------------------ connecté
select tests.login_as((select awa from _ids));

select is((select count(*)::int from public.commission_rules), 1, 'connecté : commission du Togo lisible');
select throws_ok('select * from public.ai_models', '42501', null, 'connecté : modèles d''IA illisibles');
select throws_ok('select * from public.audit_log', '42501', null, 'connecté : audit illisible');

select throws_ok(
  $$update public.commission_rules set rate_bps = 5000$$,
  '42501', null, 'connecté : modification de commission refusée'
);
select throws_ok(
  $$update public.delivery_fee_defaults set base_fee_minor = 0$$,
  '42501', null, 'connecté : modification des frais refusée'
);
select throws_ok(
  $$delete from public.categories$$,
  '42501', null, 'connecté : suppression de rayon refusée'
);
select throws_ok(
  $$insert into public.feature_flags (key, is_enabled, description) values ('x', true, 'x')$$,
  '42501', null, 'connecté : création de flag refusée'
);
select throws_ok(
  $$select * from public.events$$,
  '42501', null, 'connecté : événements illisibles'
);

-- ------------------------------------------------------------------ parents inactifs
select tests.logout();
update public.categories set is_active = false where slug = 'legumes';
update public.zones set is_active = true;
update public.cities set is_active = false where slug = 'lome';

select tests.login_anonymous();
select is(
  (select count(*)::int from public.categories where slug in ('tomates', 'feuilles')),
  0,
  'rayon parent inactif : sous-rayons invisibles'
);
select is(
  (select count(*)::int from public.zones),
  0,
  'ville inactive : quartiers invisibles'
);
select tests.logout();

update public.cities set is_active = true;
update public.countries set is_active = false where code = 'TG';
select tests.login_anonymous();
select is((select count(*)::int from public.cities), 0, 'pays inactif : villes invisibles');
select is((select count(*)::int from public.payment_methods), 0, 'pays inactif : moyens de paiement invisibles');

select * from finish();
