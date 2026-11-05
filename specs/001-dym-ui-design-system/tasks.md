---
description: "Tâches — 001 Socle et design system DYM, avec galerie de validation"
---

# Tasks: Socle et design system DYM, avec galerie de validation

**Input**: Design documents from `specs/001-dym-ui-design-system/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/dym_ui-components.md, quickstart.md

**Tests**: demandés par la constitution (VII) et le plan : unitaires (`dym_core`), widget (`dym_ui`),
golden des 8 écrans (`dym_gallery`).

**Organization**: tâches groupées par user story (US1 à US4 de spec.md).

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, pas de dépendance sur une tâche non terminée)
- **[Story]** : user story concernée

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Créer le `pubspec.yaml` racine (workspace : `packages/foundation/dym_core`, `packages/ui/dym_ui`, `apps/dym_gallery` ; dev : `melos ^8.9.0` ; section `melos` avec `sdkPath: .fvm/flutter_sdk` et scripts `tokens`, `analyze`, `test`, `golden`) dans `pubspec.yaml`
- [X] T002 [P] Créer `analysis_options.yaml` racine incluant `package:very_good_analysis/analysis_options.yaml` avec `public_member_api_docs: false`
- [X] T003 [P] Créer le package Dart pur `packages/foundation/dym_core` (`pubspec.yaml` avec `resolution: workspace`, dépendance `intl: ^0.20.3`, `lib/dym_core.dart`)
- [X] T004 [P] Créer le package Flutter `packages/ui/dym_ui` (`pubspec.yaml` avec `resolution: workspace`, dépendances `dym_core`, `flutter_animate: ^4.5.2`, déclaration des polices `Nunito` et `NunitoSans`, `lib/dym_ui.dart`)
- [X] T005 [P] Créer l'app `apps/dym_gallery` via `fvm flutter create --platforms android,web --org dev.dym --empty`, puis `resolution: workspace`, dépendances `dym_core`, `dym_ui`, déclaration des dossiers `assets/demo/` et `assets/reference/`
- [X] T006 [P] Pointer `.vscode/settings.json` vers `.fvm/flutter_sdk`
- [X] T007 Exécuter `melos bootstrap` et vérifier que le SDK utilisé est 3.47.5

---

## Phase 2: Foundational (Blocking Prerequisites)

- [X] T008 [P] Implémenter `Currency` (`code` ISO 4217 3 lettres majuscules ; `minorUnits` 0 à 3 ; `symbol` ; `locale` ; constantes `xof` « F CFA » 0 décimale locale `fr`, `ghs` « GH₵ » 2 décimales locale `en`) dans `packages/foundation/dym_core/lib/src/money/currency.dart`
- [X] T009 Implémenter `Money` (`amountMinor` entier, jamais de flottant ; `+` même devise sinon `ArgumentError` ; `* int` quantité ≥ 0 ; comparaisons ; `isZero` ; `format()`) dans `packages/foundation/dym_core/lib/src/money/money.dart`
- [X] T010 Tester `Money` (formatage XOF « 4 100 F CFA » à l'espace insécable près, GHS 2 décimales, addition de devises différentes refusée, multiplication) dans `packages/foundation/dym_core/test/money_test.dart`
- [X] T011 [P] Télécharger `Nunito[wght].ttf`, `NunitoSans[YTLC,opsz,wdth,wght].ttf` et `OFL.txt` depuis google/fonts dans `packages/ui/dym_ui/fonts/`
- [X] T012 Écrire le générateur de tokens (lecture de `docs/design/tokens/dym.tokens.json`, résolution des alias `{groupe.token}`, sortie de constantes typées couleurs, typographies, espacements, rayons, tailles, ombre) dans `packages/ui/dym_ui/tool/generate_tokens.dart`
- [X] T013 Générer `packages/ui/dym_ui/lib/src/tokens/dym_tokens.g.dart` via `melos run tokens`
- [X] T014 Implémenter `DymColors` et `DymTextStyles` (`ThemeExtension`), `DymTheme.light()` et l'extension `context.dym` dans `packages/ui/dym_ui/lib/src/theme/`
- [X] T015 [P] Implémenter `DymMotion` (durées ≤ 450 ms, `Duration.zero` si `MediaQuery.disableAnimationsOf`) dans `packages/ui/dym_ui/lib/src/theme/dym_motion.dart`
- [X] T016 [P] Implémenter `StoreOrigin` et `MoneyText` dans `packages/ui/dym_ui/lib/src/foundation/`
- [X] T017 [P] Tester la conformité tokens/thème (valeurs générées = JSON) et les contrastes texte/fond ≥ 4,5:1 dans `packages/ui/dym_ui/test/tokens_test.dart` et `packages/ui/dym_ui/test/contrast_test.dart`
- [X] T018 [P] Générer les images de démonstration avec ChatGPT via Codex (produits dans leurs contenants sur fond transparent, avatars, couvertures, tuiles de rayon, zem, bassine du splash) dans `apps/dym_gallery/assets/demo/` (sources PNG hors dépôt)
- [X] T019 Convertir les images en WebP (produits et tuiles 512 px, avatars 256 px, couvertures 1024 × 576) et copier les 8 écrans validés dans `apps/dym_gallery/assets/reference/`
- [X] T020 Implémenter les données de démonstration (`DemoCountry` TG/GH avec `demoRate`, boutiques, produits, panier de l'écran 5 = 3 400 F + 700 F = 4 100 F) dans `apps/dym_gallery/lib/demo/`
- [X] T021 Implémenter la coquille de la galerie (accueil avec « Écrans validés », « Catalogue », sélecteur de pays, bandeau « Données de démonstration », bouton « Comparer » avec surimpression et curseur d'opacité) dans `apps/dym_gallery/lib/main.dart` et `apps/dym_gallery/lib/shell/`

**Checkpoint** : socle prêt, les user stories peuvent commencer.

---

## Phase 3: User Story 1 - Valider les écrans de référence (Priority: P1) 🎯 MVP

**Goal** : les 8 écrans validés reproduits fidèlement avec les composants `dym_ui`.

**Independent Test** : ouvrir chaque écran avec « Comparer » ; captures golden 360 × 800 comparables aux images validées.

### Composants (contrat `contracts/dym_ui-components.md`)

- [X] T022 [P] [US1] `DymButton` (primary, secondary, plantain ; désactivé ; chargement ; `trailing`) dans `packages/ui/dym_ui/lib/src/components/dym_button.dart`
- [X] T023 [P] [US1] `DymFilterChip` dans `packages/ui/dym_ui/lib/src/components/dym_filter_chip.dart`
- [X] T024 [P] [US1] `DymOriginBadge` et `DymPromoBadge` dans `packages/ui/dym_ui/lib/src/components/dym_badges.dart`
- [X] T025 [P] [US1] `DymSearchBar` dans `packages/ui/dym_ui/lib/src/components/dym_search_bar.dart`
- [X] T026 [P] [US1] `DymDeliveryPill` dans `packages/ui/dym_ui/lib/src/components/dym_delivery_pill.dart`
- [X] T027 [P] [US1] `DymQuantityStepper` dans `packages/ui/dym_ui/lib/src/components/dym_quantity_stepper.dart`
- [X] T028 [US1] `DymProductCard` (grid, compact ; « + » ↔ compteur) dans `packages/ui/dym_ui/lib/src/components/dym_product_card.dart`
- [X] T029 [P] [US1] `DymMiniCartBar` dans `packages/ui/dym_ui/lib/src/components/dym_mini_cart_bar.dart`
- [X] T030 [P] [US1] `DymStoreCard` et `DymAvatar` dans `packages/ui/dym_ui/lib/src/components/dym_store_card.dart` et `dym_avatar.dart`
- [X] T031 [P] [US1] `DymAisleTile` dans `packages/ui/dym_ui/lib/src/components/dym_aisle_tile.dart`
- [X] T032 [P] [US1] `DymFreeDeliveryGauge` dans `packages/ui/dym_ui/lib/src/components/dym_free_delivery_gauge.dart`
- [X] T033 [P] [US1] `DymPaymentOption` dans `packages/ui/dym_ui/lib/src/components/dym_payment_option.dart`
- [X] T034 [P] [US1] `DymTimeline` dans `packages/ui/dym_ui/lib/src/components/dym_timeline.dart`
- [X] T035 [P] [US1] `DymBottomNav` dans `packages/ui/dym_ui/lib/src/components/dym_bottom_nav.dart`
- [X] T036 [P] [US1] `DymSelectableCard` et `DymSectionHeader` dans `packages/ui/dym_ui/lib/src/components/`
- [X] T037 [US1] Exporter tous les composants dans `packages/ui/dym_ui/lib/dym_ui.dart`
- [X] T038 [P] [US1] Tests widget (rendu, cible ≥ 48 dp, sémantique, état sélectionné/désactivé) dans `packages/ui/dym_ui/test/components/`

### Écrans reproduits

- [X] T039 [P] [US1] Écran 01 Splash dans `apps/dym_gallery/lib/screens/s01_splash.dart`
- [X] T040 [P] [US1] Écran 02 Accueil dans `apps/dym_gallery/lib/screens/s02_home.dart`
- [X] T041 [P] [US1] Écran 03 Rayon Légumes dans `apps/dym_gallery/lib/screens/s03_aisle.dart`
- [X] T042 [P] [US1] Écran 04 Page boutique « Les jus d'Esi » dans `apps/dym_gallery/lib/screens/s04_store.dart`
- [X] T043 [P] [US1] Écran 05 Panier dans `apps/dym_gallery/lib/screens/s05_cart.dart`
- [X] T044 [P] [US1] Écran 06 Suivi dans `apps/dym_gallery/lib/screens/s06_tracking.dart`
- [X] T045 [P] [US1] Écran 07 « Où vends-tu ? » dans `apps/dym_gallery/lib/screens/s07_seller_origin.dart`
- [X] T046 [P] [US1] Écran 08 Commande reçue dans `apps/dym_gallery/lib/screens/s08_seller_new_order.dart`
- [X] T047 [US1] Tests golden des 8 écrans en 360 × 800 (polices chargées, images préchargées, tag `golden`) dans `apps/dym_gallery/test/golden/`

**Checkpoint** : US1 démontrable seule.

---

## Phase 4: User Story 2 - Animations clés (Priority: P2)

**Goal** : splash, ajout au panier, mini-panier, sonnerie, zem.

**Independent Test** : déclencher les 4 animations ; avec « réduire les animations », état final immédiat.

- [X] T048 [P] [US2] Transformation animée « + » → compteur dans `packages/ui/dym_ui/lib/src/components/dym_product_card.dart`
- [X] T049 [P] [US2] Glissement d'apparition et rebond du compteur du mini-panier dans `packages/ui/dym_ui/lib/src/components/dym_mini_cart_bar.dart`
- [X] T050 [P] [US2] Entrée orchestrée du splash (bassine, logo, slogan, bande kente) dans `apps/dym_gallery/lib/screens/s01_splash.dart`
- [X] T051 [P] [US2] Zem qui avance le long de l'itinéraire dans `apps/dym_gallery/lib/screens/s06_tracking.dart`
- [X] T052 [P] [US2] Pulsation de sonnerie dans `apps/dym_gallery/lib/screens/s08_seller_new_order.dart`
- [X] T053 [US2] Ajout interactif au panier de démonstration dans l'écran Rayon (mise à jour du mini-panier) dans `apps/dym_gallery/lib/screens/s03_aisle.dart`
- [X] T054 [US2] Tests widget : animations terminées en ≤ 450 ms et désactivées si `disableAnimations` dans `packages/ui/dym_ui/test/motion_test.dart`

---

## Phase 5: User Story 3 - Devise selon le pays (Priority: P2)

**Goal** : bascule Togo/Ghana sur tous les montants et la ville.

**Independent Test** : écran Panier en Ghana, aucun montant en F CFA.

- [X] T055 [US3] Brancher tous les montants des 8 écrans sur `Money` du pays sélectionné et la ville sur `DemoCountry.city` dans `apps/dym_gallery/lib/screens/` et `apps/dym_gallery/lib/demo/`
- [X] T056 [US3] Test widget : en Ghana, l'écran Panier n'affiche aucun « F CFA » et affiche des montants à 2 décimales dans `apps/dym_gallery/test/country_switch_test.dart`

---

## Phase 6: User Story 4 - Catalogue du design system (Priority: P3)

**Goal** : tokens et composants consultables avec leurs états.

**Independent Test** : chaque composant du contrat présent avec ses états.

- [X] T057 [P] [US4] Page Couleurs avec ratio de contraste calculé dans `apps/dym_gallery/lib/catalog/colors_page.dart`
- [X] T058 [P] [US4] Page Typographie, espacements, rayons dans `apps/dym_gallery/lib/catalog/foundations_page.dart`
- [X] T059 [P] [US4] Page Composants avec états côte à côte dans `apps/dym_gallery/lib/catalog/components_page.dart`

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T060 [P] CI GitHub Actions (FVM, melos bootstrap, vérification des tokens générés, analyze, test hors golden) dans `.github/workflows/ci.yml`
- [X] T061 [P] Mettre à jour `AGENTS.md`, `README.md` et `docs/architecture/PACKAGES.md` (commandes Melos, galerie)
- [X] T062 Exécuter `quickstart.md` de bout en bout (analyze, test, golden, lancement web) et consigner les résultats
- [X] T063 Produire les captures de comparaison (golden à côté des écrans validés) pour la validation du porteur produit
- [X] T064 [P] `DymStateView` (vide, erreur, hors ligne ; titre, message, action en paramètres) et sa page au catalogue, dans `packages/ui/dym_ui/lib/src/components/dym_state_view.dart` (analyse C1, constitution VIII)
- [X] T065 [P] Tests des cas limites : nom de 80 caractères tronqué sur 2 lignes, montant 1 250 000 F CFA sans débordement, image absente remplacée, facteur de texte 1,3 sans coupure, dans `packages/ui/dym_ui/test/components/edge_cases_test.dart` (analyse E1)
- [ ] T066 (à faire : aucun appareil branché lors de l'implémentation) Vérifier la fluidité sur un Android d'entrée de gamme en mode profile et consigner le résultat dans `specs/001-dym-ui-design-system/quickstart.md` (analyse E2, SC-005)
- [X] T067 Ajouter à `apps/dym_gallery/test/country_switch_test.dart` l'assertion « total du panier = montant à payer au suivi » (analyse E3, FR-017)

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 → US1 (P1) → US2 et US3 (P2, parallélisables) → US4 (P3) → Polish.
- T018/T019 (images) bloquent les écrans T039–T046 mais pas les composants.
- T013 (tokens générés) bloque T014 puis tous les composants.
- US2 et US3 modifient des écrans de US1 : à faire après T039–T046.

## Parallel Example: User Story 1

Composants T022–T027, T029–T036 en parallèle (fichiers distincts) ; puis écrans T039–T046 en parallèle.

## Implementation Strategy

1. Socle (Phases 1–2), puis US1 complète : la galerie montre les 8 écrans statiques fidèles → première validation possible.
2. US2 (animations) et US3 (pays) ajoutent du ressenti et la preuve du générique.
3. US4 (catalogue) pour les specs suivantes.
4. Polish : CI, documentation, captures de comparaison.
