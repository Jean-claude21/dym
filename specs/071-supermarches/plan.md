# Implementation Plan: Supermarchés

**Branch**: `feat/071-supermarches` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| IV. Générique par configuration | Origine en base (`store_origins`) ; apps inchangées hors badge | OK |
| V. Sécurité | Aucune table nouvelle ; `update_store` vérifie déjà l'origine active | OK |

## Décisions

- Migration `0070_supermarket_origin.sql`.
- Badge : `Icons.local_grocery_store_rounded`, fond vert tendre, texte vert profond.
- Illustration : rayons du magasin en attendant une photo dédiée.
