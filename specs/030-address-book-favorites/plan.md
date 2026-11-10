# Implementation Plan: Carnet, favoris et paniers enregistrés

**Branch**: `feat/030-address-book-favorites` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Favoris, paniers, remise au panier (par `cart_add`) et prix du jour en SQL | OK |
| IV. Générique | Aucune liste dans le code ; devise du panier et du pays | OK |
| V. Sécurité | Tables sous RLS (lecture propriétaire), écriture par fonctions `SECURITY DEFINER` | OK |
| VI. Couches | `FavoritesRepository` (dym_data) → services de l'app → viewmodels | OK |
| VII. Qualité | pgTAP, tests du dépôt et des écrans ; Neon propre ; essai sur staging | OK |
| VIII. Terrain | États vide, chargement, erreur, hors ligne ; cœur ≥ 48 dp avec libellé | OK |
| IX. Mesure | Événements serveur (favori, panier enregistré, remis au panier) | OK |

Maquette : écrans dérivés des listes et du panier validés ; validation par le porteur produit
(T008), comme pour les specs 026 à 029.

## Décisions

- Migration 0037 : `favorite_stores`, `favorite_products`, `saved_baskets` (lignes en jsonb) ;
  fonctions `toggle_favorite`, `my_favorite_ids`, `my_favorites`, `save_cart_as_basket`,
  `my_baskets`, `rename_basket`, `delete_basket`, `basket_to_cart`.
- Cartes : `app.store_summary` et `app.catalog_item` (déjà utilisées par la découverte).
- App : cœur sur la page boutique et la fiche produit ; « Mes favoris » et « Mes paniers » dans
  « Moi » ; « Enregistrer ce panier » dans le panier.
