# Feature Specification: Cuisine sociale

**Feature Branch**: `feat/101-cuisine-sociale`

**Created**: 2026-11-16

**Status**: Done

**Input**: Décisions du porteur (2026-11-16) : la Cuisine devient sociale (profils, abonnements,
fils Pour toi / Abonnements / Près de moi, « Mes recettes », « J'ai fait la recette ») ; vidéos
adaptatives (HLS) sur Bunny Stream, les photos et médias du chat restent sur Neon.

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** Profil public d'une créatrice ou d'une boutique, lisible sans compte : nom, bio,
  abonnés, s'abonner, grille de ses contenus. Ouvert d'un geste sur le nom dans le fil.
- **US2 (P1)** Onglet « Près de moi » : vidéos des boutiques qui livrent le quartier, les plus
  récentes d'abord.
- **US3 (P1)** « Mes recettes » : enregistrer ou retirer une vidéo, retrouver ses recettes.
- **US4 (P2)** « J'ai fait la recette » (une fois, avec un petit mot facultatif) : la créatrice est
  prévenue (`recipe_cooked`).
- **US5 (P2)** Vidéo adaptative : la tâche planifiée envoie les nouvelles vidéos à Bunny Stream et
  lit le HLS une fois prêt ; sans clé, la vidéo d'origine est lue (rien ne casse).

## Requirements *(mandatory)*

- **FR-001** Migration 0094 : `content_saves`, `content_cooks`, colonnes `stream_*` des contenus,
  `toggle_save_content`, `my_saved_contents`, `i_cooked_it`, `content_profile`,
  `app.stream_pending`, `app.set_stream` ; `content_json` enrichi ; onglet `near`.
- **FR-002** Functions : `/v1/jobs/content-streams` toutes les 5 min (`BUNNY_STREAM_*`).
- **FR-003** App cliente : onglet « Près de moi », « Mes recettes », « J'ai fait », profil public,
  lecture HLS.
- **FR-004** Événements `recipe_saved`, `recipe_cooked` (jamais de nom ni de note).
