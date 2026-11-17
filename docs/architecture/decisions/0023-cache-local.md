# 0023 — Cache local : fichiers JSON de l'app (`path_provider`)

**Statut** : Acceptée (2026-11-17)

## Contexte

La spec 107 (suite de la 062) demande le premier écran depuis un cache local et une file hors ligne
des gestes (« rupture » de la vendeuse au marché, réseau faible). Les jetons sont déjà dans
`flutter_secure_storage` ; les vidéos légères dans `flutter_cache_manager` (spec 103).

## Options

| Option | Pour | Contre |
|---|---|---|
| `shared_preferences` | Simple | Fichier XML unique, lent au-delà de quelques Ko ; pas fait pour des réponses entières |
| `hive_ce` / `isar` / `sqflite` | Requêtes, gros volumes | Dépendance lourde pour quelques réponses ; schéma à maintenir |
| `flutter_secure_storage` | Déjà là | Chiffré et lent ; réservé aux secrets |
| **Fichiers JSON (`path_provider`)** | Paquet officiel de l'équipe Flutter, aucun schéma, écriture atomique | Pas de requêtes (inutile ici) |

## Décision

- `LocalJsonStore` (dym_platform) : un fichier JSON par clé dans le dossier de l'app ; écriture
  atomique ; illisible = absent ; web : rien n'est gardé.
- Data API : `OfflineReadCache` (neon_kit) garde les lectures du premier écran (référentiel du pays,
  boutiques, accueil, fil) et les rend sans réseau ; jamais d'écriture ; effacé à la déconnexion.
- `OfflineQueue` : gestes gardés hors ligne (rupture de la vendeuse), rejoués au retour du réseau.
- Jamais de secret dans ce cache.
