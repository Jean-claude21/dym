# Implementation Plan: Remplacement et garantie fraîcheur

**Branch**: `feat/034-substitution-freshness` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Propositions, réponses, crédits et limites en SQL ; totaux des commandes inchangés | OK |
| IV. Générique | `countries.freshness_claim_hours`, `freshness_claims_per_month` | OK |
| V. Sécurité | Rôle vérifié (vendeuse de la commande, cliente) ; photos privées par liens signés courts | OK |
| VII. Qualité | pgTAP (dont grand livre équilibré), tests Function et Flutter ; Neon propre ; staging | OK |
| IX. Mesure | `substitution_proposed`, `substitution_answered`, `freshness_claimed` | OK |

## Décisions

- Migration 0041 : `order_adjustments` (remplacement ou réclamation, photo, statut, crédit),
  transaction `order_credit` (boutique → wallet), réglages pays, notifications ; `order_json`
  recopiée avec les ajustements.
- Function : `POST /v1/orders/:id/photo-uploads` (clé `orders/<id>/…`, bucket privé) et
  `POST /v1/orders/:id/photos` (liens signés), réservés aux deux parties.
- Apps : vendeuse « Proposer un remplacement » (produit, photo, mot) ; cliente : accepter ou
  refuser, « Pas frais ? » sur une commande livrée.
