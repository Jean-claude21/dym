# Feature Specification: Messagerie cliente ↔ vendeuse

**Feature Branch**: `feat/015-messaging`

**Created**: 2026-10-10

**Status**: Draft

**Input**: Spec `messaging` de la roadmap (Phase 2 ; C-CHAT-01/02/04, V-MSG-01..04, V-DASH-04) :
chat cliente ↔ vendeuse (texte, image, partage de produit), non-lus, push.

## Contexte

Au marché, on demande avant d'acheter : « Vous avez encore du gombo ? ». Awa doit pouvoir écrire
à une boutique, envoyer une photo (une liste, un produit abîmé) et recevoir une fiche produit
qu'elle ajoute au panier. Fatou voit ses conversations, répond et partage un produit. Les
deux sont prévenues des messages non lus.

**Maquettes** à valider : 60 (conversation côté cliente), 61 (messages de la vendeuse),
62 (conversation et partage de produit côté vendeuse).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Awa écrit à une boutique (Priority: P1)

Depuis la page d'une boutique ou d'un produit, Awa ouvre la conversation avec cette boutique
(une seule par boutique). Elle écrit, envoie une photo, ou partage le produit qu'elle regarde.
Elle retrouve ses conversations dans « Moi », avec les non-lus.

**Acceptance Scenarios**:

1. **Given** une boutique active, **When** Awa ouvre la conversation et envoie « Vous avez
   encore du gombo ? », **Then** le message apparaît, la vendeuse reçoit une notification
   « Nouveau message » (sans le contenu du message).
2. **Given** une conversation, **When** Awa envoie une photo, **Then** elle n'est lisible que
   par Awa, la vendeuse et l'équipe.
3. **Given** un produit de la boutique partagé dans la conversation, **When** Awa touche
   « Ajouter au panier », **Then** le produit rejoint son panier au prix serveur.

---

### User Story 2 - Fatou répond et partage un produit (Priority: P1)

Fatou ouvre l'onglet « Messages » (61), voit les conversations les plus récentes d'abord avec
le nombre de non-lus, répond, envoie une photo ou partage un de ses produits publiés (62).
L'accueil de la vendeuse montre ses messages non lus.

**Acceptance Scenarios**:

1. **Given** un message non lu, **When** Fatou ouvre la conversation, **Then** il est marqué
   lu et le compteur baisse.
2. **Given** un produit d'une autre boutique ou non publié, **When** Fatou tente de le
   partager, **Then** c'est refusé.
3. **Given** une conversation d'une autre boutique, **When** Fatou tente de la lire ou d'y
   écrire, **Then** c'est refusé.

### Edge Cases

- Boutique suspendue ou fermée : la conversation reste lisible ; écrire à une boutique non
  active est refusé pour une nouvelle conversation.
- Une vendeuse ne s'écrit pas à elle-même.
- Envoi rejoué (réseau instable) : la clé d'idempotence évite le doublon.
- Hors ligne : le fil déjà chargé reste affiché, l'envoi échoue avec un message clair.

## Requirements *(mandatory)*

- **FR-001**: Une conversation par (cliente, boutique), ouverte par la cliente sur une
  boutique active.
- **FR-002**: Messages texte (1 à 1 000 caractères), image (clé dans l'espace privé de la
  conversation) ou produit (publié, de la boutique de la conversation) ; seuls la cliente et
  la propriétaire de la boutique écrivent et lisent ; idempotence par clé.
- **FR-003**: Non-lus par conversation et au total, pour la cliente et la vendeuse ; ouvrir
  une conversation la marque lue.
- **FR-004**: Notification « Nouveau message » au destinataire (catégorie messages) et push
  selon ses préférences ; le contenu n'apparaît pas dans le push.
- **FR-005**: Images dans un stockage privé ; liens de lecture signés et courts, délivrés
  aux seules participantes.
- **FR-006**: Le fil se relit régulièrement quand il est ouvert (réseau 3G) ; les nouveaux
  messages arrivent aussi par push.
- **FR-007**: Écrans 60 à 62 : vide, chargement, erreur, hors ligne ; sept tailles, texte
  130 %, français et anglais.

## Success Criteria *(mandatory)*

- **SC-001**: Awa envoie une question à une boutique en moins de 20 secondes.
- **SC-002**: Aucune lecture ni écriture hors des participantes (pgTAP).
- **SC-003**: Aucun doublon de message sur rejeu (pgTAP).

## Assumptions

- **Temps réel** : relecture périodique et push plutôt qu'un flux SSE (voir le plan).
- **« Vu », horodatage détaillé (C-CHAT-03)** : P1, hors périmètre ; l'heure d'envoi est
  affichée.
- **Délai de réponse moyen** de la maquette 60 : non construit (aucun identifiant).
