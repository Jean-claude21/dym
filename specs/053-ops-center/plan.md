# Implementation Plan: Centre d'opérations, rôles par pays

**Branch**: `feat/053-ops-center` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Indicateurs et retards calculés en SQL ; périmètre vérifié en base | OK |
| IV. Générique | Seuils par pays (colonnes de `countries`), aucun pays en dur | OK |
| V. Sécurité | Admin requis, périmètre par pays, écritures auditées | OK |
| VII. Qualité | pgTAP `490`, tests Flutter, branche Neon propre | OK |

## Décisions

- Migration 0059 :
  - seuils `ops_*_alert_minutes` sur `countries` ; table `admin_scopes` ;
  - `app.admin_countries`, `app.require_ops` ; `ops_countries`, `ops_live`, `admin_ops_settings`,
    `admin_set_ops_thresholds`, `admin_set_feed_weights` (sur `admin_set_feed_ranking`, 0044),
    `admin_save_membership_plan`, `admin_set_scope`.
- Admin : onglet « Opérations » (`OpsCenterView`, service à part), en direct et réglages ;
  confirmation du cash des livreurs par `admin_confirm_courier_cash` (0050).
