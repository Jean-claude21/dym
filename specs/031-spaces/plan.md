# Implementation Plan: Espaces partagés

**Branch**: `feat/031-spaces` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Rôles, panier commun, prix, budget et validation en SQL ; ajout au panier par `cart_add` | OK |
| IV. Générique | Pays et devise de l'espace tirés du profil ; fuseau du pays ; aucun modèle d'espace en dur | OK |
| V. Sécurité | Tables sous RLS (membres seulement), écriture par fonctions `SECURITY DEFINER` vérifiant le rôle | OK |
| VI. Couches | `SpaceRepository` (dym_data) → `SpacesService` → viewmodels | OK |
| VII. Qualité | pgTAP, tests du dépôt et des écrans ; Neon propre ; essai à deux comptes sur staging | OK |
| VIII. Terrain | États vide, chargement, erreur, hors ligne ; cibles ≥ 48 dp | OK |
| IX. Mesure | Événements serveur (création, adhésion, validation) | OK |

Maquette : écrans dérivés du panier et des listes validés ; validation par le porteur produit (T008).

## Décisions

- Migration 0038 : `spaces` (budget mensuel facultatif, code d'invitation), `space_members`
  (`payer` : valide et paie ; `member` : remplit), `space_items`, `space_validations` (dépensé du
  mois).
- Remplir : « Envoyer mon panier à l'espace » (le membre parcourt l'app comme d'habitude).
- Valider : articles passés au panier de la personne qui valide, puis commande habituelle.
- Notification `space_validated` aux autres membres.
