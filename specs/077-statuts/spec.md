# Feature Specification: Statuts au premier plan

**Feature Branch**: `feat/077-statuts`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Point 5 de la liste validée par le porteur (2026-11-13) : statuts créés en peu de gestes,
vocabulaire « statut », partage WhatsApp avec lien qui ouvre le contenu. Features V-CNT-01..03,
C-HOME-07.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Publier un statut depuis l'accueil (Priority: P1)

« Publier un statut » sur l'accueil de la vendeuse ouvre directement l'écran de publication (photo,
vidéo ou texte, produits tagués).

### User Story 2 - Un seul mot : « statut » (Priority: P1)

L'app dit « Statut 24 h », « Publier le statut », « Statuts des boutiques », « Mes statuts et vidéos ».

### User Story 3 - Partager sur WhatsApp (Priority: P1)

Le bouton « Partager » (fil, créatrice, et maintenant le lecteur de statuts) ouvre WhatsApp avec le
texte et le lien court ; sans WhatsApp, le texte est copié.

## Requirements *(mandatory)*

- **FR-001**: raccourci affiché seulement si les contenus sont actifs (flag).
- **FR-002**: lien court existant (spec 040) ; aucune donnée personnelle dans l'URL.

## Success Criteria *(mandatory)*

- **SC-001**: tests (raccourci, partage WhatsApp puis copie) ; analyse.
