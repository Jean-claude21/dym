# Implementation Plan: Livreurs relancés, alerte « prête », refus automatique

**Branch**: `feat/066-courier-dispatch` | **Date**: 2026-11-12 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Transitions et relances en SQL ; la Function ne fait qu'appeler | OK |
| IV. Générique | Délais par pays, modifiables et journalisés | OK |
| V. Sécurité | `order_dispatch` sans accès Data API ; `admin_dispatch` réservé | OK |
| IX. Mesurer | `courier_relaunched`, `courier_ready_alerted`, `order_rejected` (`no_response`) | OK |

## Décisions

- Migration `0066_courier_dispatch.sql` : réglages du pays, motif `no_response`, table
  `order_dispatch`, `app.dispatch_couriers`, déclencheur (acceptée, prête), `mission_open_for`
  élargie, `app.auto_refuse_order`, `app.run_dispatch_watch`, `admin_dispatch`.
- Tâche `dispatchWatch` (`*/5 * * * *`) → `/v1/jobs/dispatch-watch`.
- Les apps vendeuse et livreur affichent les textes de notification du serveur : aucun code de plus.
