# Feature Specification: Livraison suivie par tous

**Feature Branch**: `feat/109-suivi-livraison-complet`

**Created**: 2026-11-17

**Status**: Done

**Input**: Notes du porteur (2026-11-17) : « les livreurs doivent avoir le chat ; les livreurs, les
vendeurs et les clients suivent la carte ; itinéraire pour aller chez le vendeur ; quand le livreur
part livrer, tout le monde le suit ; le vendeur sait que sa commande est livrée à la confirmation
finale ». Décision : groupes de discussion liés à un achat ; le fil de commande d'abord.

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** Fil de commande : dès qu'un livreur est affecté, la cliente, la boutique et le livreur
  échangent dans une même conversation (texte, photo, vocal, position ; le livreur n'envoie ni fiche
  ni devis). Chaque message prévient les deux autres. Lecture seule 24 h après la remise.
- **US2 (P1)** Carte de la livraison, la même pour les trois : boutique, porte, livreur, itinéraire
  tracé (livreur → boutique → porte, puis livreur → porte), étape en clair, minutes restantes,
  relue toutes les 10 s. Sans itinéraire : ligne droite en pointillés.
- **US3 (P1)** La vendeuse voit le livreur venir, repartir, puis « Livrée et confirmée par le code » ;
  elle est prévenue à la remise (notification `courier_delivered`, déjà en place).
- **US4 (P2)** Le livreur garde « Itinéraire » vers l'app de cartes du téléphone.

## Requirements *(mandatory)*

- **FR-001** Migration 0098 : `conversations.order_id`, `courier_id`, `courier_read_at` ; une seule
  conversation directe par cliente et boutique (index partiel) ; rôle `courier` ; `order_thread`,
  `app.order_thread_closed` ; envoi, temps réel, non-lus et liste étendus ; `new_message_courier`.
- **FR-002** Functions : `POST /v1/route` (OSRM derrière `RouteProvider`, cache 10 min ; `ROUTING_URL`,
  serveur public de démonstration par défaut sur staging).
- **FR-003** `dym_map` : tracés d'itinéraire (`DymMapRoute`).
- **FR-004** Package `dym_order_live` (cliente, vendeuse, livreur) : `OrderLiveCard`.
- **FR-005** `dym_chat` : rôle livreur, fil à plusieurs (nom de l'auteur, titre, réponses rapides,
  fil fermé) ; apps : boutons « Discuter » et carte dans les trois apps.

## Limites et suite

- Serveur d'itinéraire public (OSRM de démonstration) : à remplacer par un serveur à soi (Coolify)
  ou un fournisseur avant la production (`ROUTING_URL`).
- Groupes de l'espace famille et de l'achat groupé : spec suivante, si validée.
