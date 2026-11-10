# Implementation Plan: App livreur

**Branch**: `feat/041-delivery-app` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres | Proposition, acceptation atomique, limite, gestes du livreur dans la machine d'états SQL | OK |
| IV. Générique | Limite de courses par pays ; zones du référentiel ; aucun lieu en dur | OK |
| V. Sécurité | Tables sans droit direct ; coordonnées de la cliente seulement après acceptation | OK |
| VI. Couches | Nouvelle app `dym_delivery` (Stacked) ; `CourierRepository` dans `dym_data` ; modèles purs dans `dym_models` | OK |
| VII. Qualité | pgTAP, tests Flutter (viewmodels, écrans, démarrage, câblage) ; Neon propre ; staging | OK |
| VIII. Terrain | États vide, chargement, erreur, hors ligne ; cibles ≥ 48 dp ; icône et libellé | OK |

## Décisions

- Migration 0048 :
  - `courier_profiles`, `courier_zones`, `countries.courier_max_active` ;
  - `order_couriers.courier_id` et `accepted_at` ;
  - rôle `courier` dans `order_transition_allowed` et `transition_order` (récupérée, livrée) ;
  - app `delivery` dans `complete_profile`, `push_tokens` et `notification_app` ;
  - notifications `mission_available`, `courier_assigned`, `courier_out_for_delivery`, `courier_delivered`.
- App `apps/dym_delivery` :
  - plateformes copiées de l'app vendeuse ;
  - connexion `dym_auth` (variante livreur) ;
  - inscription ;
  - onglets Missions, Mes courses et Moi.
- Pas de nouvelle maquette : direction validée et démonstration web du gate (ROADMAP, phases 6 à 13).
