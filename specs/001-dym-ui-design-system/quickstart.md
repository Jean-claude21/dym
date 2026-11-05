# Quickstart — valider dym_ui

## Prérequis

- FVM 4 (`dart pub global activate fvm`). Melos est une dépendance du workspace.
- Android avec débogage USB ou Chrome

## Installation

```bash
fvm install                       # installe Flutter 3.47.5 depuis .fvmrc
fvm flutter pub get
fvm dart run melos bootstrap      # résout le workspace avec le SDK FVM (sdkPath)
fvm dart run melos run tokens     # régénère le thème depuis docs/design/tokens/dym.tokens.json
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
fvm dart run melos run analyze    # aucune erreur
fvm dart run melos run test       # widget et robustesse (360×640, texte 130 %)
fvm dart run melos run test:dart  # dym_core
fvm dart run melos run golden     # captures 412×915 des 8 écrans (machine de dev)
```

Les captures golden sont écrites dans `apps/dym_gallery/test/golden/goldens/` pour comparaison avec
`docs/design/screens/`.

## Résultats de validation (2026-10-02)

| Contrôle | Résultat |
|---|---|
| `melos run analyze` (very_good_analysis, `--fatal-infos`) | Aucun problème |
| `dym_core` (`dart test`) | 9/9 |
| `dym_ui` (tokens, contrastes, composants, animations, cas limites) | 35/35 |
| Galerie : robustesse 8 écrans × 2 pays en 360 × 640, texte 130 % | 16/16 sans débordement |
| Galerie : bascule Togo/Ghana, total panier = montant au suivi | 3/3 |
| Captures golden 412 × 915 des 8 écrans | 8/8, comparaisons dans [`validation/`](validation/) |
| `flutter build web --release` de la galerie | Réussi |
| Fluidité sur Android d'entrée de gamme en mode profile (T066) | **À faire** : aucun appareil branché |

Planches de comparaison référence / rendu : [`validation/compare-01.jpg`](validation/compare-01.jpg) à
[`compare-08.jpg`](validation/compare-08.jpg) ; vue d'ensemble : [`validation/apercu-dym_ui.jpg`](validation/apercu-dym_ui.jpg).

Écarts assumés par rapport aux écrans de référence (rendus IA) :

- Le compteur d'une carte produit s'affiche sur sa propre ligne : la référence le place à côté du
  prix avec des boutons trop petits pour la règle des 48 dp.
- Le panier compte les unités (« 6 articles ») ; la référence comptait les lignes (« 4 articles »).
- Couleur de marque passée au vert profond `#0B5D3F` (décision 0011).
