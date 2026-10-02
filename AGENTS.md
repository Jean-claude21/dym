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
| Pourquoi DYM, contrat V1, apps | `docs/product/VISION.md` |
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
```

- Une migration appliquée ne se modifie jamais : on en crée une nouvelle.
- Toute table de `public` active RLS et accorde ses droits explicitement. Sinon,
  `000_security_guard.sql` échoue.

Functions (`functions/`, Node ≥ 22 en local, Node 24 sur Neon) : `npm ci && npm test`.

Apps : `cd apps/dym_client && fvm flutter run -d chrome --dart-define=DYM_ENV=dev`. En
`staging` ou `production`, `DYM_AUTH_URL`, `DYM_DATA_API_URL` et `DYM_FUNCTIONS_URL` sont
obligatoires.

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

## Zones sensibles (relecture humaine obligatoire)

Migrations, politiques RLS, authentification, argent et paiements, transitions de statut,
webhooks, secrets. Un agent peut les proposer ; il ne les fusionne pas seul.

## Interdits

- Ajouter une feature absente de la spec en cours, même « logique ».
- Utiliser des données fictives dans un flux de production.
- Committer un secret, un `.env`, un `google-services.json` ou une clé de signature.
- Désactiver une vérification (lint, test, hook) pour faire passer un changement.

## Fin de tâche

Avant de dire qu'une tâche est terminée : analyse et tests verts, tests pgTAP si le schéma change,
événements de `METRICS.md` émis, et résumé indiquant ce qui a été vérifié et ce qui ne l'a pas été.
