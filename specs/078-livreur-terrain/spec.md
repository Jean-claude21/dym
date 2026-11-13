# Feature Specification: Le livreur sur le terrain

**Feature Branch**: `feat/078-livreur-terrain`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Point 6 de la liste validée par le porteur (2026-11-13) : course proposée, itinéraire,
remise du cash, lisible en plein soleil. Features L-01..L-04.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Joindre et trouver (Priority: P1)

Sur la course en cours, la boutique et la cliente ont chacune « Appeler » (composeur) et
« Itinéraire » (app de cartes du téléphone, sinon une page de carte).

### Edge Cases

- Position inconnue : pas de bouton « Itinéraire » ; numéro inconnu : pas de bouton « Appeler ».
- Course proposée (pas encore acceptée) : aucun bouton (rien n'est communiqué avant).

## Requirements *(mandatory)*

- **FR-001**: liens `tel:` et `geo:` ouverts par le téléphone ; aucun fournisseur de carte imposé.

## Success Criteria *(mandatory)*

- **SC-001**: tests de l'app livreur ; capture relue.
