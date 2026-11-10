# Implementation Plan: Affiliation des créatrices

**Branch**: `feat/039-affiliation` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Taux, attribution, antifraude, échéance et versement en SQL ; la Function ne fait que déclencher la tâche | OK |
| IV. Générique | Minimum, délai, prise en charge du lancement : colonnes de `countries` ; montants en `amount_minor` | OK |
| V. Sécurité | Tables sans droit direct ; RPC `SECURITY DEFINER` ; taux réservé à la propriétaire ; tâche vérifiée par le parseur des triggers | OK |
| VII. Qualité | pgTAP (taux, attribution, antifraude, échéance, annulation, grand livre), tests Function et Flutter | OK |
| IX. Mesurer | `commission_earned`, `commission_paid` côté serveur, sans donnée personnelle | OK |

## Décisions

- Migration 0046 :
  - `countries.affiliate_min_rate_bps` (300), `affiliate_window_days` (7), `affiliate_launch_subsidy` ;
    `stores.affiliate_rate_bps`, `products.affiliate_rate_bps`.
  - `affiliate_touches` (dernier contenu par variante, `tagged` ou `ingredient`),
    `user_devices` (identifiant d'installation), `affiliate_commissions`.
  - Déclencheur sur `order_items` (commission en attente), sur `orders` (échéance à la livraison +
    `freshness_claim_hours`, annulation si refusée ou annulée).
  - `app.settle_affiliate_commissions(at)` : remboursée ou ligne rendue → annulée ; sinon écriture
    `affiliate_commission` (boutique ou `platform_promotions` → wallet de la créatrice).
  - RPC `content_touch`, `register_device`, `my_commissions`, `set_affiliate_rate`, `my_affiliate_rate`.
- Function : `POST /v1/jobs/affiliate-settlement`, trigger planifié toutes les 15 minutes.
- Apps : attribution après chaque ajout réussi depuis un contenu ; gains dans le studio ;
  mention « Contenu rémunéré » ; taux de la boutique et par produit dans « Mes contenus » (vendeuse) ;
  identifiant d'installation aléatoire en stockage sécurisé (`dym_platform`).
- Le taux par produit vit dans « Mes contenus » plutôt que dans le formulaire produit, dont la
  maquette est validée (pas de changement d'écran validé hors spec).
