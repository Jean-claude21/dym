# Feature Specification: Wallet et poches

**Feature Branch**: `feat/025-wallet-pockets`

**Created**: 2026-11-09

**Status**: Draft

**Input**: Spec `wallet-pockets` de la roadmap (Phase 7, décision 0015, VISION §3 « Wallet »).
S'écrit dans le grand livre de la spec 024.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - J'ai un wallet et je le recharge (Priority: P1)

La cliente voit son solde et le recharge. Tant que le fournisseur réel n'est pas branché, la
recharge est simulée et signalée comme telle.

**Independent Test**: ouvrir « Mon wallet », recharger 5 000, lire le solde et le mouvement.

**Acceptance Scenarios**:

1. **Given** un wallet vide, **When** la cliente recharge 5 000, **Then** son solde est de 5 000 et
   un mouvement « Recharge » apparaît.
2. **Given** la même recharge renvoyée après une coupure, **When** elle est reçue, **Then** le solde
   ne double pas.
3. **Given** la recharge simulée coupée pour le pays, **When** la cliente ouvre son wallet, **Then**
   le bouton n'apparaît pas et le serveur refuse toute recharge simulée.

### User Story 2 - Je mets de côté dans des poches (Priority: P1)

La cliente crée autant de poches qu'elle veut, à nom libre, avec un objectif et un arrondi
facultatifs, et déplace de l'argent entre wallet et poches.

**Acceptance Scenarios**:

1. **Given** un wallet de 3 000, **When** elle crée « Tabaski » (objectif 10 000) et y déplace
   2 000, **Then** la poche affiche 2 000 et 20 % de l'objectif, le wallet 1 000.
2. **Given** un déplacement supérieur au solde de l'origine, **When** elle valide, **Then** c'est
   refusé avec « Solde insuffisant ».
3. **Given** une poche avec arrondi à 500, **When** elle paie 700 avec le wallet, **Then** 300 sont
   mis dans la poche.
4. **Given** une poche, **When** elle la ferme, **Then** son solde revient au wallet.

### User Story 3 - Je paie mes courses avec le wallet (Priority: P1)

« Wallet DYM » apparaît parmi les moyens de paiement, accepté par toutes les boutiques.

**Acceptance Scenarios**:

1. **Given** un wallet suffisant, **When** elle commande avec le wallet, **Then** la commande est
   payée immédiatement et l'argent reste protégé jusqu'à la livraison (spec 024).
2. **Given** un wallet insuffisant, **When** elle commande, **Then** la commande est refusée avec un
   message clair.
3. **Given** une commande payée par le wallet puis remboursée, **When** le remboursement réussit,
   **Then** l'argent revient au wallet.

### User Story 4 - Je gagne du cashback (Priority: P3)

**Acceptance Scenarios**:

1. **Given** une règle de cashback de 10 % dans le pays, **When** une commande est livrée et payée,
   **Then** 10 % du montant des articles est crédité au wallet.
2. **Given** aucune règle, **When** une commande est livrée, **Then** aucun cashback.

### Edge Cases

- Une personne ne voit ni ne déplace jamais l'argent d'une autre.
- 50 poches ouvertes au plus par personne.
- Toute écriture porte une clé d'idempotence ; l'app la garde tant que la réponse a pu se perdre.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le wallet et chaque poche DOIVENT être des comptes du grand livre, dans la devise du
  pays de la personne.
- **FR-002**: La recharge simulée DOIT dépendre d'un réglage par pays, et être signalée à l'écran.
- **FR-003**: Les poches DOIVENT être illimitées en usage (50 ouvertes), à nom libre, avec objectif
  et arrondi facultatifs.
- **FR-004**: « Wallet DYM » DOIT être un moyen de paiement accepté par toutes les boutiques, réglé
  par le serveur à la commande.
- **FR-005**: Un solde insuffisant DOIT refuser la commande ou le déplacement.
- **FR-006**: Un remboursement d'une commande payée par le wallet DOIT revenir au wallet.
- **FR-007**: Le cashback DOIT dépendre d'une règle par pays ; sans règle, aucun cashback.
- **FR-008**: Les événements `wallet_topped_up`, `wallet_payment_succeeded`, `pocket_created` DOIVENT
  être émis côté serveur.

## Success Criteria *(mandatory)*

- **SC-001**: 0 doublon de recharge ou de déplacement après rejeu.
- **SC-002**: 100 % des transactions du wallet équilibrées.
- **SC-003**: 0 lecture ou écriture de l'argent d'une autre personne.

## Assumptions

- Les paniers à offrir et le paiement pour un proche viennent avec la spec `spaces` (phase 9).
- La recharge par un vrai fournisseur (Moneroo) et en cash auprès d'une vendeuse ou d'un livreur
  viennent avec ces fournisseurs ; le cadre légal du wallet est réglé avant la production finale.
