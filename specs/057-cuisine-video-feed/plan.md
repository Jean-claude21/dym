# Implementation Plan: Flux vidéo « Cuisine »

**Branch**: `feat/057-cuisine-video-feed` | **Date**: 2026-11-11 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| II. Valider avant de construire | Planche 02 validée le 2026-11-11 | OK |
| III. Postgres source de vérité | Quantités pour N personnes en SQL ; aucun total calculé dans l'app | OK |
| V. Sécurité | `recipe_basket` recréée avec les mêmes droits (authenticated) ; pgTAP 530 | OK (relecture humaine : migration) |
| VI. Couches | Feuilles dans l'app (feature content) ; dépôt `dym_data` passe `p_servings` | OK |
| VIII. Terrain | 48 px, texte à 130 %, barre sombre seulement en lecture | OK |
| IX. Mesurer | `recipe_basket_built` avec `servings` | OK |

## Décisions

- Migration `0064_recipe_servings.sql` : `contents.servings` (4 par défaut, 1 à 50) ;
  `recipe_basket(p_content, p_zone, p_servings)` ; réponse avec `servings` et `base_servings`.
- `CopilotProposal.servings/baseServings` ; `ContentRepository.recipeBasket(servings:)` ;
  `ContentService.recipeBasket(content, servings:)`.
- `recipe_sheets.dart` : `showVideoProducts` (rail, ajout, « Tout pour la recette ») et
  `showRecipeSheet` (portions, cases, ajout au panier).
- `FeedView` : en-tête texte, puces sombres, colonne d'actions, autrice et mention, vignettes de
  produits, message « ajouté · Voir » effacé seul ; `onRecipe` retiré (la recette ne quitte plus la
  vidéo ; le lien partagé ouvre toujours la page recette).
- `DymBottomNav.dark` et `DymAdaptiveScaffold.darkBottomNav` ; mini-panier par-dessus la vidéo.
- `compactCount` (dym_core) pour les compteurs.

## Vérification

- pgTAP `530_recipe_servings.sql` ; `content_test.dart` (ajout, recette pour 5) ; captures
  `test/capture/cuisine_capture_test.dart`.
