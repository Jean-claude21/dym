# Tasks: Référentiel générique

**Input**: `specs/004-reference-data/` (spec, plan, data-model)

**Tests**: demandés (SC-001 à SC-004).

## Phase 1: Setup

- [ ] T001 Créer `packages/domain/dym_models` (json_serializable) et `packages/data/dym_data`, les ajouter au workspace `pubspec.yaml`
- [ ] T002 Consigner le no-go freezed dans `docs/architecture/decisions/0013-validations-neon.md` (point 5) et `docs/architecture/PACKAGES.md`

## Phase 2: Foundational

- [ ] T003 `LocalizedText` dans `packages/foundation/dym_core/lib/src/i18n/localized_text.dart` + tests
- [ ] T004 Exposer le serveur simulé de test dans `packages/infra/neon_kit/lib/testing.dart` (réutilisé par `dym_data`)

## Phase 3: US1 + US2 + US3 — Référentiel lisible, protégé, cohérent (P1) 🎯 MVP

- [ ] T005 [US1] Migration `db/migrations/0002_reference_data.sql` : tables, contraintes (`minor_units between 0 and 3`, `label ? 'fr'`, `rate_bps between 0 and 10000`, montants `>= 0`), index uniques partiels, triggers (devise du frais = devise du pays, 2 niveaux de rayons, `updated_at`), RLS et politiques de lecture par parent actif, `GRANT SELECT` ciblés
- [ ] T006 [US1] Migration `db/migrations/0004_reference_seed.sql` : TG actif (XOF, Lomé, quartiers), GH inactif (GHS, Accra), rayons du design, 3 origines, unités par pays, fournisseurs, moyens de paiement (cash actif, Moneroo inactif), frais de la maquette, commission 0, flags désactivés, modèle d'IA inactif
- [ ] T007 [P] [US1] `db/tests/010_reference_schema.sql` : tables, RLS, colonnes clés
- [ ] T008 [P] [US2] `db/tests/011_reference_access.sql` : anonyme et connecté lisent les actifs, pays inactif et enfants invisibles, aucune écriture, tables internes vides, commissions réservées aux connectés
- [ ] T009 [P] [US3] `db/tests/012_reference_integrity.sql` : chaque incohérence de FR-006 refusée
- [ ] T010 [P] [US1] `db/tests/014_reference_seed.sql` : valeurs initiales, activation du Ghana par une seule mise à jour (SC-001)

## Phase 4: US4 — Événements et audit (P2)

- [ ] T011 [US4] Migration `db/migrations/0003_events_audit.sql` : `event_names`, `events`, `audit_log` (ajout seul), `app.assert_no_personal_data`, `public.track_event`, `app.emit_event`, `app.audit` ; noms d'événements de `METRICS.md`
- [ ] T012 [US4] `db/tests/013_events_audit.sql` : auteur imposé, nom inconnu refusé, email/téléphone refusés (clé et valeur, imbriqués), > 4 Ko refusé, déduplication, événement serveur refusé côté client, audit illisible et non modifiable

## Phase 5: Côté Dart (US1, US4)

- [ ] T013 [US1] Modèles `packages/domain/dym_models/lib/src/reference/` + génération + tests de `fromJson`
- [ ] T014 [US1] `ReferenceRepository` dans `packages/data/dym_data/lib/src/reference_repository.dart` (`countries`, `countryConfig(code)` en lectures parallèles) + tests contre serveur simulé
- [ ] T015 [US4] `EventsRepository.track` (identifiant client uuid v4, RPC `track_event`) + tests

## Phase 6: Polish

- [ ] T016 Mettre à jour `docs/architecture/ARCHITECTURE.md` §3 (tables réelles) et `quickstart.md` ; vérification finale (analyse, tests Dart, base) ; PR

## Dependencies

T001-T004 → T005 → T006 → tests T007-T010 ; T011 → T012 ; T013 → T014 → T015 ; T016 en dernier.
