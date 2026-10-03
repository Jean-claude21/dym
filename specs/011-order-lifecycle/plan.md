# Implementation Plan: Cycle de vie des commandes et notifications

**Branch**: `feat/011-order-lifecycle` | **Date**: 2026-10-03 | **Spec**: [spec.md](spec.md)

## Summary

- **Migration `0013_order_lifecycle.sql`** :
  - statuts étendus, horodatages, raison, auteur de l'annulation, encaissement, remboursement à
    faire ; `order_status_events` (historique) ;
  - `app.transition_order(user, order, to, reason)` : règles FR-001, verrou de ligne, stock rendu,
    remboursement marqué, événements, notifications ; `app.confirm_cash(user, order)` ;
  - `notifications`, `notification_preferences`, `push_tokens` ; déclencheurs : nouvelle commande
    visible (cash créée, paiement confirmé, passage au cash) → vendeuse ; paiement confirmé ou
    échoué → cliente ;
  - lectures : `my_orders`, `my_order` (frise, ETA, gestes permis), `my_store_orders(p_scope)`
    redéfinie (nouvelles, en cours, terminées), `my_store_order` avec historique et gestes
    permis ; `my_notifications`, `unread_notifications_count`, `mark_notifications_read`,
    `my_notification_preferences`, `set_notification_preference`, `register_push_token` ;
  - `app.pending_pushes(limit)` et `app.mark_pushed(ids, outcome)` pour la Function.
- **Functions** :
  - `POST /v1/orders/:id/transitions` `{to, reason}` et `POST /v1/orders/:id/cash-collected` ;
  - `PushSender` : `fcmPushSender` (compte de service, OAuth JWT, API HTTP v1) si
    `FCM_SERVICE_ACCOUNT` est défini, sinon envoi ignoré et marqué ;
  - après chaque route qui crée des notifications (commande, paiement, transition, webhook) :
    envoi des push en attente.
- **Dart** : `OrderStatus`, `OrderSummary`, `OrderTrack`, `AppNotification`,
  `NotificationPreference` ; `OrderTrackingRepository`, `NotificationRepository` ; transitions dans
  `VendorOrderRepository`.
- **App cliente** : onglet « Commandes » (43), suivi (06, rafraîchi toutes les 20 s, annulation),
  centre (44) avec compteur, réglages (46) depuis « Moi ».
- **App vendeuse** : onglets nouvelles / en cours / terminées, alerte (son système + vibration) à
  l'arrivée d'une commande, « Nouvelle commande ! » (08), gestes par étape, refus (45),
  encaissement.
- **Galerie** : 43 à 46, et le vrai suivi (47) et la vraie nouvelle commande (48) à côté de 06 et
  08.

## Constitution Check

| Principe | Vérification | Statut |
|---|---|---|
| I | Spec `order-lifecycle`, IDs cités | ✅ |
| II | 06 et 08 validées ; 43 à 46 générées, à valider | ⚠️ validation |
| III | Transitions, stock, remboursement, ETA et notifications décidés en SQL | ✅ |
| IV | Raisons de refus en codes traduits par l'app ; aucun texte stocké | ✅ |
| V | RLS sur les nouvelles tables ; gestes par Function ; historique ; pgTAP croisés | ✅ |
| VI | Features dans les apps ; dépôts dans `dym_data` | ✅ |
| VII | pgTAP, Function, Flutter, bout en bout staging | ✅ |
| VIII | Clé de requête sur chaque geste ; 4 états ; 7 tailles | ✅ |
| IX | Événements de commande serveur | ✅ |

## Decisions

| # | Décision | Pourquoi |
|---|---|---|
| D1 | Une seule fonction de transition, table de règles par rôle et mode | Machine à états testable par paires |
| D2 | `expected` (statut vu par l'app) obligatoire : refus si l'état a changé | Double tap et deux téléphones |
| D3 | Notification = type + paramètres, texte traduit par l'app | Générique (langues, pays) |
| D4 | Push envoyés par la Function à partir d'une file en base (`pushed_at`) | Jamais deux fois ; pas de push perdu si FCM tombe |
| D5 | Sans FCM, relecture 20 s + son système et vibration | Pas de dépendance nouvelle avant Firebase |
| D6 | Raison de refus : code (`out_of_stock`, `too_busy`, `area_not_served`, `other`) + précision libre | Mesurable, traduisible |

## Complexity Tracking

Aucune dérogation.
