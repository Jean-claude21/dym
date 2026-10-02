# Implementation Plan: Catalogue de la vendeuse

**Branch**: `feat/007-catalog` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

- **Migration `0007_catalog.sql`** :
  - tables `store_categories`, `products`, `product_variants`, `product_photos`,
    `product_store_categories`, `app.ai_product_suggestions` (schéma `app`, non exposé) ;
  - lecture publique par RLS : produits publiés des boutiques actives, avec leurs enfants ;
  - écritures par fonctions `SECURITY DEFINER` :
    - `save_store_category`, `archive_store_category`, `reorder_store_categories`,
      `my_store_categories` ;
    - `save_product`, `publish_product`, `set_product_available`, `set_variant_stock`,
      `archive_product`, `delete_product_draft`, `my_products` ;
  - fonctions réservées aux Functions (rôle propriétaire, schéma `app`) :
    `app.photo_upload_prefix(user)`, `app.suggestion_context(user, key)`,
    `app.record_product_suggestion(...)`.
- **Functions** :
  - `POST /v1/catalog/photo-uploads` : URL présignée S3 (stockage d'objets Neon) ;
  - `POST /v1/catalog/suggestions` : proposition par le modèle d'`ai_models` (AI SDK, sortie
    structurée).

  Le stockage et le modèle sont injectés derrière des interfaces, ce qui permet de les tester
  sans réseau.
- **Dart** :
  - `dym_models` : `StoreCategory`, `Product`, `ProductVariant`, `ProductPhoto`,
    `ProductSuggestion`, `ProductStatus` ;
  - `dym_data` : `CatalogRepository` (RPC) et `CatalogMediaRepository` (Functions, puis `PUT`
    direct) ;
  - `dym_platform` : `PhotoPicker`, avec appareil photo et galerie (`image_picker`), compression
    à 1 600 px et qualité 80.
- **App vendeuse**, feature `catalog` :
  - `ProductsView` (écran 24) ;
  - `ProductEditorView` en 2 étapes (écrans 25 et 26) ;
  - `StoreCategoriesView` (écran 27) ;
  - onglets Produits, Boutique, Moi ;
  - « Ajouter mon premier produit » ouvre l'éditeur.
- **Galerie** : écrans 24 à 27.

## Technical Context

Même pile que la spec 006. Nouvelles dépendances :
- `image_picker`, dans `dym_platform` ;
- `ai`, `@ai-sdk/openai`, `@aws-sdk/client-s3` et `@aws-sdk/s3-request-presigner`, dans
  `functions/`.

## Constitution Check

| Principe | Vérification | Statut |
|---|---|---|
| I | Spec `catalog` (Phase 2), IDs cités | ✅ |
| II | Maquettes 24-27 générées dans la direction, à valider (dérogation de la roadmap, comme 006) | ⚠️ validation |
| III | Statut, devise, complétude, propriété et comparaison avec la proposition en SQL ; la Function ne fait que présigner et appeler le modèle | ✅ |
| IV | Rayons, unités et modèle d'IA lus du référentiel ; fournisseur d'IA et de stockage derrière une interface | ✅ |
| V | Écritures par fonctions seulement ; propositions dans `app` (aucun droit Data API) ; clés OpenAI et S3 en variables de Function ; pgTAP croisé | ✅ |
| VI | Feature dans l'app vendeuse ; `PhotoPicker` dans `dym_platform` (infra) | ✅ |
| VII | pgTAP, tests Functions (vitest), tests Flutter ; essai réel S3 et OpenAI en attente (0013) | ⚠️ comme 003 |
| VIII | Chargement, erreur, hors ligne ; idempotence par identifiant fourni par l'app ; 7 tailles | ✅ |
| IX | `product_published`, `product_stock_changed`, `ai_product_suggestion_accepted` (serveur), `ai_product_suggestion_shown` (app) | ✅ |

## Decisions

| # | Décision | Pourquoi |
|---|---|---|
| D1 | Tout produit a au moins une variante ; la variante par défaut n'a pas de libellé | La ligne de panier (spec `cart-checkout`) référencera toujours une variante |
| D2 | Identifiants du produit et des variantes générés par l'app ; `save_product` crée ou met à jour | Idempotence sans table de clés : une nouvelle tentative réécrit la même ligne |
| D3 | `save_product(p_product jsonb)` enregistre fiche, variantes, photos et catégories en une transaction ; `publish_product` est séparé | Un seul aller-retour par étape ; la publication vérifie la complétude |
| D4 | Fonctions `app.*` à identifiant explicite, exécutées par les Functions (rôle propriétaire) | La Function a déjà vérifié le JWT ; pas de bascule de rôle dans la connexion |
| D5 | Clé de photo `stores/<store_id>/products/<uuid>.<ext>` ; URL publique = base publique + clé | Le préfixe prouve la propriété en SQL ; aucune URL stockée |
| D6 | Stock `null` = non suivi (fait maison du jour) | Les vendeuses de plats ne comptent pas des unités |
| D7 | `ai_product_suggestion_accepted` porte `fields_changed` (0 à 3), émis à la publication | Mesure de H8 sans donnée personnelle |
| D8 | Suppression réservée aux brouillons ; publié → archivage | Les commandes futures référenceront les variantes |
| D9 | « Ajouter un produit » ouvre directement l'appareil photo | Parcours photo d'abord : un geste de moins (objectif < 60 s, H1) |
| D10 | Archiver et supprimer depuis la fiche, pas depuis la liste | Liste lisible à 360 dp (écran 24) ; « Restaurer » reste dans la liste des archivés |
| D11 | Base publique des photos en configuration (`DYM_MEDIA_URL`) ; l'URL est recomposée depuis la clé | Aucune URL stockée en base ; changer de stockage ne touche pas les données |
