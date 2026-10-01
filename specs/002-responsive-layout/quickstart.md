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
