# Implementation Plan: Recherche et classement réglables

**Branch**: `feat/028-ai-search-ranking` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Score, raison et élargissement en SQL (`copilot_pick`, `search_catalog`, `expand_query`) | OK |
| IV. Générique | Poids et noms locaux en tables par pays ; aucun nom local dans le code | OK |
| V. Sécurité | Tables sans accès direct ; réglages `require_admin` + `admin_did` (audit) | OK |
| VII. Qualité | pgTAP (10), tests modèles (2), admin (2) ; Neon propre ; essai sur staging | OK |

## Décisions

- `search_catalog` et `copilot_quote` recopiées depuis leur dernière version, une seule ligne
  changée chacune (élargissement ; raison transmise).
- Score = Σ poids × critère normalisé (texte relatif au meilleur, prix relatif min–max).
- Raison = critère qui a le plus contribué au score.
- Admin : onglet « Recherche » dans Réglages (poids du pays choisi, noms locaux).
