-- 0086 — Ouverture de la Côte d'Ivoire (données de référence, décision 0015) pour les essais avec
-- des testeuses en Afrique de l'Ouest. Abidjan et ses communes ; unités, créneaux, abonnements,
-- synonymes et flags repris du Togo (même devise, mêmes usages) ; Mobile Money simulé tant que
-- Moneroo n'a pas de passerelle XOF (moyens Moneroo créés désactivés).

insert into public.countries (code, name, currency_code, dial_code, default_locale, timezone, is_active, sort)
values ('CI', '{"fr": "Côte d''Ivoire", "en": "Côte d''Ivoire"}', 'XOF', '+225', 'fr', 'Africa/Abidjan', false, 3)
on conflict (code) do nothing;

-- Réglages du pays repris du Togo (délais, fraîcheur, affiliation, livreurs, alertes).
update public.countries ci set
  schedule_days_ahead = tg.schedule_days_ahead, freshness_claim_hours = tg.freshness_claim_hours,
  freshness_claims_per_month = tg.freshness_claims_per_month, affiliate_min_rate_bps = tg.affiliate_min_rate_bps,
  affiliate_window_days = tg.affiliate_window_days, affiliate_launch_subsidy = tg.affiliate_launch_subsidy,
  courier_max_active = tg.courier_max_active, qr_commission_bps = tg.qr_commission_bps,
  ops_pending_alert_minutes = tg.ops_pending_alert_minutes, ops_ready_alert_minutes = tg.ops_ready_alert_minutes,
  ops_transit_alert_minutes = tg.ops_transit_alert_minutes, order_auto_refuse_minutes = tg.order_auto_refuse_minutes,
  courier_relaunch_minutes = tg.courier_relaunch_minutes, courier_relaunch_max = tg.courier_relaunch_max
from public.countries tg
where ci.code = 'CI' and tg.code = 'TG';

insert into public.cities (country_code, slug, name, sort, delivery_minutes, service_radius_m)
values ('CI', 'abidjan', 'Abidjan', 1, 30, 25000)
on conflict do nothing;

insert into public.zones (city_id, slug, name, sort, latitude, longitude)
select c.id, z.slug, z.name, z.sort, z.lat, z.lng
from public.cities c
cross join (values
  ('plateau', 'Plateau', 1, 5.323700, -4.020100),
  ('cocody', 'Cocody', 2, 5.359900, -3.981000),
  ('marcory', 'Marcory', 3, 5.303000, -3.979000),
  ('treichville', 'Treichville', 4, 5.298000, -4.008000),
  ('yopougon', 'Yopougon', 5, 5.345000, -4.089000),
  ('adjame', 'Adjamé', 6, 5.361000, -4.024000),
  ('koumassi', 'Koumassi', 7, 5.296000, -3.952000),
  ('abobo', 'Abobo', 8, 5.418000, -4.020000),
  ('port-bouet', 'Port-Bouët', 9, 5.256000, -3.926000),
  ('bingerville', 'Bingerville', 10, 5.355000, -3.885000)
) z(slug, name, sort, lat, lng)
where c.country_code = 'CI' and c.slug = 'abidjan'
on conflict do nothing;

-- Tables de réglage par pays : copie des lignes du Togo (hors identifiants et dates).
do $$
declare
  t text;
  cols text;
begin
  foreach t in array array['units', 'commission_rules', 'delivery_windows', 'membership_plans',
                           'search_synonyms', 'feature_flags']
  loop
    select string_agg(quote_ident(column_name), ', ' order by ordinal_position) into cols
    from information_schema.columns
    where table_schema = 'public' and table_name = t
      and column_name not in ('id', 'created_at', 'updated_at', 'country_code')
      and is_generated = 'NEVER';
    execute format(
      'insert into public.%I (country_code, %s) select ''CI'', %s from public.%I where country_code = ''TG'' on conflict do nothing',
      t, cols, cols, t);
  end loop;
end
$$;

insert into public.delivery_fee_defaults (country_code, city_id, currency_code, base_fee_minor, extra_pickup_fee_minor, free_threshold_minor)
values ('CI', null, 'XOF', 500, 200, 4000);

insert into public.payment_methods (country_code, provider_code, operator_code, label, sort, is_active) values
  ('CI', 'cash', null, '{"fr": "Cash à la livraison", "en": "Cash on delivery"}', 1, true),
  ('CI', 'simulator', 'orange', '{"fr": "Orange Money (simulé)", "en": "Orange Money (simulated)"}', 2, true),
  ('CI', 'simulator', 'mtn', '{"fr": "MTN MoMo (simulé)", "en": "MTN MoMo (simulated)"}', 3, true),
  ('CI', 'simulator', 'moov', '{"fr": "Moov Money (simulé)", "en": "Moov Money (simulated)"}', 4, true),
  ('CI', 'simulator', 'wave', '{"fr": "Wave (simulé)", "en": "Wave (simulated)"}', 5, true),
  ('CI', 'moneroo', 'orange', '{"fr": "Orange Money", "en": "Orange Money"}', 6, false),
  ('CI', 'moneroo', 'mtn', '{"fr": "MTN MoMo", "en": "MTN MoMo"}', 7, false),
  ('CI', 'moneroo', 'wave', '{"fr": "Wave", "en": "Wave"}', 8, false)
on conflict do nothing;
insert into public.payment_methods (country_code, provider_code, operator_code, label, sort, is_active)
select 'CI', provider_code, operator_code, label, 9, is_active from public.payment_methods
where country_code = 'TG' and provider_code = 'wallet'
on conflict do nothing;

-- Ouverte si tout ce qu'exige l'activation est présent (sinon, l'admin la complète puis l'active).
update public.countries set is_active = true
where code = 'CI' and cardinality(app.country_missing('CI')) = 0;
