# Feature Specification: Tout par position

**Feature Branch**: `feat/094-position-partout`

**Created**: 2026-11-16

**Status**: Done (frais par distance reportés à la spec 096)

**Input**: Décision du porteur (2026-11-16) : le quartier n'est plus la base ; une boutique ouverte
n'importe où sert les clientes autour d'elle (application mondiale, France ouverte). Phase 15.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Une boutique sert autour d'elle (Priority: P1)

La boutique a une position (adresse de retrait, sinon centre de son quartier) et un rayon de
livraison (5 km par défaut, de 1 à 30 km dans l'app, 500 m à 50 km en base). Elle sert toute
position dans ce rayon, en plus des quartiers cochés (repris tels quels).

**Acceptance**: un quartier non coché mais dans le rayon est servi ; un point hors rayon ne l'est
pas ; rayon hors bornes refusé.

### User Story 2 - La cliente voit les boutiques autour d'elle (Priority: P1)

Avec la position de l'appareil (ou celle de son quartier), la découverte renvoie les boutiques qui
la servent, ouvertes d'abord puis les plus proches, avec la distance (« 1,2 km »). La visiteuse
sans compte aussi.

### User Story 3 - Couvert sans configuration (Priority: P2)

Une position est couverte si elle est dans le rayon d'une ville ou d'une boutique active, sans
quartier à créer d'avance.

## Requirements *(mandatory)*

- **FR-001**: `app.distance_m` (haversine), `app.store_point`, `app.store_serves_point` ;
  `app.store_serves` élargi au rayon ; `stores.delivery_radius_m`.
- **FR-002**: `discover_stores(p_zone, p_limit, p_at, p_latitude, p_longitude)` : tri par distance,
  `distance_m` par boutique ; `store_summary` donne position et rayon.
- **FR-003**: `nearest_zone` couvert aussi par le rayon d'une boutique.
- **FR-004**: vendeuse : réglage « Je livre jusqu'à » (1 à 30 km) ; `update_store` accepte
  `delivery_radius_m`.

## Hors périmètre

- Frais par tranches de distance : avec l'adresse exacte sur la carte (spec 096).
- Zone de livraison dessinée (polygone) : le rayon couvre le besoin ; PostGIS non requis.
