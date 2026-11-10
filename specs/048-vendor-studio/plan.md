# Implementation Plan: Partage de la boutique et fin de marché

**Branch**: `feat/048-vendor-studio` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Remise appliquée par `app.eom_price` dans `variant_price`, `product_min_price`, `catalog_item`, `product_page` | OK |
| IV. Générique | Montants en unités mineures ; aucun pays en dur | OK |
| V. Sécurité | Remise réservée à la boutique de la personne ; page publique sans donnée personnelle | OK |
| VII. Qualité | pgTAP `440` (prix affiché = prix payé), tests Function et Flutter, branche Neon propre | OK |

## Décisions

- Migration 0054 :
  - `products.eom_percent` et `eom_until` ;
  - `set_end_of_market`, `clear_end_of_market`, `my_end_of_market`, `store_share_preview` ;
  - quatre fonctions de prix recopiées.
- Function : `GET /b/:id` (page de la boutique, lien `?store=` vers l'app web).
- App vendeuse : « Faire connaître ma boutique » (partage, fin de marché).
- App cliente : badge, ouverture de `?store=`.
