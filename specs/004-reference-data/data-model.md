# Data Model — 004 Référentiel générique

Conventions :
- `label jsonb not null check (label ? 'fr')` ;
- `is_active boolean not null default true` ;
- `created_at` et `updated_at` (trigger `app.set_updated_at`) ;
- montants en `bigint` d'unités mineures, `>= 0`.

| Table | Colonnes clés | Contraintes | Accès apps |
|---|---|---|---|
| `currencies` | `code char(3)` PK, `minor_units smallint`, `symbol`, `format_locale` | `code ~ '^[A-Z]{3}$'`, `minor_units between 0 and 3` | lecture (tous) |
| `countries` | `code char(2)` PK, `name jsonb`, `currency_code` → currencies, `dial_code`, `default_locale`, `timezone`, `is_active`, `sort` | `code ~ '^[A-Z]{2}$'`, `dial_code ~ '^\+[0-9]{1,4}$'` | lecture des actifs |
| `cities` | `id uuid`, `country_code`, `slug`, `name`, `is_active`, `sort` | unique `(country_code, slug)` | actives si pays actif |
| `zones` | `id uuid`, `city_id`, `slug`, `name`, `is_active`, `sort` | unique `(city_id, slug)` | actives si ville et pays actifs |
| `categories` | `id uuid`, `parent_id` → categories, `slug` unique, `label`, `icon`, `sort`, `is_active` | 2 niveaux max (trigger) | actives, parent actif |
| `store_origins` | `code text` PK (`marche`, `maison`, `magasin`), `label`, `description`, `sort`, `is_active` | `code ~ '^[a-z_]+$'` | actives |
| `units` | `id uuid`, `country_code`, `code`, `label`, `kind` (`piece`, `weight`, `volume`, `bundle`), `indicative_grams`, `indicative_ml`, `sort`, `is_active` | unique `(country_code, code)`, quantités `> 0` | actives si pays actif |
| `payment_providers` | `code text` PK (`cash`, `moneroo`, `chariow`), `label`, `kind` (`cash`, `mobile_money`, `card`, `digital`), `is_active` | — | actifs |
| `payment_methods` | `id uuid`, `country_code`, `provider_code`, `operator_code` (null pour cash), `label`, `sort`, `is_active` | unique `(country_code, provider_code, coalesce(operator_code,''))` | actifs si fournisseur et pays actifs |
| `commission_rules` | `id uuid`, `country_code`, `category_id` null (défaut du pays), `rate_bps int`, `valid_from`, `valid_to` | `rate_bps between 0 and 10000`, `valid_to > valid_from`, unique actif (D3) | lecture (connectés) |
| `delivery_fee_defaults` | `id uuid`, `country_code`, `city_id` null, `currency_code`, `base_fee_minor`, `extra_pickup_fee_minor`, `free_threshold_minor` null, `valid_from`, `valid_to` | montants `>= 0`, devise = devise du pays (trigger), unique actif `(country, coalesce(city))` | lecture (tous) si pays actif |
| `feature_flags` | `id uuid`, `key`, `country_code` null (global), `is_enabled`, `description` | `key ~ '^[a-z][a-z0-9_]*$'`, unique `(key, coalesce(country_code,'*'))` | lecture (tous) |
| `ai_models` | `usage text` PK, `provider`, `model`, `params jsonb`, `is_active` | — | **aucun** |
| `event_names` | `name text` PK, `emitted_by` (`client`, `server`), `description` | `name ~ '^[a-z]+(_[a-z]+)+$'` | **aucun** |
| `events` | `id bigint identity`, `occurred_at`, `actor_id uuid`, `actor_role`, `app`, `country_code`, `name` → event_names, `entity_type`, `entity_id`, `props jsonb`, `client_event_id uuid` unique | `pg_column_size(props) <= 4096` | **aucun** (écriture par `track_event`) |
| `audit_log` | `id bigint identity`, `occurred_at`, `actor_id`, `action`, `entity_type`, `entity_id`, `before jsonb`, `after jsonb`, `reason` | ajout seul (trigger refusant `UPDATE` et `DELETE`) | **aucun** |

## Fonctions

| Fonction | Sécurité | Rôle |
|---|---|---|
| `public.track_event(p_name, p_app, p_country_code, p_entity_type, p_entity_id, p_props, p_client_event_id)` | `SECURITY DEFINER`, exécutable par `authenticated` et `anonymous` | Événement client : nom autorisé (`emitted_by = 'client'`), auteur et rôle imposés, garde anti-données personnelles, déduplication silencieuse |
| `app.emit_event(p_name, p_actor_id, p_actor_role, p_app, p_country_code, p_entity_type, p_entity_id, p_props)` | interne (non exposé) | Événement serveur, appelé par les fonctions métier |
| `app.audit(p_actor_id, p_action, p_entity_type, p_entity_id, p_before, p_after, p_reason)` | interne | Entrée d'audit |
| `app.assert_no_personal_data(jsonb)` | interne | Refuse les clés et valeurs personnelles (récursif) |

## Modèles Dart (`dym_models`)

| Modèle | Champs |
|---|---|
| `LocalizedText` (`dym_core`) | `Map<String, String>` ; `resolve(locale)` → langue demandée, sinon `fr`, sinon la première valeur |
| `CurrencyInfo` → `Currency` | `code`, `minorUnits`, `symbol`, `formatLocale` |
| `Country` | `code`, `name`, `currencyCode`, `dialCode`, `defaultLocale`, `timezone` |
| `City`, `Zone` | `id`, `countryCode`/`cityId`, `slug`, `name` |
| `Category` | `id`, `parentId`, `slug`, `label`, `icon`, `sort` |
| `StoreOriginInfo` | `code`, `label`, `description` |
| `MarketUnit` | `id`, `countryCode`, `code`, `label`, `kind`, `indicativeGrams`, `indicativeMl` |
| `PaymentMethod` | `id`, `countryCode`, `providerCode`, `operatorCode`, `label`, `kind` |
| `DeliveryFeeDefault` | `countryCode`, `cityId`, `currencyCode`, `baseFeeMinor`, `extraPickupFeeMinor`, `freeThresholdMinor` |
| `CommissionRule` | `countryCode`, `categoryId`, `rateBps` |
| `FeatureFlag` | `key`, `countryCode`, `isEnabled` |
| `CountryConfig` | agrégat de tout ce qui précède pour un pays |
