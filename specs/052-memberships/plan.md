# Implementation Plan: DYM+, vendeuse Pro, visibilité sponsorisée

**Branch**: `feat/052-memberships` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Paiement, prolongation, avantages, commission en SQL | OK |
| IV. Générique | Formules par pays en base ; avantages en données (`benefits`) | OK |
| V. Sécurité | Tables sans accès direct ; paiement par fonction `SECURITY DEFINER`, clé d'idempotence | OK |
| VII. Qualité | pgTAP `480`, tests Flutter, branche Neon propre | OK |

## Décisions

- Migration 0058 :
  - compte `platform_subscriptions`, mouvements `membership` et `member_benefit` ;
  - `membership_plans` (formules de départ du Togo), `memberships` ;
  - `membership_offer`, `subscribe_plan` (wallet, prolongation, rejouable) ;
  - `app.member_flag`, `app.member_bps` ; déclencheur avant insertion sur `orders` (commission Pro) ;
    déclencheur à la livraison (frais rendus et cashback DYM+, financés par `platform_promotions`) ;
  - copie de `discover_stores` (0008) avec `sponsored`.
- `MembershipView` partagé dans `dym_account` (cliente : DYM+ dans Mon compte ; vendeuse : « Pro et
  visibilité » dans Ma boutique). Accueil cliente : section « À la une », mention « Sponsorisé ».
