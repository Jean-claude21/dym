# Implementation Plan: Référentiel générique

**Branch**: `feat/004-reference-data` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

| Livrable | Contenu |
|---|---|
| Migration `0002_reference_data.sql` | Schéma du référentiel, contraintes d'argent et de pays, libellés multilingues (`jsonb` avec `fr` obligatoire), RLS en lecture seule pour les apps, tables internes sans accès |
| Migration `0003_events_audit.sql` | Journal d'événements avec `public.track_event` (liste blanche, auteur imposé, garde anti-données personnelles, déduplication) et `app.emit_event` ; audit en ajout seul avec `app.audit` |
| Migration `0004_reference_seed.sql` | Valeurs initiales : Togo actif, Ghana inactif, données de la maquette validée |
| Tests pgTAP | Schéma, accès, cohérence, événements et audit, valeurs initiales |
| Côté Dart | `dym_models` (modèles immuables, `fromJson` générés par `json_serializable`) ; `dym_data` (`ReferenceRepository`, `EventsRepository` sur `neon_kit`) ; `LocalizedText` dans `dym_core` |

## Technical Context

**Language/Version**: SQL PostgreSQL 17 ; Dart 3.13.4 / Flutter 3.47.5 (FVM)

**Primary Dependencies**: `json_annotation` 4.12, `json_serializable` 6.x, `build_runner` 2.16, `neon_kit`

**Storage**: PostgreSQL (Neon), tables du schéma `public` exposées en lecture via la Data API

**Testing**: pgTAP (`dym-db test`), `dart test` (modèles, dépôts contre serveur simulé)

**Target Platform**: Neon (Francfort) ; apps Android, iOS, Web

**Project Type**: monorepo mobile + backend Neon

**Performance Goals**: configuration d'un pays en ≤ 9 lectures parallèles ; tables de quelques centaines de lignes

**Constraints**:
- aucun montant flottant (unités mineures, points de base) ;
- aucune écriture depuis les apps ;
- aucune donnée personnelle dans les événements.

**Scale/Scope**: 15 tables, 3 fonctions, 3 migrations, 5 fichiers pgTAP, 2 packages Dart

## Constitution Check

| Principe | Vérification | Statut |
|---|---|---|
| I. Contrat et gates | Spec `reference-data` (Phase 1) ; A-CFG-01..06 | ✅ |
| II. Valider avant de construire | Aucun écran | ✅ (N/A) |
| III. Postgres source de vérité | Contraintes et triggers de cohérence ; auteur des événements imposé en SQL | ✅ |
| IV. Générique | Toute liste (pays, unités, opérateurs, modèles d'IA) en données ; libellés multilingues | ✅ |
| V. Sécurité | RLS sur 15 tables, aucune écriture client, tables internes sans droit, audit en ajout seul, pgTAP d'accès | ✅ |
| VI. Couches | `dym_data → neon_kit, dym_models → dym_core` ; Dart pur | ✅ |
| VII. Qualité | pgTAP et tests Dart ; rejeu sur branche Neon dès l'accès (0013) | ⚠️ comme 003 |
| VIII. Terrain | Lectures en parallèle, résultats typés (hors ligne → `NetworkFailure`) | ✅ |
| IX. Mesurer | Mécanisme d'événements + événements client de `METRICS.md` | ✅ |

## Decisions

| # | Décision | Pourquoi |
|---|---|---|
| D1 | Libellés en `jsonb` (`{"fr": …, "en": …}`), contrainte `? 'fr'` | Une colonne par langue fige les langues. Une table de traductions est lourde pour quelques centaines de lignes |
| D2 | Commission en **points de base** (`int`, 0 à 10 000) | Aucun flottant (constitution IV) |
| D3 | Unicité de la commission active par index partiel `(country_code, coalesce(category_id, zéro)) where valid_to is null` | Sans extension `btree_gist` |
| D4 | Devise du frais de livraison vérifiée par trigger | Contrainte inter-tables |
| D5 | Visibilité par politiques RLS qui joignent le parent (`is_active` du pays, de la ville, du rayon parent) | Un parent désactivé masque ses enfants (cas limite) |
| D6 | `ai_models`, `audit_log`, `events` : RLS activé, aucun `GRANT` aux rôles de l'API | Données internes ; écriture par fonctions `SECURITY DEFINER` seulement |
| D7 | `track_event` : liste blanche en table `event_names(name, emitted_by)` ; propriétés ≤ 4 Ko ; refus des clés `email`, `phone`, `telephone`, `address`, `adresse`, `name`, `nom` et des valeurs qui ressemblent à un email ou à un numéro ; `client_event_id` unique | Constitution IX |
| D8 | **freezed abandonné pour l'instant** : sur Flutter 3.47.5, `flutter_test` fige `test_api`, donc l'analyzer doit être inférieur à 14. Aucune version de freezed n'est compatible avec `stacked_generator` 2.0.4 (source_gen 4.2) et `build_runner` 2.16. Plan B : classes immuables écrites à la main et `fromJson` par `json_serializable` | Point 5 de l'architecture §7, consigné dans 0013 |

## Project Structure

```text
db/migrations/0002_reference_data.sql · 0003_events_audit.sql · 0004_reference_seed.sql
db/tests/010_reference_schema.sql · 011_reference_access.sql · 012_reference_integrity.sql
         013_events_audit.sql · 014_reference_seed.sql
packages/foundation/dym_core/lib/src/i18n/localized_text.dart
packages/domain/dym_models/lib/src/reference/*.dart (+ .g.dart)
packages/data/dym_data/lib/src/{reference_repository.dart, events_repository.dart}
packages/infra/neon_kit/lib/testing.dart          # serveur simulé partagé pour les tests
```

## Complexity Tracking

| Écart | Pourquoi | Alternative rejetée |
|---|---|---|
| Pas de `freezed` (pile constitutionnelle) | Incompatibilité de résolution sur le SDK retenu (D8) | Changer de version de Flutter : contraire à 0006. Retirer Stacked : contraire à 0003 |
