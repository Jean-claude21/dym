# Implementation Plan: Passerelle temps réel

**Branch**: `feat/067-realtime-gateway` | **Date**: 2026-11-12 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Événements écrits par déclencheurs dans la transaction du changement | OK |
| IV. Fournisseurs derrière une interface | `LiveFeed` : Neon Realtime pourra remplacer la lecture sans toucher aux apps | OK |
| V. Sécurité | Événement adressé à une personne, jeton vérifié avant la poignée de main ; table sans accès Data API | OK |
| VI. Couches | `dym_core` (contrat) → `neon_kit` (client) → `dym_platform` (cycle de vie) → services des apps | OK |
| VIII. Terrain | Reprise, signal de vie, reconnexion progressive, relecture en filet | OK |

## Décisions

- Lecture par instance toutes les secondes, seulement avec des connexions (la base peut dormir) ;
  `LISTEN/NOTIFY` écarté (base toujours allumée exigée) ; Neon Realtime écarté pour l'instant (bêta,
  sans Dart ni RLS).
- Migration `0067_live_events.sql` ; ménage par la tâche `dispatch-watch`.
