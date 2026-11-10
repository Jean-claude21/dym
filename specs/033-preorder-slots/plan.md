# Implementation Plan: Précommande et créneaux

**Branch**: `feat/033-preorder-slots` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Créneaux proposés et validés en SQL, dans la transaction de `place_order` | OK |
| IV. Générique | `delivery_windows` et `countries.schedule_days_ahead` en données de référence | OK |
| V. Sécurité | Date d'arrivage par la propriétaire seulement ; aucune écriture directe | OK |
| VII. Qualité | pgTAP, tests Function et Flutter ; Neon propre ; essai sur staging | OK |
| IX. Mesure | `order_scheduled`, `product_arrival_set` (serveur) | OK |

## Décisions

- Migration 0040 : `delivery_windows`, `countries.schedule_days_ahead`, `products.arrival_on`,
  `orders.scheduled_start/end` ; `delivery_slots()`, `set_product_arrival()`,
  `app.place_order_scheduled()` (appelle `place_order` puis programme) ; `order_eta` rend le début
  du créneau ; `catalog_item`, `order_json`, `my_orders`, `my_store_orders` recopiées avec les
  nouveaux champs.
- Function : `slot` facultatif dans `POST /v1/orders`.
- Apps : « Quand ? » dans la livraison (écran 34), badge d'arrivage, date d'arrivage (vendeuse),
  créneau dans les suivis.
