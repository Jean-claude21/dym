# Implementation Plan: Panier multi-boutiques, adresses et commande

**Branch**: `feat/009-cart-checkout` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

- **Migration `0011_cart_checkout.sql`** ([data-model.md](data-model.md)) :
  - tables `customer_addresses`, `carts`, `cart_items`, `purchases`, `orders`, `order_items`,
    RLS active, aucune écriture directe ;
  - `app.cart_quote` : seule fonction qui calcule lignes, problèmes, frais, totaux et
    commission ; elle sert la lecture du panier et la création de la commande ;
  - fonctions publiques (Data API) : `my_cart`, `cart_add`, `cart_set_quantity`,
    `my_addresses`, `save_address`, `delete_address`, `set_default_address`, `my_purchase` ;
  - `app.place_order(user, key, payload)` : création atomique et idempotente, appelée par la
    Function seulement ; émet `order_created`.
- **Function** `POST /v1/orders` (en-tête `Idempotency-Key`) : appelle `app.place_order`. Les
  specs `payments` (Moneroo) et `order-lifecycle` (push) se branchent sur cette route.
- **Dart** :
  - `dym_models` : `CartView`, `CartStoreGroup`, `CartLine`, `CartIssue`, `CustomerAddress`,
    `Purchase`, `PurchaseOrder`, `OrderRequest` ;
  - `dym_data` : `CartRepository`, `AddressRepository`, `OrderRepository`.
- **App cliente**, feature `cart` :
  - `CartService` (panier courant observable pour le mini-panier) ;
  - écrans : panier (05), livraison (34), mes adresses (35), nouvelle adresse (36), commande
    envoyée (37) ;
  - ajout depuis la fiche produit et les cartes ; mini-panier sur l'accueil, les rayons, la
    recherche et la page boutique ; « Mes adresses » dans Moi.
- **Galerie** : écrans 34 à 37 et vrai écran panier (38) à côté de la maquette 05.

## Technical Context

Même pile que les specs 006 à 008 : Postgres 17 (Neon), pgTAP, Functions Node 24 (Hono, zod,
`pg`), Flutter 3.47.5 via FVM, Stacked, `json_serializable`. Aucune dépendance nouvelle.

## Constitution Check

| Principe | Vérification | Statut |
|---|---|---|
| I | Spec `cart-checkout` (Phase 2), IDs cités | ✅ |
| II | 05 validée ; 34 à 37 générées, à valider sur le terrain | ⚠️ validation |
| III | Prix, frais, totaux, commission, stocks et refus calculés en SQL ; l'app n'envoie aucun montant pris en compte | ✅ |
| IV | Frais, seuil, devise, moyens de paiement : référentiel ; aucun pays ni montant dans le code | ✅ |
| V | RLS sur 6 tables ; écritures par fonctions `SECURITY DEFINER` ; création par Function ; pgTAP lecture et écriture croisées | ✅ |
| VI | Feature dans l'app cliente ; dépôts dans `dym_data` ; composant d'adresse dans `dym_ui` (déjà là) | ✅ |
| VII | pgTAP, tests Function, tests Flutter, parcours nominal ; démo Android en attente | ⚠️ démo |
| VIII | Clé d'idempotence sur la création ; 4 états par écran ; 7 tailles | ✅ |
| IX | `order_created` serveur avec `stores_count` ; `cart_item_added`, `checkout_started` app | ✅ |

## Decisions

| # | Décision | Pourquoi |
|---|---|---|
| D1 | Une seule fonction de calcul (`app.cart_quote`) pour l'affichage et la création | Le montant affiché est, par construction, celui facturé |
| D2 | Frais : base + supplément par ramassage au-delà du premier ; la boutique du plus gros sous-total porte la base (ou ses propres frais) ; gratuité au seuil (maquette 05) | Règle validée sur le terrain ; chaque commande garde sa part, utile pour l'encaissement par boutique |
| D3 | Création par la Function `POST /v1/orders`, qui appelle `app.place_order` | Constitution III (une écriture à effet passe par une Function) ; paiement et push s'y branchent ensuite |
| D4 | Idempotence : `purchases (user_id, idempotency_key)` unique ; un rejeu rend l'achat existant | Réseau 3G instable ; une seule commande par geste |
| D5 | `expected_total_minor` envoyé par l'app sert seulement de garde : s'il diffère, refus `total_changed` et relecture | La cliente ne paie jamais un total qu'elle n'a pas vu ; le montant reste calculé en base |
| D6 | Adresse copiée dans l'achat (`address` jsonb) | Modifier ou supprimer une adresse ne change pas une commande passée |
| D7 | Position de l'adresse conservée seulement si la cliente l'a donnée ; jamais dans un événement | Guide la livraison ; donnée personnelle protégée par la RLS |
| D8 | Statut initial `pending` seul ; la contrainte s'étend avec `order-lifecycle` | Pas de transition construite hors de sa spec |
| D9 | Paiement : seul le fournisseur `cash` est accepté par `place_order` ; un moyen actif d'un autre fournisseur est refusé (`payment_unavailable`) jusqu'à `payments` | Pas de commande sans moyen de la payer |
| D10 | Prix vu à l'ajout (`unit_price_seen_minor`) pour signaler un prix modifié ; il est remis à jour à chaque modification de la ligne | Avertir sans bloquer ; le prix courant est toujours celui facturé |
| D11 | Le devis sert aussi la devise du référentiel (`currency`) et `app.catalog_item` la variante par défaut (`default_variant_id`) | Le mini-panier formate sans devise écrite dans l'app ; le « + » d'une carte ajoute la variante unique |
| D12 | `CartScope` (InheritedWidget) rend le `CartService` accessible aux écrans de découverte ; absent dans la galerie et les tests de découverte | Ajout et mini-panier sans faire dépendre chaque écran de découverte du panier |

## Project Structure

```text
db/migrations/0011_cart_checkout.sql
db/tests/060_addresses.sql · 061_cart.sql · 062_orders.sql
functions/src/orders/{ports,routes,adapters}.ts · functions/test/orders.test.ts, orders-pg.test.ts
packages/domain/dym_models/lib/src/cart/cart_models.dart
packages/data/dym_data/lib/src/cart_repository.dart (CartRepository, AddressRepository, OrderRepository)
apps/dym_client/lib/features/cart/
  cart_service.dart · testing.dart · cart_viewmodels.dart
  cart/cart_view.dart · delivery/delivery_view.dart
  addresses/addresses_view.dart · addresses/address_form_view.dart
  sent/order_sent_view.dart · widgets/cart_widgets.dart
apps/dym_gallery/lib/screens/ (34 à 38)
```

## Complexity Tracking

Aucune dérogation.
