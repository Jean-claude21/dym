# 0020 — Analytics dans la base et MCP admin

**Statut** : Acceptée (2026-11-13)

## Contexte

Le porteur veut piloter l'admin et faire des analyses avec un assistant (MCP), et suivre l'activité
sans multiplier les outils. Les événements de `METRICS.md` et les commandes sont déjà en base.

## Décision

- Les analyses lisent des vues du schéma `analytics` (aucune colonne personnelle, vérifié par
  pgTAP). Rôle `analytics_reader` en lecture seule ; un outil de graphiques s'y branche par un
  utilisateur de connexion créé hors dépôt, membre de ce rôle.
- Serveur MCP dans la Function (`POST /mcp`, JSON-RPC, MCP « Streamable HTTP » sans session).
  Clés personnelles (`dym_mcp_…`, empreinte SHA-256 seule) ; chaque appel s'exécute avec
  l'identité de l'admin propriétaire, donc avec son rôle et ses pays (garde de la spec 085).
- Outils : `dym_functions` (ce que la clé permet), `dym_call` (fonctions admin publiques déclarées
  dans `admin_function_permissions`), `analytics_schema`, `analytics_query` (SELECT unique, lecture
  seule, 15 s, 500 lignes). Les écritures sont journalisées (`mcp_call`).

## Conséquences

- Une nouvelle fonction admin devient appelable par le MCP dès qu'elle reçoit sa permission.
- Looker Studio (gratuit, sans serveur) ou Metabase se branchent sans code.

## Alternatives écartées

- Outil d'analytics externe (Firebase Analytics, PostHog) comme source : seconde vérité, données
  hors de la base.
- SQL libre sur toute la base par le MCP : risque sur les données personnelles.
