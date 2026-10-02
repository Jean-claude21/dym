# Quickstart — socle technique

## Base locale (PostgreSQL 17 installé, sans conteneur)

```bash
node db/scripts/dym-db.mjs local start   # cluster .local/pgdata sur 54329, base dym + imitations Neon
node db/scripts/dym-db.mjs migrate
node db/scripts/dym-db.mjs test          # résumé pgTAP
```

## Dart et apps

```bash
fvm dart run melos bootstrap
fvm dart run melos run generate          # build_runner (Stacked) dans les apps
fvm dart run melos run analyze
fvm dart run melos run test
cd apps/dym_client && fvm flutter run -d chrome --dart-define=DYM_ENV=dev
```

## Functions

```bash
cd functions && npm ci && npm test
```

## Scénarios de validation

| # | Action | Attendu |
|---|---|---|
| 1 | `local start`, `migrate`, `test` | Tout passe en < 2 min (SC-001) |
| 2 | Relancer `migrate` | « Aucune migration à appliquer » |
| 3 | Modifier `0001_platform.sql`, relancer `migrate` | Refus : empreinte modifiée |
| 4 | Créer une table `public` sans RLS dans une migration de test, lancer `test` | La garde de sécurité échoue |
| 5 | Lancer chaque app en anglais | Textes en anglais, premier écran sans débordement |
| 6 | Avec l'accès Neon : `migrate --url` et `test --url` sur une branche | Mêmes résultats qu'en local (US5) |

## Résultats de validation (2026-10-02, local)

| Contrôle | Résultat |
|---|---|
| `melos run analyze` (`--fatal-infos`) | Aucun problème |
| `dym_core` (`Result`, `Failure`, environnement) | 19/19 |
| `neon_kit` (OTP, Google, restauration, renouvellement unique, 401, retry réseau/5xx ≤ 3, aucun retry 4xx, erreurs typées) | 21/21 |
| `dym_platform` (session sécurisée) · `dym_l10n` (fr par défaut, en) | 2/2 · 3/3 |
| Apps cliente, vendeuse, admin : démarrage à 7 tailles × fr/en × texte 130 %, production sans configuration | 17/17 chacune |
| Base : `local reset` → `migrate` → `test` | 1 migration, pgTAP 9/9 |
| Scénario 2 (migrate relancé) · 3 (migration modifiée) · 4 (table sans RLS) | « aucune migration » · refus « a changé après application » · garde en échec sur la table et l'écriture anonyme |
| Functions : typage strict, `vitest` | OK, 11/11 |
| Génération Stacked sur Flutter 3.47.5 (point 5 de l'architecture §7) | Réussie dans les 3 apps |
| `flutter build web --release` de l'admin | Réussi |
| Validations sur une branche Neon (US5) | **En attente d'accès** : procédure dans la décision 0013 |

Deux défauts trouvés en route et corrigés :

- **Droits sur les fonctions.** Retirer `EXECUTE` à `PUBLIC` schéma par schéma ne suffit pas.
  Le retrait est désormais global, et vérifié par pgTAP.
- **Fichier jamais commité.** Le `.gitignore` global du poste excluait les dossiers `env/`, donc
  `environment.dart` n'avait jamais été versionné. Le fichier vit désormais dans
  `lib/src/config/`.
