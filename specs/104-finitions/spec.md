# Feature Specification: Finitions

**Feature Branch**: `feat/104-finitions`

**Created**: 2026-11-17

**Status**: Done

**Input**: Écarts relevés le 2026-11-17 entre le plan validé et le code (« décidé mais pas construit »).

## User Scenarios & Testing *(mandatory)*

- **US1 (P1)** Le parent choisit les rayons que l'enfant peut acheter ; une commande payée par le
  wallet de l'enfant avec un autre rayon est refusée (« Ce rayon n'est pas autorisé par ton parent »).
- **US2 (P1)** Le livreur partage sa course en cours avec un proche (lien temporaire, sans compte,
  WhatsApp sinon copié), pour sa sécurité.
- **US3 (P2)** Wallet : chaque mouvement est nommé (abonnement et avantage DYM+, paiement en
  boutique, « À Yao » / « De Awa » entre proches) au lieu de « Mouvement ».
- **US4 (P3)** Échec de chargement de l'équipe de la boutique : « La page n'a pas pu se charger ».

## Requirements *(mandatory)*

- **FR-001** Migration 0096 : `family_links.allowed_categories`, `family_set_categories`,
  `app.check_child_categories` (appelé au paiement wallet), `my_wallet` (`p2p_sent`,
  `p2p_received`, `counterpart`), `my_family` (`allowed_categories`).
- **FR-002** App cliente : rayons dans les règles du parent, erreurs d'enfant au paiement, mouvements.
- **FR-003** App livreur : « Partager ma course » (`share_tracking`, déjà permis au livreur).
