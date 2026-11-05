# Feature Specification: Admin du pilote

**Feature Branch**: `feat/017-admin-pilot`

**Created**: 2026-10-10

**Status**: Draft

**Input**: Spec `admin-pilot` de la roadmap (Phase 3 ; A-DASH-01..08, A-ANA-01..03, A-CFG-07,
A-SUP-01..03, A-LIT-07, A-CLI-02, A-VEN-06/07, A-FIN-01/02). Elle est construite avant le gate de la
phase 2 par décision du porteur produit du 2026-10-10 (dérogation consignée dans
`docs/product/ROADMAP.md`).

## Contexte

Pendant le pilote, l'équipe ouvre l'admin le matin et doit savoir en un coup d'œil :

- ce qui tourne : commandes actives, chiffre d'affaires, paiements, livraisons ;
- ce qui coince : commandes bloquées, litiges hors délai, demandes d'aide sans réponse, boutiques en
  brouillon.

Elle répond aux demandes d'aide envoyées depuis les apps (spec 016), consulte le profil d'une
cliente, voit une boutique telle que la vendeuse la voit et suit les revenus de la plateforme. Elle
ouvre aussi, pays par pays, les fonctions de la phase 4.

**Maquettes** à valider : 67 (tableau de bord), 68 (clientes), 69 (support), 70 (revenus).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Le point du matin (Priority: P1)

L'admin s'ouvre sur le tableau de bord (67). Il affiche, pour la période choisie (aujourd'hui,
semaine, mois) :

- commandes actives, chiffre d'affaires encaissé, taux de paiements réussis sur 24 h et sur la
  dernière heure, taux de livraisons réussies ;
- les alertes : commandes bloquées, litiges en attente (dont ceux de plus de 48 h), tickets
  ouverts (dont ceux sans réponse depuis plus d'une heure), boutiques en brouillon. Chaque alerte
  ouvre l'onglet concerné ;
- les commandes des 30 derniers jours, les utilisatrices actives sur 7 jours et les nouvelles
  inscriptions ;
- le top des boutiques, des catégories et des produits.

**Acceptance Scenarios**:

1. **Given** une commande bloquée, **When** l'équipe touche l'alerte, **Then** l'onglet Commandes
   s'ouvre.
2. **Given** un compte non admin, **When** il lit le tableau de bord, **Then** c'est refusé.

### User Story 2 - Répondre aux demandes d'aide (Priority: P1)

Le support (69) liste les demandes ouvertes, en attente et fermées. Une demande sans réponse depuis
plus d'une heure est signalée « > 1 h ». L'équipe lit le fil, répond (la demande passe « en
attente » et l'autrice est prévenue) ou ferme.

### User Story 3 - Profil d'une cliente (Priority: P2)

Clientes (68) : recherche par prénom ou e-mail, puis profil en lecture seule. Le profil montre les
commandes, le montant dépensé, les litiges, les demandes d'aide, les adresses et les avis. Chaque
consultation est inscrite au journal.

### User Story 4 - Une vendeuse vue de l'intérieur (Priority: P2)

Depuis Boutiques, « Voir comme elle » montre les produits (prix, stock, statut), les dernières
commandes et la note, en lecture seule et journalisé. Une vendeuse sans commande peut être supprimée,
avec une raison. Avec des commandes, la suppression est refusée et il faut suspendre la boutique.

### User Story 5 - Revenus de la plateforme (Priority: P2)

Finances → Revenus (70) affiche, pour ce mois, le mois dernier ou 30 jours :

- les ventes encaissées ;
- la commission DYM ;
- le net des vendeuses ;
- les remboursements ;
- le détail par boutique.

Les remboursements et les paiements en attente gardent leurs sections (57).

### User Story 6 - Ouvrir une fonctionnalité (Priority: P3)

Réglages → Fonctionnalités liste les drapeaux, globaux ou par pays. Ceux de la phase 4 sont coupés
par défaut. Chaque changement est journalisé.

### Edge Cases

- Plusieurs devises : les montants sont affichés par devise, jamais additionnés entre devises.
- Une commande livrée sans encaissement (cash non remis, paiement non confirmé) ne compte pas dans
  le chiffre d'affaires.
- Une réponse vide ou de plus de 2000 caractères est refusée.
- Hors ligne : erreurs claires, aucune donnée inventée.

## Requirements *(mandatory)*

- **FR-001**: Tableau de bord calculé en SQL (`admin_dashboard`), réservé à l'équipe :
  - indicateurs de la période ;
  - alertes ;
  - série sur 30 jours ;
  - tops.
- **FR-002**: Le chiffre d'affaires ne compte que les commandes livrées et encaissées : paiement
  confirmé ou cash remis.
- **FR-003**: Retards :
  - litige ouvert depuis plus de 48 h (A-LIT-07) ;
  - demande d'aide sans première réponse depuis plus d'une heure.
- **FR-004**: Support :
  - liste par état ;
  - réponse de l'équipe : passage « en attente », première réponse datée, notification
    `support_replied` ou `support_replied_vendor` ;
  - clôture.

  Chaque geste est journalisé.
- **FR-005**: Clientes : recherche, profil en lecture, consultation journalisée (`client_viewed`).
- **FR-006**: Vue vendeuse journalisée (`vendor_viewed`). Suppression d'une vendeuse avec une
  raison, refusée si sa boutique a des commandes (`vendor_has_orders`).
- **FR-007**: Revenus par période et par boutique : ventes, commission (calculée à la commande), net
  et remboursements.
- **FR-008**: Drapeaux de fonctionnalités, lus et modifiés par l'équipe (journalisé). La phase 4 est
  amorcée coupée : `ai_search`, `intent_copilot`, `shoppable_content`, `vendor_broadcast`.
- **FR-009**: Écrans 67 à 70 :
  - états vide, chargement, erreur et hors ligne ;
  - sept tailles, texte à 130 % ;
  - sur téléphone, les onglets au-delà de quatre passent sous « Plus ».

## Success Criteria *(mandatory)*

- **SC-001**: L'équipe repère une commande bloquée ou une demande sans réponse en moins de
  10 secondes après l'ouverture de l'admin.
- **SC-002**: Aucune lecture ni aucun geste de l'admin n'est possible pour un compte non admin
  (pgTAP).

## Assumptions

Hors de cette spec :

- l'alerte automatique sur le taux de paiement (moins de 90 %) relève de la spec 021 ;
- les graphiques sur 90 jours et l'export CSV restent au backlog.
