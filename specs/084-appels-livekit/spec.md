# Feature Specification: Appels réels dans le chat (LiveKit)

**Feature Branch**: `feat/084-appels-livekit`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Choix du porteur (2026-11-13) : appels du chat par internet avec LiveKit, numéro caché,
historique en base sans enregistrement. Features C-CHAT-03, V-CHAT-03 (appels audio et vidéo de la
spec 035, jusque-là simulés).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Appeler la boutique depuis la conversation (Priority: P1)

La cliente touche « Appeler » (audio ou vidéo) ; la vendeuse décroche ; elles se parlent pour de
vrai, sans voir le numéro de l'autre. Pendant l'appel : « Micro ouvert / coupé », « Haut-parleur /
Écouteur », raccrocher ; en vidéo, l'autre en plein écran et soi en vignette.

### User Story 2 - Réseau faible (Priority: P2)

Voix à faible débit, vidéo 360p adaptée ; si le média ne se connecte pas : « Son indisponible :
vérifie ta connexion, puis rappelle », l'appel reste ouvert et peut être raccroché.

### Edge Cases

- Flag `calls_livekit` coupé (ou projet LiveKit absent) : appel simulé, signalé comme avant.
- Personne hors de la conversation, appel non décroché ou terminé : aucun jeton.

## Requirements *(mandatory)*

- **FR-001**: fournisseur fixé par la base à la création (`calls.provider` : `livekit` ou
  `simulated`), flag `calls_livekit` global ou par pays.
- **FR-002**: `app.call_media_access` décide de l'accès ; la Function `POST /v1/calls/:id/media`
  émet un jeton LiveKit (10 min, une salle) ; aucun secret dans les apps.
- **FR-003**: `LiveKitCallProvider` (dym_platform) ; textes par `dym_l10n`.
- **FR-004**: événement `call_started` avec le fournisseur.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 680 ; tests de la Function et du viewmodel ; jeton reçu et salle LiveKit
  rejointe depuis l'app sur staging.
