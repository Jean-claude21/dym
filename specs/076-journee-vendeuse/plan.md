# Implementation Plan: La journée de la vendeuse

**Branch**: `feat/076-journee-vendeuse` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Ventes précédentes : mêmes règles que `app.vendor_dashboard` | OK |
| VI. Couches | Évolution calculée par le modèle (règle d'affichage pure) | OK |

## Décisions

- Éditeur de produit : déjà en deux étapes courtes (photo, nom, rayon ; prix, unité) ; conforme.
