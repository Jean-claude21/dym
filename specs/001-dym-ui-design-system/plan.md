# Implementation Plan: Socle et design system DYM, avec galerie de validation

**Branch**: `feat/001-dym-ui-design-system` | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-dym-ui-design-system/spec.md`

## Summary

Créer le monorepo Flutter de DYM (FVM 3.47.5, pub workspace, Melos), un `dym_core` minimal
(argent), la bibliothèque `dym_ui` générée depuis les tokens validés (thème, polices variables
embarquées, 18 composants, animations sobres) et une app outil `dym_gallery` qui reproduit les 8
écrans de référence avec des données de démonstration, un mode de comparaison avec l'image validée
et un sélecteur Togo/Ghana. Des tests golden produisent des captures 360 × 800 à comparer aux
écrans validés.

## Technical Context

**Language/Version**: Dart 3.13.4 / Flutter 3.47.5 (FVM, `.fvmrc`)

**Primary Dependencies**: `intl` 0.20.3 (formatage), `flutter_animate` 4.5.2 (animations
orchestrées) ; dev : `melos` 8.9.0, `very_good_analysis` 11.0.0, `mocktail` 1.0.5, `flutter_test`

**Storage**: N/A (données de démonstration en mémoire dans la galerie)

**Testing**: `flutter test` (unitaires, widget, golden étiquetés `golden`), `dart test` pour `dym_core`

**Target Platform**: Android (API 24+) et Web pour la galerie ; `dym_ui` multiplateforme

**Project Type**: monorepo mobile (bibliothèques + app outil)

**Performance Goals**: 60 images/s sur Android 2 Go ; micro-interactions ≤ 450 ms

**Constraints**: hors connexion (polices et images embarquées), contraste AA, cibles ≥ 48 dp,
respect de « réduire les animations », aucune valeur de design hors tokens

**Scale/Scope**: 2 packages, 1 app outil, 18 composants, 8 écrans, ~35 images de démonstration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Vérification | Statut |
|---|---|---|
| I. Contrat V1 et gates | Spec 001 inscrite à la roadmap (phase 1 · `foundation`, volet interface) ; aucune feature produit ajoutée | ✅ |
| II. Valider avant de construire | Les 8 écrans validés sont la référence ; la galerie sert à la validation par le porteur produit | ✅ |
| III. Postgres source de vérité | Aucune règle métier dans cette spec ; montants de démonstration statiques | ✅ (N/A) |
| IV. Générique par configuration | Montants en `Money` (entier + devise ISO) ; pays de démonstration configurable ; tous les textes de la galerie en français, centralisés | ✅ voir note i18n |
| V. Sécurité par défaut | Aucun secret, aucune donnée réelle ; images générées | ✅ |
| VI. Architecture en couches | `dym_core` (foundation, Dart pur) ← `dym_ui` (ui) ← `dym_gallery` (outil). `dym_ui` ne dépend pas de Stacked | ✅ voir Complexity Tracking |
| VII. Qualité vérifiable | Tests unitaires, widget et golden ; analyse sans erreur ; démo sur Android | ✅ |
| VIII. Terrain | 360 × 640 testé, contraste mesuré, `disableAnimations`, hors connexion | ✅ |
| IX. Mesurer et tracer | Aucun parcours de `METRICS.md` concerné (outil interne) | ✅ (N/A) |

Note i18n : `dym_l10n` (ARB) n'est pas créé dans cette spec. Les composants de `dym_ui` ne contiennent
**aucun texte en dur** : tous les libellés sont passés en paramètres. Les textes de démonstration vivent
dans la galerie, qui est un outil. `dym_l10n` arrive avec la première app produit.

**Re-check post-design** : ✅ inchangé (voir data-model et contrat d'interface).

## Project Structure

### Documentation (this feature)

```text
specs/001-dym-ui-design-system/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── dym_ui-components.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
dym/
├── .fvmrc                         # 3.47.5
├── pubspec.yaml                   # workspace + melos (sdkPath: .fvm/flutter_sdk)
├── analysis_options.yaml          # very_good_analysis
├── packages/
│   ├── foundation/dym_core/
│   │   ├── lib/dym_core.dart
│   │   ├── lib/src/money/{currency.dart,money.dart}
│   │   └── test/money_test.dart
│   └── ui/dym_ui/
│       ├── tool/generate_tokens.dart
│       ├── fonts/{Nunito[wght].ttf, NunitoSans[...].ttf, OFL.txt}
│       ├── lib/dym_ui.dart
│       ├── lib/src/tokens/dym_tokens.g.dart
│       ├── lib/src/theme/{dym_theme.dart, dym_colors.dart, dym_text_styles.dart, dym_motion.dart}
│       ├── lib/src/components/…   # 18 composants (voir contrat)
│       └── test/{tokens_test.dart, contrast_test.dart, components/…}
└── apps/
    └── dym_gallery/
        ├── assets/demo/{products,stores,avatars,aisles,illustrations}/…webp
        ├── assets/reference/…webp          # copie des écrans validés pour « Comparer »
        ├── lib/main.dart
        ├── lib/demo/{demo_country.dart, demo_catalog.dart}
        ├── lib/catalog/…                   # pages du catalogue
        ├── lib/screens/…                   # 8 écrans reproduits
        └── test/golden/{flutter_test_config.dart, screens_golden_test.dart}
```

**Structure Decision** : conforme à `docs/architecture/PACKAGES.md` (catégories `foundation`, `ui`)
avec une app outil `apps/dym_gallery`. Les packages `infra`, `domain`, `data`, `features` et les apps
produit ne sont pas créés ici (YAGNI) ; ils arriveront avec leurs specs.

## Complexity Tracking

| Écart | Pourquoi | Alternative plus simple rejetée |
|---|---|---|
| `dym_gallery` n'utilise pas Stacked | Outil de validation sans logique ; Stacked ajouterait génération et injection sans bénéfice | Utiliser Stacked : coût de génération sans valeur pour un outil |
| `dym_l10n` reporté | Aucun texte produit dans cette spec ; les composants reçoivent leurs libellés | Créer un package ARB vide : structure sans usage |
