# Implementation Plan: Dernières pages et règles de relecture

**Branch**: `feat/064-last-pages` | **Date**: 2026-11-12 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| II. Valider avant de construire | Planches épurées ; grille `REVUE_CAPTURES.md` pour les pages sans planche | OK |
| IV. Générique | Origines et sous-rayons lus du référentiel | OK |
| VI. Couches | Vues seules ; `DymProductCard`, `DymAvatar`, `DymSelectableCard`, `DymPromoTone` partagés | OK |
| VIII. Terrain | Cibles 48 px, fonds de repli des photos, aucun débordement | OK |

## Décisions

- `DymPromoTone` : `promo` (rouge), `highlight` et `fresh` (jaune), `info` (menthe).
- `DymAvatar.initial` : initiale sous la photo, visible si elle manque.
- `DiscoveryViewModel.selectOrigin` et `selectSubCategory` indépendants.
- Passes d'espacement par scripts (espaceurs, `runSpacing`), puis relecture visuelle.
