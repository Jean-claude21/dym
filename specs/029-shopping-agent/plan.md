# Implementation Plan: Assistant de courses

**Branch**: `feat/029-shopping-agent` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Listes, habitudes, composition (`copilot_pick` à 20 besoins), rappels en SQL | OK |
| IV. Générique | Périodes et heure en SQL ; fuseau du pays ; aucune liste d'articles dans le code | OK |
| V. Sécurité | `shopping_lists` sous RLS (lecture propriétaire), écriture par fonctions `SECURITY DEFINER` | OK |
| VI. Couches | `ShoppingListRepository` (dym_data) → `ShoppingService` → viewmodels | OK |
| VII. Qualité | pgTAP, tests Function, tests Flutter ; Neon propre ; essai à l'écran sur staging | OK |
| VIII. Terrain | États vide, chargement, erreur, hors ligne ; cibles ≥ 48 dp | OK |
| IX. Mesure | Événements serveur (liste enregistrée, proposée, rappel) et app (ajout au panier) | OK |

Maquette : écrans dérivés du copilote validé (écran 73) ; validation terrain par le porteur produit
(tâche T009), comme pour les specs 026 à 028.

## Décisions

- Migration 0036 :
  - table `shopping_lists` (articles en jsonb, période 7/14/30 jours, prochaine échéance, quartier) ;
  - `copilot_pick` reçoit un plafond (`p_max`, 7 par défaut, 20 au plus) : recopiée depuis 0035,
    seule la boucle change ;
  - fonctions `save_shopping_list`, `delete_shopping_list`, `my_shopping_lists`,
    `shopping_habits` (produits achetés dans au moins 2 commandes sur 90 jours, quantité médiane),
    `shopping_list_proposal` ;
  - `app.create_shopping_reminders(p_at)` : 8 h locales, échéance avancée dans la même requête
    (verrou `for update skip locked`), notification `shopping_list_due`.
- Function : `POST /v1/agent/list` `{text}` → articles (15 au plus), planificateur du copilote avec
  un plafond ; tâche `POST /v1/jobs/shopping-reminders` (déclencheur toutes les 15 min).
- App cliente : tuile « Mes courses » sur l'accueil → listes → édition → proposition (écran du
  copilote réutilisé, sans zone de saisie) → panier. Notification `shopping_list_due` → la liste.
