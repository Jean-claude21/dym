# Feature Specification: Recherche tolérante aux fautes

**Feature Branch**: `feat/079-recherche-tolerante`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Point 7 de la liste validée par le porteur (2026-11-13) : trouver « tomates » en deux
secondes, même mal écrit ; filtres supermarché, ouvert, livre aujourd'hui. Features C-SRCH-01..05.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Trouver malgré une faute (Priority: P1)

« tomattes », « tomtes » trouvent « Tomates fraîches » ; l'écran dit « Résultats proches de
« tomattes » ».

### User Story 2 - Filtrer par type de boutique (Priority: P2)

Le filtre d'origine (déjà présent) propose « Supermarché » depuis la spec 071.

### Edge Cases

- Requête de moins de 3 caractères : pas de tolérance (trop de bruit).
- Rien de proche : aucun résultat, comme avant.

## Requirements *(mandatory)*

- **FR-001**: tolérance en SQL (`pg_trgm`, similarité de mots ≥ 0,45) seulement si la recherche
  exacte ne trouve rien ; résultat signalé (`fuzzy`).

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 650.
