# Quickstart — valider dym_ui

## Prérequis

- FVM 4 (`dart pub global activate fvm`), Melos 8 (`dart pub global activate melos`)
- Android avec débogage USB ou Chrome

## Installation

```bash
fvm install            # installe Flutter 3.47.5 depuis .fvmrc
melos bootstrap        # résout le workspace avec le SDK FVM (sdkPath)
melos run tokens       # régénère le thème depuis docs/design/tokens/dym.tokens.json
```

## Lancer la galerie

```bash
cd apps/dym_gallery
fvm flutter run -d chrome          # ou -d <id de l'appareil Android>
```

Résultat attendu : écran d'accueil de la galerie avec « Écrans validés », « Catalogue » et le
sélecteur Togo / Ghana ; bandeau « Données de démonstration ».

## Scénarios de validation

| # | Action | Résultat attendu |
|---|---|---|
| 1 | Ouvrir chacun des 8 écrans, toucher « Comparer » | L'image validée se superpose ; les écarts sont visibles avec le curseur d'opacité (US1) |
| 2 | Rayon : toucher « + » sur « Gombo frais » | Le bouton devient « − 1 + », le mini-panier se met à jour avec animation (US2) |
| 3 | Ouvrir Suivi | Le zem avance sur l'itinéraire (US2) |
| 4 | Ouvrir Commande reçue | L'icône centrale pulse (US2) |
| 5 | Activer « réduire les animations » sur le téléphone | Les écrans apparaissent directement dans leur état final |
| 6 | Basculer sur Ghana, ouvrir Panier | Tous les montants en cedis, 2 décimales, ville du Ghana (US3) |
| 7 | Ouvrir Catalogue › Couleurs | Chaque couleur avec son ratio de contraste (US4) |

## Contrôles automatiques

```bash
melos run analyze      # aucune erreur
melos run test         # unitaires et widget
melos run golden       # régénère les captures 360×800 des 8 écrans (machine de dev)
```

Les captures golden sont écrites dans `apps/dym_gallery/test/golden/goldens/` pour comparaison avec
`docs/design/screens/`.
