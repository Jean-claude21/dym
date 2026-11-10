# Implementation Plan: Pont TikTok

**Branch**: `feat/040-tiktok-bridge` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Compte déclaré, origine du post, liens courts et compteur en SQL ; la Function ne fait que lire TikTok et copier la couverture | OK |
| IV. Générique | Fournisseur derrière `VideoImportProvider` ; adresse de l'app web lue dans `ALLOWED_ORIGINS` | OK |
| V. Sécurité | Origine réservée à l'autrice ; page publique échappée ; aucun secret | OK |
| VII. Qualité | pgTAP, tests Function (dont la réponse oEmbed réduite constatée) et Flutter ; Neon propre ; staging | OK |
| VII. Simulation | Compte déclaré non vérifié, signalé à l'écran jusqu'à la connexion TikTok (décision 0015) | OK |

## Décisions

- Migration 0047 :
  - `creator_profiles.tiktok_handle` ;
  - `contents.source` et `source_url` ;
  - `share_links` ;
  - RPC `set_tiktok_handle`, `set_content_source`, `create_share_link`, `open_share_link`
    (ouverte sans compte) ;
  - `content_json` recopié avec l'origine.
- Function :
  - `POST /v1/creator-content/tiktok-import` (oEmbed public, sans clé, couverture copiée dans le
    dossier de la créatrice) ;
  - `GET /s/:code` (page légère avec Open Graph, sans script).
- App cliente :
  - section TikTok du studio et écran d'import ;
  - « Partager » dans le studio et le fil (lien copié) ;
  - « Voir sur TikTok » ;
  - `?share=<code>` gardé jusqu'à l'accueil, puis « Tout pour la faire ».
