# Implementation Plan: Pages de la cliente restructurées

**Branch**: `feat/058-client-pages` | **Date**: 2026-11-11 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| II. Valider avant de construire | Planches 08 et 09 validées ; autres pages selon l'option A choisie par le porteur | OK |
| III. Postgres source de vérité | Prix unitaire de la base ; « même boutique » lue dans `storePage` | OK |
| IV. Générique | Textes l10n ; aucune constante métier | OK |
| VI. Couches | Vues sans logique ; `ProductPageViewModel.related`, `SearchViewModel.aisles` | OK |
| VIII. Terrain | Cibles 48 px (« + » 32 px visibles), états vides, texte à 130 % | OK |

## Décisions

- Widgets : `ProductRow`, `ProductList`, `RoundAddButton` (discovery) ; `ProductThumb` réutilisé.
- `DymStateView.icon` ; `AppBarTheme` : titre 24 à gauche ; chat sans jaune.
- Captures avec photos de contrôle générées (`test/capture/photos`, ≤ 70 Ko), lues en mémoire.

## Vérification

- `apps/dym_client/test/capture/*` (tag `golden`) ; tests de la cliente mis à jour (recherche,
  fiche, variante, mention de retrait).
