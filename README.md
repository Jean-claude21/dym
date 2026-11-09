# DYM — Do Your Market

Marketplace mobile multi-boutiques pour le commerce informel ouest-africain :
**découvrir, comparer, commander, payer, recevoir — simple, local, fiable.**

## Applications

| App | Pour qui | Plateforme | Phase |
|---|---|---|---|
| `apps/dym_client` | Clientes | Android, iOS | 1 |
| `apps/dym_vendor` | Vendeuses | Android, iOS | 1 |
| `apps/dym_admin` | Équipe ops | Flutter Web | 1 |
| `apps/dym_delivery` | Livreurs | Android | Sur déclencheur de volume |
| `apps/dym_gallery` | Équipe (outil interne) | Android, Web | Galerie de validation du design system |

## Stack

Flutter 3.47.5 via FVM · Stacked · Melos (pub workspaces) · Neon (Postgres, Auth, Data API,
Object Storage, Functions) · Moneroo + cash · AI SDK + OpenAI · FCM · Coolify.

## Démarrer

```bash
fvm install
fvm flutter pub get
fvm dart run melos bootstrap
node db/scripts/dym-db.mjs local start && node db/scripts/dym-db.mjs migrate && node db/scripts/dym-db.mjs test
cd apps/dym_client && fvm flutter run -d chrome --dart-define=DYM_ENV=dev
cd apps/dym_client && fvm flutter run --dart-define-from-file=../../config/staging.json  # branche Neon staging
cd apps/dym_gallery && fvm flutter run -d chrome   # galerie du design system
```

Base locale sans conteneur (PostgreSQL 17 installé) ; détails dans [AGENTS.md](AGENTS.md).

## Documentation

- [Guide des agents et commandes](AGENTS.md)
- [Constitution](.specify/memory/constitution.md)
- [Vision](docs/product/VISION.md) · [Roadmap](docs/product/ROADMAP.md) ·
  [Hypothèses](docs/product/HYPOTHESES.md) · [Métriques](docs/product/METRICS.md)
- [Architecture](docs/architecture/ARCHITECTURE.md) · [Packages](docs/architecture/PACKAGES.md) ·
  [Décisions](docs/architecture/decisions/README.md)
- [Direction de design](docs/design/DESIGN_DIRECTION.md) · [Maquettes](docs/design/MOCKUPS.md)

## Contribuer

Tout développement passe par Spec Kit (`/speckit-specify` → … → `/speckit-implement`), une branche
par spec et des commits conventionnels. Voir la constitution.
