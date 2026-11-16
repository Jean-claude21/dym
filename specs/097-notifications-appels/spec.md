# Feature Specification: Notifications et appels

**Feature Branch**: `feat/097-notifications-appels`

**Created**: 2026-11-16

**Status**: Done

**Input**: Décisions du porteur (2026-11-16) : un son par événement, boutons d'action dans les
notifications, boîte de notifications de la vendeuse et du livreur, appel qui sonne en plein écran
même téléphone verrouillé, appel manqué. Phase 15.

## User Scenarios & Testing *(mandatory)*

### US1 — Un son par événement (P1)

Nouvelle commande (trois notes montantes), message (note double discrète), course proposée au
livreur (alerte insistante), appel (sonnerie qui boucle). Chaque son a son canal Android ; la
personne peut le régler ou le couper dans les réglages du téléphone. Sons générés pour DYM, sans
droits.

### US2 — Boutons dans les notifications (P1)

Nouvelle commande : « Accepter » (la commande est acceptée, l'écran s'ouvre) et « Voir ». Course
proposée : « Accepter » (le livreur la prend). Message : « Répondre » (texte saisi dans la
notification, envoyé sans ouvrir l'app) et « Voir ». Appel : « Décrocher » et « Refuser ».

### US3 — Appel en plein écran (P1)

Un appel entrant sonne en plein écran, même téléphone verrouillé (Android), jusqu'à la réponse ou
60 s. Non décroché : « Appel manqué » notifié à la personne appelée, dans la bonne app.

### US4 — Boîte de notifications de la vendeuse et du livreur (P2)

Une cloche avec le nombre de non-lues ; la boîte liste les notifications de cette app (texte rendu
par la base dans la langue de la personne) ; ouvrir la boîte vaut lecture ; toucher ouvre la
commande ou la conversation.

## Requirements *(mandatory)*

- **FR-001** Migration 0090 : déclencheur d'appel manqué (`call_missed`, `call_missed_vendor`),
  balayage `app.sweep_missed_calls` (cron des Functions), `my_app_notifications`,
  `unread_app_notifications`.
- **FR-002** Functions : canaux `*_v2` avec leur son, canal des appels ; notifications à boutons et
  appels envoyés en données seules (affichés par l'app, avec `call_id` pour refuser).
- **FR-003** `dym_platform` : canaux et sons, boutons, plein écran, affichage en arrière-plan,
  libellés traduits gardés sur le téléphone.
- **FR-004** Package `dym_notifications` (vendeuse, livreur) : boîte et cloche.
- **FR-005** Apps : gestes depuis les notifications (`quickChatAction` dans `dym_chat`, accepter
  une commande ou une course), manifestes (plein écran, écran allumé sur l'appel).

## Hors périmètre

- Sons personnalisés sur iOS (son par défaut) et CallKit : avec le compte Apple.
