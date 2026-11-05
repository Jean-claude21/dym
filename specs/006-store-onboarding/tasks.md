# Tasks: Onboarding et réglages de la boutique

## Phase 1: Setup

- [X] T001 Maquettes 16-23 dans `docs/design/screens/` (+ `DESIGN_DIRECTION.md`, `MOCKUPS.md`)

## Phase 2: Base (US1, US2, US3, US4)

- [X] T002 Migration `db/migrations/0006_stores.sql` : tables, contraintes (nom 2-60, présentation ≤ 280, délai 5-240, frais ≥ 0, jour 1-7, ouverture < fermeture), RLS, privilèges par colonne, fonctions `start_store`, `update_store`, `set_store_pickup_address`, `set_store_delivery_zones`, `set_store_payment_methods`, `set_store_hours`, `publish_store`, `set_store_open`, `my_store`
- [X] T003 [P] `db/tests/030_stores_onboarding.sql` : brouillon, reprise (étape), pays déduit, une seule boutique, rôle vendeuse requis, quartiers d'une autre ville refusés, paiement d'un autre pays refusé, horaires invalides refusés, ouverture incomplète refusée, ouverture complète + événements
- [X] T004 [P] `db/tests/031_stores_access.sql` : lecture publique des actives sans adresse ni propriétaire, brouillon invisible, autre vendeuse refusée, statut non modifiable, suspendue non rouvrable, ouvrir/fermer + événements

## Phase 3: Dart (US1, US2, US4)

- [X] T005 `dym_models` : `Store`, `PickupAddress`, `StoreHours`, `MyStore` + tests
- [X] T006 `dym_data` : `StoreRepository` + tests serveur simulé
- [X] T007 ARB : textes de l'onboarding et de « Ma boutique » (fr, en)

## Phase 4: App vendeuse (US1, US2, US4)

- [X] T008 `StoreOnboardingViewModel` (7 étapes, enregistrement par étape, reprise, validation) + tests
- [X] T009 Vues des 7 étapes, `StoreOpenedView`, `MyStoreView` (interrupteur, sections) + tests aux 7 tailles fr/en 130 %
- [X] T010 Démarrage : boutique absente ou brouillon → onboarding ; active → « Ma boutique » ; navigation à onglets (Boutique, Moi)

## Phase 5: Polish

- [X] T011 Galerie : écrans 16-23 (démonstration), captures ; comparaison ; vérification finale ; PR
