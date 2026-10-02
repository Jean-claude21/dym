-- Référentiel : structure (spec 004, FR-001).

select plan(20);

select has_table('public', t, 'table ' || t)
from unnest(array[
  'currencies', 'countries', 'cities', 'zones', 'categories', 'store_origins', 'units',
  'payment_providers', 'payment_methods', 'commission_rules', 'delivery_fee_defaults',
  'feature_flags', 'ai_models', 'event_names', 'events', 'audit_log'
]) as t;

select col_type_is('public', 'commission_rules', 'rate_bps', 'integer', 'commission en points de base (entier)');
select col_type_is('public', 'delivery_fee_defaults', 'base_fee_minor', 'bigint', 'frais en unités mineures');
select has_function('public', 'track_event', 'track_event exposée');
select has_function('app', 'audit', 'app.audit existe');

select * from finish();
