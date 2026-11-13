# Implementation Plan: Appels réels (LiveKit)

**Branch**: `feat/084-appels-livekit` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Fournisseur et droit au média décidés en SQL | OK |
| IV. Fournisseurs derrière une interface | `CallProvider` ; LiveKit Cloud ou auto-hébergé par configuration | OK |
| V. Sécurité | Jeton émis par la Function après contrôle SQL ; secret LiveKit hors dépôt | OK |
| VIII. Terrain | Opus à faible débit, vidéo 360p adaptative, cibles de 56 dp, icône + libellé | OK |

## Décisions

- Décision 0019.
