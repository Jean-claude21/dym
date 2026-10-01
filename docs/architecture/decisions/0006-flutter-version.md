# 0006 — Version de Flutter

**Statut :** Acceptée · 2026-10-01

## Contexte

Règle fixée par l'équipe : la version retenue est celle qui permet de résoudre **nos packages à
leur dernière version**. FVM 4.3.1 ; dernières versions stables disponibles : 3.47.5 (18/09/2026),
3.44.9, 3.41.x, 3.38.6 (déjà installée).

Plusieurs packages imposent un SDK récent dans leur dernière version :
`freezed` 4.0.2 et `very_good_analysis` 11.0.0 exigent Dart ≥ 3.13 (donc Flutter 3.47) ;
`cached_network_image` 4.0.4, `app_links` 7.2.1 et `widgetbook` 3.25.0 exigent Flutter ≥ 3.44.

## Vérification (projet sonde, 2026-10-01)

Sur **Flutter 3.47.5 / Dart 3.13.4** :

- Toutes les dépendances directes se résolvent à leur **dernière version** (`pub outdated` : à jour).
- `build_runner` génère les fichiers Stacked (`app.router.dart`, `app.locator.dart`), freezed et
  json_serializable ; `flutter analyze` : aucun problème ; test d'aller-retour JSON : vert.
- Compatibilité des générateurs : `stacked_generator` 2.0.4, `freezed` 4.0.2,
  `json_serializable` 6.14.1, `build_runner` 2.16.1 partagent `analyzer` 14.x.

| Package | Version | Package | Version |
|---|---|---|---|
| stacked | 3.5.0 | stacked_services | 1.6.0 |
| stacked_generator | 2.0.4 | build_runner | 2.16.1 |
| freezed | 4.0.2 | freezed_annotation | 3.1.0 |
| json_serializable | 6.14.1 | json_annotation | 4.12.0 |
| postgrest | 2.9.1 | dio | 5.11.1 |
| flutter_secure_storage | 11.2.0 | google_sign_in | 7.2.0 |
| firebase_core | 4.15.0 | firebase_messaging | 16.7.0 |
| flutter_local_notifications | 22.3.1 | image_picker | 1.2.3 |
| flutter_image_compress | 2.5.1 | cached_network_image | 4.0.4 |
| geolocator | 14.1.1 | app_links | 7.2.1 |
| url_launcher | 6.3.2 | intl | 0.20.3 |
| sentry_flutter | 9.30.1 | rive | 0.14.11 |
| flutter_animate | 4.5.2 | flutter_svg | 2.3.0 |
| widgetbook | 3.25.0 | logger | 2.8.0 |
| mocktail | 1.0.5 | patrol | 4.10.0 |
| very_good_analysis | 11.0.0 | melos | 8.9.0 |

## Décision

**Flutter 3.47.5** (Dart 3.13.4), épinglé dans `.fvmrc`. Toute commande passe par `fvm flutter` /
`fvm dart`.

## Conséquences

- `equatable` est exclu : sa version 3 entre en conflit avec `patrol` (qui exige `^2.1`) ;
  l'égalité est fournie par freezed.
- `sentry_flutter` doit être contraint explicitement à `^9.30.1` (sans contrainte, la résolution
  choisit 8.x).
- Montée de version : on rejoue la sonde (résolution + génération + analyse + test) avant de
  modifier `.fvmrc`.

## Alternatives écartées

3.44.9 : freezed 4 et very_good_analysis 11 non résolubles. 3.38.6 : la moitié des dernières
versions non résolubles.
