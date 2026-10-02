# Tasks: Panier multi-boutiques, adresses et commande

**Input**: [spec.md](spec.md), [plan.md](plan.md), [data-model.md](data-model.md),
[contracts/api.md](contracts/api.md)

Tests demandés par la constitution (VII) : pgTAP pour toute règle, tests Function, tests
Flutter des viewmodels et des vues.

## Phase 1: Setup

- [X] T001 Maquettes 34 à 37 générées dans la direction validée, copiées dans `docs/design/screens/` et listées dans `docs/design/MOCKUPS.md`
- [X] T002 Textes fr et en du panier, des adresses, de la livraison et de la confirmation dans `packages/foundation/dym_l10n/lib/l10n/app_{fr,en}.arb`

## Phase 2: Foundational

- [X] T003 Tables `customer_addresses`, `carts`, `cart_items`, `purchases`, `orders`, `order_items`, RLS et droits (colonnes `commission_minor` non accordées) dans `db/migrations/0011_cart_checkout.sql`
- [X] T004 `app.cart_quote` (lignes, problèmes, frais D2, totaux, commission, délai) dans `db/migrations/0011_cart_checkout.sql`
- [X] T005 [P] Modèles `CartView`, `CartStoreGroup`, `CartLine`, `CustomerAddress`, `Purchase`, `PurchaseOrder`, `OrderRequest` dans `packages/domain/dym_models/lib/src/cart/cart_models.dart` (+ génération)

## Phase 3: User Story 1 — panier multi-boutiques (P1)

- [X] T006 [US1] pgTAP : ajout, fusion des lignes, autre pays refusé, quantité 1 à 99 et plafond au stock, groupement, frais base + supplément, gratuité, panier d'une autre cliente invisible, dans `db/tests/061_cart.sql`
- [X] T007 [US1] `my_cart`, `cart_add`, `cart_set_quantity` dans `db/migrations/0011_cart_checkout.sql`
- [X] T008 [P] [US1] `CartRepository` et tests dans `packages/data/dym_data/lib/src/cart_repository.dart`
- [X] T009 [US1] `CartService` (panier observable, `cart_item_added`) et doubles mémoire dans `apps/dym_client/lib/features/cart/`
- [X] T010 [US1] Écran panier (05) : sous-paniers, quantités, jauge, totaux, états, dans `apps/dym_client/lib/features/cart/cart/cart_view.dart`
- [X] T011 [US1] Ajout depuis la fiche produit (variante, quantité) et les cartes ; mini-panier sur accueil, rayons, recherche, boutique, dans `apps/dym_client/lib/features/discovery/`

## Phase 4: User Story 2 — adresses (P1)

- [X] T012 [US2] pgTAP : création, défaut unique, première par défaut, suppression du défaut, 20 au plus, quartier inactif refusé, accès d'une autre cliente refusé, dans `db/tests/060_addresses.sql`
- [X] T013 [US2] `my_addresses`, `save_address`, `delete_address`, `set_default_address` dans `db/migrations/0011_cart_checkout.sql`
- [X] T014 [P] [US2] `AddressRepository` et tests dans `packages/data/dym_data/lib/src/address_repository.dart`
- [X] T015 [US2] Écrans mes adresses (35) et nouvelle adresse (36, `DymPlacePicker`, position conservée) ; entrée « Mes adresses » dans Moi, dans `apps/dym_client/lib/features/cart/addresses/` et `packages/features/dym_account`

## Phase 5: User Story 3 — commande en un tap (P1)

- [X] T016 [US3] pgTAP : achat et commandes créés, montants égaux au devis, lignes figées, stock décrémenté, panier vidé, rejeu idempotent, retrait sans frais, `total_changed`, paiement non accepté, `order_created` avec `stores_count`, lecture croisée refusée, vendeuse limitée à sa boutique, dans `db/tests/062_orders.sql`
- [X] T017 [US3] `app.place_order` et `my_purchase` dans `db/migrations/0011_cart_checkout.sql`
- [X] T018 [US3] Route `POST /v1/orders` (jeton, `Idempotency-Key`, zod, erreurs SQL → 422) et adaptateur `pg` dans `functions/src/orders/`, branchés dans `functions/src/app.ts` et `functions/src/index.ts`, tests dans `functions/test/orders.test.ts`
- [X] T019 [P] [US3] `OrderRepository` (clé d'idempotence conservée jusqu'à la réponse) et tests dans `packages/data/dym_data/lib/src/order_repository.dart`
- [X] T020 [US3] Écran livraison (34 : adresse, mode par boutique, remplacement, `checkout_started`) et paiement dans le panier, dans `apps/dym_client/lib/features/cart/delivery/delivery_view.dart`
- [X] T021 [US3] Confirmation « Commander » et écran commande envoyée (37) dans `apps/dym_client/lib/features/cart/sent/order_sent_view.dart`

## Phase 6: User Story 4 — changements signalés (P2)

- [X] T022 [US4] pgTAP : rupture, boutique fermée, suspendue, quartier non livré, prix modifié, commande refusée avec le bon code, dans `db/tests/061_cart.sql` et `db/tests/062_orders.sql`
- [X] T023 [US4] Problèmes affichés sur la ligne et le sous-panier, avec action (retirer, retrait, changer d'adresse) ; bouton « Commander » désactivé et message, dans `apps/dym_client/lib/features/cart/`

## Phase 7: Polish

- [X] T024 Galerie : écrans 34 à 37 et vrai panier (38), goldens, dans `apps/dym_gallery/`
- [X] T025 Tests de vues aux 7 tailles, fr et en, texte 130 %, et test du parcours nominal (panier → commande) dans `apps/dym_client/test/` — l'enchaînement fiche produit → panier est couvert par les tests séparés des deux écrans
- [X] T026 Migrations et pgTAP sur la branche Neon `staging` (339/339), Function redéployée, commande de bout en bout réelle (`packages/data/dym_data/test/order_flow_live_test.dart` : deux boutiques, adresse, panier, retrait, commande, rejeu, lecture limitée, nettoyage) verte sur staging
- [X] T027 `ROADMAP.md`, `METRICS.md` (événements émis), quickstart vérifié ; analyse et tests verts

## Dependencies

Phase 2 avant tout. US1 et US2 sont indépendantes ; US3 dépend de US1 et US2 ; US4 dépend de
US1 et US3. Les tâches [P] touchent des fichiers distincts.

## Implementation Strategy

MVP : US1 + US2 + US3 (commander un panier de deux boutiques en cash). US4 complète la
confiance avant le pilote.
