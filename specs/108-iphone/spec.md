# Feature Specification: iPhone

**Feature Branch**: `feat/108-iphone`

**Created**: 2026-11-17

**Status**: Done (sauf CallKit : compte Apple)

**Input**: Demande du porteur (2026-11-17) : implémenter même ce qui attend un compte.

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** Sur iPhone, chaque notification sonne avec le son de son événement (commande,
  message, course, appel) et se range par sujet ; les messages « à boutons » (données seules sur
  Android) s'affichent aussi sur iPhone, app fermée.
- **US2 (P2)** Chaque changement du code iOS est compilé sur un Mac de GitHub (client, vendeuse).

## Requirements *(mandatory)*

- **FR-001** Functions : bloc `apns` (alerte, son `<son>.wav`, `thread-id`, priorité 10) sur tous
  les push.
- **FR-002** Apps iOS cliente et vendeuse : 4 sons WAV dans `Runner` (projet Xcode) ;
  `DarwinNotificationDetails` (son, sujet, appel « time-sensitive »).
- **FR-003** Workflow « iOS (compilation) » : construit les deux apps sans signature et vérifie les
  sons embarqués.

## Attend le porteur

- Compte Apple Developer : clé APNs dans Firebase (sans elle, aucun push n'arrive sur iPhone),
  signature, TestFlight.
- CallKit (sonnerie plein écran app fermée) : notifications VoIP PushKit et certificat VoIP Apple.
