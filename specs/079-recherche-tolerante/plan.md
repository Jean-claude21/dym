# Implementation Plan: Recherche tolérante aux fautes

**Branch**: `feat/079-recherche-tolerante` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Correspondance approchée en SQL | OK |

## Décisions

- `pg_trgm` (extension standard, disponible sur Neon) ; seuil 0,45 choisi pour accepter une lettre
  oubliée ou doublée sans ramener des mots éloignés.
- Revue : filtres existants (rayon, origine dont supermarché, prix, disponible) conformes.
