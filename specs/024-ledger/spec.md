# Feature Specification: Grand livre

**Feature Branch**: `feat/024-ledger`

**Created**: 2026-11-09

**Status**: Draft

**Input**: Spec `ledger` de la roadmap (Phase 7, décision 0015, VISION §3 « DYM : compte unique et
grand livre »). Socle de l'argent : wallet, poches, commissions des créateurs et livreurs viendront
s'y écrire.

## Contexte

Aujourd'hui, l'argent est déduit de plusieurs tables (paiements, commandes, remboursements). Aucune
vue ne dit, à un instant donné, combien DYM doit à une boutique, combien DYM a gagné, ni combien
d'argent de clientes DYM détient. Le compte unique existe déjà : un même compte porte plusieurs
rôles (client, vendeuse, admin, livreur) ; cette spec n'y touche pas.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Chaque franc est tracé (Priority: P1)

Chaque mouvement d'argent (paiement en ligne réussi, commande livrée, cash encaissé, remboursement)
est écrit une fois, et une seule, dans un grand livre équilibré.

**Why this priority**: tout le reste (wallet, commissions, versements) repose sur cette vérité.

**Independent Test**: dérouler un paiement en ligne puis une livraison, et un achat en cash ; lire
les écritures et les soldes.

**Acceptance Scenarios**:

1. **Given** un paiement en ligne réussi, **When** il est confirmé, **Then** l'argent est enregistré
   comme détenu par DYM pour la cliente, jusqu'à la livraison.
2. **Given** une commande payée en ligne, **When** elle est livrée, **Then** la boutique est
   créditée du total moins la commission, et la commission revient à DYM.
3. **Given** une commande en cash livrée, **When** la vendeuse confirme l'encaissement, **Then** la
   boutique doit la commission à DYM.
4. **Given** un remboursement en ligne exécuté, **When** il réussit, **Then** l'argent rendu est
   sorti du bon compte (argent détenu avant livraison, boutique après).
5. **Given** le même événement reçu deux fois, **When** il est traité, **Then** une seule écriture
   existe.

### User Story 2 - Les soldes se lisent (Priority: P2)

La vendeuse connaît ce que DYM lui doit ou ce qu'elle doit à DYM ; l'équipe voit les anomalies.

**Why this priority**: sans lecture, le grand livre n'apporte rien aux personnes.

**Independent Test**: lire le solde de sa boutique, puis le contrôle d'anomalies en admin.

**Acceptance Scenarios**:

1. **Given** une vendeuse, **When** elle lit son solde, **Then** elle voit le montant dans sa devise
   et ses derniers mouvements, et jamais ceux d'une autre boutique.
2. **Given** un admin, **When** il lance le contrôle, **Then** il voit les incohérences (argent
   détenu négatif sur un achat), et une liste vide quand tout va bien.
3. **Given** une personne qui n'est pas admin, **When** elle lance le contrôle, **Then** c'est refusé.

### Edge Cases

- Commission nulle : aucune écriture vide n'est créée.
- Remboursement en cash : l'argent ne passe pas par DYM, aucune écriture.
- Historique existant : les mouvements passés sont repris une fois, à l'installation.
- Une écriture ne se modifie ni ne se supprime ; une erreur se corrige par une écriture inverse.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Chaque mouvement DOIT être une transaction dont la somme des écritures est nulle, dans
  une seule devise.
- **FR-002**: Chaque transaction DOIT porter une clé unique ; un rejeu NE DOIT PAS créer de doublon.
- **FR-003**: Les écritures NE DOIVENT jamais être modifiées ni supprimées.
- **FR-004**: Un paiement en ligne réussi DOIT créditer l'argent détenu pour la cliente.
- **FR-005**: La livraison d'une commande payée en ligne DOIT répartir son total entre la boutique
  et la commission de DYM.
- **FR-006**: L'encaissement cash confirmé DOIT inscrire la commission due par la boutique.
- **FR-007**: Un remboursement en ligne réussi DOIT sortir l'argent du compte adapté.
- **FR-008**: Les mouvements existants DOIVENT être repris une fois à l'installation.
- **FR-009**: Une vendeuse DOIT pouvoir lire le solde et les derniers mouvements de sa seule boutique.
- **FR-010**: Seul un admin DOIT pouvoir lancer le contrôle d'anomalies.
- **FR-011**: Aucune écriture NE DOIT pouvoir être créée directement depuis une app.

### Key Entities

- **Compte** : boutique, commission de DYM, argent détenu pour les clientes, argent chez les
  fournisseurs de paiement ; toujours dans une devise.
- **Transaction** : un mouvement, avec sa clé unique et sa référence (achat, commande, paiement,
  remboursement).
- **Écriture** : un montant signé sur un compte, dans une transaction.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100 % des transactions sont équilibrées.
- **SC-002**: 0 doublon après rejeu de chaque événement.
- **SC-003**: Pour toute commande livrée, part boutique + commission = total de la commande.
- **SC-004**: 0 lecture du solde d'une autre boutique.

## Assumptions

- Les frais de livraison font partie du total de la commande et reviennent à la boutique, comme
  aujourd'hui (la vendeuse livre).
- Les versements aux boutiques, le wallet et les poches viennent dans les specs suivantes.
- L'écran « Ma caisse » est construit en phase 12 ; cette spec fournit sa source.
