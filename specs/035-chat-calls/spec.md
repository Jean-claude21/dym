# Feature Specification: Vocaux et appels

**Feature Branch**: `feat/035-chat-calls`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `chat-calls` de la roadmap (Phase 9, VISION §3) : vocaux, médias, appel audio et
vidéo « Montre-moi ». Le livreur dans la conversation vient avec l'app livreur (phase 11).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Messages vocaux (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une conversation, **When** la cliente ou la vendeuse enregistre un vocal (60 s au
   plus), **Then** il est envoyé et l'autre partie l'écoute.
2. **Given** une personne extérieure, **When** elle tente de l'écouter, **Then** c'est refusé.

### User Story 2 - Appel audio ou vidéo « Montre-moi » (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une conversation, **When** une partie appelle (audio ou vidéo), **Then** l'autre est
   prévenue et peut décrocher ou refuser.
2. **Given** un appel décroché, **When** l'une raccroche, **Then** l'appel se termine et un
   résumé (durée) apparaît dans la conversation ; sans réponse en 60 s : appel manqué.
3. **Given** le fournisseur média indisponible, **When** on appelle, **Then** l'appel est simulé
   et **signalé à l'écran** (décision 0015) ; le vrai fournisseur (WebRTC) remplace la simulation
   avant la production finale, derrière la même interface.

### Edge Cases

- Un seul appel actif par conversation.
- Flag pays `calls_simulated` coupé : appels refusés (`feature_disabled`).
- Vocal vide ou trop long : refusé.

## Requirements *(mandatory)*

- **FR-001**: États d'appel et durées DOIVENT être tenus en base (rôle vérifié).
- **FR-002**: Les médias DOIVENT rester privés (liens signés courts, participantes seulement).
- **FR-003**: Le média de l'appel DOIT passer par une interface `CallProvider`.
- **FR-004**: Événements serveur : `call_started` (type), `call_ended` (durée, issue),
  `voice_message_sent` (durée).
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une cliente montre le produit à distance avant de payer (appel vidéo).
- **SC-002**: Aucun vocal lisible hors de la conversation (pgTAP).

## Assumptions

- Le livreur rejoint la conversation avec la phase 11.
- Le fournisseur média réel (WebRTC, serveur TURN) est une démarche avant la production finale.
