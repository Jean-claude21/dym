-- 0004 — Valeurs initiales du référentiel (spec 004, FR-009).
-- Le Togo (pilote) est actif ; le Ghana est prêt mais inactif : l'ouvrir se
-- fait en activant le pays (SC-001). Les valeurs commerciales (commission,
-- frais) sont initiales et seront fixées par le porteur produit.

insert into public.currencies (code, minor_units, symbol, format_locale) values
  ('XOF', 0, 'F CFA', 'fr'),
  ('GHS', 2, 'GH₵', 'en');

insert into public.countries (code, name, currency_code, dial_code, default_locale, timezone, is_active, sort) values
  ('TG', '{"fr": "Togo", "en": "Togo"}', 'XOF', '+228', 'fr', 'Africa/Lome', true, 1),
  ('GH', '{"fr": "Ghana", "en": "Ghana"}', 'GHS', '+233', 'en', 'Africa/Accra', false, 2);

insert into public.cities (country_code, slug, name, sort) values
  ('TG', 'lome', 'Lomé', 1),
  ('GH', 'accra', 'Accra', 1);

insert into public.zones (city_id, slug, name, sort)
select c.id, z.slug, z.name, z.sort
from public.cities c
join (values
  ('lome', 'be', 'Bè', 1),
  ('lome', 'be-kpota', 'Bè Kpota', 2),
  ('lome', 'tokoin', 'Tokoin', 3),
  ('lome', 'adawlato', 'Adawlato', 4),
  ('lome', 'nyekonakpoe', 'Nyékonakpoè', 5),
  ('lome', 'kodjoviakope', 'Kodjoviakopé', 6),
  ('lome', 'hedzranawoe', 'Hédzranawoé', 7),
  ('lome', 'adidogome', 'Adidogomé', 8),
  ('lome', 'agoe', 'Agoè', 9),
  ('lome', 'kegue', 'Kégué', 10),
  ('lome', 'baguida', 'Baguida', 11),
  ('accra', 'osu', 'Osu', 1),
  ('accra', 'madina', 'Madina', 2),
  ('accra', 'makola', 'Makola', 3),
  ('accra', 'kaneshie', 'Kaneshie', 4),
  ('accra', 'east-legon', 'East Legon', 5)
) as z (city, slug, name, sort) on z.city = c.slug;

-- Rayons du design validé (accueil, rayon Légumes), puis rayons non alimentaires.
insert into public.categories (slug, label, icon, sort) values
  ('legumes', '{"fr": "Légumes", "en": "Vegetables"}', 'legumes', 1),
  ('fruits', '{"fr": "Fruits", "en": "Fruit"}', 'fruits', 2),
  ('fait-maison', '{"fr": "Fait maison", "en": "Homemade"}', 'fait-maison', 3),
  ('tubercules', '{"fr": "Tubercules", "en": "Tubers"}', 'tubercules', 4),
  ('poissons-fumes', '{"fr": "Poissons fumés", "en": "Smoked fish"}', 'poissons', 5),
  ('epices', '{"fr": "Épices", "en": "Spices"}', 'epices', 6),
  ('cereales-farines', '{"fr": "Céréales et farines", "en": "Grains and flours"}', 'cereales', 7),
  ('huiles-condiments', '{"fr": "Huiles et condiments", "en": "Oils and condiments"}', 'huiles', 8),
  ('boissons', '{"fr": "Boissons", "en": "Drinks"}', 'boissons', 9),
  ('hygiene', '{"fr": "Hygiène", "en": "Hygiene"}', 'hygiene', 10),
  ('pagnes-textile', '{"fr": "Pagnes et textile", "en": "Wax and textiles"}', 'textile', 11),
  ('beaute', '{"fr": "Beauté", "en": "Beauty"}', 'beaute', 12);

insert into public.categories (parent_id, slug, label, sort)
select p.id, s.slug, s.label::jsonb, s.sort
from public.categories p
join (values
  ('legumes', 'tomates', '{"fr": "Tomates", "en": "Tomatoes"}', 1),
  ('legumes', 'feuilles', '{"fr": "Feuilles", "en": "Leafy greens"}', 2),
  ('legumes', 'piments-oignons', '{"fr": "Piments et oignons", "en": "Peppers and onions"}', 3),
  ('fait-maison', 'jus-maison', '{"fr": "Jus maison", "en": "Homemade juices"}', 1),
  ('fait-maison', 'plats-sauces', '{"fr": "Plats et sauces", "en": "Dishes and sauces"}', 2),
  ('fait-maison', 'patisseries', '{"fr": "Pâtisseries", "en": "Pastries"}', 3)
) as s (parent, slug, label, sort) on s.parent = p.slug;

