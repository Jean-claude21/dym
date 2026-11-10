# Feature Specification: App livreur

**Feature Branch**: `feat/041-delivery-app`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `delivery-app` de la roadmap (Phase 11, VISION §3 « Livreur » ; app `dym_delivery`) :
app livreur, inscription, missions, acceptation. Modèle : zems indépendants qui acceptent des missions.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Devenir livreur (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une personne avec un compte DYM (ou qui en crée un dans l'app livreur), **When** elle
   donne son nom, son téléphone, son moyen (à pied, vélo, moto, voiture) et ses zones, **Then**
   elle devient livreur (même compte DYM, rôle ajouté).
2. **Given** un livreur, **When** il se met en ligne, **Then** les missions de ses zones lui sont
   proposées ; hors ligne ou suspendu par l'équipe, aucune.

### User Story 2 - Accepter une mission (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une commande à livrer acceptée par la boutique, **When** la boutique ou la cliente est
   dans une zone du livreur en ligne, **Then** il est prévenu et la voit : boutique, quartiers,
   articles, frais de livraison ; ni téléphone ni repère de la cliente avant acceptation.
2. **Given** deux livreurs, **When** ils acceptent la même mission, **Then** un seul l'obtient ; la
   boutique et la cliente savent qui livre.
3. **Given** trop de courses en cours (limite du pays), **Then** l'acceptation est refusée.

### User Story 3 - Récupérer et livrer (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une mission acceptée, **When** la boutique l'a déclarée prête, **Then** le livreur la
   marque récupérée, puis livrée ; la cliente et la boutique sont prévenues.
2. **Given** une mission pas encore récupérée, **When** le livreur ne peut plus, **Then** il la rend
   et elle revient aux autres.

### Edge Cases

- Ses propres commandes ou celles de sa boutique : jamais proposées.
- Commande annulée ou refusée : disparaît des missions.
- États vide, chargement, erreur et hors ligne sur chaque écran.

## Requirements *(mandatory)*

- **FR-001**: Proposition, acceptation et transitions DOIVENT être décidées en base (rôle `courier`
  de la machine d'états).
- **FR-002**: Limite de courses simultanées : réglage du pays.
- **FR-003**: Événements serveur : `courier_joined`, `courier_online`, `courier_offline`,
  `mission_accepted`, `mission_released` ; `order_delivered` porte le rôle livreur.
- **FR-004**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Gate de la phase 11 (avec les specs suivantes) : une commande livrée de bout en bout
  par l'app livreur.

## Assumptions

- Code de remise, tournées multi-boutiques : spec `delivery-routing`. Gains et cash : spec
  `delivery-cash`. Position en direct : spec `live-tracking`.
- Inscription sans validation préalable pendant la phase de test ; l'équipe peut suspendre.
