# Feature Specification: Notifications, suite

**Feature Branch**: `feat/080-notifications-suite`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Point 8 de la liste validée par le porteur (2026-11-13) : grande photo du produit, rappels
utiles (« ton panier t'attend »), boutons d'action. Suite de la spec 072.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Voir le produit dans la notification (Priority: P1)

Les notifications d'une commande montrent la photo du produit principal (si l'adresse publique des
photos est configurée).

### User Story 2 - Être rappelée d'un panier oublié (Priority: P1)

Panier laissé plus de 3 h : « Ton panier t'attend — Tomates et 1 autre article : finalise ta commande
en un geste. » Une fois par jour au plus, de 9 h à 20 h (heure du pays), jamais après une commande.
Toucher le rappel ouvre le panier (push et centre de notifications).

### Edge Cases

- Sans `MEDIA_PUBLIC_URL` : push sans photo.

## Requirements *(mandatory)*

- **FR-001**: règles du rappel en SQL (`app.remind_carts`), lancé par la tâche de 5 minutes.
- **FR-002**: événement `cart_reminded`.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 660 ; tests Functions (photo) ; tests cliente.

## Reporté

- Boutons d'action dans la notification (« Accepter », « Répondre ») : demandent un traitement en
  arrière-plan sur le téléphone, à valider sur un vrai appareil dans une spec dédiée.
