# Implementation Plan: Console des opérations « Épuré »

**Branch**: `feat/061-ops-console` | **Date**: 2026-11-11 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| II. Valider avant de construire | Planche 06 validée le 2026-11-11 | OK |
| V. Sécurité | Aucune action nouvelle ; journal inchangé | OK |
| VI. Couches | `AdminDomain` regroupe les `AdminTab` existants ; vues inchangées sauf En direct | OK |

## Décisions

- `AdminDomain` (7) ; `_tabsOf` et `_domainOf` ; puces de sous-sections.
- `AdminCard` : filet par défaut ; En direct : chiffres-clés en ligne, alertes en pastilles, retards
  avant la fraude.
- Capture : `apps/dym_admin/test/capture/ops_capture_test.dart` (1280 × 800).
