# Feature Specification: Carnet, favoris et paniers enregistrés

**Feature Branch**: `feat/030-address-book-favorites`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `address-book-favorites` de la roadmap (Phase 9, décision 0015, VISION §3) :
carnet (adresses, boutiques et produits favoris), paniers enregistrés (petit-déjeuner, déjeuner,
mois) à recommander en un geste.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Boutiques et produits favoris (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une boutique ou un produit, **When** la cliente touche le cœur, **Then** il entre
   dans ses favoris ; un second geste l'en retire.
2. **Given** des favoris, **When** elle ouvre « Mes favoris », **Then** elle voit ses boutiques
   (ouvertes ou non) et ses produits encore en vente, et les ouvre d'un geste.
3. **Given** une autre personne, **When** elle consulte les favoris, **Then** elle ne voit que les
   siens.

### User Story 2 - Paniers enregistrés (Priority: P1)

**Acceptance Scenarios**:

1. **Given** un panier rempli, **When** elle l'enregistre sous un nom libre (« Petit-déjeuner »),
   **Then** il est gardé tel quel (articles et quantités).
2. **Given** un panier enregistré, **When** elle touche « Remettre au panier », **Then** les
   articles encore disponibles sont ajoutés aux règles du panier et ceux qui ne le sont plus sont
   nommés ; le prix est celui du jour, calculé par le serveur.
3. **Given** un panier enregistré, **When** elle le renomme ou le supprime, **Then** le
   changement est gardé.

### User Story 3 - Carnet d'adresses (Priority: P2)

Déjà livré (spec 009, « Mes adresses ») ; inchangé, accessible depuis « Moi ».

### Edge Cases

- Boutique suspendue ou fermée définitivement, produit archivé : absent des favoris affichés,
  gardé en base (réapparaît s'il revient).
- Panier vide : enregistrement refusé. Plus de 20 paniers : refusé.
- Article d'un autre pays que le panier en cours : nommé comme non ajouté.

## Requirements *(mandatory)*

- **FR-001**: Favoris et paniers DOIVENT appartenir à une seule personne (RLS) et s'écrire par
  fonctions.
- **FR-002**: Un panier enregistré contient au plus 50 lignes ; 20 paniers par personne ; nom 1 à
  40 caractères ; 200 favoris de chaque sorte.
- **FR-003**: Les prix affichés et l'ajout au panier DOIVENT venir du serveur (règles de
  `cart_add`).
- **FR-004**: Événements serveur : `favorite_added` (type), `basket_saved` (lignes),
  `basket_reordered` (ajoutés, non ajoutés). Aucune donnée personnelle.
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Refaire un panier habituel en 2 gestes depuis « Moi » ou le panier.
- **SC-002**: Aucun favori ni panier visible par une autre personne (pgTAP).

## Assumptions

- Les adresses pour un proche et les paniers partagés viennent avec `spaces`.
- Les listes de besoins (résolues au meilleur marchand) sont celles de la spec 029 ; ici, un panier
  enregistré garde les articles exacts.
