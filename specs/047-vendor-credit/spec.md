# Feature Specification: Ardoise et relances

**Feature Branch**: `feat/047-vendor-credit`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `vendor-credit` de la roadmap (Phase 12, VISION §3 « Vendeuse » : faire crédit sans
rien perdre) : ardoise, relances.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tenir l'ardoise (Priority: P1)

1. **Given** une vendeuse, **When** elle ouvre l'ardoise d'une cliente (nom, téléphone, plafond
   facultatif), **Then** elle y inscrit ce que la cliente prend à crédit et ce qu'elle rembourse ;
   le dû et le total de l'ardoise sont calculés en base.
2. **Given** un plafond atteint ou un remboursement supérieur au dû, **Then** c'est refusé.

### User Story 2 - Relancer (Priority: P1)

1. **Given** une cliente qui doit, avec un téléphone, **When** la vendeuse relance, **Then**
   WhatsApp s'ouvre avec un message poli (nom, dû, boutique) ; une relance par jour au plus.

### Edge Cases

- Ardoise soldée : retirée de la liste, gardée en base.
- Double envoi : une ligne par clé d'idempotence.
- L'argent ne transite pas par DYM : rien au grand livre.

## Requirements *(mandatory)*

- **FR-001**: Dû, plafond et fréquence des relances DOIVENT être décidés en base.
- **FR-002**: Événements serveur : `credit_given`, `credit_repaid`, `credit_reminded`, sans donnée
  personnelle.
- **FR-003**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Une vendeuse note un crédit en moins de 15 secondes.

## Assumptions

- La cliente n'est pas reliée à son compte DYM (pas de recherche par téléphone, pour la vie
  privée) ; une ardoise visible côté cliente viendra avec un consentement explicite.
