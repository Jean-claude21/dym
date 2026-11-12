# Feature Specification: Flux vidéo « Cuisine »

**Feature Branch**: `feat/057-cuisine-video-feed`

**Created**: 2026-11-11

**Status**: Draft

**Input**: Spec `cuisine-video-feed` de la roadmap (Phase 14). Planche
[02](../../docs/design/screens/epure/02-cliente-cuisine-flux-video.webp) et
[PARCOURS.md](../../docs/design/PARCOURS.md) §4.1 (Cuisine) et parcours de Kossi. Features C-37
(fil shoppable), C-38 (tout pour la recette), C-39 (contenu rémunéré).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Faire défiler (Priority: P1)

1. **Given** l'onglet Cuisine, **Then** les vidéos défilent en plein écran ; en haut « Pour toi ·
   Abonnements » et la grille ; à droite l'autrice avec « + » pour s'abonner, j'aime (compteur court),
   commentaires, partager, signaler ; en bas l'autrice « · Créatrice », « Contenu rémunéré », la
   légende, deux vignettes de produits et « +N ».
2. **Given** la lecture, **Then** la barre de navigation est sombre ; partout ailleurs elle reste claire.

### User Story 2 - Voir les produits sans quitter la vidéo (Priority: P1)

1. **Given** une vignette touchée, **Then** la feuille « Dans cette vidéo · N produits » s'ouvre
   par-dessus la vidéo : photo, nom, unité et boutique, prix, « + ».
2. **Given** une recette, **Then** « Tout pour la recette · total » (total chiffré par la base).

### User Story 3 - Quantités pour N personnes (Priority: P1)

1. **Given** la feuille de recette, **Then** « Pour N personnes » avec − et + ; chaque changement
   redemande le panier à la base, qui recalcule les quantités des ingrédients (arrondi au-dessus, au
   moins 1) ; les ustensiles et produits tagués restent à 1.
2. **Given** les articles cochés, **When** « Ajouter N articles · total », **Then** ils vont au panier,
   la feuille se ferme, la vidéo reste, et « N articles ajoutés au panier · Voir » s'affiche.

### Edge Cases

- Portions hors de 1 à 50 : refusées par la base (`invalid_servings`).
- Articles décochés : le bouton dit « Ajouter N articles » sans total (aucun montant calculé dans l'app).
- Ingrédient introuvable : nommé sous la liste.
- Texte à 130 %, petit écran, paysage : rien ne déborde.

## Requirements *(mandatory)*

- **FR-001**: Les quantités pour N personnes sont calculées en SQL (`recipe_basket`, migration 0064).
- **FR-002**: Aucun dégradé ni voile : textes et icônes ombrés sur la vidéo.
- **FR-003**: L'événement `recipe_basket_built` porte les portions ; les ajouts restent tracés
  (`recipeAdded`).
- **FR-004**: Aucun texte en dur.

## Success Criteria *(mandatory)*

- **SC-001**: Les quatre étapes de la planche 02 capturées et conformes.
- **SC-002**: pgTAP 530, tests Flutter (dont le parcours recette pour N), analyse : verts.

## Assumptions

- Portions de référence : 4 par défaut pour chaque contenu ; l'autrice pourra les régler dans une
  spec du studio créatrice.
- L'onglet « Marché » du haut de la planche n'est pas construit : le fil n'a pas de filtre par source.
  Les catégories restent en puces.
- Le préchargement d'une seule vidéo et la qualité selon le réseau relèvent de `field-performance`.