insert into public.store_origins (code, label, description, sort) values
  ('marche', '{"fr": "Au marché", "en": "At the market"}',
   '{"fr": "Tu as un étal ou une place au marché.", "en": "You have a stall at the market."}', 1),
  ('maison', '{"fr": "Fait maison", "en": "Homemade"}',
   '{"fr": "Tu prépares ou vends depuis ta maison.", "en": "You cook or sell from home."}', 2),
  ('magasin', '{"fr": "Boutique", "en": "Shop"}',
   '{"fr": "Tu as un magasin ou un kiosque.", "en": "You have a shop or a kiosk."}', 3);

-- Unités du marché (quantités indicatives, ajustables par l'admin).
insert into public.units (country_code, code, label, kind, indicative_grams, indicative_ml, sort) values
  ('TG', 'tas', '{"fr": "le tas", "en": "the heap"}', 'bundle', 500, null, 1),
  ('TG', 'botte', '{"fr": "la botte", "en": "the bunch"}', 'bundle', 250, null, 2),
  ('TG', 'boite', '{"fr": "la boîte", "en": "the tin"}', 'volume', null, 1000, 3),
  ('TG', 'bol', '{"fr": "le bol", "en": "the bowl"}', 'volume', null, 500, 4),
  ('TG', 'piece', '{"fr": "la pièce", "en": "each"}', 'piece', null, null, 5),
  ('TG', 'sachet', '{"fr": "le sachet", "en": "the bag"}', 'piece', null, null, 6),
  ('TG', 'kilo', '{"fr": "le kilo", "en": "per kilo"}', 'weight', 1000, null, 7),
  ('TG', 'litre', '{"fr": "le litre", "en": "per litre"}', 'volume', null, 1000, 8),
  ('GH', 'heap', '{"fr": "le tas", "en": "the heap"}', 'bundle', 500, null, 1),
  ('GH', 'bunch', '{"fr": "la botte", "en": "the bunch"}', 'bundle', 250, null, 2),
  ('GH', 'olonka', '{"fr": "l''olonka", "en": "the olonka"}', 'volume', null, 2500, 3),
  ('GH', 'margarine_tin', '{"fr": "la boîte", "en": "the margarine tin"}', 'volume', null, 500, 4),
  ('GH', 'piece', '{"fr": "la pièce", "en": "each"}', 'piece', null, null, 5),
  ('GH', 'kilo', '{"fr": "le kilo", "en": "per kilo"}', 'weight', 1000, null, 6),
  ('GH', 'litre', '{"fr": "le litre", "en": "per litre"}', 'volume', null, 1000, 7);

insert into public.payment_providers (code, label, kind) values
  ('cash', '{"fr": "Cash à la livraison", "en": "Cash on delivery"}', 'cash'),
  ('moneroo', '{"fr": "Mobile Money", "en": "Mobile Money"}', 'mobile_money'),
  ('chariow', '{"fr": "Chariow", "en": "Chariow"}', 'digital');

-- Cash actif ; Mobile Money (Moneroo) inactif jusqu'à la validation du KYC.
insert into public.payment_methods (country_code, provider_code, operator_code, label, sort, is_active) values
  ('TG', 'cash', null, '{"fr": "Cash à la livraison", "en": "Cash on delivery"}', 1, true),
  ('TG', 'moneroo', 'tmoney', '{"fr": "T-Money", "en": "T-Money"}', 2, false),
  ('TG', 'moneroo', 'flooz', '{"fr": "Flooz", "en": "Flooz"}', 3, false),
  ('GH', 'cash', null, '{"fr": "Cash à la livraison", "en": "Cash on delivery"}', 1, true),
  ('GH', 'moneroo', 'mtn', '{"fr": "MTN MoMo", "en": "MTN MoMo"}', 2, false),
  ('GH', 'moneroo', 'telecel', '{"fr": "Telecel Cash", "en": "Telecel Cash"}', 3, false);

-- Commission : 0 % en attendant la décision du porteur produit (avant le pilote).
insert into public.commission_rules (country_code, category_id, rate_bps) values
  ('TG', null, 0),
  ('GH', null, 0);

-- Frais de la maquette validée (écran Panier) : 500 + 200 par ramassage
-- supplémentaire, offerte dès 4 000 F CFA. Ghana : valeurs équivalentes.
insert into public.delivery_fee_defaults (country_code, city_id, currency_code, base_fee_minor, extra_pickup_fee_minor, free_threshold_minor) values
  ('TG', null, 'XOF', 500, 200, 4000),
  ('GH', null, 'GHS', 1000, 400, 8000);

insert into public.feature_flags (key, country_code, is_enabled, description) values
  ('momo_payments', null, false, 'Paiement Mobile Money (Moneroo)'),
  ('ai_product_suggestion', null, false, 'Fiche produit proposée par l''IA depuis une photo'),
  ('phone_otp', null, false, 'Connexion par téléphone'),
  ('product_substitution', null, true, 'Remplacement d''un produit manquant par un équivalent au même prix');

insert into public.ai_models (usage, provider, model, params, is_active) values
  ('product_from_photo', 'openai', 'gpt-5.4-mini', '{"temperature": 0.2}', false);
