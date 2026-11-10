# Implementation Plan: Fil classé, abonnements et commentaires

**Branch**: `feat/037-feed-ranking` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Score, fil, abonnements et commentaires en SQL | OK |
| IV. Générique | `feed_ranking_rules` par pays (défaut : pays nul) | OK |
| V. Sécurité | Écritures par fonctions ; commentaires signalables ; réglages admin audités | OK |
| VII. Qualité | pgTAP, tests Flutter ; Neon propre ; staging | OK |
| IX. Mesure | `follow_added`, `comment_added` | OK |

## Décisions

- Migration 0044 : `follows`, `content_comments`, `feed_ranking_rules` ; `content_feed_ranked`
  (onglet, catégorie, décalage), `follow`, `content_comments_list`, `add_comment`,
  `delete_comment`, `admin_set_feed_ranking` ; `report`, `admin_moderate`, `admin_reports`
  recopiées (cible `comment`).
- App : onglets et catégories, bouton « S'abonner », commentaires en feuille, bascule
  grille/plein écran.
