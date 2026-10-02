# Implementation Plan: Paiements génériques et fournisseur simulé

**Branch**: `feat/010-payments` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

- **Migration `0012_payments.sql`** :
  - fournisseur `simulator` (kind `mobile_money`, référentiel) ; aucun moyen par pays n'est créé
    (activation par configuration, hors production) ;
  - `purchases.payment_status` (`cash_on_delivery`, `awaiting_payment`, `paid`, `failed`) ;
  - tables `payments` (tentatives) et `payment_events` (confirmations brutes, idempotence par
    `(provider_code, event_id)`), RLS active, lecture par la cliente de l'achat ;
  - `app.place_order` redéfinie : paramètre `p_online_providers text[]` (fournisseurs disponibles
    dans le déploiement) ; moyen en ligne → achat `awaiting_payment` et paiement `pending` ;
  - `app.payment_initiated`, `app.payment_initiation_failed`, `app.apply_payment_event`
    (idempotente, contrôle du montant), `app.retry_payment`, `app.switch_to_cash` ;
  - `app.can_read_order` : la vendeuse ne lit que les achats `cash_on_delivery` ou `paid` ;
  - `public.my_store_orders()` et `public.my_store_order(id)` (vendeuse, sans email ni
    téléphone de la cliente) ; `purchase_json` expose l'état de paiement et le paiement courant.
- **Functions** :
  - `PaymentProvider` (`initiate`, `verifyWebhook`, `normalizeEvent`) et registre des
    fournisseurs disponibles ; `simulatorProvider` si `PAYMENTS_SIMULATOR_SECRET` est défini et
    que la branche n'est pas la production ;
  - `POST /v1/orders` : passe les fournisseurs disponibles, puis initie le paiement en ligne ;
  - `POST /v1/purchases/:id/payments` (réessai, `Idempotency-Key`) et
    `POST /v1/purchases/:id/cash` (passage au cash) ;
  - `POST /v1/payments/webhooks/:provider` : journal brut, signature, traitement ;
  - `GET /v1/payments/simulator/:paymentId` (page HTML) et `POST …/:outcome` : envoie une
    confirmation signée au webhook (même chemin que Moneroo).
- **Dart** :
  - `dym_models` : `PaymentStatus`, `PurchasePayment`, champs de `Purchase` ; `VendorOrder` ;
  - `dym_data` : `OrderRepository.retryPayment`, `payOnDelivery` ; `VendorOrderRepository` ;
  - `dym_platform` : `ExternalPageOpener` (`url_launcher`).
- **App cliente** : écran 39 (attente, relecture toutes les 3 s et au premier plan), 40 (échec :
  réessayer, cash), 37 avec « Paiement confirmé ».
- **App vendeuse** : onglet « Commandes » (41) et détail (42), rafraîchis toutes les 20 s.
- **Galerie** : 39 à 42.

## Constitution Check

| Principe | Vérification | Statut |
|---|---|---|
| I | Spec `payments` (Phase 2), IDs cités ; simulateur demandé par le porteur produit | ✅ |
| II | 39 à 42 générées, à valider ; 05 et 08 validées | ⚠️ validation |
| III | États de paiement, montants et visibilité décidés en SQL ; la Function ne porte que l'appel au fournisseur et le webhook | ✅ |
| IV | Fournisseur derrière une interface ; moyens par pays en données ; aucun pays en dur | ✅ |
| V | Webhook signé, idempotent, journalisé brut ; simulateur absent en production ; RLS + pgTAP | ✅ |
| VI | Ouverture d'URL dans `dym_platform` ; features dans les apps | ✅ |
| VII | pgTAP, tests Function, tests Flutter, bout en bout sur staging | ✅ |
| VIII | Clé d'idempotence sur la commande et le réessai ; 4 états par écran | ✅ |
| IX | `payment_initiated`, `payment_succeeded`, `payment_failed` serveur | ✅ |

## Decisions

| # | Décision | Pourquoi |
|---|---|---|
| D1 | Le simulateur est un vrai fournisseur (page de paiement + webhook signé HMAC), pas un raccourci dans l'app | Les apps et la base suivent exactement le chemin de Moneroo |
| D2 | Garde double : variable `PAYMENTS_SIMULATOR_SECRET` (absente en production) et branche non par défaut | Impossible d'encaisser une commande « simulée » en production |
| D3 | `p_online_providers` passé par la Function à `place_order` | La base reste seule juge, sans connaître le déploiement |
| D4 | État de paiement porté par l'achat, recalculé à chaque événement | Une seule règle de visibilité pour les vendeuses |
| D5 | L'app relit le statut (3 s) plutôt qu'une connexion temps réel | Pas de push avant `order-lifecycle` ; suffisant pour SC-001 |
| D6 | Un échec garde la commande et son stock ; réessai ou cash | Ne jamais perdre une commande ; annulation dans `order-lifecycle` |
| D7 | `url_launcher` dans `dym_platform` (`ExternalPageOpener`) | Plugin d'appareil ; l'app ne connaît pas le fournisseur |
| D8 | Liste vendeuse en lecture seule, rafraîchie toutes les 20 s | Les actions (accepter, refuser) appartiennent à `order-lifecycle` |

## Project Structure

```text
db/migrations/0012_payments.sql · db/tests/070_payments.sql
functions/src/payments/{ports,providers,routes,adapters,simulator}.ts · functions/test/payments*.test.ts
packages/domain/dym_models/lib/src/cart/cart_models.dart · src/orders/vendor_orders.dart
packages/data/dym_data/lib/src/{cart,vendor_order}_repository.dart
packages/infra/dym_platform/lib/src/external_page_opener.dart
apps/dym_client/lib/features/cart/payment/ (39, 40)
apps/dym_vendor/lib/features/orders/ (41, 42)
```

## Complexity Tracking

Aucune dérogation.
