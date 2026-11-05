# Implementation Plan: Litiges

**Branch**: `feat/012-disputes` | **Date**: 2026-10-03 | **Spec**: [spec.md](spec.md)

## Summary

- **Migration `0014_disputes.sql`** : `disputes`, `dispute_messages`, `refunds` (RLS, lecture par
  fonctions) ; `app.open_dispute`, `app.dispute_reply`, `app.resolve_dispute` (admin, audit,
  remboursement) ; lectures `order_dispute(order)` (cliente, vendeuse, admin),
  `admin_disputes(status)`, `admin_dispute(id)` ; notifications `dispute_opened`,
  `dispute_replied`, `dispute_resolved` et leurs textes de push.
- **Functions** : `POST /v1/orders/:id/disputes`, `POST /v1/disputes/:id/messages`,
  `POST /v1/admin/disputes/:id/resolve`.
- **Dart** : `Dispute`, `DisputeMessage`, `DisputeRepository`.
- **Apps** : cliente 49 et 50 depuis le suivi ; vendeuse bandeau et réponse (51).
- **Galerie** : 49 à 51.

## Constitution Check

| Principe | Vérification | Statut |
|---|---|---|
| I | Spec `disputes`, IDs cités | ✅ |
| II | 49 à 51 à valider | ⚠️ validation |
| III | Droits, délai, montants et décisions en SQL | ✅ |
| V | RLS, gestes par Function, audit de chaque décision, pgTAP croisés | ✅ |
| IX | `dispute_opened`, `dispute_resolved` | ✅ |

## Decisions

| # | Décision | Pourquoi |
|---|---|---|
| D1 | Remboursement = ligne `refunds` à exécuter, séparée de la décision | Une décision n'échoue jamais à cause du fournisseur ; exécution rejouable |
| D2 | Méthode déduite de l'achat (fournisseur si payé en ligne, cash sinon) | Pas de choix possible incohérent |
| D3 | Une conversation par litige, rôles client / vendor / admin | Même fil pour les trois, lisible par l'équipe |
