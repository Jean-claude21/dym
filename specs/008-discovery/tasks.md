# Tasks: Découverte côté cliente

## Phase 1: Setup

- [X] T001 Maquettes 28-30 dans `docs/design/screens/` (+ `DESIGN_DIRECTION.md`, `MOCKUPS.md`)

## Phase 2: Base (US1-US4)

- [X] T002 Migration `db/migrations/0008_discovery.sql` : `unaccent`, `app.normalize`, colonnes `search` et index, centres des quartiers, `cities.delivery_minutes`, `discover_stores`, `nearest_zone`, `search_catalog`, `store_page`, `product_page`
- [X] T003 `db/tests/050_discovery.sql` : ouverture selon horaires et interrupteur, quartiers desservis, ordre, estimation, quartier le plus proche, recherche sans accents et par préfixe, filtres et tris, disponibilité, rayon et sous-rayons, pages sans données privées, boutique suspendue invisible

## Phase 3: Dart

- [X] T004 `dym_models` + `dym_data` `DiscoveryRepository` + tests
- [X] T005 `dym_platform` `LocationProvider` (`geolocator`)
- [X] T006 ARB : textes de la découverte (fr, en)

## Phase 4: App cliente (US1-US4)

- [X] T007 Viewmodels : accueil, quartier, rayon, boutique, fiche, recherche et filtres + tests
- [X] T008 Vues 02, 03, 04, 28, 29, 30 + tests aux 7 tailles fr/en 130 % ; parcours nominal
- [X] T009 Onglets Accueil, Rayons, Moi ; navigation ; injection

## Phase 5: Polish

- [X] T010 Galerie : écrans 28-33, captures, comparaison ; vérification finale ; PR
