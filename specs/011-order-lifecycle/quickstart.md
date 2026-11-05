# Quickstart — Spec 011

## Base

```bash
node db/scripts/dym-db.mjs migrate
node db/scripts/dym-db.mjs test db/tests/080_order_lifecycle.sql db/tests/081_notifications.sql
```

Attendu : toutes les paires de transitions par rôle et par mode ; saut d'étape et état changé
refusés ; stock rendu au refus et à l'annulation ; remboursement marqué après un paiement en
ligne ; encaissement une seule fois ; notifications à chaque étape ; file de push réservée une
fois, avec le texte de la langue de la personne.

## Function

```bash
cd functions && npm test
```

Attendu : `POST /v1/orders/:id/transitions` et `/cash-collected` ; après chaque geste réussi, les
push en attente partent (FCM si `FCM_SERVICE_ACCOUNT` est défini, sinon ignorés et marqués).

## Activer les push (dès que le projet Firebase existe)

1. Compte de service Firebase (JSON) dans la variable `FCM_SERVICE_ACCOUNT` du déploiement
   (fichier `.env` hors dépôt), puis `neon deploy`.
2. Enregistrement du téléphone dans les apps (`register_push_token`) : à brancher avec le plugin
   Firebase des apps, avec ses fichiers de configuration (hors dépôt).

## Bout en bout réel (staging)

```bash
cd packages/data/dym_data && fvm dart test test/order_flow_live_test.dart
```

Attendu, en plus des specs 009 et 010 : une commande cash va de « nouvelle » à « livrée » puis
encaissée (saut d'étape et double geste refusés) ; une autre est refusée avec sa raison ; une
autre est annulée par la cliente ; la cliente a une notification par étape ; la vendeuse est
prévenue de l'annulation.

## Apps

- Cliente : onglet « Commandes » (43), suivi (06), cloche et centre (44), « Moi › Notifications »
  (46). L'état se relit toutes les 20 s.
- Vendeuse : onglet « Commandes » avec Nouvelles / En cours / Terminées ; une nouvelle commande
  joue le son système et vibre ; « Nouvelle commande ! » (08) avec Accepter et Refuser (45) ;
  bouton de l'étape suivante ; « J'ai encaissé … » pour le cash livré.
