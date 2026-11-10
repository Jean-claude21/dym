# Feature Specification: Centre d'opérations, rôles par pays

**Feature Branch**: `feat/053-ops-center`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `ops-center` de la roadmap (Phase 13) : centre d'opérations en direct, rôles par pays.
Les volets IA (antifraude, modération, agent support) font l'objet de la spec 054.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - L'équipe voit un pays en direct (Priority: P1)

1. **Given** un admin, **When** il ouvre « Opérations » et choisit un pays de son périmètre, **Then** il
   voit les commandes des 24 dernières heures par statut, le montant livré, les livreurs en ligne, les
   livraisons sans livreur, les litiges, tickets et signalements ouverts. La vue se rafraîchit seule.
2. **Given** une commande bloquée au-delà du seuil de son statut, **Then** elle apparaît dans « Commandes
   en retard » avec ses minutes d'attente ; un clic ouvre la commande.
3. **Given** un livreur qui doit du cash à DYM, **When** l'équipe le reçoit, **Then** elle le confirme
   d'un geste (grand livre, audit).

### User Story 2 - Réglages des opérations (Priority: P1)

1. **Given** un pays, **When** l'admin change les seuils d'alerte, les poids du fil ou le prix et
   l'activation d'une formule, **Then** c'est enregistré et audité.

### User Story 3 - Rôles par pays (Priority: P2)

1. **Given** un admin sans limite, **When** il limite un autre admin à un pays, **Then** ce dernier ne
   pilote plus que ses pays dans le centre d'opérations, et ne gère pas les limites.

### Edge Cases

- Pays hors périmètre : refusé.
- Seuil hors bornes : refusé par la base.
- Les autres écrans de l'admin restent globaux pour l'instant (à étendre si le terrain le demande).

## Requirements *(mandatory)*

- **FR-001**: Indicateurs, retards, périmètre et réglages DOIVENT être calculés et vérifiés en base.
- **FR-002**: Toute écriture DOIT être écrite dans `audit_log`.
- **FR-003**: Les seuils DOIVENT être des données de référence par pays.

## Success Criteria *(mandatory)*

- **SC-001**: Une commande en retard est visible en moins d'une minute.

## Assumptions

- Les seuils de départ : 10 min en attente, préparation + 20 min, 60 min en route.
