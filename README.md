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

## Stack

Flutter 3.47.5 via FVM · Stacked · Melos (pub workspaces) · Neon (Postgres, Auth, Data API,
Object Storage, Functions) · Moneroo + cash · AI SDK + OpenAI · FCM · Coolify.

## Démarrer

```bash
fvm install
fvm dart pub global activate melos
melos bootstrap
```

## Documentation

- [Guide des agents et commandes](AGENTS.md)
- [Constitution](.specify/memory/constitution.md)
- [Vision et contrat V1](docs/product/VISION.md) · [Roadmap](docs/product/ROADMAP.md) ·
  [Hypothèses](docs/product/HYPOTHESES.md) · [Métriques](docs/product/METRICS.md)
- [Architecture](docs/architecture/ARCHITECTURE.md) · [Packages](docs/architecture/PACKAGES.md) ·
  [Décisions](docs/architecture/decisions/README.md)
- [Direction de design](docs/design/DESIGN_DIRECTION.md) · [Maquettes](docs/design/MOCKUPS.md)

## Contribuer

Tout développement passe par Spec Kit (`/speckit-specify` → … → `/speckit-implement`), une branche
par spec et des commits conventionnels. Voir la constitution.
