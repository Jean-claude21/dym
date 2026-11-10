# Implementation Plan: Tout pour la faire

**Branch**: `feat/038-recipe-to-cart` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Ingrédients validés, panier composé et chiffré en SQL (`copilot_pick`, `copilot_quote`) | OK |
| IV. Générique | Rayon « Ustensiles » et rayons retirés en données de référence | OK |
| V. Sécurité | Ingrédients fixés par l'autrice seulement | OK |
| VII. Qualité | pgTAP, tests Function et Flutter ; Neon propre ; staging | OK |

## Décisions

- Migration 0045 : `contents.ingredients` (jsonb, 15 au plus) ; `set_content_ingredients`,
  `recipe_basket` ; rayon `ustensiles` ; rayons hors grocery désactivés ; contenu recopié avec les
  ingrédients.
- Repérage des ingrédients : endpoint IA des listes (`POST /v1/agent/list`, spec 029), réutilisé tel quel.
- App : section « Ingrédients » à la publication (à la main ou par l'IA) ; « Tout pour la faire »
  dans le fil (écran du copilote réutilisé).
