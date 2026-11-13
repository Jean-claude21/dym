# AGENTS.md — Guide opérationnel

Ce fichier dit à tout agent (et à tout humain) comment travailler dans ce dépôt.
Les règles non négociables sont dans `.specify/memory/constitution.md` : elles priment.

## Avant de commencer une tâche

1. Lire la constitution, puis la ligne concernée de `docs/product/ROADMAP.md`.
2. Vérifier que la tâche appartient à une spec existante (`specs/NNN-*`). Sinon : `/speckit-specify`.
3. Pour une tâche d'UI : ouvrir la maquette validée correspondante (`docs/design/MOCKUPS.md`).

## Où trouver quoi

| Besoin | Fichier |
|---|---|
| Pourquoi DYM, fonctionnalités validées, apps | `docs/product/VISION.md` |
| Phases, specs, heures, gates | `docs/product/ROADMAP.md` |
| Hypothèses à valider | `docs/product/HYPOTHESES.md` |
| Événements à émettre, KPIs | `docs/product/METRICS.md` |
| Features détaillées par identifiant (lecture seule) | `docs/product/sources/` |
| Architecture, couches, sécurité | `docs/architecture/ARCHITECTURE.md` |
| Packages et dépendances | `docs/architecture/PACKAGES.md` |
| Décisions et leur justification | `docs/architecture/decisions/` |
| Direction de design et maquettes | `docs/design/` |

## Commandes

Toujours via FVM. Ne jamais appeler `flutter` ou `dart` directement. Melos est une dépendance du
workspace et utilise le SDK FVM (`sdkPath: .fvm/flutter_sdk`).

```bash
fvm install                          # installe la version de .fvmrc (3.47.5)
fvm flutter pub get                  # résout le workspace
fvm dart run melos bootstrap
fvm dart run melos run tokens        # régénère le thème dym_ui depuis les tokens
fvm dart run melos run analyze       # analyse stricte (very_good_analysis)
fvm dart run melos run test          # tests Flutter (hors golden)
fvm dart run melos run test:dart     # tests Dart purs (dym_core)
fvm dart run melos run golden        # captures de la galerie (machine de dev)
fvm dart run melos run generate      # génération Stacked (routes, injection) des apps
```

Base de données (PostgreSQL 17 installé, **jamais de conteneur**) :

```bash
node db/scripts/dym-db.mjs local start    # cluster .local/pgdata sur 54329 + imitations Neon
node db/scripts/dym-db.mjs migrate        # migrations db/migrations (empreintes vérifiées)
node db/scripts/dym-db.mjs test           # pgTAP (db/tests), chaque fichier en transaction annulée
node db/scripts/dym-db.mjs local reset    # base vierge
node db/scripts/dym-db.mjs grant-admin <email> [--url <url>]   # rôle admin (audité)
```

- Une migration appliquée ne se modifie jamais : on en crée une nouvelle.
- Toute table de `public` active RLS et accorde ses droits explicitement. Sinon,
  `000_security_guard.sql` échoue.

Functions (`functions/`, Node ≥ 22 en local, Node 24 sur Neon) : `npm ci && npm test`.

Apps (`dym_client`, `dym_vendor`, `dym_delivery`, `dym_admin`) : `cd apps/dym_client && fvm flutter run -d chrome --dart-define=DYM_ENV=dev`. En
`staging` ou `production`, `DYM_AUTH_URL`, `DYM_DATA_API_URL`, `DYM_FUNCTIONS_URL` et
`DYM_MEDIA_URL` sont obligatoires.

Neon `staging` (projet `dym`, décision 0013) :

```bash
# App sur la branche staging (URL publiques seulement) ; web : port fixe autorisé par la Function.
cd apps/dym_client && fvm flutter run -d chrome --web-port 5555 --dart-define-from-file=../../config/staging.json
# Migrations et pgTAP sur la branche (URL hors dépôt : functions/.env.local, écrit par neon deploy).
node db/scripts/dym-db.mjs migrate --url "$DATABASE_URL_UNPOOLED" && node db/scripts/dym-db.mjs test --url "$DATABASE_URL_UNPOOLED"
# Après une migration : la Data API ne voit les nouvelles fonctions qu'après ce rafraîchissement (sinon 404).
npx neonctl data-api refresh-schema --project-id <id> --branch staging --database neondb
# Commande de bout en bout (comptes de test créés puis supprimés) :
# NEON_LIVE_AUTH_URL, NEON_LIVE_DATA_API_URL, NEON_LIVE_FUNCTIONS_URL = URL de config/staging.json ;
# NEON_LIVE_DATABASE_URL (hors dépôt) active le scénario de l'admin (rôle accordé par grant-admin).
cd packages/data/dym_data && fvm dart test test/order_flow_live_test.dart
# pgTAP complet sur une branche Neon propre (jetable, créée depuis `main` vide). `main` a Neon Auth
# mais pas les rôles de la Data API : `--neon-shims` crée les rôles et laisse `neon_auth` intact.
npx neonctl branches create --project-id <id> --name test-spec-NNN --parent main
node db/scripts/dym-db.mjs migrate --neon-shims --url "$(npx neonctl connection-string test-spec-NNN --project-id <id>)"
node db/scripts/dym-db.mjs test --url "<même URL>" && npx neonctl branches delete test-spec-NNN --project-id <id>
# Déploiement : clés lues dans un fichier hors dépôt.
cd functions && npx neonctl deploy --branch staging --env <fichier .env hors dépôt> --no-env-pull
# Le fichier DOIT contenir toutes les variables de neon.ts (ALLOWED_ORIGINS, OPENAI_API_KEY,
# PAYMENTS_SIMULATOR_SECRET, FCM_SERVICE_ACCOUNT, MEDIA_PUBLIC_URL, ERROR_REPORTING_DSN, LIVEKIT_URL,
# LIVEKIT_API_KEY, LIVEKIT_API_SECRET) : une variable absente est
# remise à vide. MEDIA_PUBLIC_URL = DYM_MEDIA_URL de config/<env>.json (photos des push).
# Une Function déjà créée ne reçoit PAS les nouvelles variables par `neon deploy` : les pousser ensuite
# (toutes, celles absentes du fichier sont retirées) avec NEON_API_KEY dans l'environnement :
cd functions && node scripts/deploy-env.mjs <fichier .env hors dépôt> staging <id du projet>
```

