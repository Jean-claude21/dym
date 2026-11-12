# Feature Specification: Rayon de service par ville

**Feature Branch**: `feat/065-coverage-radius`

**Created**: 2026-11-12

**Status**: Draft

**Input**: Constat du porteur (2026-11-12) : à l'inscription, des quartiers de Lomé sont proposés
alors que DYM est multi-pays. Les pays, villes et quartiers sont bien des données, mais le quartier
le plus proche est pris sans limite de distance : une personne à Abidjan serait rattachée à Lomé.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Position hors zone (Priority: P1)

Une personne trop loin de tout quartier desservi voit « DYM n'est pas encore chez toi ». Aucun pays
ni quartier ne lui est imposé ; elle peut choisir un quartier desservi (commander pour un proche).
Même règle à l'inscription (quatre apps), sur l'accueil de la cliente et dans l'adresse de livraison.

**Acceptance**: position à 640 km : message hors zone, quartier vide ; choix manuel possible.

### User Story 2 - Rayon réglé par l'équipe (Priority: P1)

Chaque ville a un rayon de service (15 km par défaut, de 1 à 200 km), modifiable dans Configuration
et journalisé avec l'avant et l'après.

### User Story 3 - Savoir où ouvrir (Priority: P2)

Le tableau de bord affiche les positions hors zone de la période par pays le plus proche, avec la
distance médiane. L'événement ne contient jamais la position.

### Edge Cases

- Position refusée : comportement inchangé (liste des pays actifs et des quartiers).
- Ancienne réponse sans `covered` : considérée comme couverte.

## Requirements *(mandatory)*

- **FR-001**: `cities.service_radius_m` (données, pas de constante) ; `nearest_zone` renvoie
  `covered` et `service_radius_m`.
- **FR-002**: événement client `location_outside_coverage` (pays, km, app).
- **FR-003**: `admin_coverage(période)` réservé à l'équipe.
- **FR-004**: aucun texte en dur.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP (10 assertions) : couvert, hors zone, rayon refusé au-delà de 200 km, rayon
  élargi, comptage par pays, accès réservé.
- **SC-002**: tests des viewmodels (inscription, accueil, adresse) ; analyse et tests verts.
