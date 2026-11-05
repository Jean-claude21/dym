# Tasks: Cycle de vie des commandes et notifications

**Input**: [spec.md](spec.md), [plan.md](plan.md)

## Phase 1: Setup

- [X] T001 Maquettes 43 à 46 dans `docs/design/screens/`, listées dans `docs/design/MOCKUPS.md`
- [X] T002 Textes fr et en (statuts, gestes, raisons, notifications, réglages)

## Phase 2: Foundational

- [X] T003 Statuts, horodatages, historique, `app.transition_order`, `app.confirm_cash` dans `db/migrations/0013_order_lifecycle.sql`
- [X] T004 Notifications, préférences, téléphones, déclencheurs, file de push dans `db/migrations/0013_order_lifecycle.sql`
- [X] T005 pgTAP : toutes les paires de transitions par rôle et mode, conflit d'état, stock rendu, remboursement marqué, encaissement unique, notifications, préférences, lectures croisées, dans `db/tests/080_order_lifecycle.sql` et `db/tests/081_notifications.sql`

## Phase 3: US1 et US2 — vendeuse (P1)

- [X] T006 [US1] Routes `POST /v1/orders/:id/transitions` et `/cash-collected`, `PushSender` (FCM, ignoré) et envoi après chaque route, tests, dans `functions/src/`
- [X] T007 [P] [US1] Modèles et dépôts (transitions, historique, gestes permis)
- [X] T008 [US1] Onglets nouvelles / en cours / terminées, alerte à l'arrivée, nouvelle commande (08), refus (45) dans `apps/dym_vendor/lib/features/orders/`
- [X] T009 [US2] Gestes préparation, prête, en route, livrée, encaissement dans le détail (42)

## Phase 4: US3 et US4 — cliente (P1)

- [X] T010 [US3] Onglet « Commandes » (43) et suivi (06) avec annulation, dans `apps/dym_client/lib/features/orders/`
- [X] T011 [US4] Centre de notifications (44) avec compteur, réglages (46) depuis « Moi »

## Phase 5: Polish

- [X] T012 Galerie 43 à 48 et goldens ; tests de vues aux 7 tailles
- [X] T013 Staging : migration, pgTAP, Function ; bout en bout (accepter, livrer, encaisser ; annuler ; refuser) dans `packages/data/dym_data/test/order_flow_live_test.dart`
- [X] T014 Quickstart, analyse et tests verts
