# Implementation Plan: Nouvelle commande impossible à manquer

**Branch**: `feat/075-nouvelle-commande` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Heure limite calculée en SQL (même règle que le refus automatique) | OK |
| VIII. Terrain | Alerte lisible en plein soleil, cibles ≥ 48 dp, son coupable par le téléphone | OK |

## Décisions

- `NewOrderWatcher` porté par l'accueil de la vendeuse (tous les onglets) ; l'ancien message en bas
  de l'onglet Commandes est retiré (doublon).
