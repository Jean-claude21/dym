# Quickstart : Assainissement

## Vérifier

```bash
node db/scripts/dym-db.mjs migrate && node db/scripts/dym-db.mjs test
fvm dart run melos run analyze && fvm dart run melos run test
cd functions && npm audit --omit=dev && npm test
```

## Lot de préparation des tests régularisé (FR-014)

Pays ouverts (0026), admins par défaut (0025, décision 0014), connexion par mot de passe, données de
démonstration. Les scripts `db/scripts/seed-demo.mjs` et `demo-*.mjs` exigent `DYM_TARGET=staging`.

## Avant la production finale

```sql
update public.payment_methods set is_active = false where provider_code = 'simulator';
```

Ne pas définir `PAYMENTS_SIMULATOR_SECRET`, compiler avec `DYM_ENV=production`.
