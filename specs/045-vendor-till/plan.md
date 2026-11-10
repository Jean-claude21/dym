# Implementation Plan: Caisse de la vendeuse

**Branch**: `feat/045-vendor-till` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Lecture du montant, stock, totaux, solde et versement en SQL | OK |
| IV. Générique | Décimales et fuseau du pays ; aucune devise en dur | OK |
| V. Sécurité | Ventes sans droit direct ; tout passe par la boutique de la personne | OK |
| VII. Simulation | Versement derrière `store_simulated_payout`, signalé (décision 0015) | OK |
| VII. Qualité | pgTAP `410`, tests Flutter, branche Neon propre | OK |

## Décisions

- Migration 0051 :
  - `store_sales` ;
  - `till_parse`, `record_till_sale`, `void_till_sale`, `my_till`, `store_payout_simulated` ;
  - opération de grand livre `store_payout`.
- Dictée : enregistreur vocal et transcription existants (`/v1/search/voice`), puis `till_parse`.
- App vendeuse :
  - « Ma caisse », accessible depuis Ma boutique et le tableau de bord ;
  - frise dans le détail d'une commande (historique déjà servi par la base).
- Numéro 0051 réutilisé : le brouillon de suivi en direct (reporté) n'a été appliqué nulle part.
