# Implementation Plan: Antifraude, modération et support assistés

**Branch**: `feat/054-ops-ai` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Règles de fraude en SQL ; la Function n'appelle que l'IA | OK |
| IV. Générique | Seuils (`fraud_rules`) et modèles (`ai_models`) en base | OK |
| V. Sécurité | Tables sans accès direct ; décisions par l'équipe, auditées | OK |
| VII. Qualité | pgTAP `500`, tests des Functions et Flutter, branche Neon propre | OK |

## Décisions

- Migration 0060 :
  - `fraud_rules`, `fraud_signals`, `handover_failures` (déclencheur sur `handover_attempts`) ;
  - `app.detect_fraud_signals`, `admin_fraud_signals`, `admin_decide_fraud_signal` ;
  - `report_triage`, `app.reports_to_triage`, `app.record_report_triage` ; modèles `moderation_triage`
    et `support_agent` ; `app.support_draft_context` ;
  - copies de `admin_reports` (0044, avec l'avis) et `ops_live` (0059, avec `fraud_open`).
- Functions (`src/ops/assist.ts`) : jobs `fraud-signals` et `moderation-triage` (toutes les 15 min),
  route `POST /v1/admin/tickets/:id/draft`.
- Admin : signaux dans « Opérations », avis de l'IA dans la modération, « Brouillon IA » au support.
