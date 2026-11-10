# Feature Specification: Tout pour la faire

**Feature Branch**: `feat/038-recipe-to-cart`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `recipe-to-cart` de la roadmap (Phase 10, VISION §3, décision 0015) : « Tout pour la
faire », rayon ustensiles, ingrédients génériques reliés aux vendeuses.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Les ingrédients d'une recette (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une créatrice qui publie une recette, **When** elle liste les ingrédients (à la main
   ou repérés par l'IA dans sa légende), **Then** ils sont gardés avec le post, sans produit
   précis : « tomate », « gombo », « huile rouge ».

### User Story 2 - « Tout pour la faire » (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une recette avec des ingrédients et des produits tagués, **When** une cliente touche
   « Tout pour la faire », **Then** le serveur compose le panier : les produits tagués, et chaque
   ingrédient chez la meilleure vendeuse qui livre son quartier (règles de la spec 028), chiffré,
   avec ce qui manque ; elle retire ce qu'elle veut et ajoute au panier.

### User Story 3 - Rayon ustensiles (Priority: P2)

**Acceptance Scenarios**:

1. **Given** le référentiel, **When** une vendeuse publie une marmite, **Then** elle la range dans
   « Ustensiles », rayon visible des clientes ; une créatrice la tague sur sa recette.
2. **Given** les rayons hors grocery (pagnes, beauté, hygiène), **When** le référentiel est mis à
   jour, **Then** ils ne sont plus proposés (décision 0015) ; les produits existants restent.

### Edge Cases

- Aucun ingrédient ni produit : bouton masqué.
- Ingrédient introuvable dans le quartier : nommé comme manquant.
- 15 ingrédients au plus, quantités 1 à 10.

## Requirements *(mandatory)*

- **FR-001**: La composition DOIT être faite en base (choix, prix) ; l'IA ne propose que des
  ingrédients, jamais un prix ni une boutique.
- **FR-002**: Seule l'autrice DOIT pouvoir fixer les ingrédients de son post.
- **FR-003**: Événements serveur : `recipe_basket_built` (articles, manquants).
- **FR-004**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une cliente passe d'une recette à un panier complet en 2 gestes.

## Assumptions

- Commission de la créatrice sur ces achats : spec `affiliation`.
