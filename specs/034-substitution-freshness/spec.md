# Feature Specification: Remplacement et garantie fraîcheur

**Feature Branch**: `feat/034-substitution-freshness`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `substitution-freshness` de la roadmap (Phase 9, VISION §3) : remplacement validé
par photo, garantie fraîcheur avec remboursement immédiat.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Remplacement validé par photo (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une commande acceptée dont un article manque, et des remplacements autorisés,
   **When** la vendeuse propose un autre produit de sa boutique avec une photo, **Then** la
   cliente est prévenue et voit la photo.
2. **Given** une proposition, **When** la cliente accepte, **Then** la ligne devient le produit
   proposé, même quantité, même prix : pas de mauvaise surprise.
3. **Given** une proposition, **When** la cliente refuse, **Then** le montant de la ligne lui est
   rendu tout de suite sur son wallet (débité du solde de la boutique).

### User Story 2 - Garantie fraîcheur (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une commande livrée depuis moins de 24 h (réglage du pays), **When** la cliente
   signale un article pas frais avec une photo, **Then** le montant de la ligne est rendu tout de
   suite sur son wallet et la vendeuse est prévenue.
2. **Given** la limite mensuelle du pays atteinte, **When** elle signale, **Then** c'est refusé :
   elle passe par « Signaler un problème » (litige, l'équipe tranche).

### Edge Cases

- Remplacement refusé si la cliente ne l'autorise pas, si la commande n'est pas en cours, ou si le
  produit proposé n'est pas de la boutique.
- Une ligne ne peut être remboursée qu'une fois (refus ou fraîcheur).
- Photos privées : visibles seulement de la cliente et de la vendeuse de la commande.

## Requirements *(mandatory)*

- **FR-001**: Tout crédit DOIT être une transaction équilibrée du grand livre (boutique → wallet),
  idempotente par ligne.
- **FR-002**: Délai et limite mensuelle DOIVENT être des réglages par pays.
- **FR-003**: Le prix d'une ligne remplacée NE DOIT PAS changer.
- **FR-004**: Événements serveur : `substitution_proposed`, `substitution_answered` (accepté),
  `freshness_claimed` (montant).
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une cliente récupère son argent pour un article pas frais en moins d'une minute.
- **SC-002**: Grand livre équilibré après remplacements refusés et réclamations (pgTAP).

## Assumptions

- Le stock n'est pas ajusté par un remplacement (la vendeuse sert ce qu'elle a).
- Abus répétés : antifraude du centre d'opérations (phase 13).
