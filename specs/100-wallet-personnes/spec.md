# Feature Specification: Avoir entre personnes

**Feature Branch**: `feat/100-wallet-personnes`

**Created**: 2026-11-16

**Status**: Done

**Input**: Décisions du porteur (2026-11-16) : avoir DYM entre personnes, simulé, jamais retiré :
QR personnel, envoyer, demander (« paie ma commande »), recharger pour un proche, argent de poche et
suivi parental avec plafonds. Cadre BCEAO (instruction 008-05-2015, art. 3) : un avoir utilisable
seulement chez l'émetteur et ses partenaires est exempté ; transférer n'est pas retirer. Validation
juridique avant tout argent réel.

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** Chacun a un code personnel (8 caractères, QR « DYM-P2P:… »), jamais l'email ni le
  téléphone. Envoyer : code tapé ou scanné, prénom du destinataire confirmé, montant, message.
- **US2 (P1)** Demander une somme à quelqu'un ; la personne paie ou refuse en un geste.
- **US3 (P2)** Recharger le wallet d'un proche (recharge simulée, drapeau `wallet_simulated_topup`).
- **US4 (P2)** Famille : le parent invite l'enfant par son code, l'enfant accepte ; le parent voit
  solde, dépenses du jour et derniers mouvements, règle l'argent de poche (jour, semaine, mois, versé
  par le cron depuis son wallet) et un plafond par jour appliqué à toutes les dépenses de l'enfant.
- **US5 (P1)** L'avoir reçu d'une personne ne se retire jamais (`p2p_not_withdrawable`).

## Requirements *(mandatory)*

- **FR-001** Migration 0093 : `wallet_handles`, `p2p_transfers`, `p2p_requests`, `family_links` ;
  transferts au grand livre (`wallet_transfer`), verrou par wallet, idempotence ; plafond parental
  dans le paiement wallet, la demande de paiement de boutique et les envois.
- **FR-002** Cron : `app.pay_allowances`.
- **FR-003** App cliente : « Entre proches » (QR, envoyer, demander, recharger, demandes,
  historique, famille).
- **FR-004** Événement `wallet_shared` (type, montant ; jamais de nom).
