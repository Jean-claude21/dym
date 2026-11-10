# Implementation Plan: Cash et gains du livreur

**Branch**: `feat/043-delivery-cash` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Frais, cash dû, recharge et retrait décidés en SQL, au grand livre | OK |
| IV. Générique | Montants en `amount_minor` ; aucune devise en dur ; saisie selon les décimales du pays | OK |
| V. Sécurité | Tables sans droit direct ; confirmation réservée à la boutique ; action de l'équipe journalisée | OK |
| VII. Qualité | pgTAP `390`, grand livre équilibré ; tests Flutter ; branche Neon propre | OK |
| VII. Simulation | Retrait simulé derrière `wallet_simulated_withdrawal`, signalé à l'écran (décision 0015) | OK |

## Décisions

- Migration 0050 :
  - comptes `courier_cash` (livreur + boutique, ou livreur seul pour DYM) et `platform_cash` ;
  - déclencheur à la livraison : `courier_fee` (payée en ligne) ou `courier_cash` (paiement à la
    livraison, avec `cash_collected_at` pour réutiliser commission et cashback existants) ;
  - `confirm_courier_cash`, `cash_topup_code`, `courier_cash_topup`, `admin_confirm_courier_cash`,
    `wallet_withdraw_simulated`, `courier_earnings`, `store_courier_cash` ;
  - `account_deletion_blockers` et `my_wallet` recopiés.
- App livreur : onglet « Gains ». App cliente : retrait et code de recharge. App vendeuse :
  « Cash des livreurs » dans Ma boutique.
- Migration non appliquée sur staging avant relecture humaine : elle reste modifiable.