MCP admin (spec 086) : clé créée dans l'admin (Configuration → MCP, super-admin), puis
`claude mcp add --transport http dym <DYM_FUNCTIONS_URL>/mcp --header "Authorization: Bearer <clé>"`.
Graphiques (Looker Studio, Metabase) : créer un utilisateur de connexion sur la branche (console ou
`neonctl roles create`), puis `grant analytics_reader to <utilisateur>;` ; il ne lit que `analytics.*`.

Suivi des erreurs (facultatif ; sans valeur, rien n'est envoyé) : `--dart-define=DYM_ERROR_DSN=https://<clé>@<hôte>/<projet>`
pour les apps (Sentry ou GlitchTip), variable `ERROR_REPORTING_DSN` pour les Functions. Sentry
(organisation `dym-mq`, région Europe) : un projet par app (`dym-client`, `dym-vendor`,
`dym-delivery`, `dym-admin`) et `dym-functions` ; DSN hors dépôt (`.secrets/dym-sentry-apps.env`,
`DYM_ERROR_DSN_<APP>`, et le fichier d'environnement des Functions). Aucune donnée
personnelle n'est envoyée.

Notifications (FCM) : `google-services.json` (console Firebase, projet `do-your-market-79ff7`) dans
`apps/dym_client`, `apps/dym_vendor`, `apps/dym_delivery` sous `android/app/` (hors dépôt). Absent :
l'app se construit sans push. Côté serveur, `FCM_SERVICE_ACCOUNT` (clé de compte de service, JSON sur
une ligne) dans le fichier d'environnement des Functions.

Builds de release Android : `apps/dym_client/android/key.properties` (et `dym_vendor`), hors dépôt,
avec `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. Sans ce fichier, la release est signée
avec les clés de debug (essais seulement).

Galerie de validation du design system : `cd apps/dym_gallery && fvm flutter run -d chrome`.

Les scripts Melos sont définis dans le `pubspec.yaml` racine.

## Branches

| Branche | Rôle | Créée depuis | Fusionnée dans |
|---|---|---|---|
| `main` | Production | — | — |
| `dev` | Intégration | `main` | `main` (release) |
| `feat/NNN-<slug>` | Une spec Spec Kit | `dev` | `dev` |
| `feat/<slug>` | Travail hors spec (design, docs) | `dev` | `dev` |
| `hotfix/<slug>` | Correctif urgent | `main` | `main`, puis `dev` |

- Toujours se placer sur `dev` à jour avant `/speckit-specify` : la branche de spec est créée
  depuis la branche courante, avec le préfixe `feat`.
- Pas de commit direct sur `main` ou `dev` : une pull request à chaque fois.

## Règles de code

- **Où mettre une règle :** montant, statut, permission → SQL (fonction + RLS + test pgTAP).
  Appel à un service externe → Neon Function. Affichage et navigation → Flutter.
- **Argent :** `amount_minor` (entier) + `currency_code`. Jamais de `double`. Jamais de prix calculé dans l'app.
- **Générique :** aucune liste de pays, devise, opérateur, catégorie ou modèle d'IA dans le code.
- **Texte :** aucun texte visible en dur ; tout passe par `dym_l10n`.
- **Stacked :** vue sans logique ; viewmodel → repository → `Result<T>`.
- **Packages :** respecter le sens des dépendances de `PACKAGES.md` ; ne pas créer de package hors de ses règles.
- **Réseau :** nouvelle tentative seulement sur erreur réseau ou 5xx ; clé d'idempotence sur toute création.
- **Fichiers générés** (`*.g.dart`, `*.freezed.dart`, `*.router.dart`, `*.locator.dart`) : ne jamais les modifier à la main.

## Zones sensibles (relecture renforcée)

Migrations, politiques RLS, authentification, argent et paiements, transitions de statut,
webhooks, secrets. Le porteur délègue la relecture et la fusion à l'agent (décision du 2026-11-12) :
l'agent lit le diff, fait passer l'analyse, les tests, pgTAP sur une branche Neon jetable créée
depuis `main` puis supprimée, et la CI ; il fusionne alors dans `dev` sans attendre. La branche
Neon `main` (production) n'est jamais modifiée par un agent.

## Interdits

- Ajouter une feature absente de la spec en cours, même « logique ».
- Utiliser des données fictives dans un flux de production.
- Committer un secret, un `.env`, un `google-services.json` ou une clé de signature.
- Désactiver une vérification (lint, test, hook) pour faire passer un changement.

## Fin de tâche

Avant de dire qu'une tâche est terminée : analyse et tests verts, tests pgTAP si le schéma change,
événements de `METRICS.md` émis, et résumé indiquant ce qui a été vérifié et ce qui ne l'a pas été.
