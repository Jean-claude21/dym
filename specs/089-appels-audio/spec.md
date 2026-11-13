# Feature Specification: Appels audio seulement, validés sur deux téléphones

**Feature Branch**: `feat/089-appels-audio`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Demande du porteur (2026-11-13) : « On peut enlever vidéo d'abord » ; valider les appels
et l'audio entre deux émulateurs. Features C-CHAT-03, V-CHAT-03.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Appeler, seulement en audio (Priority: P1)

Dans la conversation, seul « Appeler » est proposé ; la vidéo revient quand le flag `calls_video`
est ouvert (pays ou global). La base refuse un appel vidéo tant qu'il est fermé.

### User Story 2 - S'entendre (Priority: P1)

La cliente appelle depuis un téléphone, la vendeuse décroche sur un autre : les deux rejoignent la
salle LiveKit, chacune publie sa voix et reçoit celle de l'autre.

## Requirements *(mandatory)*

- **FR-001**: flag `calls_video` (coupé) ; `start_call` refuse `video` (`video_disabled`).
- **FR-002**: bouton vidéo du chat affiché seulement si le flag est ouvert.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 730 ; essai sur deux émulateurs : deux participants, pistes audio publiées et
  reçues des deux côtés.
