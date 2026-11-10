# Feature Specification: Suivi en direct

**Feature Branch**: `feat/044-live-tracking`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `live-tracking` de la roadmap (Phase 11, VISION §3 « Livreur ») : suivi en direct
(GPS simulé), heure d'arrivée, score, bonus, zones.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Voir son livreur arriver (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une commande en route avec un livreur DYM, **When** la cliente ouvre son suivi,
   **Then** elle voit qui arrive, à quelle distance et à quelle heure, calculées en base.
2. **Given** un appareil sans GPS, **When** le livreur est en course, **Then** une position simulée
   approche de la cliente ; le livreur et la cliente en sont prévenus à l'écran.

### User Story 2 - Score du livreur (Priority: P2)

**Acceptance Scenarios**:

1. **Given** une commande livrée par un livreur DYM, **When** la cliente note la remise (1 à 5),
   **Then** la note compte une seule fois et le livreur voit sa moyenne des 50 dernières.

### User Story 3 - Zones et bonus (Priority: P2)

**Acceptance Scenarios**:

1. **Given** des missions en attente dans une zone, **When** leur nombre atteint le seuil du pays,
   **Then** le livreur voit la zone en forte demande et le bonus annoncé.
2. **Given** une course prise dans cette zone, **When** elle est livrée, **Then** DYM verse le bonus
   sur son wallet, fixé à l'acceptation.

### Edge Cases

- Adresse sans coordonnées : le livreur s'affiche, sans distance ni heure.
- Position de plus de 10 minutes : ignorée.
- Bonus du pays à 0 : aucun bonus.

## Requirements *(mandatory)*

- **FR-001**: Distance, heure d'arrivée, score et bonus DOIVENT être calculés en base.
- **FR-002**: Vitesses, seuil et bonus DOIVENT être des données de référence.
- **FR-003**: La position n'est lisible que par la cliente de la commande, et seulement en route.
- **FR-004**: Événement serveur : `courier_rated`, sans donnée personnelle.
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Gate de la phase 11 : une commande livrée de bout en bout par l'app livreur.

## Assumptions

- Pas de carte : distance et heure d'arrivée suffisent à cette étape, sans nouvelle dépendance.
- Distance à vol d'oiseau, faute de service d'itinéraire.
- Le bonus reste à 0 par défaut : l'équipe l'active par pays.
