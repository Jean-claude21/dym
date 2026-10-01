# 0008 — Spec Kit comme flux de développement

**Statut :** Acceptée · 2026-10-01

## Contexte

Les versions précédentes ont produit beaucoup de code non vérifié, guidé par trois jeux de docs
concurrents. Le goulot n'est plus l'écriture du code mais sa vérification.

## Décision

- Spec Kit 1.0.7, intégration Claude Code, extension `git` (une branche par spec).
- La constitution (`.specify/memory/constitution.md`) contient les règles non négociables.
- Une spec par ligne de `docs/product/ROADMAP.md`, qui cite ses identifiants de features.
- Cycle : `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` →
  `/speckit-analyze` → `/speckit-implement`.
- Les maquettes validées (phase 0) sont les critères d'acceptation des specs d'UI.

## Conséquences

- Une seule source de vérité produit : `docs/product/` ; `docs/product/sources/` est en lecture seule.
- Pas de code produit en dehors d'une spec.
