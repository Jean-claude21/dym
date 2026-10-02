# Tasks: Catalogue de la vendeuse

## Phase 1: Setup

- [ ] T001 Maquettes 24-27 dans `docs/design/screens/` (+ `DESIGN_DIRECTION.md`, `MOCKUPS.md`)

## Phase 2: Base (US1, US2, US3, US4, US5)

- [ ] T002 Migration `db/migrations/0007_catalog.sql` : tables, contraintes (nom 2-80, description ≤ 500, prix > 0, stock ≥ 0 ou nul, 1-5 photos, 1-10 variantes, 30 catégories, nom de catégorie unique sans casse), RLS de lecture publique, fonctions d'écriture, fonctions `app.*` des Functions, événements
- [ ] T003 [P] `db/tests/040_catalog_products.sql` : création idempotente, devise de la boutique, unité d'un autre pays refusée, publication incomplète refusée, publication et événement, proposition comparée, rupture et stock avec événements, archivage, suppression du brouillon seulement, boutique suspendue figée
- [ ] T004 [P] `db/tests/041_catalog_access.sql` : lecture publique des publiés seulement, brouillons et archives invisibles, catégories archivées invisibles, écritures croisées refusées, clé de photo d'une autre boutique refusée, propositions inaccessibles

## Phase 3: Functions (US1)

- [ ] T005 `functions/src/catalog/` : `photo-uploads` (présignature S3) et `suggestions` (AI SDK, sortie structurée) derrière des interfaces ; erreurs « indisponible » ; tests vitest

## Phase 4: Dart (US1-US4)

- [ ] T006 `dym_models` : catalogue + tests
- [ ] T007 `dym_data` : `CatalogRepository`, `CatalogMediaRepository` + tests serveur simulé
- [ ] T008 `dym_platform` : `PhotoPicker` (`image_picker`, 1 600 px, qualité 80)
- [ ] T009 ARB : textes du catalogue (fr, en)

## Phase 5: App vendeuse (US1-US4)

- [ ] T010 `ProductEditorViewModel` (2 étapes, envoi de la photo, proposition, variantes, idempotence, publication) + tests
- [ ] T011 `ProductsViewModel`, `StoreCategoriesViewModel` + tests
- [ ] T012 Vues 24-27 + tests aux 7 tailles fr/en 130 % ; parcours nominal au toucher
- [ ] T013 Onglets Produits, Boutique, Moi ; « Ajouter mon premier produit » ; injection

## Phase 6: Polish

- [ ] T014 Galerie : écrans 24-27, captures, comparaison ; vérification finale ; PR
