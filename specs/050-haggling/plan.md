# Implementation Plan: Marchandage dans la limite de la vendeuse

**Branch**: `feat/050-haggling` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Plancher, contre-prix, prix du panier et de la commande en SQL ; l'app n'envoie qu'une offre | OK |
| IV. Générique | Limite en pourcentage, montants en unités mineures de la devise de la boutique | OK |
| V. Sécurité | Table `haggles` sans accès direct ; limite jamais exposée ; fonctions `SECURITY DEFINER` | OK |
| VII. Qualité | pgTAP `460`, tests Flutter, branche Neon propre | OK |

## Décisions

- Migration 0056 :
  - `stores.haggle_max_percent` (1 à 50, nulle : pas de marchandage) et `products.haggle_max_percent`
    (nulle : celle de la boutique, 0 : jamais) ;
  - table `haggles` ; `propose_haggle`, `accept_haggle`, `set_haggle_limit`, `my_haggling` ;
  - `app.cart_line_price(panier, variante, quantité)` : prix conclu en cours, sinon `variant_price` ;
  - copies de `cart_quote`, `cart_add`, `cart_set_quantity` (0011) qui passent par ce prix, et
    `list_price_minor` sur chaque ligne ; copie de `product_page` (0054) avec `can_haggle` ;
  - déclencheur sur `order_items` : la commande consomme le prix conclu (`used`).
- App cliente : bouton « Marchander » de la fiche produit, feuille de proposition, mention
  « Prix marchandé » dans le panier.
- App vendeuse : « Marchandage » dans Ma boutique (limite, par produit, derniers marchés).
