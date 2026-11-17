# Feature Specification: La position décide du pays

**Feature Branch**: `feat/110-position-pays`

**Created**: 2026-11-17

**Status**: Done

**Input**: Retour du porteur (2026-11-17) : « je charge la localisation à Rouen, je vois Lomé ».
Cause : le pays venait du profil (inscription au Togo) et la recherche du quartier le plus proche
était limitée à ce pays.

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** Au premier affichage de l'accueil, la position est cherchée dans tous les pays
  ouverts. Ailleurs que le lieu affiché (autre ville, autre pays) : « Tu es à Rouen · Voir les
  boutiques de Rouen ». En un geste : quartier, pays, devise, rayons et boutiques suivent ; le
  profil aussi.
- **US2 (P1)** Panier rempli dans un autre pays : « Vider le panier » ou « Garder pour plus tard »
  (une commande ne mélange jamais deux pays).
- **US3 (P2)** Choix du quartier : les pays ouverts en puces, puis leurs quartiers.

## Requirements *(mandatory)*

- **FR-001** Migration 0099 : `set_my_place` (quartier et pays du profil, panier d'un autre pays
  signalé), `cart_clear`, événement `place_changed`.
- **FR-002** App cliente : `nearest_zone` sans filtre de pays ; `moveTo` ; référentiels des services
  gardés par pays ; bandeaux « Tu es à … » et panier d'un autre pays ; puces des pays.
