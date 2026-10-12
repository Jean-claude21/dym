# Tâches : Prêt pour le pilote

- [X] T001 Migration `0024_profile_settings.sql` ; pgTAP `190_profile_settings.sql` (9 assertions)
- [X] T002 [US1] `updateProfile`, `supportedLocales`, `LocalePreference` ; écran « Moi » (prénom, langue)
- [X] T003 [US2] Entrées sans destination masquées (vendeuse : adresses, notifications)
- [X] T004 [US3] Suivi des erreurs : apps (`DYM_ERROR_DSN`) et Functions (`ERROR_REPORTING_DSN`) ; tests
- [X] T005 Démarrage : `configureServices` séparé, test de câblage dans chaque app
- [X] T006 [US4] Permissions Android/iOS, noms affichés, signature de release hors dépôt
- [X] T007 Builds de release (web ×3, APK ×2) ; staging et bout en bout
- [ ] T008 Clé de signature, DSN, projet Firebase, identifiants de publication (porteur produit)
