# Implementation Plan: Socle technique

**Branch**: `feat/003-foundation` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

- **Base de données** : un dossier `db/`, avec :
  - des migrations SQL numérotées ;
  - des imitations Neon réservées au local ;
  - des tests pgTAP ;
  - un outil en ligne de commande Node sans dépendance, qui pilote `psql` et un cluster
    PostgreSQL 17 local (`initdb`/`pg_ctl`, port 54329, sans conteneur).
- **`neon_kit`** (Dart pur) : client Better Auth REST, Data API via `postgrest`, Functions via
  `dio`, avec jeton à renouvellement unique, politique de nouvelle tentative et échecs typés.
- **`functions/`** : projet TypeScript Neon Functions (`neon.ts`, Hono, `jose`, `zod`, `vitest`).
- **Fondations Dart** :
  - `Result`/`Failure` et `DymEnvironment` dans `dym_core` ;
  - `dym_l10n` (ARB fr/en) ;
  - `dym_platform` (stockage sécurisé de session).
- **Apps** : trois apps Stacked (`dym_client`, `dym_vendor`, `dym_admin`).
- **CI** : job pgTAP sur le PostgreSQL du runner, et job Functions.

## Technical Context

**Language/Version**:
- Dart 3.13.4 / Flutter 3.47.5 (FVM) ;
- TypeScript 5 sur Node 24 (Neon), Node ≥ 22 en local ;
- SQL PostgreSQL 17.

**Primary Dependencies**:

| Où | Dépendances |
|---|---|
| `neon_kit` | `dio` 5.11, `postgrest` 2.9, `http` |
| Apps | `stacked` 3.5, `stacked_services`, `stacked_generator` 2.0, `build_runner` |
| `dym_platform` | `flutter_secure_storage` 11 |
| `functions` | `hono` 4, `jose` 6, `zod` 4, `@neon/config`, `@neon/env`, `@neon/functions`, `pg` 8, `vitest` 5 |
| Base | pgTAP 1.3.4 |

**Storage**: PostgreSQL 17 (Neon en cible, cluster local en développement)

**Testing**:

| Partie | Outil |
|---|---|
| SQL | pgTAP via `node db/scripts/dym-db.mjs test` |
| Dart pur | `dart test` |
| Flutter | `flutter test` |
| Functions | `vitest` |

**Target Platform**:

| Cible | Plateformes |
|---|---|
| Apps cliente et vendeuse | Android, iOS, Web |
| Admin | Web |
| Functions | Node 24 sur Neon |

**Project Type**: monorepo mobile + backend Neon

**Performance Goals**: base locale prête, migrations et tests en < 2 min (SC-001)

**Constraints**:
- aucun conteneur ;
- aucun secret dans le dépôt ;
- les imitations Neon ne sont jamais appliquées hors local ;
- retry réseau ou 5xx seulement.

**Scale/Scope**:
- 1 migration socle, 3 fichiers de tests pgTAP ;
- 4 packages Dart (dont 3 nouveaux) et 3 apps ;
- 1 projet de Functions.

## Constitution Check

| Principe | Vérification | Statut |
|---|---|---|
| I. Contrat V1 et gates | Spec `foundation` de la roadmap (Phase 1). Le gate de la Phase 0 est confirmé par le porteur produit le 2026-10-02 (terrain fait) | ✅ |
| II. Valider avant de construire | Aucun écran métier : premier écran technique remplacé par `auth` | ✅ |
| III. Postgres source de vérité | Socle SQL (schéma `app`, identité courante) ; Functions limitées aux effets | ✅ |
| IV. Générique | `neon_kit` sans notion DYM ; environnements et URLs à la compilation ; textes en ARB | ✅ |
| V. Sécurité | Test pgTAP de garde : toute table de `public` sans RLS fait échouer la CI ; droits par défaut de la Data API révoqués ; secrets déclarés, jamais stockés | ✅ |
| VI. Couches | `apps → … → infra (neon_kit, dym_platform) → foundation (dym_core, dym_l10n)` ; Stacked seulement dans les apps | ✅ |
| VII. Qualité | pgTAP, `dart test`, `flutter test` et `vitest` en CI. La démo Android et la branche Neon attendent l'accès (US5) | ⚠️ voir Complexity Tracking |
| VIII. Terrain | Retry, renouvellement unique, échecs typés ; écrans aux 7 tailles | ✅ |
| IX. Mesurer | Aucun parcours de `METRICS.md` | ✅ (N/A) |

## Project Structure

### Documentation (this feature)

```text
specs/003-foundation/
├── plan.md · research.md · data-model.md · quickstart.md · tasks.md
├── contracts/{db-cli.md, neon_kit.md, functions-http.md}
└── checklists/requirements.md
```

### Source Code

```text
db/
├── migrations/0001_platform.sql
├── local/neon_shims.sql          # imitation Neon, jamais appliquée sur Neon
├── tests/_helpers.sql            # tests.login_as(), chargé dans chaque transaction
├── tests/000_security_guard.sql  # toute table exposée a RLS
├── tests/001_platform.sql
└── scripts/dym-db.mjs            # local start|stop|reset|status · migrate · test
packages/
├── foundation/dym_core/          # + Result, Failure, DymEnvironment
├── foundation/dym_l10n/          # ARB fr/en, gen-l10n
├── infra/neon_kit/               # NeonClient : auth, data, functions
└── infra/dym_platform/           # SecureSessionStore (flutter_secure_storage)
apps/
├── dym_client/ · dym_vendor/ · dym_admin/   # Stacked : app/, ui/views/startup/
functions/
├── neon.ts · package.json · tsconfig.json · vitest.config.ts
└── src/{index.ts, app.ts, lib/{auth.ts, errors.ts, validate.ts, db.ts}, routes/health.ts} + test/
```

**Structure Decision** : conforme à `PACKAGES.md`, avec deux précisions consignées dans la
recherche :
- `dym_models` et `dym_data` arrivent avec `reference-data` ;
- `neon_kit` dépend de `dym_core`, seulement pour `Result`/`Failure`.

## Complexity Tracking

| Écart | Pourquoi | Alternative plus simple rejetée |
|---|---|---|
| pgTAP et démo Android pas encore sur branche Neon (VII) | Accès Neon non branché sur la machine (secrets non lisibles par l'agent) | Attendre l'accès : bloquerait toutes les specs ; on reproduit Neon en local et on rejoue sur Neon dès l'accès (US5) |
| Outil base en Node sans dépendance | Multiplateforme (Windows et CI Linux), réutilise le Node des Functions | Scripts PowerShell + bash : logique dupliquée ; `pg_prove` : Perl absent sous Windows |
