# Plan : Recherche vocale et par photo

**Spec** : [spec.md](spec.md)

**Branche** : `feat/018-search-voice-image`, empilée sur `feat/017-admin-pilot`.

## Technique

### Base

Migration `db/migrations/0020_search_ai.sql` :

- **Flags** : `app.feature_enabled(key, pays)` lit le flag du pays, à défaut le flag global.
- **Historique** : table `search_history`, fermée à la Data API. On y accède par trois fonctions :
  - `remember_search` (texte normalisé, sans doublon, 20 au plus) ;
  - `my_searches` ;
  - `forget_searches`.
- **Suggestions** : `search_suggestions(préfixe, quartier)` renvoie des rayons et des produits.
  Visiteuse comprise, jokers échappés.
- **IA** :
  - `app.search_ai_context` : flag `ai_search` et modèle actif, sinon `feature_disabled` ;
  - table `ai_requests` et `app.record_ai_request` (résultat, latence, sans contenu) ;
  - événements `voice_search_used` et `photo_search_used`.
- **Amorçage** : modèles `search_transcription` (`gpt-4o-mini-transcribe`) et `search_from_photo`.

### Function

`functions/src/search/` :

- `POST /v1/search/voice` (audio en base64, 1 Mo au plus) : transcription par `transcribe` de l'AI
  SDK ;
- `POST /v1/search/photo` (image en base64, 1,5 Mo au plus) : sortie structurée
  `{found, query}`.

Le texte est nettoyé, l'échec du fournisseur renvoie 503 et chaque requête est journalisée.

### Dart

- **Modèles** : `SearchSource`, `SearchHistoryEntry`, `SearchSuggestion`.
- **Données** : `SearchAiRepository`.
- **`dym_platform`** : `VoiceRecorder`, via `PluginVoiceRecorder` sur le paquet `record`. Le flux
  PCM 16 bits mono à 16 kHz est emballé en WAV, seul format de flux disponible partout.

### App cliente

- `SearchAiService`, en version Neon et en version mémoire.
- Recherche :
  - historique quand le champ est vide ;
  - suggestions pendant la saisie ;
  - micro et appareil photo si le flag est actif.
- Écoute (71).
- En-tête de résultats d'une photo (72).

## Dépendance ajoutée

`record` dans `dym_platform`, inscrit dans `docs/architecture/PACKAGES.md`. C'est la seule façon
d'enregistrer le micro sur Android, iOS et le web.

## Constitution

- **Postgres source de vérité** :
  - le flag et le modèle sont vérifiés en SQL avant tout appel ;
  - l'app ne fait qu'afficher le texte rendu ;
  - les résultats viennent de la recherche existante.
- **Générique** : modèles en base, fournisseur derrière une interface. Aucun pays ni aucune langue
  dans le code.
- **Données personnelles** : ni l'audio ni la photo ne sont conservés. L'historique n'est lisible
  que par son autrice et n'entre pas dans les événements.

## Dérogations

- **Gate de la phase 3 (H10 non testée)** : dérogation du porteur produit du 2026-10-10. Tout reste
  derrière `ai_search`, coupé par défaut.
- **Image** : description en texte au lieu d'embeddings et de pgvector (voir la spec).
