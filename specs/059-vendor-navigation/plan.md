# Implementation Plan: Navigation de la vendeuse « Épuré »

**Branch**: `feat/059-vendor-navigation` | **Date**: 2026-11-11 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| II. Valider avant de construire | Planche 04 validée le 2026-11-11 | OK |
| III. Postgres source de vérité | Montant relu en base ; aperçu seulement dans l'app | OK |
| VI. Couches | `AppNavigator.toCharge`, `toAccount` ; vues sans logique | OK |
| VIII. Terrain | Clavier géant, 48 px et plus, texte à 130 % | OK |

## Décisions

- `HomeTab { dashboard, orders, products, messages, store }` ; « Moi » retiré, compte dans Boutique.
- `DashboardView` refait (accueil, boutons d'encaissement, puces de période, lignes à traiter).
- `QrChargeView` : clavier géant ; `QrChargeViewModel.preview`.
- Catalogue et fiche commande sans jaune ni aplat foncé ; `DymNavRail` : deux lignes de libellé.
- Captures : `apps/dym_vendor/test/capture/` (tag `golden`).
