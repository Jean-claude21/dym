# Tasks: Mise en page adaptative du design system et de la galerie

**Input**: Design documents from `specs/002-responsive-layout/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/dym_ui-layout.md, quickstart.md

**Tests**: demandés par la spec (FR-011, FR-012, FR-015, SC-001..SC-004).

**Organization**: tâches groupées par user story ; chemins relatifs à la racine du dépôt.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Inscrire `responsive-layout` (volet interface du socle, ~2 h) dans la Phase 1 de `docs/product/ROADMAP.md` et ajouter à la définition de terminé « écrans vérifiés aux tailles de référence de `dym_ui` »
- [X] T002 Rejouer les goldens 412 × 915 de la spec 001 **sans** `--update-goldens` pour fixer la référence avant tout changement (`apps/dym_gallery/test/golden/screens_golden_test.dart`)

## Phase 2: Foundational (bloquant)

- [X] T003 Ajouter les groupes `breakpoint` (`medium` 600, `expanded` 840, `large` 1200) et `layout` (`gutter-compact` 16, `gutter-medium` 24, `gutter-expanded` 32, `gutter-large` 32, `content-max` 1200, `form-max` 600, `floating-max` 560, `rail-width` 88, `rail-extended-width` 220) dans `docs/design/tokens/dym.tokens.json`
- [X] T004 Générer `DymTokenBreakpoints` et `DymTokenLayout` dans `packages/ui/dym_ui/tool/generate_tokens.dart`, puis `melos run tokens` (`packages/ui/dym_ui/lib/src/tokens/dym_tokens.g.dart`)
- [X] T005 [P] Tests de tokens : seuils croissants, `form-max ≤ content-max` dans `packages/ui/dym_ui/test/tokens_test.dart`
- [X] T006 [P] `DymWindowClass` (`of`, `fromWidth`, ordre, seuil inclus dans la classe supérieure) dans `packages/ui/dym_ui/lib/src/layout/dym_window_class.dart`
- [X] T007 [P] `DymLayout.gutter` et `DymLayout.columns` dans `packages/ui/dym_ui/lib/src/layout/dym_layout.dart`
- [X] T008 [P] `DymContentWidth` (borne, centre, marge de classe optionnelle) dans `packages/ui/dym_ui/lib/src/layout/dym_content_width.dart`
- [X] T009 Exporter les briques dans `packages/ui/dym_ui/lib/dym_ui.dart`
- [X] T010 Tests : seuils 599/600/839/840/1199/1200, colonnes (360 → 2, 800 → 3, 1 280 → ≥ 4), bornes de `DymContentWidth` dans `packages/ui/dym_ui/test/layout/layout_test.dart`
- [X] T011 Format de prévisualisation et cadre (`DeviceFormat` : téléphone, téléphone paysage, tablette, tablette paysage, bureau, libre ; `MediaQuery` simulé + `FittedBox`) dans `apps/dym_gallery/lib/shell/device_frame.dart`
- [X] T012 Matrice de robustesse 8 écrans × 7 tailles × 2 pays × 2 textes, avec un échec sur toute exception de rendu, dans `apps/dym_gallery/test/screens_layout_matrix_test.dart` (remplace `screens_smoke_test.dart`)

**Checkpoint** : les briques existent, la matrice tourne (échecs attendus hors téléphone).

## Phase 3: User Story 1 — Écrans utilisables à toutes les tailles (P1) 🎯 MVP

**Goal**: aucun débordement aux 7 tailles, contenu borné et centré, téléphone portrait inchangé.

**Independent Test**: matrice T012 verte ; goldens 412 × 915 inchangés ; bornes vérifiées sur bureau.

- [X] T013 [US1] Borner `DymMiniCartBar` à `layout.floating-max`, centré, dans `packages/ui/dym_ui/lib/src/components/dym_mini_cart_bar.dart` (+ test de largeur dans `packages/ui/dym_ui/test/layout/layout_test.dart`)
- [X] T014 [P] [US1] Splash sans débordement en paysage 640 × 360 dans `apps/dym_gallery/lib/screens/s01_splash.dart`
- [X] T015 [P] [US1] Suivi borné à `form-max`, carte adaptée au paysage, dans `apps/dym_gallery/lib/screens/s06_tracking.dart`
- [X] T016 [P] [US1] « Où vends-tu ? » borné à `form-max` dans `apps/dym_gallery/lib/screens/s07_seller_origin.dart`
- [X] T017 [P] [US1] « Commande reçue » bornée à `form-max` dans `apps/dym_gallery/lib/screens/s08_seller_new_order.dart`
- [X] T018 [US1] Positionner le mini-panier au-dessus du contenu borné dans les écrans 02, 03 et 04 (`apps/dym_gallery/lib/screens/s02_home.dart`, `s03_aisle.dart`, `s04_store.dart`)
- [X] T019 [US1] Assertions de bornes sur bureau (formulaire ≤ 600, contenu ≤ 1 200, mini-panier ≤ 560) dans `apps/dym_gallery/test/screens_layout_matrix_test.dart`

**Checkpoint** : US1 livrable seule.

## Phase 4: User Story 2 — Le contenu profite de la place (P2)

**Goal**: grilles adaptées, panier en deux colonnes en étendue.

**Independent Test**: colonnes du rayon 2 / ≥ 3 / ≥ 4 ; panier en deux colonnes à 1 440.

- [X] T020 [P] [US2] Rayon : colonnes `DymLayout.columns(minTile 168, min 2, max 6)`, contenu ≤ `content-max`, dans `apps/dym_gallery/lib/screens/s03_aisle.dart`
- [X] T021 [P] [US2] Page boutique : grille de produits adaptative, contenu borné sous la couverture pleine largeur, dans `apps/dym_gallery/lib/screens/s04_store.dart`
- [X] T022 [P] [US2] Accueil : rayons `columns(minTile 88, min 4, max 8)`, cartes « Racheter » à largeur de téléphone au-delà de la classe compacte, contenu ≤ `content-max`, dans `apps/dym_gallery/lib/screens/s02_home.dart`
- [X] T023 [P] [US2] Panier en deux colonnes (articles / livraison, paiement, total, « Payer ») à partir de la classe étendue dans `apps/dym_gallery/lib/screens/s05_cart.dart`
- [X] T024 [US2] Tests : colonnes du rayon par taille (SC-004), présence des deux colonnes du panier à 1 440 et d'une seule à 412, dans `apps/dym_gallery/test/screens_adaptive_test.dart`

## Phase 5: User Story 3 — Navigation adaptative (P2)

**Goal**: barre basse, rail, rail étendu.

**Independent Test**: type de navigation par classe, sélection et sémantique.

- [X] T025 [P] [US3] `DymNavRail` (actif vert profond + trait, libellé sous l'icône ou à côté si `extended`, 48 dp, `Semantics`) dans `packages/ui/dym_ui/lib/src/components/dym_nav_rail.dart`
- [X] T026 [US3] `DymAdaptiveScaffold` (compacte → `DymBottomNav`, moyenne/étendue → rail, large → rail étendu ; corps conservé) dans `packages/ui/dym_ui/lib/src/layout/dym_adaptive_scaffold.dart` + export
- [X] T027 [US3] Tests : navigation par largeur (400, 700, 1 000, 1 300), changement d'élément, sémantique `selected`, conservation de l'état du corps au redimensionnement, dans `packages/ui/dym_ui/test/layout/adaptive_scaffold_test.dart`
- [X] T028 [US3] Accueil sur `DymAdaptiveScaffold` dans `apps/dym_gallery/lib/screens/s02_home.dart`

## Phase 6: User Story 4 — Prévisualisation par format (P3)

**Goal**: le porteur produit voit chaque écran à chaque format.

**Independent Test**: changer de format dans la visionneuse ; « Comparer » seulement en téléphone.

- [X] T029 [US4] Sélecteur de format dans `apps/dym_gallery/lib/shell/screen_viewer.dart` (utilise `device_frame.dart`, « Comparer » désactivé hors téléphone)
- [X] T030 [US4] Test du sélecteur (format appliqué, « Comparer » indisponible hors téléphone) dans `apps/dym_gallery/test/screen_viewer_test.dart`
- [X] T031 [US4] Goldens tablette 800 × 1 280 et bureau 1 440 × 900 des 8 écrans dans `apps/dym_gallery/test/golden/screens_golden_test.dart`
- [X] T032 [US4] Planches de validation (8 écrans, tablette et bureau) dans `specs/002-responsive-layout/validation/`

## Phase 7: Polish

- [X] T033 [P] Contrat de composants et catalogue : ajouter `DymNavRail` et les briques de mise en page (`specs/001-dym-ui-design-system/contracts/dym_ui-components.md`, page Fondations de la galerie `apps/dym_gallery/lib/catalog/foundations_page.dart`)
- [X] T034 [P] Décision `docs/architecture/decisions/0012-mise-en-page-adaptative.md`, index des décisions, et amendement de la constitution v1.2.0 (principe VIII) dans `.specify/memory/constitution.md`
- [X] T035 [P] `docs/design/DESIGN_DIRECTION.md` : section « Grands écrans »
- [X] T036 Vérification finale : `melos run analyze`, `melos run test`, `flutter test --tags golden` (412 × 915 inchangés), `flutter build web --release` ; résultats dans `specs/002-responsive-layout/quickstart.md`

## Dependencies & Execution Order

- Setup (T001, T002) → Foundational (T003 → T004 → T005-T012) → US1 → US2 et US3 (indépendantes, mais T022 et T028 touchent le même fichier : T022 puis T028) → US4 → Polish.
- US1 est le MVP : la matrice verte prouve l'absence de débordement à toutes les tailles.

## Parallel Example: User Story 1

```text
T014 s01_splash.dart  |  T015 s06_tracking.dart  |  T016 s07_seller_origin.dart  |  T017 s08_seller_new_order.dart
```

## Implementation Strategy

1. Fondations et matrice (échecs visibles hors téléphone).
2. US1 jusqu'à une matrice verte, puis goldens 412 × 915 inchangés.
3. US2 et US3, puis US4 pour la validation par le porteur produit.
