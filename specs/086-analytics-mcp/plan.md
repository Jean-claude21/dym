# Implementation Plan: Analytics et MCP admin

**Branch**: `feat/086-analytics-mcp` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Le MCP appelle les fonctions admin SQL ; aucune règle dans la Function | OK |
| V. Sécurité | Droits de l'admin propriétaire, clés hachées, écritures journalisées, analytics en lecture seule | OK |
| IX. Mesurer et tracer | Vues sur les événements de `METRICS.md`, sans donnée personnelle | OK |

## Décisions

- Décision 0020.
