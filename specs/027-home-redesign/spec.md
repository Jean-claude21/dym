# Feature Specification: Nouvel accueil

**Feature Branch**: `feat/027-home-redesign`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `home-redesign` de la roadmap (Phase 8, décision 0015) : accueil « Qu'est-ce qu'on
mange ? », fil personnel.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Une seule question en haut (Priority: P1)

L'accueil s'ouvre sur « Qu'est-ce qu'on mange ? » avec la recherche (texte, voix, photo) et,
quand il est actif, l'assistant qui compose le panier.

**Acceptance Scenarios**:

1. **Given** l'accueil, **When** il s'ouvre, **Then** la question et la recherche sont en haut,
   avant toute liste.

### User Story 2 - Recommander ses dernières courses (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une commande déjà livrée, **When** l'accueil s'ouvre, **Then** une carte propose de
   la recommander (boutique, nombre d'articles).
2. **Given** « Recommander », **When** elle touche le bouton, **Then** les articles encore
   disponibles vont au panier et le panier s'ouvre.
3. **Given** aucune commande livrée, **When** l'accueil s'ouvre, **Then** la carte n'apparaît pas.

### User Story 3 - Des produits, pas seulement des boutiques (Priority: P1)

**Acceptance Scenarios**:

1. **Given** des commandes récentes dans le quartier, **When** l'accueil s'ouvre, **Then** « Les
   plus demandés près de toi » montre les produits les plus commandés depuis 30 jours, disponibles
   et livrés dans le quartier.
2. **Given** des produits publiés depuis 14 jours, **When** l'accueil s'ouvre, **Then**
   « Nouveautés » les montre.
3. **Given** une section vide, **When** l'accueil s'ouvre, **Then** elle n'apparaît pas.

### Edge Cases

- Visiteuse sans compte : pas de carte « Recommander », le reste est visible.
- Échec du fil personnel : l'accueil reste utilisable (boutiques, rayons).

## Requirements *(mandatory)*

- **FR-001**: Le fil DOIT être calculé par le serveur, pour le quartier choisi.
- **FR-002**: Seuls les produits publiés, disponibles, de boutiques actives qui livrent le
  quartier DOIVENT apparaître.
- **FR-003**: La dernière commande livrée DOIT être celle de la personne connectée uniquement.
- **FR-004**: Un échec du fil NE DOIT PAS empêcher l'affichage des boutiques et rayons.
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Recommander ses dernières courses depuis l'accueil en deux gestes (Recommander,
  Commander).
- **SC-002**: L'accueil montre des produits dès l'ouverture quand le quartier a de l'activité.

## Assumptions

- « Mes espaces » s'ajoutera à l'accueil avec la spec `spaces` (phase 9) ; les promos avec
  `memberships` (phase 13).
