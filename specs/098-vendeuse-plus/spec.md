# Feature Specification: Vendeuse +

**Feature Branch**: `feat/098-vendeuse-plus`

**Created**: 2026-11-16

**Status**: Done

**Input**: Décision du porteur (2026-11-16) : pousser l'accueil de la vendeuse (alerte de commande,
statistiques simples, résumé du jour, alertes de stock, meilleurs produits, clientes fidèles). Phase 15.

## User Scenarios & Testing *(mandatory)*

### US1 — Comprendre sa journée et sa semaine en un coup d'œil (P1)

Sous le chiffre encaissé : ventes jour par jour (barres), panier moyen, nombre de clientes dont
nouvelles, selon la période choisie (jour, semaine, mois).

### US2 — Agir sur ce qui compte (P1)

« Bientôt en rupture » (produits sous le seuil de la boutique, 5 par défaut), « Tes meilleurs
produits » (quantités et montants), « Tes clientes fidèles » (prénom et nombre de commandes,
jamais de téléphone). L'alerte de commande reste en tête (sonnerie et bouton Accepter : spec 097).

## Requirements *(mandatory)*

- **FR-001** `my_vendor_insights(période)` : une lecture, calculée en base dans le fuseau du pays ;
  équipe de la boutique avec la permission `orders`.
- **FR-002** Accueil vendeuse : sections ci-dessus ; un échec garde la dernière lecture.
