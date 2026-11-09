# Implementation Plan: Finition haut de gamme

**Branch**: `feat/026-premium-foundation` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| VI. Couches | `dymNetworkImage` dans `dym_platform` ; `DymSkeleton` dans `dym_ui` ; retour haptique injecté par la vue | OK |
| VIII. Terrain | Cache des photos (3G) ; squelettes statiques si animations coupées ; cible 48 dp | OK |
| IV. Textes | `cartDeliveryTo`, `cartAddAddress` en français et en anglais | OK |
| VII. Qualité | Analyse, tests Flutter (dont `premium_test.dart`) ; contrôle à l'écran sur staging | OK |

## Décisions

- **Cache** : `cached_network_image` (disque sur mobile, cache du navigateur sur le web) derrière
  `dymNetworkImage`, utilisé par les trois apps et le chat.
- **Squelette** : remplace le cercle de `DiscoveryState` (découverte, panier, wallet…).
- **Panier** : bouton d'en-tête avec compteur animé ; pas de 6e onglet.
- **Commande en un écran** : l'adresse choisie s'affiche dans la ligne « Livraison » ; sans adresse,
  invitation à en ajouter une.
- **Haptique** : ajout au panier (léger), commande réussie (moyen, injecté par la vue pour garder le
  viewmodel testable sans moteur Flutter).
