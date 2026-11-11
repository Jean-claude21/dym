# Implementation Plan: Performance terrain

**Branch**: `feat/062-field-performance` | **Date**: 2026-11-11 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| VIII. Terrain | Images légères, décodage à la taille affichée, geste optimiste | OK (partiel) |
| VII. Qualité | Budgets vérifiés par un test ; rupture optimiste testée | OK |
| Stack | Aucune dépendance ajoutée ; le cache persistant attend une décision | Reporté |

## Décisions

- Rayons recompressés en 256 px (≤ 30 Ko), photos d'origine et de bienvenue ≤ 120 Ko.
- `DymSizedImage` et `DymSizedImage.sized` (ResizeImage) dans `DymAisleTile`, `DymProductCard`,
  `ProductThumb`, `StoreRow`.
- `ProductsViewModel.available` : état optimiste de la rupture.
