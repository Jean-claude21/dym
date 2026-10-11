# Feature Specification: Contenus shoppables et modération

**Feature Branch**: `feat/020-shoppable-content`

**Created**: 2026-10-11

**Status**: Draft

**Input**: Spec `shoppable-content` de la roadmap (Phase 4 ; C-HOME-06/07, C-CAT-12, V-CONT-01..08,
A-MOD-01..05). Elle est construite avant le gate de la phase 3 (H10 non testée) par décision du
porteur produit du 2026-10-10. Côté apps, elle reste derrière le flag `shoppable_content`, coupé
par défaut.

## Contexte

Fatou filme son étal le matin : « Tomates du jour, arrivées ce matin ! ». Elle tague ses tomates.
Awa voit la vidéo dans son fil et ajoute les tomates au panier sans quitter la vidéo. Un contenu
trompeur, un produit interdit ou un avis insultant peut être signalé. L'équipe le garde ou le
retire, avec une raison.

**Maquettes** à valider : 74 (fil de vidéos), 75 (publier un contenu), 76 (modération).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fatou publie (Priority: P1)

Depuis « Ma boutique → Mes stories et vidéos », Fatou publie (75) :

- une **story 24 h** : photo ou courte vidéo ;
- ou une **vidéo** : 60 secondes au plus, filmée ou choisie dans la galerie.

Elle tague jusqu'à 5 de ses produits publiés et ajoute une légende facultative. « Mes stories et
vidéos » montre les vues, les clics sur les produits et les « j'aime ». Elle peut archiver ou
supprimer un contenu.

**Acceptance Scenarios**:

1. **Given** une photo et un produit tagué, **When** Fatou publie une story, **Then** la story est
   visible 24 h par les clientes de sa zone.
2. **Given** le produit d'une autre boutique ou un média hors de son dossier, **When** elle publie,
   **Then** c'est refusé.

### User Story 2 - Awa regarde et achète (Priority: P1)

L'onglet « Vidéos » (74) fait défiler les vidéos du quartier, verticalement. Deux onglets :

- « Pour toi » ;
- « Boutiques suivies » : celles où Awa a déjà commandé.

Chaque vidéo montre la boutique, son origine, la légende et le produit tagué avec « Ajouter ». Les
stories des boutiques s'affichent en tête de l'accueil (C-HOME-07). La fiche d'un produit montré en
vidéo propose « Voir en vidéo » (C-CAT-12).

### User Story 3 - Signaler (Priority: P1)

Une vidéo, une story, un produit ou un avis peut être signalé, avec un motif : trompeur,
insultant, interdit, spam ou autre. Chaque personne signale une cible une seule fois.

### User Story 4 - L'équipe modère (Priority: P1)

La file de modération (76) regroupe les signalements par cible : nombre, motifs, aperçu. L'équipe
garde ou retire, avec une raison obligatoire inscrite au journal. Selon la cible, retirer :

- sort le contenu du fil ;
- sort le produit du catalogue ;
- masque l'avis.

### Edge Cases

- Story expirée : elle sort de l'accueil, mais la vendeuse la garde dans ses statistiques.
- Boutique suspendue : ses contenus disparaissent du fil.
- Flag coupé : ni onglet « Vidéos », ni stories, ni « Mes stories et vidéos ».

## Requirements *(mandatory)*

- **FR-001**: Publication par la Data API (`save_content`) :
  - média déjà envoyé par une URL présignée (Function) dans `stores/<boutique>/contents/` ;
  - une story expire 24 h après sa publication ;
  - 5 produits tagués au plus, publiés et de la boutique.
- **FR-002**: Fil, stories et compteur de vidéos d'un produit : contenus publiés et non expirés, de
  boutiques actives qui livrent le quartier. Visiteuse comprise.
- **FR-003**: Statistiques : vues, clics sur un produit tagué (`content_product_clicked`), « j'aime »
  (une personne, un « j'aime »).
- **FR-004**: Signalements : un par personne et par cible, motif connu (`content_reported`).
- **FR-005**: Modération réservée à l'équipe, raison obligatoire, journalisée
  (`content_removed`, `content_kept`). Les produits retirés prennent le statut `removed`.
- **FR-006**: Écrans 74 à 76 :
  - états vide, chargement, erreur et hors ligne ;
  - sept tailles, texte à 130 % ;
  - animations désactivables.

## Success Criteria *(mandatory)*

- **SC-001**: Fatou publie une story en moins d'une minute.
- **SC-002**: Aucun contenu, signalement ou statistique d'une autre boutique n'est modifiable
  (pgTAP).

## Assumptions

- Publication planifiée (V-CONT-07, P2) : backlog.
- La vidéo est envoyée telle quelle (60 s au plus). Une compression côté serveur sera à prévoir si
  le volume grandit.
- Pas de partage externe depuis le fil : aucun paquet de partage dans la pile.
