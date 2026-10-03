# Feature Specification: Admin des opérations

**Feature Branch**: `feat/013-admin-ops`

**Created**: 2026-10-03

**Status**: Draft

**Input**: User description: "Spec `admin-ops` de la roadmap (Phase 2 ; A-AUTH-01/02/04/05, A-ORD-01..06/08, A-VEN-01..05/08/09, A-LIV-04, A-LOG-01/02, A-FIN-03/04) : admin Flutter Web, commandes (recherche, détail, chronologie, forcer un statut, annuler et rembourser, assigner une livraison externe), vendeuses (liste, profil, activer, suspendre), configuration, journal d'audit."

## Contexte

La preuve V1 de l'équipe : « un incident résolu depuis l'admin en moins d'une heure, sans
développeur » (`docs/product/VISION.md`). Cette spec donne à l'équipe ses écrans : voir et
débloquer une commande, trancher un litige (règles de la spec 012), exécuter les
remboursements, suspendre une boutique, configurer un pays et relire le journal d'audit.

L'ouverture du pays hôte du pilote passe par cet écran : villes, quartiers, moyens de paiement
et frais de livraison sont saisis par l'équipe (aucune ville n'est écrite dans le code ni dans
les migrations).

**Maquettes** à valider (bureau, 1280 × 800) : 52 (commandes), 53 (détail d'une commande),
54 (litiges), 55 (boutiques), 56 (réglages), 57 (finances), 58 (journal d'audit). La connexion
(15) existe depuis la spec 005.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Débloquer une commande (Priority: P1)

Mawuena (équipe) ouvre « Commandes » (52), filtre « Bloquées » : les commandes actives sans
étape depuis trop longtemps remontent en rouge. Elle cherche par numéro, cliente ou boutique,
ouvre le détail (53) : chronologie complète (statuts, paiement, remboursements, litige, actions
de l'équipe), articles, adresse et téléphone de livraison. Elle peut forcer un statut avec une
raison, assigner un livreur externe (nom, téléphone) ou annuler la commande avec une raison :
si elle était payée en ligne, un remboursement est créé.

**Acceptance Scenarios**:

1. **Given** une commande en préparation depuis 52 min, **When** Mawuena filtre « Bloquées »,
   **Then** elle la voit avec son ancienneté.
2. **Given** cette commande, **When** Mawuena force « Prête » avec la raison « Vendeuse
   injoignable », **Then** le statut change, la chronologie montre l'acteur « équipe », la
   cliente est prévenue et le journal d'audit garde avant, après et raison.
3. **Given** une commande payée en ligne, **When** Mawuena l'annule avec une raison, **Then**
   elle est annulée par l'équipe, le stock est rendu, un remboursement du total est créé à
   exécuter, la cliente et la vendeuse sont prévenues.
4. **Given** une commande en livraison, **When** Mawuena assigne un livreur externe, **Then**
   la vendeuse est prévenue avec le nom et le téléphone du livreur.
5. **Given** une personne sans rôle admin, **When** elle tente l'un de ces gestes ou une
   lecture admin, **Then** c'est refusé.

---

### User Story 2 - Trancher un litige et rembourser (Priority: P1)

Mawuena ouvre « Litiges » (54) : les litiges ouverts, les plus anciens d'abord. Elle lit la
conversation et la commande, écrit si besoin, puis tranche (règles de la spec 012). Dans
« Finances » (57), elle exécute les remboursements à faire : par le fournisseur de paiement
pour un achat payé en ligne, ou « remis en main propre » pour le cash. Elle voit aussi les
paiements en attente.

**Acceptance Scenarios**:

1. **Given** un remboursement de 300 à exécuter sur un achat payé en ligne, **When** Mawuena
   l'exécute, **Then** le fournisseur est appelé, le remboursement passe à « effectué », la
   cliente est prévenue et la commande n'a plus de remboursement dû.
2. **Given** un fournisseur qui refuse, **When** Mawuena exécute, **Then** le remboursement
   passe à « échoué » avec l'erreur, et peut être relancé.
3. **Given** un remboursement cash, **When** Mawuena le marque remis, **Then** il est effectué
   sans appel au fournisseur.

---

### User Story 3 - Suspendre ou réactiver une boutique (Priority: P2)

Dans « Boutiques » (55), Mawuena filtre par statut (actives, brouillons, suspendues), cherche,
ouvre un profil : vendeuse, quartier, ventes et commandes des 7 derniers jours, produits
publiés, litiges ouverts, historique des actions de l'équipe. Elle suspend avec une raison
(la boutique est fermée et disparaît des clientes), réactive, ou corrige les données (nom,
description, quartier, temps de préparation, retrait).

**Acceptance Scenarios**:

1. **Given** une boutique active, **When** Mawuena la suspend avec une raison, **Then** elle
   est suspendue et fermée, la vendeuse est prévenue, l'audit garde la raison et la vendeuse
   ne peut plus l'ouvrir.
2. **Given** une boutique suspendue, **When** Mawuena la réactive, **Then** elle redevient
   active (fermée : la vendeuse l'ouvre quand elle est prête).
3. **Given** une correction du nom, **When** Mawuena l'enregistre, **Then** l'audit garde
   avant et après.

---

### User Story 4 - Configurer un pays (Priority: P2)

Dans « Réglages » (56), Mawuena gère les pays (activer), les villes et quartiers (créer,
renommer, désactiver, position facultative), les moyens de paiement du pays (activer), la
commission (par pays, éventuellement par catégorie), les frais de livraison par défaut (pays
ou ville : base, ramassage en plus, seuil de gratuité) et les catégories (créer, renommer,
désactiver). Un pays ne s'active que s'il est prêt : au moins une ville active avec un
quartier actif, un moyen de paiement actif et des frais de livraison.

**Acceptance Scenarios**:

1. **Given** un pays sans ville, **When** Mawuena l'active, **Then** c'est refusé avec la liste
   de ce qui manque.
2. **Given** une ville et un quartier créés, un moyen de paiement actif et des frais, **When**
   Mawuena active le pays, **Then** il apparaît aux clientes et vendeuses.
3. **Given** une nouvelle commission, **When** elle est enregistrée, **Then** l'ancienne règle
   est close et la nouvelle s'applique aux prochaines commandes.

---

### User Story 5 - Relire le journal (Priority: P2)

« Journal » (58) liste toutes les actions de l'équipe (connexions comprises), les plus récentes
d'abord, avec recherche (action, entité, raison), filtres par action, entité et dates, et le
détail avant / après.

**Acceptance Scenarios**:

1. **Given** un statut forcé, **When** Mawuena cherche la commande, **Then** elle trouve
   l'entrée avec le membre, la raison, avant et après.

### Edge Cases

- Forcer le statut actuel, ou forcer depuis « livrée », « refusée », « annulée » : refusé
  (une commande terminée ne se rouvre pas ; une erreur de livraison passe par un litige).
- Annuler une commande déjà livrée : refusé (litige).
- Exécuter deux fois le même remboursement : le second est refusé tant que le premier est en
  cours ; un remboursement effectué ne se rejoue pas.
- Désactiver un quartier utilisé par des boutiques : permis (elles restent visibles par leur
  zone) ; il disparaît des choix.
- Un moyen de paiement ne s'active que si son fournisseur est actif.

## Requirements *(mandatory)*

- **FR-001**: Toute lecture et toute action admin DOIVENT exiger le rôle admin (base) ; la
  connexion admin reste celle de la spec 005 (Google Workspace avec 2FA imposée, déconnexion
  après 30 min d'inactivité) et est journalisée.
- **FR-002**: Liste des commandes paginée, filtrée (toutes, en attente, en cours, bloquées,
  livrées, annulées ou refusées) et recherchée (numéro court, prénom de la cliente, boutique).
  Une commande est « bloquée » si elle est active et sans étape depuis : 15 min en attente,
  60 min acceptée ou en préparation, 30 min prête, 60 min en livraison (règle en SQL).
- **FR-003**: Détail d'une commande avec chronologie (statuts et acteurs, paiements,
  remboursements, litige, actions de l'équipe, livreur assigné), articles, adresse et
  téléphone de livraison.
- **FR-004**: Forcer un statut (pending → … → delivered) avec une raison obligatoire ; statut
  final non modifiable ; notifications comme une étape normale ; audit.
- **FR-005**: Annuler (raison obligatoire) une commande non livrée et non terminée : stock
  rendu, remboursement du total créé si l'achat est payé en ligne, notifications, audit.
- **FR-006**: Assigner un livreur externe (nom, téléphone) à une commande en livraison ou prête
  à livrer ; la vendeuse est prévenue ; audit.
- **FR-007**: Remboursements : liste (à exécuter, effectués, échoués) ; exécution par le
  fournisseur de l'achat (simulateur compris hors production) ou « remis en main propre » pour
  le cash ; une seule exécution en cours ; cliente prévenue ; audit ; événement.
- **FR-008**: Paiements en attente (A-FIN-03) : liste avec ancienneté.
- **FR-009**: Boutiques : liste filtrée et recherchée, profil (indicateurs 7 jours, historique
  des actions de l'équipe), suspendre (raison), réactiver, corriger les données ; audit.
- **FR-010**: Réglages : pays (activation si prêt), villes et quartiers, moyens de paiement,
  commission versionnée, frais de livraison versionnés, catégories ; audit de chaque
  changement.
- **FR-011**: Journal d'audit en lecture seule, recherché et filtré.
- **FR-012**: Chaque action émet `admin_action_performed` (action, type d'entité), sans donnée
  personnelle ; un remboursement émet `refund_completed` (méthode, montant, issue).
- **FR-013**: Les actions qui préviennent quelqu'un ou appellent un fournisseur passent par une
  Function ; les réglages et corrections sans effet externe passent par la Data API.
- **FR-014**: L'admin est utilisable de la fenêtre compacte à la large (référence : bureau).

## Success Criteria *(mandatory)*

- **SC-001**: Une commande bloquée est débloquée en moins de 5 minutes depuis l'admin.
- **SC-002**: Un litige est tranché et son remboursement exécuté en moins de 5 minutes.
- **SC-003**: Aucune lecture ni action admin sans le rôle admin (pgTAP).
- **SC-004**: Toute action de l'équipe est dans le journal d'audit (pgTAP).
- **SC-005**: Le pays hôte s'ouvre sans développeur (villes, quartiers, paiement, frais).

## Assumptions

- **Livreur externe** : nom et téléphone saisis ; pas d'app livreur (Phase 1).
- **Export CSV/PDF, impersonation, suppression de compte vendeuse** : hors V1 (P1 ou hors
  roadmap de la phase).
- **Création d'un pays ou d'une devise** : par migration (référentiel) ; l'admin active.
- **Seuils de blocage** : règle de départ, à ajuster au pilote.
