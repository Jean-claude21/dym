-- 0026 — Plus de pays figé : la France rejoint le Togo et le Ghana (tous actifs).
-- Le pays d'une personne découle du quartier le plus proche de sa position
-- (nearest_zone), parmi tous les pays actifs.

insert into public.currencies (code, minor_units, symbol, format_locale) values
  ('EUR', 2, '€', 'fr')
on conflict (code) do nothing;

insert into public.countries (code, name, currency_code, dial_code, default_locale, timezone, is_active, sort) values
  ('FR', '{"fr": "France", "en": "France"}', 'EUR', '+33', 'fr', 'Europe/Paris', true, 3)
on conflict (code) do update set is_active = true;

update public.countries set is_active = true where code in ('TG', 'GH');

insert into public.cities (country_code, slug, name, sort, delivery_minutes) values
  ('FR', 'paris', 'Paris', 1, 30),
  ('FR', 'lyon', 'Lyon', 2, 30),
  ('FR', 'marseille', 'Marseille', 3, 35),
  ('FR', 'lille', 'Lille', 4, 30),
  ('FR', 'bordeaux', 'Bordeaux', 5, 30),
  ('FR', 'toulouse', 'Toulouse', 6, 30),
  ('FR', 'nantes', 'Nantes', 7, 30),
  ('FR', 'strasbourg', 'Strasbourg', 8, 30),
  ('FR', 'nice', 'Nice', 9, 30),
  ('FR', 'montpellier', 'Montpellier', 10, 30),
  ('FR', 'rennes', 'Rennes', 11, 30)
on conflict (country_code, slug) do nothing;

insert into public.zones (city_id, slug, name, sort, latitude, longitude)
select c.id, z.slug, z.name, z.sort, z.lat, z.lng
from public.cities c
join (values
  ('paris', 'paris-1', 'Paris 1er — Louvre', 1, 48.862, 2.336),
  ('paris', 'paris-2', 'Paris 2e — Bourse', 2, 48.868, 2.343),
  ('paris', 'paris-3', 'Paris 3e — Temple', 3, 48.863, 2.360),
  ('paris', 'paris-4', 'Paris 4e — Hôtel-de-Ville', 4, 48.854, 2.357),
  ('paris', 'paris-5', 'Paris 5e — Panthéon', 5, 48.844, 2.350),
  ('paris', 'paris-6', 'Paris 6e — Luxembourg', 6, 48.849, 2.333),
  ('paris', 'paris-7', 'Paris 7e — Palais-Bourbon', 7, 48.856, 2.312),
  ('paris', 'paris-8', 'Paris 8e — Élysée', 8, 48.873, 2.311),
  ('paris', 'paris-9', 'Paris 9e — Opéra', 9, 48.877, 2.337),
  ('paris', 'paris-10', 'Paris 10e — Entrepôt', 10, 48.876, 2.361),
  ('paris', 'paris-11', 'Paris 11e — Popincourt', 11, 48.859, 2.380),
  ('paris', 'paris-12', 'Paris 12e — Reuilly', 12, 48.835, 2.421),
  ('paris', 'paris-13', 'Paris 13e — Gobelins', 13, 48.828, 2.362),
  ('paris', 'paris-14', 'Paris 14e — Observatoire', 14, 48.829, 2.327),
  ('paris', 'paris-15', 'Paris 15e — Vaugirard', 15, 48.840, 2.293),
  ('paris', 'paris-16', 'Paris 16e — Passy', 16, 48.860, 2.262),
  ('paris', 'paris-17', 'Paris 17e — Batignolles', 17, 48.887, 2.307),
  ('paris', 'paris-18', 'Paris 18e — Château-Rouge', 18, 48.892, 2.348),
  ('paris', 'paris-19', 'Paris 19e — Buttes-Chaumont', 19, 48.887, 2.385),
  ('paris', 'paris-20', 'Paris 20e — Belleville', 20, 48.863, 2.401),
  ('lyon', 'presquile', 'Presqu''île', 1, 45.760, 4.835),
  ('lyon', 'croix-rousse', 'Croix-Rousse', 2, 45.776, 4.831),
  ('lyon', 'guillotiere', 'La Guillotière', 3, 45.752, 4.843),
  ('lyon', 'part-dieu', 'Part-Dieu', 4, 45.761, 4.857),
  ('lyon', 'vaise', 'Vaise', 5, 45.776, 4.805),
  ('marseille', 'noailles', 'Noailles', 1, 43.297, 5.383),
  ('marseille', 'belsunce', 'Belsunce', 2, 43.300, 5.377),
  ('marseille', 'castellane', 'Castellane', 3, 43.286, 5.384),
  ('marseille', 'la-joliette', 'La Joliette', 4, 43.305, 5.366),
  ('marseille', 'la-plaine', 'La Plaine', 5, 43.296, 5.390),
  ('lille', 'wazemmes', 'Wazemmes', 1, 50.627, 3.050),
  ('lille', 'vieux-lille', 'Vieux-Lille', 2, 50.641, 3.064),
  ('lille', 'moulins', 'Moulins', 3, 50.620, 3.069),
  ('bordeaux', 'capucins', 'Capucins', 1, 44.829, -0.567),
  ('bordeaux', 'chartrons', 'Chartrons', 2, 44.853, -0.570),
  ('bordeaux', 'saint-michel', 'Saint-Michel', 3, 44.834, -0.565),
  ('toulouse', 'capitole', 'Capitole', 1, 43.604, 1.443),
  ('toulouse', 'arnaud-bernard', 'Arnaud-Bernard', 2, 43.611, 1.440),
  ('toulouse', 'saint-cyprien', 'Saint-Cyprien', 3, 43.598, 1.432),
  ('nantes', 'bouffay', 'Bouffay', 1, 47.215, -1.553),
  ('nantes', 'talensac', 'Talensac', 2, 47.222, -1.558),
  ('strasbourg', 'krutenau', 'Krutenau', 1, 48.580, 7.757),
  ('strasbourg', 'neudorf', 'Neudorf', 2, 48.568, 7.758),
  ('nice', 'vieux-nice', 'Vieux-Nice', 1, 43.697, 7.276),
  ('nice', 'liberation', 'Libération', 2, 43.715, 7.263),
  ('montpellier', 'ecusson', 'Écusson', 1, 43.611, 3.877),
  ('montpellier', 'beaux-arts', 'Beaux-Arts', 2, 43.617, 3.883),
  ('rennes', 'centre', 'Centre', 1, 48.111, -1.680),
  ('rennes', 'lices', 'Les Lices', 2, 48.113, -1.684)
) as z (city, slug, name, sort, lat, lng) on z.city = c.slug and c.country_code = 'FR'
on conflict (city_id, slug) do nothing;

