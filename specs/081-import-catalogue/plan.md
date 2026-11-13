# Implementation Plan: Import du catalogue

**Branch**: `feat/081-import-catalogue` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Prix lus et validés en SQL ; l'app ne fait que découper les colonnes | OK |
| V. Sécurité | `own_editable_store` : seule la boutique de la vendeuse | OK |
| IV. Générique | Rayons et unités du référentiel, décimales de la devise | OK |

## Décisions

- Coller depuis un tableur plutôt qu'un fichier : marche sur téléphone, tablette et web sans
  nouvelle dépendance.
