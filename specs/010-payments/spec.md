# Feature Specification: Paiements génériques et fournisseur simulé

**Feature Branch**: `feat/010-payments`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Spec `payments` de la roadmap (Phase 2 ; C-PAY-01/02/06, V-PAY-01/02/04/05, A-LOG-03) : interface `PaymentProvider` générique ; fournisseurs `cash` puis `moneroo` ; webhooks signés et journalisés ; confirmation automatique ; badge « paiement confirmé ». Demande du porteur produit (2026-10-02) : simuler un paiement réussi ou échoué pour voir la réaction des apps, en attendant le compte Moneroo."

## Contexte

La spec 009 crée des commandes payées en cash à la livraison. Le contrat V1 prévoit aussi le
Mobile Money. Le compte Moneroo n'est pas encore validé (KYC), mais le porteur produit veut voir,
dès maintenant, comment les apps réagissent à un paiement réussi ou échoué.

Cette spec construit donc la chaîne de paiement complète, indépendante du fournisseur :
création du paiement, page de paiement externe, confirmation par webhook signé, statut visible par
la cliente et par la vendeuse. Le premier fournisseur en ligne est un **simulateur** : sa page de
paiement propose « Paiement réussi » et « Paiement échoué ». Il n'existe que hors production.
Moneroo prendra sa place sans modifier les apps (décision 0004).

**Maquettes** :
- validées : 05 (panier, choix du paiement) et 08 (commande reçue, vendeuse) ;
- produites dans la même direction, à valider : 39 (paiement en cours), 40 (paiement échoué),
  41 (commandes de la vendeuse) et 42 (détail du paiement).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Awa paie en Mobile Money et voit la confirmation (Priority: P1)

Dans le panier, Awa choisit un moyen Mobile Money proposé dans son pays et accepté par les
boutiques. Elle touche « Commander ». L'app ouvre la page de paiement du fournisseur et affiche
« En attente du paiement » (écran 39). Quand le fournisseur confirme, l'app passe d'elle-même à
« Commande envoyée » (37), avec la mention « Paiement confirmé ».

**Why this priority**: C-PAY-01/02 ; la confirmation automatique supprime toute capture manuelle.

**Independent Test**: avec le simulateur, commander, choisir « Paiement réussi » sur la page de
paiement ; vérifier le passage automatique à l'écran 37 et le statut en base.

**Acceptance Scenarios**:

1. **Given** un panier valide et un moyen Mobile Money, **When** Awa commande, **Then** un
   paiement est créé pour le montant total calculé par la base, la page de paiement s'ouvre et
   l'app attend la confirmation.
2. **Given** la page de paiement, **When** le fournisseur confirme le paiement, **Then** le
   paiement passe à « réussi », la commande devient visible des vendeuses avec le badge
   « Paiement confirmé », et l'app de la cliente affiche la confirmation sans geste de sa part.
3. **Given** une confirmation reçue deux fois, **When** la base la traite, **Then** rien ne
   change la seconde fois.

---

### User Story 2 - Le paiement échoue : Awa réessaie ou paie à la livraison (Priority: P1)

Si le paiement échoue ou qu'Awa abandonne, l'app affiche « Le paiement n'a pas abouti » (écran
40). Sa commande est gardée. Elle peut réessayer le paiement ou choisir le paiement à la
livraison si toutes les boutiques l'acceptent.

**Why this priority**: un échec de paiement ne doit pas perdre une commande (H3, H4).

**Independent Test**: avec le simulateur, choisir « Paiement échoué » ; vérifier l'écran 40,
puis réessayer avec succès ; recommencer et choisir le paiement à la livraison.

**Acceptance Scenarios**:

1. **Given** un paiement en cours, **When** le fournisseur signale un échec, **Then** l'app
   affiche l'écran 40 et les vendeuses ne voient pas la commande.
