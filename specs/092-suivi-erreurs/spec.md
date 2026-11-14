# Feature Specification: Suivi des erreurs attrapées

**Feature Branch**: `feat/092-suivi-erreurs`

**Created**: 2026-11-14

**Status**: Done

**Input**: Demande du porteur (2026-11-14) pendant les essais : « j'espère que tu utilises bien
[le suivi] des erreurs ». Constat : seules les erreurs non gérées partaient à Sentry ; les erreurs
du serveur attrapées par les clients (affichées à l'écran) n'étaient jamais signalées.
Constitution IX (erreurs des apps et des Functions remontées).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Voir les bugs des testeurs sans qu'ils les décrivent (Priority: P1)

Quand une app reçoit une erreur du serveur (5xx), une réponse illisible ou une erreur inconnue,
l'équipe la voit dans Sentry, regroupée par lieu (`rpc/<fonction>`, `functions:POST <chemin>`,
`auth`), avec le type d'échec, sans donnée personnelle.

**Acceptance**: un 500 sur une fonction SQL est signalé avec son nom ; un 400, un 403, l'absence de
réseau ne le sont pas ; un échec du suivi ne casse jamais l'app.

## Requirements *(mandatory)*

- **FR-001**: `FailureReports` (dym_core) : destination branchée au démarrage, filtre des échecs
  inattendus (`ServerFailure`, `UnknownFailure`), identifiants retirés du lieu.
- **FR-002**: clients neon_kit (Data API, Functions, Auth) : signalement à chaque échec converti.
- **FR-003**: `runWithErrorReporting` branche la destination vers Sentry (tags `where`, `failure`).

## Success Criteria

- Tests dym_core et neon_kit verts ; évènement de vérification reçu dans les quatre projets Sentry
  des apps (puis résolu).
