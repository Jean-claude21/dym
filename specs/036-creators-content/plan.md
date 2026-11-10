# Implementation Plan: Créateurs et contenus de tous

**Branch**: `feat/036-creators-content` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Profil, publication, catégories et visibilité en SQL | OK |
| IV. Générique | `content_categories` en données de référence ; modèle d'IA en base (`content_classifier`) | OK |
| V. Sécurité | Écriture par fonctions ; clé de média dans le dossier de l'autrice ; rôle `creator` | OK |
| VII. Qualité | pgTAP, tests Function et Flutter ; Neon propre ; staging | OK |
| IX. Mesure | `creator_joined`, `content_published` | OK |

## Décisions

- Migration 0043 : rôle `creator` ; `creator_profiles` ; `content_categories` (graine) ;
  `contents.author_id`, `category_id`, `category_source`, type `post`, boutique facultative ;
  `become_creator`, `save_creator_content`, `my_creator_contents` ; `content_visible`,
  `content_json`, `content_feed`, `archive_content`, `delete_content` recopiées.
- Function : `POST /v1/creator-content/uploads` (dossier `creators/<id>/contents/`),
  `POST /v1/creator-content/classify` (IA, catégories du référentiel).
- App cliente : « Créer » dans « Moi » (devenir créatrice, publier, mes posts) ; fil : posts à
  l'auteur.
