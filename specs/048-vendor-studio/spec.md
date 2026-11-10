# Feature Specification: Partage de la boutique et fin de marché

**Feature Branch**: `feat/048-vendor-studio`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `vendor-studio` de la roadmap (Phase 12, VISION §3 « Vendeuse ») : studio IA,
boutique partageable sur WhatsApp, arrivages, fin de marché. Studio IA (photo → fiche) et arrivages
existent déjà (specs 007, 019, 033) : cette spec ajoute le partage et la fin de marché.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Partager sa boutique (Priority: P1)

1. **Given** une vendeuse, **When** elle touche « Partager sur WhatsApp », **Then** WhatsApp s'ouvre
   avec un message et le lien de sa boutique ; ce lien affiche une page légère qui ouvre la
   boutique dans l'app web (après connexion si besoin).

### User Story 2 - Prix de fin de marché (Priority: P1)

1. **Given** du frais à écouler en fin de journée, **When** la vendeuse lance une remise (10 à 50 %)
   pour 1 à 4 heures, **Then** le prix réduit s'affiche partout (catalogue, fiche, badge « Fin de
   marché ») et s'applique aux commandes passées pendant la période.
2. **Given** une remise en cours, **When** elle l'arrête, **Then** le prix normal revient aussitôt.

### Edge Cases

- Commande passée avant la fin : prix réduit gardé (ligne de commande figée).
- Boutique fermée ou inconnue : page de partage « n'existe plus ».

## Requirements *(mandatory)*

- **FR-001**: Le prix réduit DOIT être calculé par la fonction de prix unique en base.
- **FR-002**: Pourcentage borné (5 à 70 %), durée bornée (1 à 12 h).
- **FR-003**: Événement serveur : `end_of_market_started`.
- **FR-004**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Prix affiché = prix payé, à l'unité près.
