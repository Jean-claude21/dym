# Plan : Prêt pour le pilote

**Spec** : [spec.md](spec.md)

**Branche** : `feat/022-pilot-readiness`, empilée sur `feat/021-monitoring-nudges`.

## Technique

- **Base** (`0024_profile_settings.sql`) :
  - `public.update_my_profile` ;
  - `public.supported_locales` : langues tirées de `notification_templates`, donc de la
    configuration.
- **Dart** :
  - `AccountRepository.updateProfile` et `supportedLocales` ;
  - `AuthService.updateProfile` et `supportedLocales` ;
  - `LocalePreference`, écoutée par la racine des apps cliente et vendeuse ;
  - écran « Moi » : modification du prénom, choix de la langue, entrées sans destination masquées.
- **Suivi des erreurs** :
  - `DymEnvironment.errorReportingDsn` ;
  - `runWithErrorReporting` (`dym_platform`, client Dart pur `sentry`) autour de chaque app.
    `sentry_flutter` est écarté : ses versions 8 et 9 ne compilent plus avec Kotlin 2, et la 10
    impose minSdk 26 ;
  - Functions : `sentryReporter` (API d'enveloppe, sans dépendance) appelé par `onError` sur les
    5xx.
- **Démarrage** :
  - `configureServices` est séparé de `runApp` dans les trois `main.dart` ;
  - `test/startup_test.dart` dans chaque app ;
  - l'enregistreur vocal est créé à la première écoute.
- **Mobile** :
  - permissions Android (`INTERNET`, `RECORD_AUDIO`) ;
  - descriptions iOS (micro, caméra, galerie) ;
  - noms affichés ;
  - signature de release par `key.properties`.

## Constitution

- **Règles en SQL** : propriété du profil, langues issues de la configuration.
- **Aucune donnée personnelle** dans le suivi des erreurs.
- **Aucun secret dans le dépôt** : DSN et clés de signature passent par la compilation, les
  variables des Functions ou `key.properties` (ignoré par git).
