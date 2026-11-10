# Implementation Plan: Achat de gros groupé

**Branch**: `feat/049-wholesale` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Jauge, minimum, statut, décision en SQL | OK |
| IV. Générique | Offres limitées au pays de la grossiste ; aucune liste en dur | OK |
| V. Sécurité | Engagements des autres invisibles ; décisions réservées à la grossiste | OK |
| VII. Qualité | pgTAP `450`, tests Flutter, branche Neon propre | OK |

## Décisions

- Migration 0055 :
  - `stores.is_wholesaler`, `wholesale_offers`, `wholesale_commitments` ;
  - `set_wholesaler`, `create_wholesale_offer`, `commit_wholesale`, `decide_wholesale_offer`, `wholesale_board` ;
  - `notification_app` recopiée : notifications de gros vers l'app vendeuse.
- App vendeuse : « Achats de gros » dans Ma boutique.
