# Feature Specification: Paiement par QR

**Feature Branch**: `feat/046-qr-payments`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `qr-payments` de la roadmap (Phase 12) : paiement et encaissement par QR.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - La vendeuse encaisse (Priority: P1)

1. **Given** une vendeuse dans « Ma caisse », **When** elle tape un montant, **Then** un QR et un
   code à 6 chiffres s'affichent (10 minutes) ; l'écran passe à « Payé ! » dès le paiement.

### User Story 2 - La cliente paie (Priority: P1)

1. **Given** une cliente dans son wallet, **When** elle scanne le QR (ou tape le code), **Then** elle
   voit la boutique et le montant, confirme, et paie depuis son wallet, une seule fois.
2. **Given** un wallet insuffisant, un code inconnu, expiré ou déjà payé, ou sa propre boutique,
   **Then** le paiement est refusé avec un message clair.

### Edge Cases

- Caméra refusée ou absente : saisie du code.
- La vente payée apparaît dans « Ma caisse » (moyen « Wallet DYM »).
- Pays différent de la boutique : refusé.

## Requirements *(mandatory)*

- **FR-001**: Montant, solde, commission et statut DOIVENT être décidés en base, au grand livre.
- **FR-002**: Commission : réglage du pays (`qr_commission_bps`, 0 par défaut).
- **FR-003**: Événement serveur : `qr_paid`.
- **FR-004**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Gate de la phase 12 : vente hors app et QR enregistrés au grand livre.
