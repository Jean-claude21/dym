# Feature Specification: Messagerie claire et fiable

**Feature Branch**: `feat/070-chat-ergonomie`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Le porteur (2026-11-13) : « améliore l'ergonomie de tout le chat… fais tout le chat
proprement ». Features C-15 (messagerie cliente) et V-08 (messagerie vendeuse), maquettes 60, 61, 62.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lire un fil d'un coup d'œil (Priority: P1)

Les messages sont groupés par jour (« Aujourd'hui », « Hier », date) ; chaque bulle porte son heure.
Mes messages indiquent « envoyé » (✓) puis « vu » (✓✓) quand l'autre personne a ouvert la
conversation. Les messages qui se suivent sont rapprochés.

### User Story 2 - Écrire même avec un réseau instable (Priority: P1)

Le message apparaît aussitôt (horloge), puis se confirme. En échec : « Non envoyé », avec
« Réessayer » et « Supprimer » ; au retour du réseau, il repart seul. Une même clé est gardée : aucun
doublon.

### User Story 3 - Répondre vite (Priority: P1)

Des réponses rapides apparaissent au-dessus du champ quand il est vide : côté cliente « C'est
disponible ? », « Quel est le prix ? », « Vous livrez aujourd'hui ? », « Merci ! » ; côté vendeuse
« Oui, c'est disponible. », « Désolée, ce n'est plus disponible. », « Je prépare votre commande. »,
« Merci pour votre commande ! ». Champ vide : le bouton devient micro (si vocaux disponibles).

### User Story 4 - Parler d'un produit, proposer un panier (Priority: P2)

Le bouton « Joindre » ouvre : produit, appareil photo, galerie. La cliente montre un produit de la
boutique ; la vendeuse coche un ou plusieurs de ses produits (« panier proposé »), que la cliente
ajoute au panier depuis la conversation.

### User Story 5 - Garder la commande en vue (Priority: P2)

Une commande en cours entre la cliente et la boutique est rappelée en tête du fil (statut, total) et
s'ouvre d'un toucher. La cliente ouvre la boutique depuis l'en-tête. Toucher la notification d'un
message ouvre la conversation.

### Edge Cases

- Hors ligne : derniers messages affichés, bandeau discret, envois gardés en attente.
- Commande refusée, annulée ou livrée : plus de bandeau.
- Plus de 6 conversations : champ de recherche (prénom ou boutique).

## Requirements *(mandatory)*

- **FR-001**: `conversation` renvoie `peer_read_at` et `active_order` (SQL, RLS inchangée).
- **FR-002**: envois optimistes avec clé d'idempotence conservée ; renvoi automatique sur erreur
  transitoire seulement.
- **FR-003**: textes des réponses rapides dans `dym_l10n` ; aucune règle de prix dans l'app.
- **FR-004**: `conversation_id` dans les données du push d'un message.
- **FR-005**: événement serveur `chat_message_sent` (type, rôle, commande en cours).

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 580 (vu, commande en cours, mesure) ; tests du viewmodel (échec, renvoi,
  abandon, jours, réponses rapides, recherche, panier proposé) ; écrans 60–62 aux 7 tailles.
- **SC-002**: captures relues avec la grille (`docs/design/REVUE_CAPTURES.md`).
