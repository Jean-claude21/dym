# Implementation Plan: Vocaux et appels

**Branch**: `feat/035-chat-calls` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | États d'appel, durées, résumé et validation des vocaux en SQL | OK |
| IV. Générique | Fournisseur média derrière `CallProvider` ; flag pays `calls_simulated` | OK |
| V. Sécurité | Participantes seulement ; médias privés, liens signés | OK |
| VII. Qualité | pgTAP, tests Function et Flutter ; Neon propre ; staging | OK |
| Décision 0015 | Média simulé, signalé à l'écran, remplacé avant la production finale | Dérogation consignée |

## Décisions

- Migration 0042 : messages `audio` (durée) et `call` (résumé) ; table `calls` ; `start_call`,
  `answer_call`, `end_call`, `call_state`, `my_incoming_call` (sonnerie de 60 s) ;
  `send_message` et `message_json` recopiées.
- Function : types audio acceptés à l'envoi des médias de conversation.
- Paquets : lecture audio `audioplayers` dans `dym_platform` (`AudioPlayback`) ; enregistreur
  existant (`record`).
- Apps (via `dym_chat`) : micro, bulle audio, bouton d'appel, écran d'appel simulé, appel entrant.
