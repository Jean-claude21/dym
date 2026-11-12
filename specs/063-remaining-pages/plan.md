# Implementation Plan: Pages restantes revisitées

**Branch**: `feat/063-remaining-pages` | **Date**: 2026-11-11 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| II. Valider avant de construire | Planches 03, 04, 06 ; option A pour le reste | OK |
| VI. Couches | Vues seules ; `StoreSection`, `AdminSplit`, `AdminPill` partagés | OK |
| VIII. Terrain | Photo de repli, cibles 48 px | OK |

## Décisions

- `TillView`, `CreditView`, `ProductEditorView`, `AdminOrderView` refaits.
- `StoreSection` à plat ; `StorePrivacyNote` discrète ; `DymFormScaffold` sans titre centré.
- `AdminTone.warning` en pêche, `neutral` discret ; `AdminSplit` : panneau vide encadré.
- Captures générées à partir des fakes des tests d'écran (`test/capture/*`, tag `golden`).
