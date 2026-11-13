# Feature Specification: Paiement Mobile Money par Moneroo

**Feature Branch**: `feat/088-moneroo`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Demande du porteur (2026-11-13) : implémenter Moneroo (bac à sable pour les tests) et
pouvoir, depuis l'admin, dire « utilise Moneroo » ; sinon la simulation continue. Le mot
« simulation » sera retiré quand les essais réels seront bons. Features C-PAY-02 (Mobile Money),
A-SET-04 (moyens de paiement).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basculer sur Moneroo (Priority: P1)

L'admin ouvre Configuration → Paiement : sous chaque moyen Mobile Money, un choix « Fournisseur »
(Mobile Money simulé ou Moneroo). Il choisit Moneroo : les prochains paiements passent par la page
de Moneroo (bac à sable ou réel selon la clé). Il peut revenir à la simulation à tout moment ; le
changement est journalisé.

### User Story 2 - Payer (Priority: P1)

La cliente paie : la page Moneroo s'ouvre, elle choisit son opérateur, revient dans l'app ; la
commande passe « payée » dès la confirmation de Moneroo (webhook signé, statut relu chez Moneroo,
montant et devise vérifiés en base).

### Edge Cases

- Clé Moneroo absente du déploiement : Moneroo n'est pas proposé (échec clair à l'initiation).
- Avis rejoué : appliqué une seule fois. Paiement encore en cours : journalisé, rien d'appliqué.
- Montant non entier pour la devise : refusé avant l'envoi.

## Requirements *(mandatory)*

- **FR-001**: `monerooProvider` derrière `PaymentProvider` (initialisation, signature HMAC-SHA256
  du corps brut, statut relu par `/payments/:id/verify`) ; aucune donnée personnelle envoyée.
- **FR-002**: `admin_save_payment_method` change le fournisseur dans la même famille, journalisé.
- **FR-003**: `MONEROO_SECRET_KEY`, `MONEROO_WEBHOOK_SECRET` dans les variables des Functions.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 720 ; tests Moneroo (initialisation, webhook, relecture, rejeu, en cours) ;
  essai en bac à sable dès la clé fournie.
