# Implementation Plan: Qualité des écrans

**Branch**: `feat/068-screen-quality` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Le refus de remise par la vendeuse est en SQL | OK |
| IV. Générique | Langue tirée du pays (`default_locale`), jamais codée | OK |
| VIII. Terrain | Clavier, lecteur d'écran, écran qui suit l'état réel | OK |

## Décisions

- Migration `0068_courier_roles.sql` : `app.order_has_dym_courier`, `order_json`, `transition_order`.
- `OrderCourier` déplacé dans `order_tracking.dart` (partagé cliente, vendeuse, admin) avec `isDym`.
- `DymFormScaffold` : action dans le contenu quand le clavier est ouvert (tous les formulaires).
- Le champ email était bien annoncé (« [champ] » venait de l'outil de lecture d'écran) : test ajouté.
