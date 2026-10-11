# Plan : Contenus shoppables et modération

**Spec** : [spec.md](spec.md)

**Branche** : `feat/020-shoppable-content`, empilée sur `feat/019-intent-copilot`.

## Technique

### Base

Migration `db/migrations/0022_shoppable_content.sql` :

- **Tables**, toutes fermées à la Data API et lues par des fonctions :
  - `contents` : story ou vidéo, expiration, compteurs ;
  - `content_products` ;
  - `content_likes` ;
  - `reports`.
- **Lectures** :
  - `content_feed` : onglets « pour toi » et « suivies », pagination, filtre par produit ;
  - `content_stories` ;
  - `product_video_count`.
- **Gestes de la cliente** : `content_viewed`, `content_clicked`, `like_content`, `report`.
- **Gestes de la vendeuse** : `save_content`, `my_contents`, `archive_content`, `delete_content`.
- **Équipe** : `admin_reports` (groupés par cible, avec aperçu) et `admin_moderate` (raison
  obligatoire, `admin_did`).
- Le statut `removed` est ajouté aux produits.

### Function

`POST /v1/content/uploads` renvoie une URL présignée (image JPEG ou WebP, vidéo MP4).

### Dart

- **Modèles** : `ContentItem`, `StoryGroup`, `ModerationItem`, `ReportReason`, `ReportTarget`.
- **Données** :
  - `ContentRepository` ;
  - `AdminRepository.reports` et `AdminRepository.moderate`.
- **`dym_platform`** : `VideoPicker` (`image_picker`, 60 s).

### Apps

- **Cliente** :
  - onglet « Vidéos » (74, lecture par `video_player`, injectable) ;
  - stories sur l'accueil ;
  - « Voir en vidéo » et « Signaler » sur la fiche produit.
- **Vendeuse** : « Mes stories et vidéos » et publication (75).
- **Admin** : onglet « Modération » (76).

## Dépendance ajoutée

`video_player` dans l'app cliente, inscrit dans `PACKAGES.md`.

## Constitution

- **Postgres source de vérité** : en SQL, propriété des médias, produits tagués, expiration,
  visibilité, compteurs et décisions de modération.
- **Sécurité** : chaque geste est vérifié par pgTAP (autre boutique, autre personne, non-admin).
  Les décisions sont journalisées.
- **Événements serveur** : comptes et motifs, sans donnée personnelle.

## Dérogations

**Gate de la phase 3 (H10 non testée)** : dérogation du porteur produit du 2026-10-10. Côté apps,
tout reste derrière `shoppable_content`, coupé par défaut.
