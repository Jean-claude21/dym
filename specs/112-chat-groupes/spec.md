# Feature Specification: Groupes de discussion

**Feature Branch**: `feat/112-chat-groupes`

**Created**: 2026-11-17

**Status**: Done

**Input**: Suite de la spec 111 (« ensuite les groupes : espace famille, achat groupé »), retenue
par le porteur. VISION §3 : « la famille qui remplit et paie », « achat groupé entre voisins ».
Pas de maquette : conception déléguée, vérifiée sur capture.

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** Une cliente crée un **groupe famille** (« Nouveau groupe » dans Messages) ; elle en
  est l'administratrice. Elle ajoute ses proches par leur code DYM (écran « Entre proches »),
  20 personnes au plus ; chaque personne ajoutée est prévenue.
- **US2 (P1)** Dans le groupe, tout le monde écrit et partage tout ce que permet le chat (spec 111),
  dont des produits de n'importe quelle boutique. Le prénom s'affiche au-dessus des messages des
  autres ; la notification porte le nom du groupe, jamais le message.
- **US3 (P1)** Chaque personne a sa lecture : non lus, « Nouveaux messages », ✓✓ « vu » quand tout
  le groupe a lu, « reçu » quand toutes les apps l'ont reçu ; « Mia écrit… ».
- **US4 (P2)** Infos du groupe : membres, administratrice ; l'administratrice ajoute, retire,
  renomme ; les autres peuvent quitter.
- **US5 (P1)** **Achat groupé** : depuis une offre rejointe (cliente) ou une offre qui a des
  membres (vendeuse), « Discuter avec le groupe » ouvre le fil de l'offre, nommé d'après le
  produit, ouvert aux membres et à la boutique.
- **US6 (P2)** Liste : filtre « Groupes », icône famille ou panier, « Awa : … » en aperçu. Pas
  d'appel ni de réponses rapides dans un groupe.

## Requirements *(mandatory)*

- **FR-001** Migration 0101 : `conversations.kind` (`direct`, `order`, `family`, `group_buy`),
  `title`, `group_offer_id`, `store_id` facultatif (famille) ; `conversation_members` (membres de la
  famille, lecture et réception de chacun) ; `conversation_role`, `conversation_json`,
  `my_conversations`, `unread_messages_count`, `conversation`, `send_message`, `message_json`
  (`author_name`, `mine`, réaction `mine`), `live_conversation`, `mark_delivered`, `chat_typing`
  (prénom) adaptés ; `create_family_group`, `group_info`, `group_add_member`,
  `group_remove_member`, `group_rename`, `group_offer_thread` ; notifications `new_message_group`,
  `group_added` ; événements `group_created`, `group_member_added`.
- **FR-002** Modèles, dépôt, service ; `fromMe` décidé par la base dans un groupe.
- **FR-003** `dym_chat` : création, filtre, infos du groupe, prénoms, en-tête « N membres ».
- **FR-004** Apps : « Discuter avec le groupe » (cliente, vendeuse) ; textes des notifications.

## Success Criteria

- pgTAP 900 (24) ; tests `dym_chat` (5 nouveaux) ; analyse ; parcours vérifié sur l'émulateur.

## Hors périmètre

- Appels de groupe ; groupe de plusieurs boutiques ; partage du panier familial (spec à venir si
  le porteur la demande).
