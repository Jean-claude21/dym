# Feature Specification: Import du catalogue (supermarchés)

**Feature Branch**: `feat/081-import-catalogue`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Point 9 de la liste validée par le porteur (2026-11-13) : supermarchés — import en masse
du catalogue, personnel multiple, succursales. Features V-CAT-01, V-CAT-07.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mettre des centaines de produits en ligne (Priority: P1)

Catalogue → « Importer » : la vendeuse colle ses lignes depuis un tableur (nom, prix, unité, rayon,
stock ; tabulation, point-virgule ou virgule), « Vérifier » montre les lignes prêtes et les erreurs
ligne par ligne (« Ligne 3 : rayon inconnu »), « Importer 120 produits » crée des brouillons ;
photos et publication ensuite.

### Edge Cases

- Plus de 500 lignes : refusé (importer en plusieurs fois).
- Prix « 1 200 », « 12,50 » : lus selon les décimales de la devise.
- Rayon et unité reconnus par libellé (fr, en) ou code.

## Requirements *(mandatory)*

- **FR-001**: contrôle et création en SQL (`import_products`, aperçu `p_dry`), via `save_product`.
- **FR-002**: événement `products_imported`.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 670 ; tests de lecture des lignes, du viewmodel et de l'écran ; capture relue.

## Reporté (décision du porteur nécessaire)

- Personnel multiple et succursales : touchent aux droits (qui encaisse, retire l'argent, change les
  prix) ; à cadrer avant de construire.