insert into public.units (country_code, code, label, kind, indicative_grams, indicative_ml, sort) values
  ('FR', 'piece', '{"fr": "la pièce", "en": "each"}', 'piece', null, null, 1),
  ('FR', 'kilo', '{"fr": "le kilo", "en": "per kilo"}', 'weight', 1000, null, 2),
  ('FR', 'demi_kilo','{"fr": "les 500 g", "en": "500 g"}', 'weight', 500, null, 3),
  ('FR', 'botte', '{"fr": "la botte", "en": "the bunch"}', 'bundle', 250, null, 4),
  ('FR', 'barquette', '{"fr": "la barquette", "en": "the punnet"}', 'piece', null, null, 5),
  ('FR', 'sachet', '{"fr": "le sachet", "en": "the bag"}', 'piece', null, null, 6),
  ('FR', 'litre', '{"fr": "le litre", "en": "per litre"}', 'volume', null, 1000, 7),
  ('FR', 'bouteille', '{"fr": "la bouteille", "en": "the bottle"}', 'volume', null, 750, 8)
on conflict do nothing;

-- Cash partout ; paiement en ligne simulé actif pour tester sans argent réel.
insert into public.payment_methods (country_code, provider_code, operator_code, label, sort, is_active)
select v.country, v.provider, v.operator, v.label::jsonb, v.sort, true
from (values
  ('FR', 'cash', null, '{"fr": "Espèces à la livraison", "en": "Cash on delivery"}', 1),
  ('FR', 'simulator', 'card', '{"fr": "Carte bancaire (simulée)", "en": "Card (simulated)"}', 2),
  ('TG', 'simulator', 'tmoney', '{"fr": "T-Money (simulé)", "en": "T-Money (simulated)"}', 4),
  ('GH', 'simulator', 'mtn', '{"fr": "MTN MoMo (simulé)", "en": "MTN MoMo (simulated)"}', 4)
) as v (country, provider, operator, label, sort)
where not exists (
  select 1 from public.payment_methods m
  where m.country_code = v.country and m.provider_code = v.provider
    and m.operator_code is not distinct from v.operator);

insert into public.commission_rules (country_code, category_id, rate_bps)
select 'FR', null, 0
where not exists (select 1 from public.commission_rules where country_code = 'FR' and category_id is null);

-- 3,90 € + 1,50 € par ramassage supplémentaire, offerte dès 40 €.
insert into public.delivery_fee_defaults (country_code, city_id, currency_code, base_fee_minor, extra_pickup_fee_minor, free_threshold_minor)
select 'FR', null, 'EUR', 390, 150, 4000
where not exists (select 1 from public.delivery_fee_defaults where country_code = 'FR' and city_id is null);