2. **Given** l'écran 40, **When** Awa réessaie, **Then** un nouveau paiement est créé pour le
   même montant (l'ancien reste journalisé).
3. **Given** l'écran 40, **When** Awa choisit le paiement à la livraison, **Then** la commande
   devient une commande en cash, visible des vendeuses avec la mention « Cash à la livraison ».

---

### User Story 3 - Fatou voit les commandes payées et le détail du paiement (Priority: P1)

Dans l'app vendeuse, l'onglet « Commandes » (écran 41) liste les commandes de sa boutique qui
sont payées ou en cash, les plus récentes d'abord, avec un badge « Paiement confirmé » ou « Cash
à la livraison ». Le détail (écran 42) montre les articles, le montant, le moyen, la date et la
référence du paiement, et l'adresse de livraison (quartier et repère).

**Why this priority**: V-PAY-01/02/04/05 ; Fatou ne prépare jamais une commande non payée.

**Independent Test**: créer une commande cash, une commande payée et une commande dont le
paiement est en attente ; seules les deux premières apparaissent, avec le bon badge.

**Acceptance Scenarios**:

1. **Given** une commande au paiement en attente ou échoué, **When** Fatou ouvre « Commandes »,
   **Then** elle ne la voit pas.
2. **Given** un paiement confirmé pendant que l'onglet est ouvert, **When** la liste se
   rafraîchit, **Then** la commande apparaît avec « Paiement confirmé ».
3. **Given** le détail d'une commande, **When** il s'affiche, **Then** il montre montant, moyen,
   date et référence du paiement, avec son prénom, le quartier, le repère et le
   téléphone de livraison (pour une livraison), jamais son email.

---

### User Story 4 - L'équipe peut tester les réactions sans argent réel (Priority: P1)

Hors production, un moyen « Mobile Money (simulé) » peut être activé pour un pays. Sa page de
paiement, servie par DYM, montre le montant et propose « Paiement réussi », « Paiement échoué »
ou « Abandonner ». Chaque choix envoie au système une confirmation signée, traitée exactement
comme celle d'un vrai fournisseur. En production, le simulateur n'existe pas : le moyen ne peut
pas être utilisé.

**Why this priority**: demande explicite du porteur produit ; permet de tester toute la chaîne
avant le compte Moneroo.

**Independent Test**: sur la branche de test, activer le simulateur, payer avec chacune des
trois issues ; sur une configuration de production, vérifier que le moyen est refusé.

**Acceptance Scenarios**:

1. **Given** le simulateur actif hors production, **When** Awa paie, **Then** la page de
   simulation s'ouvre avec le montant et la référence.
2. **Given** une confirmation sans signature valide, **When** elle arrive, **Then** elle est
   journalisée et refusée.
3. **Given** une configuration de production, **When** une commande utilise le simulateur,
   **Then** elle est refusée (« moyen indisponible ») et rien n'est créé.

### Edge Cases

- Fournisseur injoignable au moment de créer le paiement : la commande est gardée, le paiement
  est marqué échoué et l'écran 40 s'affiche.
- Confirmation qui arrive avant que l'app ne lise le statut : l'app lit le statut à l'ouverture
  de l'écran 39 et à chaque retour au premier plan.
- Confirmation d'un paiement inconnu ou d'un montant différent : journalisée, ignorée, signalée.
- Réessai après une réussite : refusé (déjà payé).
- Passage au cash alors qu'une boutique n'accepte pas le cash : refusé.
- Cliente hors ligne pendant l'attente : l'écran 39 l'indique et relit le statut au retour du
  réseau.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Chaque achat payé en ligne DOIT avoir un ou plusieurs paiements (tentatives) :
  fournisseur, moyen, montant (unités mineures, devise du pays), statut (`pending`,
  `succeeded`, `failed`, `cancelled`), référence fournisseur, dates. Un seul paiement réussi par
  achat.
- **FR-002**: L'achat DOIT porter un état de paiement : `cash_on_delivery`, `awaiting_payment`,
  `paid`, `failed`. Il est décidé en base, à partir des paiements, jamais par une app.
- **FR-003**: Les vendeuses NE DOIVENT voir une commande que si son achat est `cash_on_delivery`
  ou `paid`.
- **FR-004**: La création de la commande DOIT accepter tout moyen actif du pays, accepté par les
  boutiques, dont le fournisseur est disponible dans le déploiement ; sinon refus
  `payment_unavailable`. Pour un moyen en ligne, elle crée le premier paiement en attente.
- **FR-005**: Les fournisseurs DOIVENT être derrière une interface commune (créer un paiement,
  vérifier une confirmation, la traduire) ; ajouter un fournisseur ne modifie aucune app.
- **FR-006**: Toute confirmation reçue DOIT être journalisée brute, vérifiée par signature, et
  traitée de façon idempotente (identifiant d'événement du fournisseur). Les appels au
  fournisseur et leurs échecs sont journalisés (A-LOG-03).
- **FR-007**: La cliente DOIT pouvoir réessayer un paiement échoué (nouvelle tentative, même
  montant, clé d'idempotence) ou passer au paiement à la livraison si toutes les boutiques
  l'acceptent.
- **FR-008**: Le simulateur DOIT n'exister que hors production (variable de déploiement) ; sa page
  propose réussite, échec et abandon, et envoie une confirmation signée par le même chemin que
  les vrais fournisseurs.
- **FR-009**: La base DOIT enregistrer `payment_initiated`, `payment_succeeded` et
  `payment_failed`, sans donnée personnelle.
- **FR-010**: L'app cliente DOIT afficher l'attente (39), l'échec (40) et la confirmation (37) ;
  elle relit le statut régulièrement pendant l'attente et à chaque retour au premier plan.
- **FR-011**: L'app vendeuse DOIT proposer l'onglet « Commandes » (41) et le détail du paiement
  (42), avec badges « Paiement confirmé » et « Cash à la livraison », et se rafraîchir
  régulièrement.

### Key Entities

- **Paiement** : achat, fournisseur, moyen, montant, devise, statut, référence fournisseur, URL de
  paiement, dernière erreur, dates.
- **Événement de paiement** : fournisseur, identifiant d'événement, corps brut, signature valide
  ou non, résultat du traitement, date.
- **État de paiement de l'achat** : `cash_on_delivery`, `awaiting_payment`, `paid`, `failed`.

## Success Criteria *(mandatory)*

- **SC-001**: Après « Paiement réussi » sur la page du simulateur, l'app cliente affiche la
  confirmation en moins de 10 secondes, sans geste.
- **SC-002**: Une confirmation rejouée 5 fois ne change l'état qu'une fois (pgTAP).
- **SC-003**: Aucune commande à paiement en attente ou échoué n'est visible d'une vendeuse
  (pgTAP).
- **SC-004**: En configuration de production, le simulateur est refusé (test de Function).
- **SC-005**: Le parcours « commander → payer → confirmé » et « commander → échec → cash » passe de
  bout en bout sur la branche de test.

## Assumptions

- **Moneroo.** Son adaptateur arrive quand le compte est validé ; il implémente la même
  interface. Les identifiants vivent dans les variables des Functions.
- **Retour dans l'app.** L'app relit le statut (toutes les 3 secondes pendant l'attente, et au
  retour au premier plan). Le retour automatique par lien profond et les notifications push
  arrivent avec `order-lifecycle`.
- **Stock.** Il reste réservé pendant l'attente et après un échec ; l'annulation (et la remise en
  stock) relève d'`order-lifecycle`, tout comme l'expiration d'un paiement abandonné.
- **File de vérification manuelle.** Les paiements en anomalie sont journalisés ici ; leur écran
  de traitement relève de `admin-ops`.
- **Remboursements** (V-PAY-06) : `admin-ops`.
- **Accepter, préparer, livrer** une commande : `order-lifecycle`. Ici, la vendeuse consulte.
