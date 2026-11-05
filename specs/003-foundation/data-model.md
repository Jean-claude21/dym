# Data Model — 003 Socle technique

## Base de données

### `dym_meta.schema_migrations` (outil, non exposé)

| Colonne | Type | Règle |
|---|---|---|
| `version` | text PK | préfixe numérique du fichier (`0001`) |
| `name` | text | nom du fichier |
| `checksum` | text | SHA-256 du contenu ; une différence bloque `migrate` |
| `applied_at` | timestamptz | `now()` |

### Schéma `app` (fonctions internes, non exposé par la Data API)

| Objet | Rôle |
|---|---|
| `app.current_user_id() → uuid` | `auth.uid()` ; NULL pour `anonymous` |
| `app.set_updated_at()` | trigger `BEFORE UPDATE` qui pose `updated_at = now()` |

### Imitation Neon (`db/local/neon_shims.sql`, local et CI uniquement)

| Objet | Équivalent Neon |
|---|---|
| rôles `authenticated`, `anonymous` | rôles de la Data API |
| `auth.user_id() → text` | `sub` du JWT |
| `auth.uid() → uuid` | `sub` en uuid |
| `neon_auth."user"` | table des utilisateurs de Neon Auth (Better Auth) |

### Aides de test (`db/tests/_helpers.sql`, chargées dans chaque transaction de test)

| Fonction | Effet |
|---|---|
| `tests.create_user(email) → uuid` | insère dans `neon_auth."user"` |
| `tests.login_as(uuid)` | `SET LOCAL ROLE authenticated` + claims `{sub}` |
| `tests.login_anonymous()` | `SET LOCAL ROLE anonymous`, sans claims |
| `tests.logout()` | `RESET ROLE`, claims vidés |

## Dart

| Type | Package | Champs |
|---|---|---|
| `Result<T>` | `dym_core` | `Ok(value)` · `Err(failure)` |
| `Failure` | `dym_core` | scellé : `NetworkFailure`, `UnauthenticatedFailure`, `ForbiddenFailure`, `NotFoundFailure`, `ConflictFailure`, `ValidationFailure(fields)`, `RateLimitedFailure`, `ServerFailure(statusCode)`, `UnknownFailure` ; tous avec `message` technique |
| `DymEnvironment` | `dym_core` | `name` (dev, staging, production), `authUrl`, `dataApiUrl`, `functionsUrl` |
| `NeonSession` | `neon_kit` | `sessionToken`, `accessToken`, `accessTokenExpiresAt`, `userId`, `email` |
| `SessionStore` | `neon_kit` | `read()`, `write(session)`, `clear()` |
