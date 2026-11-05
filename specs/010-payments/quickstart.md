# Quickstart — Spec 010

## Base

```bash
node db/scripts/dym-db.mjs migrate     # recharge aussi le cache de la Data API
node db/scripts/dym-db.mjs test db/tests/070_payments.sql
```

Attendu : moyen en ligne refusé sans fournisseur disponible ; paiement en attente, confirmations
signées appliquées une seule fois, montant contrôlé ; échec, réessai, passage au cash ; aucune
commande visible de la vendeuse avant paiement.

## Function

```bash
cd functions && npm test
```

Attendu : simulateur absent en production ; page de paiement ; webhook signé, rejeu sans effet,
signature invalide refusée (401) ; réessai et cash.

## Simuler un paiement (branche `staging`)

1. Le simulateur n'existe que si la Function est déployée avec `PAYMENTS_SIMULATOR_SECRET` sur
   une branche qui n'est pas la production :

   ```bash
   export PAYMENTS_SIMULATOR_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
   cd functions && npx neonctl deploy --branch staging --env <fichier .env hors dépôt> --update-existing
   ```

2. Le moyen « Mobile Money (simulé) » est une donnée de configuration, activée pour le pays de
   test de la branche (jamais par une migration) :

   ```sql
   insert into public.payment_methods (country_code, provider_code, label, sort, is_active)
   values ('<pays de test>', 'simulator', '{"fr": "Mobile Money (simulé)"}', 9, true);
   ```

   Les vendeuses l'acceptent à l'étape « Paiement » de leur boutique.

3. Dans l'app cliente (`--dart-define-from-file=config/staging.json`) : panier → paiement
   « Mobile Money (simulé) » → « Commander ». La page du simulateur s'ouvre dans le navigateur :
   - **Paiement réussi** : l'app passe seule à « Commande envoyée » (paiement confirmé) ; la
     commande apparaît dans l'onglet « Commandes » de la vendeuse (relu toutes les 20 s) ;
   - **Paiement échoué** ou **Abandonner** : l'app affiche « Le paiement n'a pas abouti » ;
     « Réessayer » ouvre une nouvelle page, « Payer à la livraison » passe la commande en cash.

## Bout en bout réel

```bash
# URL de config/staging.json dans NEON_LIVE_AUTH_URL, NEON_LIVE_DATA_API_URL, NEON_LIVE_FUNCTIONS_URL
cd packages/data/dym_data && fvm dart test test/order_flow_live_test.dart
```

Attendu : commande multi-boutiques ; paiement simulé réussi (vendeuse : badge et référence) ;
échec, réessai abandonné, passage au cash ; comptes de test supprimés.
