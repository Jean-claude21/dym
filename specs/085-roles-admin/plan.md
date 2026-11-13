# Implementation Plan: Rôles et permissions des admins

**Branch**: `feat/085-roles-admin` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Permissions vérifiées en SQL ; l'app ne fait que masquer | OK |
| IV. Générique par configuration | Rôles et permissions en données de référence | OK |
| V. Sécurité | Sûr par défaut (fonction non déclarée : super-admin), audit des rôles | OK |

## Décisions

- Garde unique sans réécrire les fonctions admin : la pile d'appels (`PG_CONTEXT`) donne la
  fonction appelante, la table `admin_function_permissions` la permission exigée.
- Trois fonctions qui vérifiaient l'admin à part passent par la garde commune.
