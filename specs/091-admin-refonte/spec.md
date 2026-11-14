# Feature Specification: Refonte de l'admin (console 2026)

**Feature Branch**: `feat/091-admin-refonte`

**Created**: 2026-11-14

**Status**: Done

**Input**: Demande du porteur (2026-11-14) : refondre l'admin dans un style sobre de console
(références Veyra, Acti, Gr8r), maquettes validées dans le chat, puis « implémente ça de bout en
bout et déploie », page de connexion comprise. Features A-ADM-01 (tableau de bord), A-STO-01
(boutiques), A-SET-01 (réglages) : aucune nouvelle fonction, seulement la présentation.

Maquettes validées : [tableau de bord](../../docs/design/screens/admin-2026/tableau-de-bord.webp),
[boutiques](../../docs/design/screens/admin-2026/boutiques.webp).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lire l'activité d'un coup d'œil (Priority: P1)

L'admin ouvre le tableau de bord : six cartes de même gabarit (ventes, boutiques, livraison,
à traiter, commandes dans le temps, parcours des clientes), chacune avec trois chiffres clés,
des barres ou un histogramme et une note de provenance. La période se choisit en haut à droite.

**Acceptance**: les six cartes s'affichent avec les données de la période ; une ligne « À
traiter » ouvre l'écran où agir ; sans alerte, un message le dit.

### User Story 2 - Naviguer dans une console claire (Priority: P1)

Menu latéral groupé par métier (Pilotage, Commerce, Argent, Qualité, Réglages) avec compteurs
(litiges, boutiques à valider, demandes, commandes bloquées), barre du haut avec fil d'Ariane et
compte (déconnexion), contenu sur un panneau blanc. Sur téléphone, le menu passe dans un tiroir.

**Acceptance**: seuls les onglets permis au rôle apparaissent ; le tiroir ouvre chaque page.

### User Story 3 - Gérer les boutiques en tableau (Priority: P2)

Boutiques en tableau (avatar, type, statut, vendeuse), onglets par statut avec leur nombre,
recherche ; la fiche s'ouvre à droite (chiffres clés, historique, actions).

### User Story 4 - Se connecter dans le même style (Priority: P2)

Page de connexion : carte blanche centrée sur le fond de la console, photo du marché encadrée
avec une phrase ; formulaire seul sur téléphone.

### Edge Cases

- Texte agrandi à 130 % et sept tailles d'écran : aucun débordement (tests existants).
- Rôle restreint : groupes vides masqués.

## Requirements *(mandatory)*

- **FR-001**: thème de l'admin (fond, cartes à filet, texte 14 px, titres 24 px) appliqué à
  toutes les pages par les composants partagés (`AdminPage`, `AdminCard`, `AdminPill`).
- **FR-002**: coque `AdminShell` (menu groupé, compteurs, barre du haut, tiroir sur téléphone).
- **FR-003**: tableau de bord en six cartes `AdminMetricCard`, détails sous la grille.
- **FR-004**: boutiques en tableau avec fiche latérale.
- **FR-005**: connexion dans le style de la console.
- **FR-006**: aucun texte en dur (nouvelles clés `dym_l10n`, fr et en).

## Success Criteria

- Analyse et tests de l'admin verts ; captures `refonte_*` relues.
- Admin déployée sur `dym-admin-stg.web.app`.
