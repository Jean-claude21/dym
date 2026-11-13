# Implementation Plan: Messagerie claire et fiable

**Branch**: `feat/070-chat-ergonomie` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | « Vu » et commande en cours calculés en SQL ; l'app n'en déduit rien | OK |
| V. Sécurité | Fonctions `security definer` existantes ; aucune nouvelle table | OK |
| VI. Couches | Fil prêt à afficher (`entries`) dans le viewmodel ; vues sans logique | OK |
| VII. Réseau | Renvoi automatique seulement sur erreur transitoire, même clé | OK |
| VIII. Terrain | Cibles ≥ 48 dp, hors ligne géré, 7 tailles testées | OK |
| IX. Mesure | `chat_message_sent` émis côté serveur (déclencheur) | OK |

## Décisions

- Migration `0069_chat_context.sql` : `app.conversation_active_order`, `public.conversation` enrichie,
  déclencheur de mesure.
- `pickProducts(context, storeId)` remplace `pickProduct` : sélection multiple (panier proposé),
  produits de la boutique côté cliente (`storePage`).
- Pas de nouveau type de message : un panier proposé est une suite de fiches produit.
