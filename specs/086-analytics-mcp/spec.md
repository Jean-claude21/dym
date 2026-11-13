# Feature Specification: Analytics et MCP admin

**Feature Branch**: `feat/086-analytics-mcp`

**Created**: 2026-11-13

**Status**: Draft

**Input**: Demande du porteur (2026-11-13) : « MCP doit permettre de contrôler tout et doit nous
permettre de faire des analyses » ; analytics dans la base plutôt qu'un autre outil, branchement
possible d'un outil de graphiques gratuit. Features A-ADM-07 (pilotage), A-ANA-01 (analyses).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Demander à un assistant (Priority: P1)

Le super-admin crée une clé MCP (Configuration → MCP), la copie une seule fois avec l'adresse du
serveur, la donne à Claude. Claude liste ce que la clé permet, appelle les fonctions admin avec
les droits de l'admin (rôle, pays), répond aux questions chiffrées (« quelles boutiques ont le plus
de refus ce mois-ci ? »). Chaque écriture est journalisée ; la clé se révoque d'un geste.

### User Story 2 - Graphiques sans serveur (Priority: P2)

Un outil de graphiques (Looker Studio, Metabase) se branche en lecture seule sur le schéma
`analytics` : commandes, ventes, parcours d'achat, inscriptions, rétention, délais, boutiques.

### Edge Cases

- Clé inconnue, révoquée, ou admin retiré : 401.
- Fonction hors rôle : refusée par la garde SQL (spec 085).
- Requête d'analyse : une seule instruction SELECT, lecture seule, 15 s, 500 lignes.

## Requirements *(mandatory)*

- **FR-001**: vues `analytics.*` sans colonne personnelle (test pgTAP) ; rôle `analytics_reader`.
- **FR-002**: clés MCP : empreinte SHA-256 seulement, 5 actives au plus, `mcp.write` (super-admin).
- **FR-003**: `POST /mcp` (JSON-RPC, MCP « Streamable HTTP ») : `dym_functions`, `dym_call`,
  `analytics_schema`, `analytics_query` ; permission `analytics.read` pour les analyses.
- **FR-004**: écran des clés dans l'app admin ; textes par `dym_l10n`.

## Success Criteria *(mandatory)*

- **SC-001**: pgTAP 700 (13) ; tests du serveur MCP (dont un sur base réelle) ; essai sur staging
  avec une vraie clé.
