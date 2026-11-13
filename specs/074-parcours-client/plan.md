# Implementation Plan: Parcours d'achat de haut niveau

**Branch**: `feat/074-parcours-client` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Montants et statut lus tels quels ; aucun calcul de prix | OK |
| VI. Couches | Phase et avancement dans le viewmodel | OK |
| VIII. Terrain | États chargement, erreur, hors ligne gardés ; cibles ≥ 48 dp | OK |

## Décisions

- Revue des écrans du parcours : accueil, paiement, « Mes commandes » conformes ; panier conforme
  (le bouton est sous la liste, pas dessus) ; suivi et fiche corrigés.
