# Feature Specification: La journée de la vendeuse

**Feature Branch**: `feat/076-journee-vendeuse`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Point 4 de la liste validée par le porteur (2026-11-13) : un accueil qui dit « voici quoi
faire maintenant », le stock en un geste lisible, l'ajout de produit rapide. Features V-DASH-01..05,
V-CAT-03.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Savoir quoi faire en ouvrant l'app (Priority: P1)

Commandes en attente : carte pêche tout en haut, « 3 commandes attendent ta réponse · Réponds avant
13:35 », « Répondre ».

### User Story 2 - Voir si la journée va mieux qu'hier (Priority: P2)

Sous les ventes encaissées : « ▲ 13 % vs hier à la même heure » (semaine, mois : période précédente).

### User Story 3 - Stock lisible (Priority: P1)

Sous l'interrupteur du catalogue, le libellé suit l'état : « En stock » ou « Rupture » (rouge).

### Edge Cases

- Pas de vente hier : pas d'évolution affichée.

## Requirements *(mandatory)*

- **FR-001**: comparaison et heure limite calculées en SQL (`my_vendor_dashboard`).

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 640 ; tests d'évolution et du catalogue ; captures relues.
