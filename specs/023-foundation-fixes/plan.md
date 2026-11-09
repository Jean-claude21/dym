# Implementation Plan: Assainissement

**Branch**: `feat/023-foundation-fixes` | **Date**: 2026-11-09 | **Spec**: [spec.md](spec.md)

## Summary

Remettre la vérification au vert et corriger les défauts relevés, sans nouvelle fonctionnalité.

## Technical Context

Flutter 3.47.5 (Stacked), PostgreSQL 17 + pgTAP, Functions Node. Aucune nouvelle dépendance.

## Constitution Check

| Principe | Application | État |
|---|---|---|
| I. Périmètre | Phase 6 de la roadmap | OK |
| II. Maquettes | Petits états sur écrans déjà validés ; validation par le porteur produit | OK |
| III. Postgres | Refus d'achat chez soi et état ouvert calculés en SQL | OK |
| IV. Générique | Aucun pays ni moyen en dur ; textes localisés | OK |
| V. Sécurité | Migrations 0028 et 0029 soumises à relecture humaine | OK |
| VI. Couches | Vue → viewmodel → service → repository | OK |
| VII. Qualité | pgTAP, analyse, tests ; simulation signalée (décision 0015) | OK |

## Décisions

- **Pays inactifs (FR-001)** : chaque test concerné rend les autres pays inactifs dans sa transaction.
- **Mot de passe (FR-003)** : constante de compilation `DymEnvironment.testToolsEnabled`.
- **Moyens simulés (FR-004)** : le serveur de production finale n'expose pas le fournisseur simulé,
  ce qui refuse déjà toute commande. Le retrait de l'affichage est une étape de mise en production
  (voir quickstart), car une migration ne sait pas distinguer staging de production.
- **Achat chez soi (FR-013)** : déclencheur à l'écriture de la commande (migration 0028).
- **État réel (FR-012)** : `my_store_open_now()` (migration 0029).
- **Réouverture (FR-007)** : l'heure n'est pas encore fournie par la fiche ; la fermeture seule est
  indiquée, cas prévu par la spec.

## Déjà en place, vérifié dans le code

- **FR-008** : la fiche confirme déjà l'ajout par un message temporaire (`confirm: true`).
- **FR-011** : `save_address` rend déjà par défaut la première adresse.
