# Feature Specification: Cycle de vie des commandes et notifications

**Feature Branch**: `feat/011-order-lifecycle`

**Created**: 2026-10-03

**Status**: Draft

**Input**: User description: "Spec `order-lifecycle` de la roadmap (Phase 2 ; V-ORD-01..09, C-ORD-01..04/07, C-NOTIF-01..05/09, C-PROF-03/06) : machine à états serveur ; accepter/refuser, préparation, prête, livrée ; push + son ; centre de notifications ; suivi client avec ETA ; annulation avant préparation."

## Contexte

Les specs 009 et 010 créent des commandes payées (en ligne ou en cash). Il manque la suite du
contrat V1 : Fatou **traite** la commande et **confirme l'encaissement**, Awa **suit** sa
commande. Toutes les transitions de statut sont décidées en base (constitution III).

**Maquettes** :
- validées : 06 (suivi de la commande, sans la carte ni le livreur en direct, qui relèvent de
  `live-tracking`) et 08 (nouvelle commande, vendeuse) ;
- produites dans la même direction, à valider : 43 (mes commandes), 44 (centre de
  notifications), 45 (refus avec raison) et 46 (réglages des notifications).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fatou reçoit, accepte ou refuse une commande (Priority: P1)

Quand une commande payée ou en cash arrive, l'app vendeuse la signale (son, vibration, écran
« Nouvelle commande ! », 08) et elle reçoit une notification. Fatou voit le prénom de la
cliente, le quartier, les articles, le montant qu'elle encaisse et le mode de paiement. Elle
accepte d'un geste, ou refuse avec une raison (45). La cliente est prévenue.

**Why this priority**: V-ORD-01..04 ; c'est l'action 2 du contrat V1 côté vendeuse (H9).

**Independent Test**: créer une commande cash ; l'accepter ; en créer une autre et la refuser
avec une raison ; vérifier statuts, horodatages, notifications de la cliente, stock rendu après
le refus.

**Acceptance Scenarios**:

1. **Given** une commande en attente, **When** Fatou l'accepte, **Then** elle passe à
   « acceptée », l'heure est enregistrée, la cliente reçoit « Commande acceptée » avec l'heure
   de livraison estimée.
2. **Given** une commande en attente, **When** Fatou la refuse sans raison, **Then** c'est
   refusé ; avec une raison, la commande passe à « refusée », le stock est rendu, la cliente est
   prévenue et, si elle avait payé en ligne, un remboursement est à faire.
3. **Given** une commande déjà acceptée, **When** une autre personne que Fatou tente de la
   modifier, **Then** c'est refusé.

---

### User Story 2 - Fatou prépare, livre et confirme l'encaissement (Priority: P1)

Fatou fait avancer la commande : « En préparation », « Prête », puis « En route » et « Livrée »
pour une livraison, ou « Récupérée » (livrée) pour un retrait. Pour une commande en cash, elle
confirme l'encaissement du montant affiché. Elle retrouve ses commandes par onglets : nouvelles,
en cours, terminées.

**Why this priority**: V-ORD-05/06/08/09 et l'action 3 du contrat V1 (confirmer l'encaissement).

**Independent Test**: faire avancer une commande en livraison et une en retrait jusqu'à
« livrée » ; tenter un saut d'étape ; confirmer l'encaissement d'une commande cash.

**Acceptance Scenarios**:

1. **Given** une commande acceptée, **When** Fatou la marque « Livrée » directement, **Then**
   c'est refusé (étapes dans l'ordre).
2. **Given** une commande en retrait prête, **When** Fatou la marque livrée, **Then** elle
   passe à « livrée » sans passer par « en route ».
3. **Given** une commande cash livrée, **When** Fatou confirme l'encaissement, **Then** l'heure
   est enregistrée une fois ; une commande payée en ligne n'a pas cette étape.

---

### User Story 3 - Awa suit ses commandes et peut annuler avant la préparation (Priority: P1)

L'onglet « Commandes » (43) liste ses commandes en cours puis terminées. Le suivi (06) montre la
frise « Confirmée → Préparée → En route → Livrée », l'heure de livraison estimée, la boutique et
le montant à payer en cash. Tant que la boutique n'a pas commencé la préparation, Awa peut
annuler.

**Why this priority**: C-ORD-01..04/07, C-PROF-03 ; action 3 du contrat V1 côté cliente.

**Independent Test**: suivre une commande pendant que la vendeuse la fait avancer ; annuler
une commande acceptée ; tenter d'annuler une commande en préparation.

**Acceptance Scenarios**:

1. **Given** une commande en préparation, **When** Awa ouvre le suivi, **Then** elle voit
   l'étape courante, l'heure estimée et le montant à payer à la livraison.
2. **Given** une commande en attente ou acceptée, **When** Awa l'annule, **Then** elle passe à
   « annulée », le stock est rendu et la vendeuse est prévenue.
3. **Given** une commande en préparation, **When** Awa veut l'annuler, **Then** le bouton
   n'est pas proposé et la base refuse.

---

### User Story 4 - Awa est prévenue de chaque étape (Priority: P1)

À chaque étape (paiement confirmé ou échoué, acceptée, refusée, en préparation, prête, en
route, livrée, annulée), une notification est créée. Le centre de notifications (44) les liste
avec les non-lues en tête et un compteur ; « Tout lire » les marque lues. Dans « Moi », Awa
règle ce qui peut lui être envoyé sur son téléphone (46). Une notification push est envoyée si
le téléphone est enregistré et la catégorie autorisée.

**Why this priority**: C-NOTIF-01..05/09, C-PROF-06, V-ORD-01.

**Independent Test**: faire avancer une commande ; vérifier les notifications créées, le
compteur, la lecture, et qu'une catégorie coupée n'est pas envoyée en push.

