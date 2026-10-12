# Feature Specification: Prêt pour le pilote

**Feature Branch**: `feat/022-pilot-readiness`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Spec `pilot-readiness` de la roadmap (Phase 3 ; C-PROF-01/07, V-PROF-01 ; constitution
IX). Elle finalise les apps de bout en bout avant le pilote.

## Contexte

L'audit de fin de construction a relevé ce qui empêchait encore une mise entre les mains de
vraies vendeuses et clientes :

- **Profil figé** : dans « Moi », le prénom et la langue n'étaient pas modifiables. Des entrées
  « Bientôt » ne menaient nulle part : langue, adresses et notifications côté vendeuse.
- **Erreurs invisibles** : aucun suivi des erreurs des apps ni des Functions, alors que la
  constitution IX l'exige.
- **Builds de release non prêts** :
  - pas de permission Internet en release Android ;
  - micro, caméra et galerie non déclarés ;
  - noms techniques sur l'écran d'accueil ;
  - signature de debug.
- **Démarrage non vérifié** : le câblage des services des trois apps n'était couvert par aucun
  test.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mon prénom et ma langue (Priority: P1)

Dans « Moi », Awa ou Fatou :

- modifie son prénom (40 caractères au plus) ;
- choisit sa langue parmi celles que propose la configuration. Chaque langue s'écrit dans sa
  propre langue.

L'app se traduit aussitôt. Les notifications push suivent la même langue.

### User Story 2 - Pas d'entrée qui ne mène nulle part (Priority: P1)

Une app n'affiche que les entrées qu'elle propose réellement. L'app vendeuse n'affiche plus
« Mes adresses » ni « Notifications ».

### User Story 3 - L'équipe voit les erreurs (Priority: P1)

Avec un DSN (Sentry ou GlitchTip), deux types d'erreurs sont remontés :

- les erreurs non gérées des apps ;
- les erreurs 5xx des Functions.

Aucune donnée personnelle n'est envoyée. Sans DSN, rien ne change.

### User Story 4 - Des builds installables (Priority: P1)

Les builds de release Android et iOS :

- déclarent Internet, la position, le micro, la caméra et la galerie, avec des textes clairs ;
- affichent « DYM » et « DYM Vendeuse » ;
- sont signés avec une clé lue hors du dépôt.

## Requirements *(mandatory)*

- **FR-001**: `update_my_profile(prénom, langue)` :
  - modifie le profil de la personne connectée seulement ;
  - prénom de 1 à 40 caractères ;
  - langue parmi celles qui ont leurs modèles de notification (`supported_locales`).
- **FR-002**: La langue choisie est appliquée à toute l'app (`LocalePreference`) et retombe sur
  celle de l'appareil à la déconnexion.
- **FR-003**: Suivi des erreurs :
  - apps : `DYM_ERROR_DSN`, https seulement, `sendDefaultPii` coupé, ni utilisateur, ni capture ;
  - Functions : `ERROR_REPORTING_DSN`, erreurs 5xx avec la route seulement ;
  - un envoi raté n'est jamais propagé.
- **FR-004**: Test de démarrage par app : les vrais services se résolvent, sans réseau.
- **FR-005**: Permissions et noms dans les manifestes ; signature de release par
  `android/key.properties` (ignoré par git).

## Success Criteria *(mandatory)*

- **SC-001**: Les trois apps compilent en release web, les deux apps mobiles en APK de release.
- **SC-002**: Aucun profil d'autrui modifiable (pgTAP).

## Assumptions

- **Push (FCM)** : il attend le projet Firebase, sur décision du porteur produit. Le serveur est
  prêt.
- **Identifiants d'application** (`tg.dym.*`) et compte de publication : décision du porteur
  produit avant la première publication.
- **Photo de profil** : hors périmètre.
