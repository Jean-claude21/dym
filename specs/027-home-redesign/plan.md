# Implementation Plan: Nouvel accueil

**Branch**: `feat/027-home-redesign` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Fil calculé par `public.home_feed` (migration 0034), produits filtrés en base | OK |
| V. Sécurité | Dernière commande lue pour la seule personne connectée ; visiteuse : rien | OK |
| VIII. Terrain | Échec du fil sans effet sur boutiques et rayons ; sections vides masquées | OK |
| VII. Qualité | pgTAP (8), tests Flutter (4) ; Neon propre ; contrôle à l'écran sur staging | OK |

## Décisions

- Un seul appel serveur pour le fil, chargé en parallèle des boutiques.
- Réachat : `reorder` existant (spec 016) puis ouverture du panier.
- Ordre : question et recherche → assistant → stories → Recommander → populaires → nouveautés →
  boutiques → rayons.
