# Implementation Plan: Personnel des boutiques

**Branch**: `feat/087-personnel-boutique` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Accès décidés en SQL ; l'app ne fait que masquer | OK |
| V. Sécurité | Argent, réglages et équipe à la propriétaire ; sûr par défaut ; journal | OK |
| IV. Générique | Rôles et permissions en données de référence | OK |

## Décisions

- Même méthode que les rôles admin (spec 085) : la pile d'appels donne la fonction vendeuse
  appelante, `store_function_permissions` la permission exigée. La lecture de la pile reconnaît
  aussi les fonctions SQL simples (correctif appliqué à la garde admin).
- Succursales : une boutique par lieu (`stores.owner_id` reste unique) ; le personnel peut
  appartenir à plusieurs boutiques, la boutique active est mémorisée par personne.
