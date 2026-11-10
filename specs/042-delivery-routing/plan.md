# Implementation Plan: Tournées et remise

**Branch**: `feat/042-delivery-routing` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Tournée, code, essais et consignes décidés en SQL ; « livrée » par le livreur seulement avec le code | OK |
| IV. Générique | Consignes des rayons en données de référence ; aucune liste en dur dans les apps | OK |
| V. Sécurité | Code lu par la cliente de la commande seulement ; 5 essais, ensuite l'équipe | OK |
| VII. Qualité | pgTAP (370 adapté, 380), tests Flutter livreur et cliente ; Neon propre ; staging | OK |

## Décisions

- Migration 0049 :
  - `categories.storage`, `products.storage` ;
  - `orders.handover_code` et `handover_attempts` ;
  - code tiré par déclencheur quand un livreur DYM prend la commande ;
  - `courier_deliver` ; `courier_transition` refuse « livrée » ;
  - `my_handover_code`, `set_product_storage` ;
  - `mission_json`, `accept_mission` (tournée, limite par achat) et `my_missions` recopiés.
- App livreur : chips de tournée et de consignes, remise par feuille de saisie du code.
- App cliente : carte « Code de remise » dans le suivi.
