# Implementation Plan: Paiement par QR

**Branch**: `feat/046-qr-payments` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Demande, aperçu, paiement, commission et vente en SQL, au grand livre (`qr_payment`) | OK |
| IV. Générique | Commission par pays ; devise de la boutique | OK |
| V. Sécurité | Demandes sans droit direct ; code jamais renvoyé à la cliente ; paiement unique par clé | OK |
| VI. Couches | `qr_flutter`, `mobile_scanner` derrière `dym_platform` | OK |
| VII. Qualité | pgTAP `420`, tests Flutter, branche Neon propre | OK |

## Décisions

- Migration 0052 :
  - `payment_requests`, `countries.qr_commission_bps`, méthode `dym` dans `store_sales` ;
  - `create_payment_request`, `my_payment_request`, `cancel_payment_request`,
    `payment_request_preview`, `pay_payment_request` ;
  - `notification_app` recopiée : `qr_paid` vers l'app vendeuse, et `courier_cash_confirmed`
    (spec 043) vers l'app livreur, ce qui corrige son routage.
- Contenu du QR : `DYM-PAY:<code>`.
