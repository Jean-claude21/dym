# 0004 — Paiements génériques : cash, Moneroo, Chariow

**Statut :** Acceptée · 2026-10-01

## Contexte

Le contrat V1 exige cash à la livraison (majoritaire) et MoMo. La devise dépend du pays.
Vérifications dans la documentation officielle (2026-10-01) :

- **Chariow** : le checkout API exige un `product_id` existant au prix fixé dans Chariow ; le prix
  libre est refusé via l'API ; pas d'endpoint de création de produit ; plateforme de **produits
  numériques** ; pas de partage des encaissements ni d'API de reversement.
- **Moneroo** : montant fixé à chaque paiement, XOF supporté, webhooks, API de reversements, SDK Flutter.

## Décision

Interface `PaymentProvider` côté Functions (`initiate`, `verifyWebhook`, `normalizeEvent`, `refund`,
`payout`), fournisseurs activés par pays dans `payment_methods`.

1. `cash` : premier fournisseur (phase 2, spec `payments`).
2. `moneroo` : MoMo pour les commandes (même spec, dès que le KYC est validé).
3. `chariow` : **offres numériques DYM vendues aux vendeuses** (abonnement, formation), spec `vendor-offers`.

## Conséquences

- L'app ne connaît pas le fournisseur : elle ouvre une URL de paiement et revient par deep link.
- Chaque webhook brut est journalisé ; l'idempotence repose sur l'identifiant d'événement.
- Ajouter un agrégateur = un adaptateur + une ligne de configuration (1 à 2 h).
- Si Chariow confirme un checkout à montant variable pour des biens physiques, son adaptateur
  pourra aussi servir aux commandes.

## Alternatives écartées

Chariow pour les commandes (incompatible, voir contexte) ; capture photo MoMo vérifiée par IA
(fraude, remplacée par une file de vérification manuelle).
