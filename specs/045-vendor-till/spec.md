# Feature Specification: Caisse de la vendeuse

**Feature Branch**: `feat/045-vendor-till`

**Created**: 2026-11-10

**Status**: Draft

**Input**: Spec `vendor-till` de la roadmap (Phase 12, VISION §3 « Vendeuse ») : caisse en app et
hors app, à la voix, « Ma caisse », frise de commande, tableau de bord utile.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Noter une vente faite à l'étal (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une vendeuse, **When** elle dicte ou tape « 3 tas de tomates 1500 », **Then** la base
   lit le libellé, la quantité et le montant (décimales de la devise) et reconnaît le produit ;
   elle choisit le moyen (cash, mobile money, autre) et enregistre.
2. **Given** un produit reconnu à stock suivi, **Then** le stock baisse ; une vente annulée le
   jour même le rend.

### User Story 2 - « Ma caisse » (Priority: P1)

**Acceptance Scenarios**:

1. **Given** une journée de vente, **When** la vendeuse ouvre « Ma caisse » (Ma boutique ou
   tableau de bord), **Then** elle voit le total du jour, en app et hors app, par moyen, son solde
   chez DYM, ses ventes et ses versements.
2. **Given** un solde chez DYM, **When** elle le verse, **Then** jamais plus que le solde ; le
   versement est simulé et signalé tant que le versement réel n'est pas branché.

### User Story 3 - Frise de la commande (Priority: P2)

1. **Given** une commande, **When** la vendeuse l'ouvre, **Then** elle voit chaque étape, son heure
   et qui l'a faite (elle, la cliente, le livreur, l'équipe).

### Edge Cases

- Dictée coupée pour le pays (flag `ai_search`) ou rien entendu : la vente se tape.
- Double envoi : une vente par clé d'idempotence.
- Les ventes hors app ne passent pas par le grand livre (argent qui ne transite pas par DYM).

## Requirements *(mandatory)*

- **FR-001**: Montant, stock, totaux et solde DOIVENT être calculés en base.
- **FR-002**: Le versement simulé DOIT être coupé par `store_simulated_payout` avant la production.
- **FR-003**: Événements serveur : `till_sale_recorded`, `store_paid_out`.
- **FR-004**: Les textes DOIVENT exister dans chaque langue.

## Success Criteria *(mandatory)*

- **SC-001**: Gate de la phase 12 (avec `qr-payments`) : vente hors app et QR enregistrés.

## Assumptions

- La dictée réutilise la transcription de la recherche vocale (spec 018) ; aucun audio conservé.
