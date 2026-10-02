# Implementation Plan: Authentification, profils et rôles

**Branch**: `feat/005-auth` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

- **Migration `0005_profiles_roles.sql`** :
  - tables `profiles` et `user_roles`, avec RLS ;
  - fonctions `public.me()`, `public.complete_profile(...)`, `public.record_sign_in(app)` et
    `public.delete_my_account()` ;
  - fonctions d'administration `app.grant_role` et `app.revoke_role`, avec audit, et
    `app.has_role`.
- **Dart** :
  - `dym_models` : `Profile`, `Role`, `Me` ;
  - `dym_data` : `AccountRepository` ;
  - `dym_platform` : `GoogleIdTokenProvider`, avec `google_sign_in` 7 ;
  - `dym_auth` (feature Stacked) : bienvenue, email, code, profil, et `AuthService` qui orchestre ;
  - `dym_account` : écran « Moi » et suppression de compte.
- **Apps** : routes cliente et vendeuse (démarrage → bienvenue ou accueil) ; admin (connexion
  Google, contrôle du rôle, minuteur d'inactivité de 30 min).

## Technical Context

**Language/Version**: SQL PostgreSQL 17 ; Dart 3.13.4 / Flutter 3.47.5 (FVM)

**Primary Dependencies**:
- `stacked` 3.5 et `stacked_services` 1.6 ;
- `google_sign_in` 7 ;
- `geolocator`, différé (voir D5) ;
- `neon_kit`, `dym_ui`, `dym_l10n`.

**Storage**: PostgreSQL. Tables `profiles` et `user_roles` ; utilisateurs dans `neon_auth.user`.

**Testing**: pgTAP ; `flutter test` (viewmodels, vues aux 7 tailles, parcours avec serveur simulé)

**Target Platform**: apps cliente et vendeuse (Android, iOS, Web), admin (Web)

**Constraints**:
- aucun rôle sensible attribuable depuis une app ;
- aucune donnée personnelle dans les événements et l'audit ;
- français par défaut.

## Constitution Check

| Principe | Vérification | Statut |
|---|---|---|
| I | Spec `auth` (Phase 1), IDs cités | ✅ |
| II | Écrans 09-15 générés dans la direction validée, soumis au porteur produit (dérogation consignée dans la roadmap) | ⚠️ validation en cours |
| III | Pays déduit, rôle donné et suppression faits par des fonctions SQL ; l'app ne décide de rien | ✅ |
| IV | Textes ARB, quartiers et pays lus du référentiel | ✅ |
| V | RLS et pgTAP croisés, rôles sensibles par admin avec audit, suppression effective des données personnelles | ✅ |
| VI | `dym_auth`/`dym_account` → `dym_data` → `neon_kit` ; vues sans logique, viewmodels testés | ✅ |
| VII | pgTAP et tests Flutter ; essai OTP réel sur Neon à faire (0013) | ⚠️ comme 003 |
| VIII | États chargement, réseau, code faux et session expirée ; 48 dp ; 7 tailles | ✅ |
| IX | `user_signed_up` et `user_signed_in` émis par SQL | ✅ |

## Decisions

| # | Décision | Pourquoi |
|---|---|---|
| D1 | Profil créé par `complete_profile` (`SECURITY DEFINER`) et non par un `INSERT` client | Le pays (déduit du quartier) et le rôle sont décidés en SQL (III) |
| D2 | Le rôle donné dépend de l'app déclarée (`client`/`vendor`) ; `admin`/`courier` jamais | Seuls des rôles sans privilège sont libres ; la vendeuse n'a de pouvoir que sur sa boutique (RLS future) |
| D3 | Suppression par `delete_my_account()` qui supprime la ligne `neon_auth.user`. Les tables Better Auth sont dans notre base et liées en cascade | Pas besoin d'une API d'administration externe ; à confirmer sur Neon (0013, point 1) |
| D4 | `app.account_deletion_blockers(uuid) → text[]` vide pour l'instant, complétée par `order-lifecycle` | Mécanisme prêt sans dépendance future |
| D5 | Détection du quartier différée : liste triée, sans géolocalisation | Les quartiers n'ont pas encore de coordonnées dans le référentiel ; `geolocator` arrivera avec `discovery`. Le choix dans la liste reste conforme à FR-002 (« préchoisi si la position est connue ») |
| D6 | Google via `google_sign_in` 7 (`authenticate()` → `idToken`), identifiant client serveur passé à la compilation (`DYM_GOOGLE_SERVER_CLIENT_ID`) ; absent = bouton masqué | Aucun secret dans l'app ; configuration par environnement |
| D7 | Minuteur d'inactivité de l'admin côté app (pointeur et clavier) | La durée de session serveur reste celle de Neon Auth ; l'inactivité est une règle d'interface |
