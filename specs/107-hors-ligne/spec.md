# Feature Specification: Hors ligne et premier écran

**Feature Branch**: `feat/107-hors-ligne`

**Created**: 2026-11-17

**Status**: Done

**Input**: « Reste à faire » de la spec 062 (performance terrain), PARCOURS §5 et §8 : Android 2 Go,
3G instable, données chères ; Akossiwa met un produit en rupture au marché, réseau faible.

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** Sans réseau, l'app s'ouvre sur la dernière visite : pays, boutiques, accueil, fil
  (lectures gardées sur l'appareil, rendues seulement quand le réseau manque ; effacées à la
  déconnexion).
- **US2 (P1)** La vendeuse met un produit en rupture sans réseau : l'interrupteur garde le geste,
  « 1 geste gardé hors ligne » s'affiche, le geste part tout seul au retour du réseau (au chargement,
  puis toutes les 30 s) ; s'il est refusé, l'écran revient à l'état réel.
- **US3** Vidéo selon le réseau : lecture adaptative (HLS) et économie de données (spec 103).

## Décisions

- Pas de panier hors ligne côté cliente : prix et stock doivent être confirmés en direct ; un ajout
  sans réseau afficherait des articles et des totaux faux.
- Stockage : décision 0023.

## Requirements *(mandatory)*

- **FR-001** `LocalJsonStore`, `FileJsonStore`, `OfflineQueue` (dym_platform).
- **FR-002** `OfflineReadCache` (neon_kit) branché par `createNeonClient` dans les quatre apps.
- **FR-003** Catalogue de la vendeuse : rupture hors ligne gardée et rejouée.
