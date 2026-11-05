# Tasks: Authentification, profils et rôles

## Phase 1: Setup

- [X] T001 Maquettes 09-15 générées (direction validée) dans `docs/design/screens/` + `docs/design/MOCKUPS.md` (parcours 1, admin)
- [X] T002 Packages `packages/features/dym_auth` et `packages/features/dym_account` (Stacked) ajoutés au workspace

## Phase 2: Base (US3, US1, US5, US6)

- [X] T003 Migration `db/migrations/0005_profiles_roles.sql` : `profiles` (prénom 1-40, pays déduit, quartier, langue, photo), `user_roles`, RLS (soi-même seulement, colonnes modifiables : prénom, quartier, langue), `app.has_role`, `app.is_admin`, `public.me`, `public.complete_profile`, `public.record_sign_in`, `public.delete_my_account`, `app.account_deletion_blockers`, `app.grant_role`/`app.revoke_role` (admin + audit), noms d'événements `account_deleted`
- [X] T004 [P] `db/tests/020_profiles_roles.sql` : accès croisés refusés, auto-attribution admin refusée, pays non modifiable, complétion idempotente et événement unique, rôle selon l'app
- [X] T005 [P] `db/tests/021_account_deletion.sql` : suppression effective (utilisateur, profil, rôles), audit et événement sans donnée personnelle, seconde tentative sans effet
- [X] T006 [P] `db/tests/022_admin_roles.sql` : attribution et retrait par admin avec audit, refus pour non admin, connexion admin auditée

## Phase 3: Dart données (US1-US6)

- [X] T007 `dym_models` : `Profile`, `UserRole`, `Me` + tests
- [X] T008 `dym_data` : `AccountRepository` (`me`, `completeProfile`, `recordSignIn`, `deleteMyAccount`) + tests serveur simulé
- [X] T009 `dym_platform` : `GoogleIdTokenProvider` (interface + implémentation `google_sign_in`, désactivée sans identifiant)

## Phase 4: Écrans (US1, US2, US4)

- [X] T010 ARB : textes d'authentification et de compte (fr, en)
- [X] T011 `dym_auth` : `AuthService` (état : déconnecté → code envoyé → connecté sans profil → prêt), `WelcomeView` (3 écrans, Passer), `EmailView`, `CodeView` (6 chiffres, renvoi 60 s), `ProfileSetupView` (prénom, quartiers)
- [X] T012 Tests `dym_auth` : viewmodels (email invalide, code faux, réseau, Google annulé, profil) et vues aux 7 tailles fr/en 130 %

## Phase 5: Compte et admin (US5, US6)

- [X] T013 `dym_account` : `AccountView` (« Moi », déconnexion, suppression avec confirmation) + tests
- [X] T014 Apps cliente et vendeuse : routes (démarrage → bienvenue ou accueil provisoire ou onboarding), app vendeuse au rôle `vendor`
- [X] T015 Admin : connexion Google seule, refus sans rôle admin, minuteur d'inactivité 30 min + tests

## Phase 6: Polish

- [X] T016 Galerie : écrans d'authentification dans `dym_gallery` (comparaison avec 09-15) ; vérification finale ; PR
