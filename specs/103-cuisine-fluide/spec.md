# Feature Specification: Cuisine fluide

**Feature Branch**: `feat/103-cuisine-fluide`

**Created**: 2026-11-17

**Status**: Done

**Input**: Plan validé le 2026-11-16 (bloc Cuisine) et demande du porteur du 2026-11-17 : finir tout
ce qui était décidé pour la Cuisine côté téléphone et côté « Mes vidéos ».

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** La miniature s'affiche tout de suite pendant que la vidéo se prépare ; la vidéo
  suivante est préparée d'avance (préchargement).
- **US2 (P1)** Économie de données (menu Moi) : version légère (MP4 240p) gardée sur le téléphone
  pour être revue sans data, rien de préchargé, aperçus animés coupés.
- **US3 (P2)** Appui long sur une vignette de grille : aperçu animé de quelques secondes.
- **US4 (P1)** « Mes vidéos » (vendeuse et créatrice) : temps moyen regardé, part regardée jusqu'au
  bout, ventes générées (commandes livrées des produits tagués, passées dans les 7 jours après
  avoir regardé la vidéo) ; choix de la miniature parmi les images de la vidéo.
- **US5 (P2)** Le fil « Pour toi » tient compte des vidéos regardées jusqu'au bout.

## Requirements *(mandatory)*

- **FR-001** Migration 0095 : `content_watches`, compteurs `watch_ms_total` / `completion_count`,
  `cover_frame`, `stream_thumb_count`, `content_watched`, `app.content_stats`, `set_content_cover` ;
  `content_json`, `content_feed_ranked`, `my_contents`, `my_creator_contents` étendus.
- **FR-002** Functions : la conversion Bunny transmet le nombre d'images (`thumbnailCount`).
- **FR-003** App cliente : lecteur avec repli, cache fichier, temps regardé ; préchargement ;
  `ContentThumb` ; réglage « Économie de données ».
- **FR-004** `dym_account` : `ContentStatsLine`, `showCoverPicker` (vendeuse et créatrice).

## Limites assumées

- En lecture adaptative (HLS), les segments ne sont pas gardés sur le téléphone ; le cache vaut
  pour la version légère et les vidéos non converties en économie de données.
