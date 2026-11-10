# Feature Specification: Cash et gains du livreur

**Feature Branch**: `feat/043-delivery-cash`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `delivery-cash` de la roadmap (Phase 11, VISION §3 « Livreur » et recharge « cash
auprès d'un livreur ») : circuit du cash, gains en direct, retrait, point de recharge.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Gains en direct (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une commande payée en ligne, **When** un livreur DYM la livre, **Then** les frais de
   livraison passent du solde de la boutique à son wallet.
2. **Given** un livreur, **When** il ouvre « Gains », **Then** il voit ses courses et frais du jour,
   son wallet et le cash qu'il doit remettre.

### User Story 2 - Circuit du cash (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une commande payée à la livraison, **When** le livreur la livre, **Then** il garde ses
   frais en main et doit à la boutique le prix des articles.
2. **Given** ce cash dû, **When** la boutique confirme l'avoir reçu, **Then** la dette est soldée et
   le livreur est prévenu.

### User Story 3 - Retrait et point de recharge (Priority: P2)

**Acceptance Scenarios**:

1. **Given** un solde de wallet, **When** la personne retire, **Then** le montant sort, jamais plus
   que le solde ; le retrait est simulé et signalé tant que le versement réel n'est pas branché.
2. **Given** une cliente qui montre son code de recharge (15 minutes, une fois), **When** le livreur
   saisit le code et le montant, **Then** son wallet est crédité et le livreur doit ce cash à DYM.

### Edge Cases

- Livreur saisi à la main par l'équipe : aucun mouvement automatique.
- Cash encore dû ou course en cours : suppression du compte refusée.
- Double envoi : une clé d'idempotence par opération.

## Requirements *(mandatory)*

- **FR-001**: Tout mouvement DOIT passer par le grand livre, équilibré, une fois par opération.
- **FR-002**: Le retrait simulé DOIT être coupé par un feature flag avant la production finale.
- **FR-003**: Événements serveur : `courier_earned`, `courier_cash_remitted`, `wallet_withdrawn`.
- **FR-004**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Chaque franc encaissé par un livreur est tracé jusqu'à sa remise.

## Assumptions

- La confirmation du cash remis à l'équipe DYM existe en base (`admin_confirm_courier_cash`) ; son
  écran rejoindra `ops-center` (phase 13).
- Le remboursement d'une commande déjà encaissée par un livreur suit le circuit existant.
