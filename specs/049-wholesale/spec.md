# Feature Specification: Achat de gros groupé

**Feature Branch**: `feat/049-wholesale`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `wholesale` de la roadmap (Phase 12, VISION §3 « Vendeuse » : meilleures marges) :
achat de gros groupé.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - La grossiste ouvre une offre (Priority: P1)

1. **Given** une boutique déclarée grossiste, **When** elle publie une offre sur un de ses produits
   (prix de gros à l'unité, quantité minimale, 3 à 14 jours), **Then** les vendeuses de son pays la
   voient.
2. **Given** le minimum atteint, **When** elle confirme, **Then** chaque acheteuse est prévenue de sa
   quantité ; elle peut aussi annuler.

### User Story 2 - Les vendeuses réservent ensemble (Priority: P1)

1. **Given** une offre ouverte, **When** une vendeuse réserve une quantité (0 pour se retirer),
   **Then** la jauge monte ; elle ne voit pas les quantités des autres.

### Edge Cases

- Pas de réservation sur sa propre offre, ni après la date limite ou la décision.
- Confirmation refusée tant que le minimum n'est pas atteint.
- Le règlement se fait avec la grossiste, hors de DYM.

## Requirements *(mandatory)*

- **FR-001**: Jauge, minimum, statut et notifications DOIVENT être décidés en base.
- **FR-002**: Événements serveur : `wholesale_offer_opened`, `wholesale_committed`.
- **FR-003**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une vendeuse réserve en moins de 3 gestes.

## Assumptions

- Le paiement en ligne de l'achat de gros (acompte, séquestre) viendra avec une décision dédiée.
