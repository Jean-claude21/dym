# Implementation Plan: Mise en page adaptative du design system et de la galerie

**Branch**: `feat/002-responsive-layout` | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-responsive-layout/spec.md`

## Summary

Ajouter à `dym_ui` une couche de mise en page adaptative pilotée par des tokens :

- quatre classes de fenêtre (600 / 840 / 1 200) ;
- marges latérales et largeurs maximales en tokens ;
- navigation principale adaptative (barre basse, rail, rail étendu) ;
- un conteneur à largeur bornée ;
- un calcul de colonnes ;
- un mini-panier borné.

Les 8 écrans de la galerie l'utilisent sans changer le rendu téléphone portrait validé. La galerie
gagne un sélecteur de format, une matrice de tests de robustesse sur 7 tailles, et des captures
tablette et bureau.

## Technical Context

**Language/Version**: Dart 3.13.4 / Flutter 3.47.5 (FVM, `.fvmrc`)

**Primary Dependencies**: aucune nouvelle. Le SDK Flutter suffit (`MediaQuery.sizeOf`,
`LayoutBuilder`, `FittedBox`) ; `flutter_animate` est déjà présent dans la galerie.

**Storage**: N/A

**Testing**: `flutter test` (widget, robustesse multi-tailles, golden étiquetés `golden`)

**Target Platform**: Android (téléphone, tablette), Web ; `dym_ui` multiplateforme

**Project Type**: monorepo mobile (bibliothèque `dym_ui` + app outil `dym_gallery`)

**Performance Goals**:

- la classe de fenêtre ne provoque de reconstruction qu'au changement de taille ;
- aucun coût supplémentaire en téléphone portrait.

**Constraints**:

- rendu compact identique à la spec 001, vérifié par les goldens 412 × 915 existants, sans
  régénération ;
- 48 dp, AA, `disableAnimations`, texte 130 %.

**Scale/Scope**:

- 2 groupes de tokens, 4 briques de mise en page et 1 composant (`DymNavRail`) ;
- 8 écrans adaptés ;
- 224 tests de robustesse et 16 nouvelles captures.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Vérification | Statut |
|---|---|---|
| I. Contrat V1 et gates | Ajoutée à la roadmap comme volet interface du socle (Phase 1), au même titre que 001. Aucune feature produit nouvelle | ✅ voir T001 |
| II. Valider avant de construire | La référence reste les écrans téléphone validés. Les dispositions larges en dérivent et sont validées par captures (US4, SC-005) | ✅ |
| III. Postgres source de vérité | Aucune règle métier | ✅ (N/A) |
| IV. Générique par configuration | Seuils et largeurs en tokens ; Togo et Ghana testés à toutes les tailles | ✅ |
| V. Sécurité par défaut | Aucun secret ni donnée réelle | ✅ (N/A) |
| VI. Architecture en couches | Briques dans `dym_ui` (ui), sans dépendance vers les apps ni vers Stacked | ✅ |
| VII. Qualité vérifiable | Matrice de robustesse automatique, goldens, analyse stricte en CI | ✅ |
| VIII. Terrain | Téléphone portrait inchangé et prioritaire ; 48 dp, AA, animations désactivables à toutes les tailles | ✅ voir amendement |
| IX. Mesurer et tracer | Aucun parcours de `METRICS.md` concerné | ✅ (N/A) |

**Amendement proposé (MINEUR, v1.2.0)** : ajouter au principe VIII que chaque écran DOIT rester
utilisable de la classe compacte à la classe large, aux tailles de référence de `dym_ui`, le
téléphone portrait restant la référence de design. Décision consignée dans
`docs/architecture/decisions/0012-mise-en-page-adaptative.md`.

**Re-check post-design** : ✅ inchangé.

## Project Structure

### Documentation (this feature)

```text
specs/002-responsive-layout/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/dym_ui-layout.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
docs/design/tokens/dym.tokens.json        # + groupes breakpoint, layout
packages/ui/dym_ui/
├── tool/generate_tokens.dart             # + DymTokenBreakpoints, DymTokenLayout
├── lib/src/layout/
│   ├── dym_window_class.dart             # DymWindowClass.of(context) / fromWidth
│   ├── dym_layout.dart                   # gutter(), columns()
│   ├── dym_content_width.dart            # conteneur centré et borné
│   └── dym_adaptive_scaffold.dart        # barre basse / rail / rail étendu
├── lib/src/components/dym_nav_rail.dart  # rail latéral DYM (actif vert + trait)
├── lib/src/components/dym_mini_cart_bar.dart   # borné à layout.floating-max
└── test/layout/…                          # classes, colonnes, scaffold, bornes
apps/dym_gallery/
├── lib/screens/s01..s08                   # adaptés
├── lib/shell/device_frame.dart            # formats de prévisualisation
├── lib/shell/screen_viewer.dart           # sélecteur de format
└── test/
    ├── screens_layout_matrix_test.dart    # 8 écrans × 7 tailles × 2 pays × 2 textes
    └── golden/screens_golden_test.dart    # + tablette 800×1280, bureau 1440×900
```

**Structure Decision** : nouveau dossier `lib/src/layout/` dans `dym_ui` pour les briques de mise en
page. Elles sont distinctes des composants visuels (`components/`) et des fondations
(`foundation/`).

## Complexity Tracking

| Écart | Pourquoi | Alternative plus simple rejetée |
|---|---|---|
| `DymNavRail` maison plutôt que `NavigationRail` Material | Reproduire exactement l'élément actif validé (vert profond + trait), la sémantique et les 48 dp de `DymBottomNav` | `NavigationRail` thémé : indicateur en pilule non conforme au design validé, styles difficiles à aligner |
