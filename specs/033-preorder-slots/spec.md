# Feature Specification: Précommande et créneaux

**Feature Branch**: `feat/033-preorder-slots`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `preorder-slots` de la roadmap (Phase 9, VISION §3) : précommande à prix bloqué,
arrivages réservés, créneaux de livraison. Les courses récurrentes sont livrées par la spec 029.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Choisir son créneau (Priority: P1)

**Acceptance Scenarios**:

1. **Given** un panier, **When** la cliente passe commande, **Then** elle choisit « Dès que
   possible » ou un jour (aujourd'hui à J+7, selon le pays) et un créneau (08 h–10 h…) ; les
   créneaux passés ou trop proches (préparation) ne sont pas proposés.
2. **Given** une commande programmée, **When** la cliente ou la vendeuse la suit, **Then** le
   créneau est affiché à la place de l'heure estimée.

### User Story 2 - Précommander un arrivage à prix bloqué (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une vendeuse, **When** elle indique la date d'arrivage d'un produit, **Then** la fiche
   affiche « Arrivage le … · prix bloqué ».
2. **Given** un panier qui contient un arrivage, **When** la cliente commande, **Then** un créneau à
   partir de la date d'arrivage est obligatoire ; le prix payé est celui du jour de la commande.
3. **Given** un créneau antérieur à l'arrivage, **When** elle commande, **Then** c'est refusé.

### Edge Cases

- Créneau d'un autre pays, jour hors limite ou créneau passé : refusé (rien n'est créé).
- Boutique fermée au début du créneau : refusé, la cliente choisit un autre créneau.
- Date d'arrivage passée : refusée à la saisie ; un arrivage dépassé redevient un produit normal.

## Requirements *(mandatory)*

- **FR-001**: Créneaux et horizon (jours) DOIVENT être des données de référence par pays.
- **FR-002**: La validation du créneau DOIT être faite en base, dans la même transaction que la
  création de la commande.
- **FR-003**: Le prix d'un arrivage DOIT être celui de la commande (déjà figé par ligne).
- **FR-004**: Événements serveur : `order_scheduled` (jours d'avance, précommande : oui/non),
  `product_arrival_set`.
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une cliente reçoit sa commande dans le créneau choisi, affiché des deux côtés.
- **SC-002**: Aucune commande programmée hors des règles (pgTAP).

## Assumptions

- Réservation d'argent pour une précommande : poche « précommande » du wallet (spec 025).
- Tournées et capacité par créneau : app livreur (phase 11).
