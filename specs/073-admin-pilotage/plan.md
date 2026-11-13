# Implementation Plan: Pilotage admin de haut niveau

**Branch**: `feat/073-admin-pilotage` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Chiffres et comparaisons calculés en SQL ; l'app ne fait que l'écart en % | OK |
| V. Sécurité | `admin_overview` exige le rôle admin ; aucune table nouvelle | OK |
| VI. Couches | Chiffres, écarts et courbe préparés par le viewmodel ; vues sans logique | OK |
| VIII. Terrain | Téléphone, tablette, grand écran ; cibles ≥ 40 px sur ordinateur | OK |

## Décisions

- Comparaison « au même moment » (aujourd'hui jusqu'à 10 h contre hier jusqu'à 10 h).
- Graphiques en `CustomPainter` (courbe, mini-courbe, anneau, entonnoir, barres) : pas de bibliothèque
  à ajouter pour quelques graphiques de l'admin.
- `AdminRow` : lignes de cartes de même hauteur (12 parts) ; deux par ligne sur tablette.
