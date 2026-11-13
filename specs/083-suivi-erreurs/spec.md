# Feature Specification: Suivi des erreurs (Sentry)

**Feature Branch**: `feat/083-suivi-erreurs`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Préparation de la production (constitution IX) : le porteur a ouvert Sentry
(organisation `dym-mq`, région Europe) et fourni un jeton (2026-11-13).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Voir les erreurs avant les utilisateurs (Priority: P1)

Une erreur d'une app (cliente, vendeuse, livreur, admin) ou d'une Function (5xx) arrive dans le
projet Sentry correspondant, sans donnée personnelle (route et type seulement côté serveur).

### Edge Cases

- DSN absent : rien n'est envoyé, rien ne casse.
- Envoi raté : jamais propagé à l'utilisateur.

## Requirements *(mandatory)*

- **FR-001**: cinq projets Sentry (`dym-client`, `dym-vendor`, `dym-delivery`, `dym-admin`,
  `dym-functions`) ; DSN hors dépôt.
- **FR-002**: `ERROR_REPORTING_DSN` transmis au déploiement des Functions (`neon.ts`) ; il ne
  l'était pas, la clé était ignorée en ligne.
- **FR-003**: les apps de test sont compilées avec `DYM_ERROR_DSN` de leur projet.

## Success Criteria *(mandatory)*

- **SC-001**: événement de vérification reçu par `dym-functions` ; Functions déployées sur staging
  avec le DSN.
