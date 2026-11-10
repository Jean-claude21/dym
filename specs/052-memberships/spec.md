# Feature Specification: DYM+, vendeuse Pro, visibilité sponsorisée

**Feature Branch**: `feat/052-memberships`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `memberships` de la roadmap (Phase 13 « Différence ») : DYM+, vendeuse Pro, visibilité
sponsorisée.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - La cliente prend DYM+ (Priority: P1)

1. **Given** une formule DYM+ dans son pays, **When** la cliente la prend, **Then** le prix est payé
   depuis son wallet, et la formule est active pour sa durée ; un nouvel achat la prolonge.
2. **Given** DYM+ active au moment de l'achat, **When** une commande est livrée, **Then** ses frais de
   livraison et un cashback en plus sont versés sur son wallet (le livreur garde ses frais).

### User Story 2 - La vendeuse prend Pro ou « À la une » (Priority: P1)

1. **Given** la formule Pro, **When** une commande est passée, **Then** la commission DYM est réduite.
2. **Given** « À la une », **When** une cliente d'un quartier qu'elle livre ouvre l'accueil, **Then**
   la boutique apparaît dans « À la une », signalée « Sponsorisé ».

### Edge Cases

- Wallet insuffisant : refus, rien n'est débité.
- Rejeu de la même demande : un seul paiement.
- Formule d'un autre pays ou d'une autre devise : refusée.

## Requirements *(mandatory)*

- **FR-001**: Formules (prix, durée, avantages) DOIVENT être des données de référence par pays.
- **FR-002**: Paiement, avantages et commission DOIVENT être décidés en base et tracés au grand livre.
- **FR-003**: Événements serveur : `membership_started`, `member_benefit_paid`.
- **FR-004**: Les textes DOIVENT exister dans chaque langue ; le sponsorisé est toujours signalé.

## Success Criteria *(mandatory)*

- **SC-001**: Prendre une formule en 1 geste depuis l'écran.

## Assumptions

- Formules de départ du Togo (prix validés par le porteur produit le 2026-11-11) : DYM+ 1 500 F / 30 jours,
  Vendeuse Pro 3 000 F / 30 jours, « À la une » 1 000 F / 7 jours. L'écran d'administration des
  formules relève de `ops-center`.
- Pas de renouvellement automatique : la personne prolonge elle-même.
