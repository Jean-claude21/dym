# Implementation Plan: Suivi en direct

**Branch**: `feat/044-live-tracking` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Distance (haversine), arrivée, score, zones et bonus en SQL | OK |
| IV. Générique | Vitesses en table ; seuil et bonus par pays | OK |
| V. Sécurité | Positions sans droit direct ; `order_live` réservé à la cliente de la commande | OK |
| VII. Simulation | Position simulée derrière la même écriture, signalée au livreur et à la cliente (décision 0015) | OK |
| VII. Qualité | pgTAP `400`, grand livre ; tests Flutter ; branche Neon propre | OK |

## Décisions

- Migration 0051 :
  - `courier_vehicle_speeds`, `courier_positions` (dernière position seulement) ;
  - `countries.courier_bonus_threshold` et `courier_bonus_minor` ;
  - `order_couriers.bonus_minor`, `rating`, `rated_at` ;
  - `report_position`, `order_live`, `rate_courier`, `order_courier_rating`, `zone_demand` ;
  - bonus fixé à l'affectation, versé par `platform_promotions` à la livraison (`courier_bonus`).
- App livreur : `PositionReporter` (toutes les 20 s), zones et note dans Missions.
- App cliente : carte « arrive », note de la remise dans le suivi.
- Migration non appliquée sur staging avant relecture humaine.
