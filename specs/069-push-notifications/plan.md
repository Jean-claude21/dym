# Implementation Plan: Notifications du téléphone

**Branch**: `feat/069-push-firebase` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

## Constitution Check

| Principe | Application | État |
|---|---|---|
| IV. Fournisseurs derrière une interface | `PushNotifications` isole Firebase ; l'envoi reste dans la Function | OK |
| V. Sécurité | Fichiers et clé hors dépôt ; jeton enregistré sous la session | OK |
| VIII. Terrain | Temps réel et relecture gardés si le push manque | OK |

## Décisions

- `flutter_local_notifications` 19.5 (la 23 exige le SDK 37, au-delà d'AGP 9.1).
- `getToken` gardé (jeton attendu par l'envoi FCM v1) malgré sa dépréciation.
- Plugin Google Services appliqué seulement si le fichier est présent ; canal `dym_orders` par défaut.
- Identifiants Android alignés sur Firebase (décision 0017 rectifiée).
