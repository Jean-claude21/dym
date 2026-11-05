# Implementation Plan: Onboarding et réglages de la boutique

**Branch**: `feat/006-store-onboarding` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

- **Migration `0006_stores.sql`** :
  - tables `stores`, `store_pickup_addresses`, `store_delivery_zones`,
    `store_payment_methods` et `store_hours` ;
  - lecture publique par colonnes (sans `owner_id`) des boutiques actives ;
  - toutes les écritures par fonctions `SECURITY DEFINER` : `start_store`, `update_store`,
    `set_store_pickup_address`, `set_store_delivery_zones`, `set_store_payment_methods`,
    `set_store_hours`, `publish_store`, `set_store_open` et `my_store`.
- **Dart** :
  - `dym_models` : `Store`, `StoreHours`, `PickupAddress`, `MyStore` ;
  - `dym_data` : `StoreRepository`.
- **App vendeuse** : feature `store` dans l'app (seule utilisatrice, `PACKAGES.md` règle 2),
  avec :
  - `StoreOnboardingView` (7 étapes, un viewmodel) ;
  - `StoreOpenedView` ;
  - `MyStoreView` (« Ma boutique »).

  Le démarrage oriente vers l'onboarding tant que la boutique n'est pas active.
- **Galerie** : écrans 16 à 23 pour la comparaison.

## Technical Context

Même pile que les specs 003 à 005. Aucune nouvelle dépendance.

## Constitution Check

| Principe | Vérification | Statut |
|---|---|---|
| I | Spec `store-onboarding` (Phase 2), IDs cités | ✅ |
| II | 07 validé ; 16 à 23 générés dans la direction, à valider (dérogation de la roadmap) | ⚠️ validation |
| III | Pays et devise déduits du quartier, complétude et statut décidés en SQL | ✅ |
| IV | Origines, quartiers, rayons et moyens de paiement lus du référentiel | ✅ |
| V | Adresse privée en table séparée sans droit public ; écriture par fonctions seulement ; pgTAP croisé | ✅ |
| VI | Feature dans l'app vendeuse (une seule app concernée) | ✅ |
| VII | pgTAP et tests Flutter ; essai réel sur Neon en attente (0013) | ⚠️ comme 003 |
| VIII | États de chargement, d'erreur réseau et de reprise ; 7 tailles | ✅ |
| IX | `store_created` (avec `store_origin`), `store_opened` et `store_closed` émis en SQL | ✅ |

## Decisions

| # | Décision | Pourquoi |
|---|---|---|
| D1 | Une boutique par propriétaire (`unique(owner_id)`) | V1 ; simplifie la reprise |
| D2 | Aucune écriture directe sur les tables (pas de `GRANT INSERT/UPDATE`), uniquement des RPC | Le statut, le pays et la complétude sont sensibles ; une seule porte d'écriture |
| D3 | Lecture publique par `GRANT SELECT (colonnes)` sans `owner_id`, et RLS `status = 'active'` | Les privilèges par colonne empêchent la fuite de la propriétaire. La propriétaire lit tout par `my_store()` |
| D4 | `update_store(jsonb)` n'accepte qu'une liste blanche de clés | Une seule fonction pour l'onboarding et les réglages, sans champ sensible |
| D5 | Horaires en `time` locale du pays (le fuseau vient de `countries.timezone`) | Le calcul « ouvert maintenant » se fera en SQL avec le fuseau |
| D6 | `store_payment_options()` (security definer) liste tous les moyens du pays de la boutique avec `is_available` | Les moyens inactifs sont masqués par la RLS ; l'étape 6 doit pourtant afficher Mobile Money « Bientôt » (US1-5) |
| D7 | La galerie dépend de `dym_vendor` pour afficher les vrais écrans 16 à 23 | Outil interne non publié ; évite de dupliquer les écrans. Aucune app ne dépend d'une autre app |
| D8 | `MemoryStoreService` (règles SQL reproduites en mémoire) dans `lib/features/store/testing.dart` | Partagé par les tests et la démo de la galerie, comme `neon_kit/testing.dart` ; jamais branché en production |
| D9 | « Ajouter mon premier produit » annonce « Bientôt disponible » | Le catalogue arrive avec la spec `catalog` ; aucune fonction hors spec |
