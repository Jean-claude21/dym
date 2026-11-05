# Contrat — outil base `node db/scripts/dym-db.mjs`

| Commande | Effet | Code de sortie |
|---|---|---|
| `local start` | crée `.local/pgdata` si absent (`initdb`, trust localhost), démarre sur 54329, crée la base `dym` et applique les imitations Neon | 0 si prête |
| `local stop` | arrête le cluster | 0 |
| `local reset` | supprime puis recrée la base `dym` (cluster conservé) | 0 |
| `local status` | indique si le cluster tourne | 0 / 1 |
| `migrate [--url <url>]` | applique les migrations non appliquées, dans l'ordre | 0 ; 1 si échec ou empreinte modifiée |
| `test [--url <url>] [fichier…]` | exécute les tests pgTAP (tous par défaut) et affiche le résumé | 0 si tout passe ; 1 sinon |

- **Cible.** Sans `--url`, la cible est `DATABASE_URL`, ou à défaut la base locale
  `postgresql://postgres@localhost:54329/dym`.
- **Imitations Neon.** Elles ne s'appliquent que par `local start`, et sur une base CI marquée
  `--neon-shims`. `migrate` ne les applique jamais.
- **Binaires.** `psql`, `initdb` et `pg_ctl` sont cherchés dans `PG_BIN`, puis dans
  `C:\Program Files\PostgreSQL\17\bin`, puis dans le `PATH`.
