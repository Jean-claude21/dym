# Tasks: Socle technique

**Input**: `specs/003-foundation/` (plan, spec, research, data-model, contracts, quickstart)

**Tests**: demandés (FR-004, FR-006, SC-002, SC-003, SC-005).

## Phase 1: Setup

- [X] T001 Ignorer `.local/` (cluster et pgTAP locaux) dans `.gitignore` ; consigner le gate Phase 0 (terrain confirmé le 2026-10-02) dans `docs/product/ROADMAP.md`
- [X] T002 Ajouter au workspace `packages/foundation/dym_l10n`, `packages/infra/neon_kit`, `packages/infra/dym_platform`, `apps/dym_client`, `apps/dym_vendor`, `apps/dym_admin` dans `pubspec.yaml` (racine) et les scripts Melos `generate`, `db:*`, `functions:test`

## Phase 2: Foundational

- [X] T003 [P] `Result<T>` et `Failure` scellés dans `packages/foundation/dym_core/lib/src/result/` + tests `packages/foundation/dym_core/test/result_test.dart`
- [X] T004 [P] `DymEnvironment.fromDefines()` dans `packages/foundation/dym_core/lib/src/env/environment.dart` + tests (production sans URL → erreur)

## Phase 3: User Story 1 — Base versionnée qui se comporte comme Neon (P1) 🎯 MVP

- [X] T005 [US1] Outil `db/scripts/dym-db.mjs` : `local start|stop|reset|status`, `migrate` (empreinte SHA-256, refus si modifiée), `test` (BEGIN/helpers/fichier/ROLLBACK, analyse TAP)
- [X] T006 [P] [US1] Imitation Neon `db/local/neon_shims.sql` (rôles, `auth.user_id()`, `auth.uid()`, `neon_auth."user"`)
- [X] T007 [P] [US1] Aides de test `db/tests/_helpers.sql` (`tests.create_user`, `login_as`, `login_anonymous`, `logout`)
- [X] T008 [US1] Migration `db/migrations/0001_platform.sql` (schémas `app`, `dym_meta` côté outil ; `app.current_user_id()`, `app.set_updated_at()` ; révocation des droits par défaut de la Data API)
- [X] T009 [P] [US1] Garde de sécurité `db/tests/000_security_guard.sql` (toute table de `public` a RLS ; `anonymous` n'écrit nulle part)
- [X] T010 [P] [US1] Tests du socle `db/tests/001_platform.sql` (identité courante sous `authenticated`/`anonymous`, trigger `updated_at`)
- [X] T011 [US1] Job CI `database` dans `.github/workflows/ci.yml` (PostgreSQL du runner + pgTAP via apt, `--neon-shims`, `migrate`, `test`)
- [X] T012 [US1] Vérifier les scénarios 1 à 4 du quickstart (idempotence, empreinte, garde)

## Phase 4: User Story 2 — Client Dart unique pour Neon (P1)

- [X] T013 [US2] Package `packages/infra/neon_kit` : `NeonConfig`, `NeonSession`, `SessionStore` + `InMemorySessionStore`
- [X] T014 [US2] Conversion d'erreurs HTTP/Postgrest → `Failure` dans `packages/infra/neon_kit/lib/src/errors.dart`
- [X] T015 [US2] Politique de nouvelle tentative (intercepteur dio) dans `packages/infra/neon_kit/lib/src/retry.dart`
- [X] T016 [US2] `NeonAuthClient` (OTP email, Google, session, jeton, renouvellement unique, déconnexion, `sessionChanges`) dans `packages/infra/neon_kit/lib/src/auth/`
- [X] T017 [US2] `NeonDataClient` (postgrest + `http.Client` authentifié, 401, retry GET, `run`, `rpc`) dans `packages/infra/neon_kit/lib/src/data/`
- [X] T018 [US2] `NeonFunctionsClient` (dio, jeton, `Idempotency-Key`, erreurs normalisées) dans `packages/infra/neon_kit/lib/src/functions/`
- [X] T019 [US2] Tests `packages/infra/neon_kit/test/` : OTP, Google, restauration, renouvellement anticipé, renouvellement unique concurrent (SC-003), 401 → une nouvelle tentative, retry réseau ou 5xx ≤ 3, aucun retry 4xx (SC-002), corps non JSON
- [X] T020 [P] [US2] `SecureSessionStore` (`flutter_secure_storage`) dans `packages/infra/dym_platform` + test avec stockage simulé

## Phase 5: User Story 3 — Projet de Functions (P2)

- [X] T021 [US3] Projet `functions/` (`package.json`, `tsconfig.json`, `neon.ts`, `vitest.config.ts`), `.gitignore` des `.env*`
- [X] T022 [US3] `src/lib/errors.ts`, `src/lib/validate.ts` (zod → 422), `src/lib/auth.ts` (jose JWKS, émetteur), `src/lib/db.ts` (pool `pg`)
- [X] T023 [US3] `src/app.ts` (Hono, CORS, gestion d'erreurs) + `src/routes/health.ts` + `src/index.ts`
- [X] T024 [US3] Tests `functions/test/` : santé, 401 sans/avec mauvais jeton, jeton valide, 422 normalisé
- [X] T025 [US3] Job CI `functions` (npm ci, typecheck, test)

## Phase 6: User Story 4 — Apps qui démarrent (P2)

- [X] T026 [US4] Package `packages/foundation/dym_l10n` (ARB fr/en, gen-l10n, `DymLocalizations`) + test
- [X] T027 [US4] App `apps/dym_client` (flutter create, Stacked : `app.dart`, `StartupView`/`StartupViewModel`, environnement, `dym_ui`, l10n)
- [X] T028 [P] [US4] App `apps/dym_vendor` (même ossature, fond vert profond de l'app vendeuse)
- [X] T029 [P] [US4] App `apps/dym_admin` (web, `DymAdaptiveScaffold`)
- [X] T030 [US4] Génération Stacked (`melos run generate`) + tests widget des 3 apps : fr/en, 7 tailles, production sans configuration refusée

## Phase 7: User Story 5 — Validations sur Neon (P3)

- [X] T031 [US5] Décision `docs/architecture/decisions/0013-validations-neon.md` : points §7 avec statut (validé en local, en attente d'accès), essai prévu et plan B

## Phase 8: Polish

- [X] T032 [P] Mettre à jour `AGENTS.md` (commandes base et Functions), `README.md`, `docs/architecture/PACKAGES.md` (dépendance `neon_kit → dym_core`, `dym_models`/`dym_data` avec `reference-data`)
- [X] T033 Vérification finale : `melos run analyze`, `melos run test`, `test:dart`, base `migrate` + `test`, `functions` ; résultats dans `quickstart.md`

## Dependencies

Setup → Foundational → US1 et US2 en parallèle (US2 dépend de T003) → US3 → US4 (dépend de T026) → US5 → Polish.
