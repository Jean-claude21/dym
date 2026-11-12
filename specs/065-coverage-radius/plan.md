# Implementation Plan: Rayon de service par ville

**Branch**: `feat/065-coverage-radius` | **Date**: 2026-11-12 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | La couverture est calculée en SQL (`nearest_zone`) | OK |
| IV. Générique | Rayon par ville en base, réglé depuis Configuration | OK |
| V. Sécurité | `admin_coverage` réservé ; modification de ville journalisée | OK |
| IX. Mesurer | `location_outside_coverage` sans donnée personnelle | OK |

## Décisions

- Migration `0065_coverage_radius.sql` : colonne, `nearest_zone`, `admin_geography`,
  `admin_save_city`, `admin_coverage`, nom d'événement.
- `ZoneMatch.covered` (vrai par défaut) ; `trackOutsideCoverage` dans `dym_data`.
- L'événement est émis par l'app : `nearest_zone` reste une lecture sans effet.
