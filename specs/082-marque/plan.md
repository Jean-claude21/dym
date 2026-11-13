# Implementation Plan: Marque

**Branch**: `feat/082-marque` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| IV. Générique | Aucun lieu ni mot propre à un pays ; textes dans `dym_l10n` | OK |
| VI. Couches | `lottie` seulement dans `dym_ui` | OK |
| VIII. Terrain | Animations désactivables, JSON légers, rendu `Canvas` | OK |

## Décisions

- Sources et scripts de génération : `docs/design/marque/` ; décision 0018.
- Vert actuel de la marque (`#145C43`) plutôt que l'ancien bleu-vert du logo : une seule couleur
  de marque dans les apps (décision 0016).
