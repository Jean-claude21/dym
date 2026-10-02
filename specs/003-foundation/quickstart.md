# Quickstart — socle technique

## Base locale (PostgreSQL 17 installé, sans conteneur)

```bash
node db/scripts/dym-db.mjs local start   # cluster .local/pgdata sur 54329, base dym + imitations Neon
node db/scripts/dym-db.mjs migrate
node db/scripts/dym-db.mjs test          # résumé pgTAP
```

## Dart et apps

```bash
fvm dart run melos bootstrap
fvm dart run melos run generate          # build_runner (Stacked) dans les apps
fvm dart run melos run analyze
fvm dart run melos run test
cd apps/dym_client && fvm flutter run -d chrome --dart-define=DYM_ENV=dev
```

## Functions

```bash
cd functions && npm ci && npm test
```

## Scénarios de validation

| # | Action | Attendu |
|---|---|---|
| 1 | `local start`, `migrate`, `test` | Tout passe en < 2 min (SC-001) |
| 2 | Relancer `migrate` | « Aucune migration à appliquer » |
| 3 | Modifier `0001_platform.sql`, relancer `migrate` | Refus : empreinte modifiée |
| 4 | Créer une table `public` sans RLS dans une migration de test, lancer `test` | La garde de sécurité échoue |
| 5 | Lancer chaque app en anglais | Textes en anglais, premier écran sans débordement |
| 6 | Avec l'accès Neon : `migrate --url` et `test --url` sur une branche | Mêmes résultats qu'en local (US5) |
