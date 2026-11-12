# Implementation Plan: Navigation de la cliente « Épuré »

**Branch**: `feat/056-client-navigation` | **Date**: 2026-11-11 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| II. Valider avant de construire | Planches 01 et 03 validées le 2026-11-11 | OK |
| III. Postgres source de vérité | Créneau rappelé lu dans `purchase_json` (migration 0063, lecture seule) | OK |
| IV. Générique | Aucun texte en dur ; onglet Cuisine selon le flag des contenus | OK |
| V. Sécurité | Fonction existante redéfinie, mêmes droits ; pgTAP 520 | OK (relecture humaine : migration) |
| VI. Couches | Vues sans logique ; `ActiveOrderBanner` lit `OrdersService` | OK |
| VIII. Terrain | États vide, chargement, erreur, hors ligne conservés ; 48 px | OK |

## Décisions

- `ClientTab { home, market, cuisine, cart, me }` ; « Commandes » quitte la barre pour Moi.
- `AppNavigator.cartPage` (panier en onglet, sans retour) et `toMyOrders` ; `toOrders` vide la pile
  vers Moi puis Mes commandes.
- `AccountView` (dym_account) : `banner`, `onOrders`, groupes `DymMenuGroup`.
- Nouveaux widgets : `ActiveOrderBanner`, `StoreRow`, `MarketView`, `ProductThumb`.
- Panier, en-têtes (`CartHeader`), cartes (`CartCard`, filet), jauge (verte, fine), interrupteur (filet),
  pastilles de statut (menthe), frise de suivi (vert), confirmation (créneau rappelé).
- Toutes les apps : cartes blanches avec filet (36 occurrences), graisses 800/900 ramenées à 700.
- Migration `0063_purchase_slot.sql` : `scheduled_start`, `scheduled_end` par commande dans
  `app.purchase_json` ; `PurchaseOrder.scheduledStart/End`.

## Vérification

- Captures : `apps/dym_client/test/capture/` (tag `golden`), 18 pages.
- pgTAP `520_purchase_slot.sql` ; tests Flutter de la cliente, dont la confirmation avec créneau.
