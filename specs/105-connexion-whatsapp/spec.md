# Feature Specification: Connexion WhatsApp

**Feature Branch**: `feat/105-connexion-whatsapp`

**Created**: 2026-11-17

**Status**: Done (simulé jusqu'au compte Meta)

**Input**: Décision du porteur (2026-11-17) : tout implémenter, les clés viendront ensuite.

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** « Continuer avec WhatsApp » : indicatif et numéro, code à 6 chiffres reçu par
  WhatsApp, session ouverte ; un nouveau numéro crée un compte, le même numéro rouvre toujours le
  même compte.
- **US2 (P1)** Sécurité : code haché, 10 minutes, 5 essais, 3 envois par 10 minutes ; le numéro
  n'est montré à personne.
- **US3 (P2)** Sans compte Meta (staging) : mode simulé, le code s'affiche avec la mention
  « Code simulé (WhatsApp pas encore branché) ». Jamais en production.

## Requirements *(mandatory)*

- **FR-001** Migration 0097 : `phone_identities`, `phone_login_codes`, `app.phone_code_issue`,
  `app.phone_code_check`.
- **FR-002** Functions : `GET /v1/auth/whatsapp`, `POST /v1/auth/whatsapp/start`,
  `POST /v1/auth/whatsapp/verify` ; envoi par le modèle d'authentification de la WhatsApp Cloud API ;
  session par le pont de la spec 102.
- **FR-003** `neon_kit`, `dym_auth` (`WhatsAppSignIn`, étape numéro), apps cliente, vendeuse, livreur.

## À fournir par le porteur

Compte Meta Business vérifié, numéro dédié, modèle d'authentification « dym_code » (français)
approuvé ; puis `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID` (et `WHATSAPP_TEMPLATE`,
`WHATSAPP_TEMPLATE_LANG` si autres) dans Doppler `dym-functions`. Le mode simulé se coupe seul dès
que la clé est là.
