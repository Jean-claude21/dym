# Feature Specification: Pont TikTok

**Feature Branch**: `feat/040-tiktok-bridge`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `tiktok-bridge` de la roadmap (Phase 10, VISION §3 « Lien avec TikTok dans les deux
sens ») : import par le créateur, partage vers TikTok avec lien de panier.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Importer sa vidéo TikTok (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une créatrice, **When** elle relie son compte TikTok (déclaré) et colle le lien d'une
   de ses vidéos, **Then** DYM reprend la légende et la couverture (ou lui fait choisir une photo si
   TikTok n'en donne pas), elle ajoute les ingrédients et publie ; le post garde « Voir sur TikTok ».
2. **Given** la vidéo d'un autre compte, une vidéo privée ou un lien hors TikTok, **Then** l'import
   est refusé avec un message clair.
3. **Given** le compte seulement déclaré, **Then** l'écran le signale : la vérification par la
   connexion TikTok viendra quand l'accès sera ouvert (décision 0015).

### User Story 2 - Partager vers TikTok avec le lien du panier (Priority: P1)

**Acceptance Scenarios**:

1. **Given** un post (studio ou fil), **When** on touche « Partager », **Then** un lien court est
   créé (le même à chaque fois pour la même personne) et copié avec la légende, prêt à coller dans
   la vidéo TikTok.
2. **Given** une personne qui ouvre le lien, **Then** une page légère montre le contenu et ouvre
   l'app web ; après connexion ou inscription, « Tout pour la faire » s'ouvre, et la créatrice
   touche sa commission (spec 039).

### Edge Cases

- Lien inconnu ou contenu retiré : page « Ce lien n'existe plus » (404).
- Lien court `vm.tiktok.com` : l'adresse finale donne le compte.
- Ouverture sans compte : comptée, sans donnée personnelle.

## Requirements *(mandatory)*

- **FR-001**: La lecture de TikTok DOIT passer par une interface (`VideoImportProvider`) ; la
  connexion TikTok (Login Kit) la remplacera sans changer l'app.
- **FR-002**: Seule l'autrice DOIT pouvoir marquer son post comme importé ; un compte déclaré est
  exigé ; le lien d'origine DOIT être une adresse TikTok.
- **FR-003**: Les liens courts DOIVENT être créés et lus en base ; leur ouverture DOIT être comptée.
- **FR-004**: Événements serveur : `tiktok_imported`, `share_link_created`, `share_link_opened`.
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une créatrice publie sa vidéo TikTok sur DYM en moins d'une minute.
- **SC-002**: Un lien partagé ouvre « Tout pour la faire » en un geste après connexion.

## Assumptions

- Le dépôt d'une vidéo directement dans TikTok (Share Kit) demande l'accès développeur TikTok : le
  partage se fait par lien copié jusque-là.
- Les liens ouvrent l'app web (première origine autorisée) ; les liens d'app mobile arriveront avec
  les deep links du site léger.
