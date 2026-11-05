# Feature Specification: Recherche vocale et par photo

**Feature Branch**: `feat/018-search-voice-image`

**Created**: 2026-10-10

**Status**: Draft

**Input**: Spec `search-voice-image` de la roadmap (Phase 4 ; C-SEARCH-04/05/07/08). Elle est
construite avant le gate de la phase 3 (H10 non testée) par décision du porteur produit du
2026-10-10. Elle reste derrière le flag `ai_search`, coupé par défaut.

## Contexte

Awa cherche « des tomates et du gombo pour ce soir » sans taper. Elle peut aussi photographier un
produit qu'elle connaît sans en savoir le nom. La recherche se souvient de ses dernières requêtes et
propose des complétions pendant la saisie.

**Maquettes** à valider : 71 (recherche vocale), 72 (recherche par photo).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Chercher à la voix (Priority: P1)

Dans la recherche, le micro ouvre l'écoute (71) : une onde suit la voix et un exemple est affiché.
Quand Awa a fini, l'écran affiche « Tu as dit : … » avec deux choix :

- **Chercher** : lance la recherche habituelle avec ce texte ;
- **Recommencer** : relance l'écoute.

L'historique reste visible en bas.

**Acceptance Scenarios**:

1. **Given** le flag `ai_search` actif pour le pays, **When** Awa dit « gombo frais », **Then** le
   texte est affiché, puis la recherche donne les résultats habituels.
2. **Given** le flag coupé, **When** Awa ouvre la recherche, **Then** ni micro ni appareil photo ne
   sont proposés.
3. **Given** le micro refusé ou la transcription en échec, **When** Awa parle, **Then** un message
   l'invite à taper sa recherche, sans texte inventé.

### User Story 2 - Chercher en photo (Priority: P1)

L'appareil photo propose deux sources, prendre une photo ou choisir dans la galerie. La photo est
décrite, puis les résultats s'affichent sous l'en-tête « D'après ta photo : gombo frais » (72), avec
la vignette, « Modifier » (le texte devient éditable) et « Nouvelle photo ». Si rien n'est reconnu,
Awa est invitée à taper.

### User Story 3 - Historique (Priority: P2)

Quand le champ est vide, les dernières recherches (8) s'affichent en puces, avec « Effacer ». Ne
sont retenues que les recherches validées : touche Rechercher, voix, photo ou ouverture d'un produit.
Les frappes intermédiaires ne sont pas retenues.

### User Story 4 - Suggestions (Priority: P2)

Pendant la saisie, jusqu'à 8 complétions s'affichent : des rayons puis des produits en vente dans le
quartier, dont un mot commence par le texte tapé. En toucher une lance la recherche.

### Edge Cases

- Hors ligne : la voix et la photo sont indisponibles, avec un message clair. La recherche texte
  garde son comportement.
- Message vocal trop long : l'écoute s'arrête d'elle-même à 15 secondes.
- Visiteuse sans session : pas d'historique. Les suggestions restent disponibles.

## Requirements *(mandatory)*

- **FR-001**: Voix et photo passent par une Function :
  - les modèles sont lus dans `ai_models` (`search_transcription`, `search_from_photo`) ;
  - elles sont refusées si le flag `ai_search` est coupé pour le pays (`feature_disabled`) ;
  - ni l'audio ni la photo ne sont conservés.
- **FR-002**: Le texte obtenu passe par la recherche existante (plein texte, quartier, filtres).
- **FR-003**: Chaque requête IA est journalisée (usage, résultat, latence, sans contenu). Elle émet
  `voice_search_used` ou `photo_search_used` côté serveur.
- **FR-004**: Historique :
  - 20 recherches au plus par personne, sans doublon (casse ignorée) ;
  - lisible et effaçable par elle seule ;
  - en dehors des événements.
- **FR-005**: Suggestions : rayons actifs et produits publiés dans le quartier ; caractères spéciaux
  échappés.
- **FR-006**: Écrans 71 et 72 :
  - états vide, chargement, erreur et hors ligne ;
  - sept tailles, texte à 130 % ;
  - animation de l'onde désactivée si les animations sont réduites.

## Success Criteria *(mandatory)*

- **SC-001**: Awa obtient des résultats à la voix en moins de 10 secondes sur 3G.
- **SC-002**: Aucun historique d'autrui lisible (pgTAP) ; aucune requête IA sans flag actif.

## Assumptions

- **Écart avec la roadmap** : la roadmap prévoit des embeddings et pgvector pour l'image. pgvector
  n'est pas disponible sur le cluster local. La photo est donc décrite en texte, puis cherchée en
  plein texte, ce qui suffit au catalogue du pilote. Les embeddings sont à revoir quand le catalogue
  dépassera quelques milliers de produits.
- Langues locales du pays pilote : la transcription suit le modèle configuré ; à mesurer pendant
  le pilote.
