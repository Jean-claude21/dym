# Feature Specification: Finition haut de gamme

**Feature Branch**: `feat/026-premium-foundation`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `premium-foundation` de la roadmap (Phase 8, décision 0015) : squelettes, cache
d'images, animations, accès au panier, commande en un écran.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - L'app paraît instantanée (Priority: P1)

Pendant un chargement, la cliente voit la forme de l'écran qui arrive, pas un cercle qui tourne ;
les photos déjà vues s'affichent tout de suite, même en 3G.

**Independent Test**: ouvrir l'accueil, une boutique, puis y revenir hors ligne.

**Acceptance Scenarios**:

1. **Given** un écran qui charge, **When** il s'ouvre, **Then** un squelette aux formes de l'écran
   s'affiche, sans animation si la personne a désactivé les animations.
2. **Given** une photo déjà affichée, **When** l'écran est rouvert, **Then** elle vient du cache de
   l'appareil, sans nouveau téléchargement.

### User Story 2 - Le panier est toujours à portée (Priority: P1)

**Acceptance Scenarios**:

1. **Given** l'accueil, **When** le panier contient des articles, **Then** un bouton panier affiche
   leur nombre et l'ouvre en un geste.
2. **Given** un ajout au panier, **When** il réussit, **Then** le compteur s'anime et l'appareil
   vibre légèrement (si le système le permet).

### User Story 3 - Commander depuis le panier, sans détour (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une adresse par défaut, **When** la cliente ouvre son panier, **Then** l'adresse de
   livraison y est affichée et « Commander » suffit.
2. **Given** aucune adresse, **When** une livraison est prévue, **Then** la ligne « Livraison »
   invite à ajouter une adresse.
3. **Given** une commande réussie, **When** la confirmation s'affiche, **Then** un retour haptique
   la souligne.

### Edge Cases

- Animations désactivées par le système : aucun mouvement, squelettes statiques.
- Photo absente du cache et réseau coupé : l'illustration de repli s'affiche.

## Requirements *(mandatory)*

- **FR-001**: Toute photo distante DOIT passer par un cache sur l'appareil (trois apps).
- **FR-002**: Les chargements d'écran DOIVENT afficher un squelette, statique si les animations
  sont désactivées.
- **FR-003**: L'accueil DOIT offrir un accès direct au panier avec le nombre d'articles.
- **FR-004**: Le panier DOIT afficher l'adresse de livraison choisie, ou inviter à en ajouter une.
- **FR-005**: L'ajout au panier et la commande réussie DOIVENT donner un retour haptique léger.
- **FR-006**: Tout nouveau texte DOIT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Avec une adresse par défaut, une commande se passe depuis le panier en un seul geste.
- **SC-002**: 0 cercle de chargement sur les écrans de découverte, de panier et de wallet.
- **SC-003**: Une photo revue ne déclenche aucune requête réseau.

## Assumptions

- 5 onglets restent la limite sur téléphone : le panier passe par un bouton d'en-tête et la barre
  de mini-panier, pas par un 6e onglet ; les Vidéos gardent leur onglet.
- Sur le web, le cache est celui du navigateur.
