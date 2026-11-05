# Tasks: Paiements génériques et fournisseur simulé

**Input**: [spec.md](spec.md), [plan.md](plan.md)

## Phase 1: Setup

- [X] T001 Maquettes 39 à 42 dans `docs/design/screens/`, listées dans `docs/design/MOCKUPS.md`
- [X] T002 Textes fr et en (attente, échec, badges, commandes vendeuse) dans `packages/foundation/dym_l10n/lib/l10n/app_{fr,en}.arb`

## Phase 2: Foundational

- [X] T003 `payments`, `payment_events`, `purchases.payment_status`, fournisseur `simulator`, RLS, dans `db/migrations/0012_payments.sql`
- [X] T004 `app.place_order` avec `p_online_providers`, `app.payment_initiated`, `app.payment_initiation_failed`, `app.apply_payment_event`, `app.retry_payment`, `app.switch_to_cash`, visibilité vendeuse, dans `db/migrations/0012_payments.sql`
- [X] T005 pgTAP : cash inchangé, moyen en ligne en attente, confirmation idempotente, montant différent ignoré, échec puis réessai, passage au cash, invisibilité vendeuse avant paiement, événements, dans `db/tests/070_payments.sql`

## Phase 3: User Story 4 — chaîne et simulateur (P1)

- [X] T006 [US4] `PaymentProvider`, registre, simulateur (HMAC, page HTML, issues), garde production, dans `functions/src/payments/`
- [X] T007 [US4] Routes : commande avec paiement, réessai, cash, webhook journalisé, dans `functions/src/payments/routes.ts` et `functions/src/orders/routes.ts`
- [X] T008 [US4] Tests Function (signature invalide, rejeu, production refusée, issues du simulateur) dans `functions/test/payments.test.ts`

## Phase 4: User Stories 1 et 2 — cliente (P1)

- [X] T009 [P] [US1] Modèles `PaymentStatus`, `PurchasePayment` et dépôt (`retryPayment`, `payOnDelivery`) dans `packages/domain/dym_models` et `packages/data/dym_data`
- [X] T010 [P] [US1] `ExternalPageOpener` dans `packages/infra/dym_platform`
- [X] T011 [US1] Écran 39 (attente, relecture 3 s et au premier plan) et 37 avec « Paiement confirmé » dans `apps/dym_client/lib/features/cart/payment/`
- [X] T012 [US2] Écran 40 (réessayer, payer à la livraison) dans `apps/dym_client/lib/features/cart/payment/`

## Phase 5: User Story 3 — vendeuse (P1)

- [X] T013 [US3] `my_store_orders`, `my_store_order` (pgTAP inclus) dans `db/migrations/0012_payments.sql`
- [X] T014 [US3] `VendorOrder` et `VendorOrderRepository` dans `packages/domain/dym_models` et `packages/data/dym_data`
- [X] T015 [US3] Onglet « Commandes » (41) et détail (42), rafraîchis toutes les 20 s, dans `apps/dym_vendor/lib/features/orders/`

## Phase 6: Polish

- [X] T016 Galerie 39 à 42 et goldens
- [X] T017 Tests de vues aux 7 tailles, fr et en, texte 130 %
- [X] T018 Staging : migration, pgTAP, Function avec simulateur, moyen simulé activé pour le pays de test ; bout en bout réussi et échec → cash dans `packages/data/dym_data/test/order_flow_live_test.dart`
- [ ] T019 Quickstart, analyse et tests verts

## Dependencies

Phase 2 avant tout ; US4 avant US1 et US2 ; US3 indépendante après la phase 2.
