# Implementation Plan: Livreur « Épuré »

**Branch**: `feat/060-courier-refresh` | **Date**: 2026-11-11 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| II. Valider avant de construire | Planche 05 validée le 2026-11-11 | OK |
| III. Postgres source de vérité | Code de remise vérifié par la base | OK |
| VI. Couches | `DymKeypad` dans dym_ui (partagé par deux apps) ; vues sans logique | OK |
| VIII. Terrain | Une main, touches de 56 px, texte à 130 % | OK |

## Décisions

- `MyRunsView` : en cours (posée dans Missions) ou `history` ; rechargée à chaque acceptation.
- `MissionCard` refaite ; `_CodeSheet` à quatre cases et clavier ; `EarningsView` à filets.
- Captures : `apps/dym_delivery/test/capture/` (tag `golden`).
