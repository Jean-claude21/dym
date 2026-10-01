# Quickstart — valider la mise en page adaptative

## Prérequis

Ceux de la spec 001 (`specs/001-dym-ui-design-system/quickstart.md`).

## Lancer la galerie

```bash
cd apps/dym_gallery
fvm flutter run -d chrome          # ou un téléphone / une tablette Android
```

## Scénarios de validation

| # | Action | Résultat attendu |
|---|---|---|
| 1 | Ouvrir un écran, choisir le format « Tablette », puis « Bureau » | L'écran est rendu à cette taille (réduit si besoin) ; grilles plus larges, contenu centré (US1, US2, US4) |
| 2 | Accueil en « Tablette » puis « Bureau » | Rail latéral, puis rail avec libellés à côté ; la barre basse reste en « Téléphone » (US3) |
| 3 | Panier en « Bureau » | Articles à gauche, livraison, paiement et « Payer » à droite (US2) |
| 4 | Rayon en « Téléphone paysage » | Aucun débordement, défilement normal (US1) |
| 5 | Chrome : redimensionner la fenêtre avec le format « Libre » | La disposition change de classe sans perdre les quantités du panier (cas limite) |
| 6 | Format autre que « Téléphone » | « Comparer » indisponible (US4) |

Captures sans lancer l'app : `specs/002-responsive-layout/validation/`.

## Contrôles automatiques

```bash
fvm dart run melos run analyze
fvm dart run melos run test        # dont la matrice 8 écrans × 7 tailles × 2 pays × 2 textes
cd apps/dym_gallery && fvm flutter test --tags golden   # 412×915 inchangé (SC-002), sans --update-goldens
```

## Résultats de validation (2026-10-01)

| Contrôle | Résultat |
|---|---|
| `melos run analyze` (`--fatal-infos`) | Aucun problème |
| `dym_ui` (tokens, classes de fenêtre, colonnes, bornes, rail, structure adaptative) | 55/55 |
| Galerie : matrice 8 écrans × 7 tailles × 2 pays × 2 textes (SC-001) | 224/224 sans débordement |
| Galerie : bornes sur bureau, colonnes, panier deux colonnes, navigation (SC-003, SC-004) | 16/16 |
| Galerie : sélecteur de format, « Comparer » réservé au téléphone (US4) | 3/3 |
| Goldens 412 × 915 de la spec 001 rejoués **sans** régénération (SC-002) | 8/8 identiques |
| Nouvelles captures tablette 800 × 1 280 et bureau 1 440 × 900 | 16/16 |
| `flutter build web --release` | Réussi |

Planches : [`validation/tablette-800x1280.jpg`](validation/tablette-800x1280.jpg),
[`validation/bureau-1440x900.jpg`](validation/bureau-1440x900.jpg).

Défaut trouvé et corrigé en chemin : dans la visionneuse, le cadre téléphone transmettait à l'écran
la taille de toute la fenêtre. Sur ordinateur, l'accueil affichait donc un rail dans un cadre de
412 px et débordait. Le cadre transmet désormais sa propre taille.
