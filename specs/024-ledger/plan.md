# Implementation Plan: Grand livre

**Branch**: `feat/024-ledger` | **Date**: 2026-11-09 | **Spec**: [spec.md](spec.md)

## Summary

Grand livre à double écriture en SQL (migration 0030), alimenté par déclencheurs sur les paiements,
les commandes et les remboursements, avec reprise de l'historique et deux lectures.

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Toute écriture par fonctions `SECURITY DEFINER` et déclencheurs | OK |
| IV. Générique | Une devise par compte et par transaction ; aucune devise en dur | OK |
| V. Sécurité | RLS sans politique, aucun droit direct ; lectures par fonctions ; relecture humaine | OK |
| VII. Qualité | pgTAP (règles, rejeu, immuabilité, accès) en local et sur branche Neon | OK |

## Décisions

- **Signe** : montant positif = débit. Solde affiché d'une boutique = −somme (positif : DYM lui doit).
- **Comptes** : `platform_commission`, `provider_clearing`, `customer_escrow` (par devise),
  `store_balance` (par boutique et devise). Wallet et poches ajoutés par la spec suivante.
- **Paiement protégé** : l'argent en ligne reste dans `customer_escrow` jusqu'à la livraison.
- **Équilibre** : déclencheur de contrainte différé, vérifié en fin de transaction.
- **Idempotence** : clé `payment:`, `settled:`, `cash:`, `refund:` + identifiant.
- **Cash** : l'argent reste chez la vendeuse ; seule la commission due est inscrite.

## Validation Neon (2026-11-09)

- Branche propre depuis `main` : 794 tests pgTAP réussis.
- Copie de staging : reprise de 18 paiements, 12 règlements, 1 commission cash ; 0 transaction
  déséquilibrée. Puis appliqué sur staging.
