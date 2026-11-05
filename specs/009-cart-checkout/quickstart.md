# Quickstart — Spec 009

## Base

```bash
node db/scripts/dym-db.mjs local start
node db/scripts/dym-db.mjs migrate
node db/scripts/dym-db.mjs test db/tests/060_addresses.sql db/tests/061_cart.sql db/tests/062_orders.sql
```

Attendu : adresses privées et une seule par défaut ; panier groupé par boutique, frais selon la
maquette 05 (base + supplément, gratuité au seuil) ; refus des problèmes bloquants ; commande
idempotente, montants figés, stocks décrémentés, panier vidé, `order_created` avec
`stores_count`.

## Function

```bash
cd functions && npm test
```

Attendu : `POST /v1/orders` exige jeton et `Idempotency-Key` ; les refus SQL deviennent `422`
avec leur code.

## Apps

```bash
fvm dart run melos run analyze
fvm dart run melos run test
cd apps/dym_client && fvm flutter run -d chrome --web-port 5555 --dart-define-from-file=../../config/staging.json
```

Parcours : ajouter deux produits de deux boutiques → mini-panier → panier (05) → Livraison (34),
nouvelle adresse par la position (36) → Commander → Commande envoyée (37). Rejouer la
confirmation hors ligne puis en ligne : un seul achat.

## Galerie

`cd apps/dym_gallery && fvm flutter run -d chrome` : écrans 34 à 38.
