# Implementation Plan: Moneroo

**Branch**: `feat/088-moneroo` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Statut, montant et devise vérifiés par `apply_payment_event` | OK |
| IV. Fournisseurs derrière une interface | `PaymentProvider` ; bascule par configuration | OK |
| V. Sécurité | Webhook signé, relu chez Moneroo, journalisé brut, idempotent ; clé hors dépôt | OK |
| VII. Simulé signalé | La simulation reste tant que l'admin n'a pas basculé | OK |

## Décisions

- Webhook Moneroo incomplet par conception : `resolveEvent` relit le paiement avant application.
- Montant Moneroo en unités de la devise (décimales ISO 4217) depuis les unités mineures DYM.
