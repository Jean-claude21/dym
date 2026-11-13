# Feature Specification: Pilotage admin de haut niveau

**Feature Branch**: `feat/073-admin-pilotage`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Le porteur (2026-11-13) : « l'interface d'admin doit être améliorée… plus grands, plus
propres, les graphes… les choses sont coincées ». Features A-01 (tableau de bord), A-02 (alertes).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Savoir en dix secondes si la journée va bien (Priority: P1)

Six chiffres en grand (ventes, commandes, panier moyen, livraisons et paiements réussis,
inscriptions), chacun comparé à la période précédente au même moment (▲/▼, vert ou rouge) avec sa
mini-courbe ; chaque chiffre ouvre l'écran où agir.

### User Story 2 - Voir l'évolution et le parcours d'achat (Priority: P1)

Courbe par heure (jour) ou par jour (semaine, mois) avec axes et valeur au survol, au choix
commandes, ventes ou livrées ; entonnoir clientes actives → produit vu → panier → commande → livrée.

### User Story 3 - Traiter d'abord ce qui bloque (Priority: P1)

« À traiter » en tête : commandes bloquées, courses sans livreur, litiges, tickets, boutiques en
brouillon, chacun cliquable ; « Rien à traiter » quand tout va bien.

### User Story 4 - Lire chaque bloc sans effort (Priority: P2)

Issue des commandes et boutiques par type en anneau ; livraisons et échanges en grands chiffres ;
classement des boutiques en tableau ; rayons et produits en barres.

### Edge Cases

- Rien sur la période précédente : « nouveau » au lieu d'un pourcentage.
- Téléphone : chiffres sur deux colonnes, cartes empilées, classement en liste.
- Tablette : deux cartes par ligne.

## Requirements *(mandatory)*

- **FR-001**: `admin_overview` (SQL, réservé à l'équipe) : période courante et précédente au même
  moment, courbe, entonnoir, issues ; mêmes définitions que `admin_dashboard`.
- **FR-002**: graphiques dessinés dans l'app (aucune dépendance nouvelle) ; textes dans `dym_l10n`.
- **FR-003**: lignes « étiquette / valeur » de toute l'admin alignées sur le bord droit.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 620 ; tests du viewmodel ; écran 67 aux 7 tailles, texte 130 % ; captures grand
  écran, tablette et téléphone relues.
