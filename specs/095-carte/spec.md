# Feature Specification: Carte DYM

**Feature Branch**: `feat/095-carte`

**Created**: 2026-11-16

**Status**: Done

**Input**: Décision du porteur (2026-11-16) : « la carte doit être impeccable » ; la cliente voit
les boutiques sur une carte, filtre par pays, ville, ouvertes et catégorie ; place sa porte ; la
vendeuse voit sa zone de livraison. Phase 15, après la spec 094 (tout par position).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Les boutiques sur la carte (Priority: P1)

Dans l'onglet Marché, la cliente (ou la visiteuse sans compte) passe de la liste à la carte. Chaque
boutique est une épingle carrée à l'icône et aux couleurs de son origine (marché, maison, magasin,
supermarché), grisée si elle est fermée ; les épingles proches se regroupent (nombre affiché, un
toucher zoome). Toucher une épingle ouvre une fiche : boutique, « Livre jusqu'à N km », cercle de
livraison tracé, bouton « Voir la boutique ».

**Acceptance**: le cadre visible commande la liste (relue en base) ; fermées grisées ; fiche et
cercle à la sélection ; états chargement, vide, erreur et hors ligne affichés sur la carte.

### User Story 2 - Filtrer et explorer (Priority: P1)

Puces « Ouvertes », « Tout » et rayons de premier niveau ; « Explorer » liste les villes du pays
puis les autres pays ouverts et cadre la ville choisie ; « Ma position » recentre sur l'appareil.

### User Story 3 - Placer ma porte (Priority: P1)

Dans le formulaire d'adresse, « Placer ma porte » ouvre une carte plein écran : la carte glisse sous
une épingle fixe ; « Valider cet emplacement » enregistre la position exacte et le quartier trouvé
par la base (jamais choisi d'office hors zone).

### User Story 4 - La vendeuse voit sa zone (Priority: P2)

Le réglage « Je livre jusqu'à » montre la carte autour de la boutique et le cercle du rayon, qui
suit le curseur.

## Requirements *(mandatory)*

- **FR-001**: `map_stores(sud, ouest, nord, est, catégorie, ouvertes)` : boutiques actives des
  pays et villes visibles dont la position tombe dans le cadre ; catégorie principale ou produit
  publié de la catégorie (sous-catégories comprises) ; lecture anonyme et authentifiée ; 300 au plus.
- **FR-002**: package `dym_map` (décision 0022) : `DymMap` derrière `DymMapEngine` (MapLibre par
  défaut, moteur factice pour les tests), style aux couleurs DYM sur les tuiles OpenFreeMap,
  épingles dessinées par type, regroupement, zones, `DymPinPlacer`.
- **FR-003**: quartiers du référentiel avec leur centre (`latitude`, `longitude`).
- **FR-004**: `store_map_viewed` (boutiques, filtre ouvertes, filtre catégorie ; jamais la position).
- **FR-005**: textes en français et en anglais ; icône et libellé sur chaque action.

## Hors périmètre

- Suivi du livreur sur la carte et frais par distance (spec 096).
- Itinéraire et navigation pas à pas.
- Mode sombre de la carte.