**Acceptance Scenarios**:

1. **Given** une commande acceptée, **When** Awa ouvre le centre, **Then** « Commande acceptée »
   est en tête, non lue, et le compteur vaut 1.
2. **Given** la catégorie « Suivi de mes commandes » coupée, **When** une étape arrive, **Then**
   la notification reste dans le centre mais n'est pas envoyée en push.
3. **Given** les notifications d'une autre personne, **When** Awa les lit, **Then** elle ne
   voit rien.

### Edge Cases

- Deux gestes simultanés sur une même commande (double tap, deux téléphones) : un seul passe,
  l'autre reçoit l'état courant.
- Commande dont le paiement n'est pas confirmé : invisible et intouchable pour la vendeuse.
- Toutes les commandes d'un achat annulées ou refusées après paiement en ligne : remboursement
  à faire (traité par `admin-ops`).
- Hors ligne : le geste n'est pas perdu (clé de requête), l'écran le signale.
- Pas de téléphone enregistré pour le push : le centre de notifications suffit.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Les statuts DOIVENT être : `pending`, `accepted`, `preparing`, `ready`,
  `out_for_delivery`, `delivered`, `refused`, `cancelled`. Les transitions permises sont décidées
  en base :
  - vendeuse : `pending → accepted | refused` (raison obligatoire), `accepted → preparing`,
    `accepted | preparing → ready`, `ready → out_for_delivery` (livraison),
    `out_for_delivery → delivered`, `ready → delivered` (retrait) ;
  - cliente : `pending | accepted → cancelled`.
- **FR-002**: Chaque transition DOIT être horodatée, tracée dans un historique (de, vers, qui,
  raison, quand) et refusée si l'état a changé entre-temps.
- **FR-003**: Le refus et l'annulation DOIVENT rendre le stock suivi et, pour un achat payé en
  ligne, marquer le remboursement à faire.
- **FR-004**: Pour une commande en cash livrée, la vendeuse DOIT pouvoir confirmer
  l'encaissement une fois.
- **FR-005**: L'heure de livraison estimée DOIT être calculée en base (acceptation ou création +
  préparation de la boutique + délai de la ville pour une livraison).
- **FR-006**: La base DOIT créer une notification pour la cliente à chaque étape et pour la
  vendeuse à chaque nouvelle commande visible (cash créée, paiement confirmé, passage au cash)
  et à chaque annulation. Une notification porte un type et des paramètres, jamais un texte : les
  apps la traduisent.
- **FR-007**: Le centre de notifications DOIT lister, compter les non-lues et marquer lues ; il
  n'est lisible que par sa destinataire.
- **FR-008**: Une personne DOIT pouvoir régler, par catégorie (suivi des commandes, paiements,
  messages, bons plans), l'envoi push ; le centre garde tout.
- **FR-009**: Les push DOIVENT être envoyés par une Function derrière une interface (FCM quand ses
  identifiants sont configurés), seulement aux téléphones enregistrés et pour les catégories
  autorisées ; chaque envoi est marqué pour ne jamais partir deux fois.
- **FR-010**: Les gestes qui déclenchent un effet (transition, annulation, encaissement) DOIVENT
  passer par une Function.
- **FR-011**: La base DOIT enregistrer `order_accepted`, `order_rejected`,
  `order_status_changed`, `order_delivered`, `order_cancelled`, sans donnée personnelle.
- **FR-012**: L'app cliente DOIT proposer l'onglet « Commandes » (43), le suivi (06), le centre
  (44) et les réglages (46). L'app vendeuse DOIT proposer la nouvelle commande (08) avec son et
  vibration, les gestes de chaque étape, le refus avec raison (45), l'encaissement, et les
  onglets nouvelles / en cours / terminées.

### Key Entities

- **Commande** (étendue) : statut, horodatage de chaque étape, raison, auteur de l'annulation,
  encaissement, remboursement à faire.
- **Historique de statut** : commande, de, vers, rôle, auteur, raison, date.
- **Notification** : destinataire, type, commande, paramètres, lue le, envoyée le.
- **Préférence de notification** : personne, catégorie, push autorisé.
- **Téléphone enregistré** : personne, jeton, plateforme, app.

## Success Criteria *(mandatory)*

- **SC-001**: Une vendeuse traite une commande de « nouvelle » à « livrée » en 4 gestes au plus.
- **SC-002**: Aucune transition hors des règles n'est acceptée (pgTAP, toutes les paires).
- **SC-003**: La cliente voit le nouveau statut en moins de 20 secondes sans geste.
- **SC-004**: Un refus ou une annulation rend toujours le stock (pgTAP).
- **SC-005**: Commande → acceptée → livrée → encaissée passe de bout en bout sur la branche de
  test.

## Assumptions

- **Push.** Le projet Firebase n'existe pas encore : l'envoi FCM est construit et testé, activé
  dès que ses identifiants sont fournis ; l'enregistrement du téléphone dans les apps arrive avec
  eux. D'ici là, les apps relisent l'état (20 s) et la vendeuse est alertée par le son et la
  vibration à l'arrivée d'une commande dans la liste.
- **Délai de réponse.** « Réponds dans les 10 minutes » (08) est un rappel affiché ; le rappel
  SMS ou WhatsApp (H9) et l'annulation automatique relèvent du pilote.
- **Remplacement d'un produit** (bloc de la maquette 06) : la préférence est transmise à la
  vendeuse ; la proposition d'un remplacement à accepter relève du pilote.
- **Carte et livreur en direct** (06) : `live-tracking` (Phase 5).
- **Remboursement** : marqué ici, exécuté depuis `admin-ops`.
