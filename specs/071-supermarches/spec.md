# Feature Specification: Supermarchés

**Feature Branch**: `feat/071-supermarches`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Le porteur (2026-11-13) : « Oui, ajoute les supermarchés. » Les supermarchés et supérettes
vendent aussi des produits frais : ils rejoignent DYM comme une origine de boutique (V-01, C-03).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ouvrir une boutique « Supermarché » (Priority: P1)

À l'étape « Où vends-tu ? », la vendeuse choisit « Supermarché » ; le badge de sa boutique l'indique.

### User Story 2 - Trouver les supermarchés (Priority: P1)

La cliente voit le badge « Supermarché » et peut filtrer la recherche et les rayons sur cette origine.

### Edge Cases

- Illustration dédiée absente : la photo des rayons du magasin est reprise (à remplacer par une photo
  fournie).
- Personnel multiple, succursales, import en masse du catalogue : hors de cette spec (à cadrer).

## Requirements *(mandatory)*

- **FR-001**: origine `supermarche` ajoutée comme donnée de référence (aucune liste dans les apps).
- **FR-002**: badge (icône chariot, couleurs du thème, contraste AA).

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 590 ; tests de référence mis à jour (quatre origines).
