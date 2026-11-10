# Feature Specification: Fil classé, abonnements et commentaires

**Feature Branch**: `feat/037-feed-ranking`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `feed-ranking` de la roadmap (Phase 10, VISION §3 « Contenus ») : lecture haut de
gamme, vues flexibles, algorithme de valorisation, abonnements, commentaires.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Un fil qui valorise les bons contenus (Priority: P1)

**Acceptance Scenarios**:

1. **Given** des contenus récents, populaires, suivis, locaux ou shoppables, **When** la cliente
   ouvre « Pour toi », **Then** ils sont classés par un score réglable par pays (fraîcheur,
   engagement, abonnement, proximité, affinité de catégorie, produits tagués) ; rien n'est
   calculé dans l'app.
2. **Given** des catégories, **When** elle en choisit une, **Then** le fil ne montre qu'elle.
3. **Given** le fil, **When** elle bascule en grille, **Then** elle parcourt les vignettes et
   rouvre le défilement plein écran sur celle touchée.

### User Story 2 - S'abonner (Priority: P1)

**Acceptance Scenarios**:

1. **Given** un contenu, **When** elle s'abonne à sa créatrice ou à sa boutique, **Then**
   « Abonnements » montre ses contenus, et ils remontent dans « Pour toi ».
2. **Given** un abonnement, **When** elle se désabonne, **Then** c'est immédiat.

### User Story 3 - Commenter (Priority: P2)

**Acceptance Scenarios**:

1. **Given** un contenu, **When** elle commente (300 caractères), **Then** le commentaire
   s'affiche pour tous ; elle peut supprimer le sien.
2. **Given** un commentaire abusif, **When** il est signalé puis retiré par l'équipe, **Then** il
   disparaît.

### Edge Cases

- Fil vide (aucun abonnement) : message et retour à « Pour toi ».
- Double envoi d'un commentaire (même clé) : un seul.
- Poids nuls : classement par date.

## Requirements *(mandatory)*

- **FR-001**: Le score DOIT être calculé en SQL avec des poids en données de référence par pays.
- **FR-002**: Abonnements et commentaires DOIVENT s'écrire par fonctions ; modération par la file.
- **FR-003**: Événements serveur : `follow_added` (cible), `comment_added`.
- **FR-004**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Un contenu suivi et engageant passe devant un contenu ancien sans interaction.
- **SC-002**: Un commentaire retiré n'est plus visible (pgTAP).

## Assumptions

- Réglage des poids depuis l'admin : fonction prête ; écran avec le centre d'opérations (phase 13).
