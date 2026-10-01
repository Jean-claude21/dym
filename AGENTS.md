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

Toujours via FVM. Ne jamais appeler `flutter` ou `dart` directement.

```bash
fvm install                       # installe la version de .fvmrc (3.47.5)
fvm dart pub global activate melos
melos bootstrap                   # résout le workspace
melos run generate                # build_runner (Stacked, freezed, json)
melos run analyze
melos run test
```

Les scripts Melos sont définis dans le `pubspec.yaml` racine (créé par la spec `foundation`).

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
