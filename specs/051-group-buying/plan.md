# Implementation Plan: Achat groupé entre voisins, départ groupé

**Branch**: `feat/051-group-buying` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Jauge, déblocage, prix et frais en SQL ; l'app n'envoie qu'une quantité | OK |
| IV. Générique | Offres visibles par les quartiers desservis (`store_serves`), aucune zone en dur | OK |
| V. Sécurité | Tables sans accès direct ; membres anonymes pour les autres ; fonctions `SECURITY DEFINER` | OK |
| VII. Qualité | pgTAP `470`, tests Flutter, branche Neon propre | OK |

## Décisions

- Migration 0057 :
  - `group_offers`, `group_members` ; `create_group_offer`, `cancel_group_offer`, `my_group_offers`,
    `group_offers_near`, `join_group_offer` ; notifications `group_unlocked`, `group_cancelled` ;
  - `app.cart_line_price` réécrite : le meilleur du prix conclu (0056), du prix de groupe et du prix du jour ;
  - `app.cart_store_fee` : frais des membres d'un groupe débloqué dont le produit est au panier ;
    copie de `cart_quote` (0056) qui l'utilise ;
  - déclencheur sur `order_items` : la commande consomme l'avantage.
- App cliente : « Achats groupés » dans Mon compte. App vendeuse : « Offres groupées » dans Ma boutique.
