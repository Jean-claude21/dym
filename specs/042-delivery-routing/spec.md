# Feature Specification: Tournées et remise

**Feature Branch**: `feat/042-delivery-routing`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `delivery-routing` de la roadmap (Phase 11, VISION §3 « Livreur ») : tournées
multi-boutiques, code de remise, consignes de conservation.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Une tournée pour un achat (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une cliente qui commande chez plusieurs boutiques en un achat, **When** un livreur
   accepte une de ces courses, **Then** il prend toute la tournée (chaque boutique, une seule
   remise) ; chaque boutique sait qui vient.
2. **Given** la limite de courses du pays, **Then** une tournée compte pour une course.

### User Story 2 - Remise prouvée par un code (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une commande prise par un livreur DYM, **When** la cliente ouvre son suivi, **Then**
   elle voit un code à 4 chiffres.
2. **Given** le livreur chez la cliente, **When** il saisit ce code, **Then** la commande est
   livrée ; un mauvais code est refusé, et après 5 erreurs l'équipe prend le relais.

### User Story 3 - Le frais arrive frais (Priority: P2)

**Acceptance Scenarios**:

1. **Given** les articles d'une course, **When** le livreur la voit, **Then** il lit les consignes
   (au frais, surgelé, fragile, ambiant) : celle du produit, sinon celle de son rayon.

### Edge Cases

- Livreur saisi à la main par l'équipe (spec 013) : pas de code ; la vendeuse conclut comme avant.
- Commande livrée : le code disparaît.

## Requirements *(mandatory)*

- **FR-001**: Tournée, code, essais et consignes DOIVENT être décidés en base.
- **FR-002**: Consignes des rayons : données de référence ; produit : réglage de la vendeuse.
- **FR-003**: Événements serveur : `run_accepted`, `handover_code_failed`.
- **FR-004**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Aucune commande livrée par un livreur DYM sans le code de la cliente.

## Assumptions

- Ordre des arrêts : boutiques de la tournée, puis la cliente ; l'itinéraire viendra avec le suivi
  en direct (spec `live-tracking`).
- Le réglage de la consigne par produit est exposé en base (`set_product_storage`) ; son écran
  rejoindra le formulaire produit à la prochaine maquette validée.
