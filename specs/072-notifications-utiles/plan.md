# Implementation Plan: Notifications plus utiles

**Branch**: `feat/072-notifications` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| III. Postgres source de vérité | Montants, résumés et nuit calme en SQL ; la Function ne fait que transmettre | OK |
| IV. Générique | Format des montants lu dans `currencies` ; fuseau dans `countries` | OK |
| V. Sécurité | Fonctions `security definer` ; réglage écrit par `set_notification_preference` | OK |
| IX. Mesure | Aucune donnée personnelle ajoutée aux paramètres | OK |

## Décisions

- Paramètres complétés au moment de l'envoi : la notification « nouvelle commande » est créée avant
  les lignes de la commande (constaté par le test).
- `quiet_night` rangé avec les préférences (même écran, même fonction) ; vrai = activé.
- Boutons d'action dans la notification et grande photo : reportés (demandent un traitement en
  arrière-plan et des liens d'image publics).
