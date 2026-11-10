# Feature Specification: Créateurs et contenus de tous

**Feature Branch**: `feat/036-creators-content`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `creators-content` de la roadmap (Phase 10, VISION §3 « Contenus ») : profil
créateur, posts de tous (photo, vidéo), catégorie choisie ou classée par l'IA, sinon « Autre »,
avec ou sans produits tagués, modération.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Devenir créatrice (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une cliente, **When** elle choisit un nom de créatrice (et une courte bio), **Then**
   elle obtient le rôle créateur et un profil public, sans ouvrir de boutique.

### User Story 2 - Publier un post (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une créatrice, **When** elle publie une photo ou une vidéo (60 s) avec une légende,
   **Then** le post apparaît dans le fil, à son nom.
2. **Given** une catégorie choisie (recettes, astuces, marché, ustensiles…), **When** elle publie,
   **Then** elle est gardée ; sans choix, l'IA propose une catégorie à partir de la légende, sinon
   « Autre ».
3. **Given** des produits en vente (de n'importe quelle boutique), **When** elle les tague (5 au
   plus), **Then** ils s'affichent sur le post, achetables d'un geste ; un post peut n'en avoir
   aucun.

### User Story 3 - Gérer et modérer (Priority: P2)

**Acceptance Scenarios**:

1. **Given** ses posts, **When** elle les ouvre, **Then** elle voit vues, clics et signalements,
   archive ou supprime.
2. **Given** un post signalé, **When** l'équipe modère, **Then** il est gardé ou retiré (file de
   modération existante).

### Edge Cases

- Média hors du dossier de la créatrice : refusé. Catégorie inconnue : refusée.
- Produit tagué plus en vente : masqué du post.
- Compte supprimé : posts supprimés avec lui.

## Requirements *(mandatory)*

- **FR-001**: Catégories DOIVENT être des données de référence (réglables), « Autre » par défaut.
- **FR-002**: La provenance de la catégorie (choisie, IA, défaut) DOIT être gardée.
- **FR-003**: L'IA ne propose qu'une catégorie existante ; jamais bloquante.
- **FR-004**: Événements serveur : `creator_joined`, `content_published` (type, catégorie,
  provenance, produits tagués).
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une cliente publie sa première recette taguée en moins de 2 minutes.
- **SC-002**: Aucun post publié dans le dossier d'une autre personne (pgTAP).

## Assumptions

- Classement du fil, abonnements et commentaires : spec `feed-ranking`.
- Commissions des créatrices : spec `affiliation`.
