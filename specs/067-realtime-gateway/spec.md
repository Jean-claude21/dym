# Feature Specification: Passerelle temps réel

**Feature Branch**: `feat/067-realtime-gateway`

**Created**: 2026-11-12

**Status**: Draft

**Input**: Essai sur émulateur (2026-11-12) : une course acceptée par la vendeuse n'apparaissait chez le
livreur qu'en tirant la liste ; aucun écran ne se met à jour seul. Étude de Neon (même jour) : Neon
Realtime est en bêta, sans SDK Dart ni RLS ; les Functions savent servir des WebSocket. Socle du chat
commerce (spec 068).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Les écrans se mettent à jour seuls (Priority: P1)

- Livreur : une course proposée, une commande prête apparaissent sans geste.
- Vendeuse : une nouvelle commande sonne et s'affiche ; la fiche suit le livreur.
- Cliente : le suivi avance seul ; « Mes commandes » aussi.
- Chat : un message reçu s'affiche aussitôt dans la conversation et la liste.

### User Story 2 - Réseau instable (Priority: P1)

Coupure : reconnexion progressive (1 à 30 s) avec le dernier événement reçu ; à chaque connexion,
l'écran se recharge. En arrière-plan, la connexion se ferme (le push prend le relais). Une relecture
régulière (30 à 60 s) reste en filet.

### Edge Cases

- Transaction validée après une plus récente : relecture avec recouvrement, doublons écartés.
- Aucun écran qui écoute : aucune connexion ; personne de connecté : la base n'est pas interrogée.

## Requirements *(mandatory)*

- **FR-001**: `live_events` adressés à une personne, écrits par déclencheurs (messages, statut de
  commande, notifications) ; non exposés à la Data API ; supprimés après 24 h.
- **FR-002**: `GET /v1/live` (WebSocket) : jeton Neon Auth (en-tête ou `access_token`), `after` pour la
  reprise ; messages `ready`, `event`, `ping` (25 s).
- **FR-003**: contrat générique `LiveFeed` (`dym_core`), client `NeonLiveClient` (`neon_kit`),
  `LiveConnection` (`dym_platform`).

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP `560_live_events.sql` (10) ; tests de la passerelle (6) et du client (6).
- **SC-002**: un test d'écran : une course proposée apparaît sans attendre la relecture.
