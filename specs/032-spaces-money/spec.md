# Feature Specification: Argent des espaces

**Feature Branch**: `feat/032-spaces-money`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `spaces-money` de la roadmap (Phase 9, suite de la spec 031) : poche commune,
contributions des membres, paiement depuis l'espace, part de chacun.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Verser dans la poche commune (Priority: P1)

**Acceptance Scenarios**:

1. **Given** un membre avec de l'argent sur son wallet, **When** il verse un montant dans la poche
   de l'espace, **Then** son wallet baisse et la poche monte du même montant, écrit au grand livre.
2. **Given** un solde insuffisant, **When** il verse, **Then** c'est refusé ; un double envoi
   (même clé) n'est compté qu'une fois.
3. **Given** l'espace ouvert, **When** un membre regarde, **Then** il voit le solde de la poche et
   ce que chacun a versé ce mois.

### User Story 2 - Payer depuis l'espace (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une poche suffisante, **When** la personne qui valide choisit « Payer avec la poche
   commune », **Then** le montant des articles passés au panier est viré de la poche vers son
   wallet, et elle paie avec « Wallet DYM » comme d'habitude.
2. **Given** une poche insuffisante, **When** elle choisit la poche, **Then** la validation est
   refusée sans rien déplacer.

### User Story 3 - Fermer un espace avec de l'argent (Priority: P2)

**Acceptance Scenarios**:

1. **Given** une poche non vide, **When** la responsable supprime l'espace, **Then** c'est refusé
   tant que la poche n'est pas vidée (validation financée).
2. **Given** une poche vide avec un historique, **When** elle supprime l'espace, **Then** il
   disparaît pour tous et le grand livre reste intact.

### Edge Cases

- Montant nul, négatif ou devise d'un autre pays : refusé.
- Un membre qui quitte garde l'historique de ses versements dans son wallet.

## Requirements *(mandatory)*

- **FR-001**: Tout mouvement DOIT être une transaction équilibrée du grand livre (immuable,
  idempotente), en `amount_minor` et devise de l'espace.
- **FR-002**: Seule une personne qui valide DOIT pouvoir financer une validation par la poche.
- **FR-003**: Les soldes affichés DOIVENT venir du grand livre (aucun calcul dans l'app).
- **FR-004**: Événements serveur : `space_contributed` (montant), `space_funded` (montant).
- **FR-005**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: `admin_ledger_check` reste équilibré après versements et financements (pgTAP).
- **SC-002**: Une famille paie un panier commun sans qu'un membre avance l'argent.

## Assumptions

- Le paiement de la commande reste celui du wallet (spec 025) ; la livraison est à la charge de la
  personne qui valide.
- Recharge du wallet : simulée jusqu'au branchement de Moneroo (décision 0015).
