# DYM — Carte des packages

## Règles

1. Un package existe s'il est **générique** (aucune notion DYM), **partagé par au moins deux apps**,
   ou s'il trace une **frontière nette** (design system).
2. Le reste vit **dans l'app**, rangé par feature : `lib/features/<feature>/{data,ui}`.
3. Les dépendances ne descendent que dans un sens :
   `apps → features → ui · data → domain → infra → foundation`. Jamais l'inverse.
4. `foundation` et `domain` sont en **Dart pur** (testables sans Flutter).
5. Un package qui dépend de Stacked est un package de **feature** ; les autres n'en dépendent pas.
   Ainsi, la logique reste indépendante du framework d'UI.

## Arborescence

```text
dym/
├─ .fvmrc · pubspec.yaml (workspace + melos) · analysis_options.yaml
├─ apps/
│  ├─ dym_client/        # Awa
│  ├─ dym_vendor/        # Fatou
│  ├─ dym_admin/         # Ops, Flutter Web
│  ├─ dym_delivery/      # Phase 5, créé sur déclencheur
│  └─ dym_gallery/       # Outil : galerie de validation de dym_ui (non publiée)
├─ packages/
│  ├─ foundation/
│  │  ├─ dym_core/       # Result, Failure, Money, Country, Currency, validateurs, horloge
│  │  └─ dym_l10n/       # ARB fr/en, formats selon la locale
│  ├─ infra/
│  │  ├─ neon_kit/       # Client Neon générique : Auth (Better Auth REST), Data API, Storage, Functions
│  │  └─ dym_platform/   # Push, deep links, images, géolocalisation, stockage sécurisé
│  ├─ domain/
│  │  └─ dym_models/     # Entités freezed + enums reflétant la base
│  ├─ data/
│  │  └─ dym_data/       # Repositories par domaine → Result<T>
│  ├─ ui/
│  │  └─ dym_ui/         # Design tokens, thème, composants, motion
│  └─ features/
│     ├─ dym_auth/       # Écrans + viewmodels Stacked d'authentification (4 apps)
│     ├─ dym_notifications/  # Centre de notifications (créé avec order-lifecycle)
│     ├─ dym_chat/       # Messagerie (créé avec messaging)
│     └─ dym_account/    # Profil, réglages, FAQ, support
├─ functions/            # Neon Functions (TypeScript)
├─ db/                   # migrations/ · seeds/ · tests/ (pgTAP)
└─ site/                 # Site léger (Coolify)
```

## Packages internes

| Package | Catégorie | Dépend de | Consommé par | Créé dans |
|---|---|---|---|---|
| `dym_core` | Fondation | — | Tous | `foundation` |
| `dym_l10n` | Fondation | `intl` | Apps, features, ui | `foundation` |
| `neon_kit` | Infra (générique) | `dym_core` (`Result`, `Failure` seulement), `dio`, `postgrest` | `dym_data`, `dym_platform` | `foundation` (spec 003) |
| `dym_platform` | Infra | `neon_kit`, plugins Flutter | Apps, features | `foundation` (spec 003 : session sécurisée, client Neon) |
| `dym_models` | Domaine | `dym_core`, `json_annotation` (freezed : no-go, décision 0013) | `dym_data`, features, apps | `reference-data` (spec 004) |
| `dym_data` | Données | `neon_kit`, `dym_models` | Features, apps | `reference-data` (spec 004) |
| `dym_ui` | UI (thème généré depuis `docs/design/tokens/dym.tokens.json`) | `dym_core`, `dym_l10n` | Features, apps | `foundation` |
| `dym_auth` | Feature | Stacked, `dym_data`, `dym_ui` | 4 apps | `auth` |
| `dym_notifications` | Feature | idem | Client, vendeur, livreur | `order-lifecycle` |
| `dym_chat` | Feature | idem | Client, vendeur | `messaging` |
| `dym_account` | Feature | idem | Client, vendeur, livreur | `auth` |

## Dépendances externes

Versions confirmées par une résolution réelle sur la version Flutter retenue (voir
`decisions/0006-flutter-version.md`).

| Usage | Package | Où |
|---|---|---|
| MVVM, routes, injection | `stacked`, `stacked_services`, `stacked_generator` | Apps, features |
| Modèles | `json_serializable`, `json_annotation` (freezed différé, décision 0013) | `dym_models` |
| Data API | `postgrest` (client PostgREST autonome) | `neon_kit` |
| HTTP (Auth, Functions) | `dio` | `neon_kit` |
| Jetons | `flutter_secure_storage` | `dym_platform` |
| Connexion Google | `google_sign_in` | `dym_platform` |
| Push | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` | `dym_platform` |
| Images | `image_picker`, `flutter_image_compress`, `cached_network_image` | `dym_platform`, `dym_ui` |
| Localisation | `geolocator` | `dym_platform` |
| Micro (recherche vocale, spec 018) | `record` | `dym_platform` |
| Deep links, paiement | `app_links`, `url_launcher` | `dym_platform` |
| i18n | `intl`, `flutter_localizations` | `dym_l10n` |
| Motion et illustration | `rive`, `flutter_animate`, `flutter_svg` | `dym_ui` |
| Catalogue de composants | `widgetbook` | `apps/dym_widgetbook` (outil, non livré) |
| Erreurs | `sentry_flutter` (compatible GlitchTip) | Apps |
| Tests | `mocktail`, `patrol` | Tous |
| Monorepo | `melos` | Racine |
| Lints | `very_good_analysis` | Racine |

**Écartés :** `supabase_flutter` (inutile, on garde seulement `postgrest`) ; `flutter_neon` (connexion
directe à la base depuis l'appareil, donc identifiants dans l'app) ; `fpdart` (les classes scellées
de Dart suffisent pour `Result`) ; `riverpod`/`go_router` (Stacked est retenu) ; base locale de type
Hive/Drift (le panier est côté serveur).

## Functions (TypeScript)

`ai` + `@ai-sdk/openai` (IA, sorties structurées validées par `zod`) · `@neondatabase/serverless` ·
SDK S3 + presigner · `sharp` (miniatures) · FCM HTTP v1 · `zod` (validation des entrées et webhooks).
