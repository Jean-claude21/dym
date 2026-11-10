# Implementation Plan: Ardoise et relances

**Branch**: `feat/047-vendor-credit` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Dû, plafond, relance quotidienne en SQL | OK |
| V. Sécurité | Tables sans droit direct ; tout passe par la boutique de la personne | OK |
| IX. Mesurer | Événements sans nom ni téléphone | OK |
| VII. Qualité | pgTAP `430`, tests Flutter, branche Neon propre | OK |

## Décisions

- Migration 0053 :
  - `store_credits`, `store_credit_entries` ;
  - `my_credits`, `credit_detail`, `save_credit`, `add_credit_entry`, `remind_credit`, `archive_credit`.
- Relance : lien `wa.me` ouvert par l'opener existant ; aucune nouvelle dépendance.
