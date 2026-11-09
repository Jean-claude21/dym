# Implementation Plan: Wallet et poches

**Branch**: `feat/025-wallet-pockets` | **Date**: 2026-11-09 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Soldes, refus, arrondis et cashback en SQL ; l'app n'affiche que ce que renvoie la base | OK |
| IV. Générique | Devise du pays ; cashback et recharge simulée en données ; textes localisés | OK |
| V. Sécurité | Poches en RLS (lecture de ses seules poches) ; grand livre sans accès direct ; relecture humaine | OK |
| VII. Qualité | pgTAP (20), tests Flutter (8), Functions (4) ; branche Neon propre et copie de staging | OK |
| VIII. Terrain | États chargement, erreur et hors ligne (`DiscoveryState`) ; clé d'idempotence gardée | OK |

## Décisions

- **Paiement par wallet réglé en base** : à la création du paiement (`app.wallet_settle_payment`),
  qui appelle `apply_payment_event` ; aucune Function n'est nécessaire, aucun effet externe.
- **Accepté partout** : déclencheur sur `store_payment_methods` et `stores`.
- **Fournisseur `wallet` côté Functions** : déclaré disponible (sinon `place_order` refuse) ; il
  accepte les remboursements, rendus au wallet par le grand livre.
- **Trié en dernier** parmi les moyens, pour ne pas devenir le choix par défaut à solde nul.
- **Recharge simulée** : feature flag `wallet_simulated_topup`, à couper avant la production finale.

## Écran

« Moi » → « Mon wallet » : carte de solde (Recharger en test, Déplacer), poches (objectif, arrondi,
fermer), mouvements. Sans maquette validée : à faire valider par le porteur produit (dérogation II,
comme les écrans des phases 3 et 4).

## Déploiement

La Function `api` doit être redéployée sur staging pour accepter le paiement par wallet.
