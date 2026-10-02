# Contrat — Functions HTTP

- **Authentification** : `Authorization: Bearer <JWT Neon Auth>` sur toute route protégée.
- **Idempotence** : `Idempotency-Key` sur toute création.
- **Succès** : `2xx`, corps JSON propre à la route.
- **Erreur** : `{ "error": { "code": "<code>", "message": "<texte technique>", "fields": { "<champ>": "<raison>" }? } }`

| Code HTTP | `code` | `Failure` côté Dart |
|---|---|---|
| 400 | `bad_request` | `ValidationFailure` |
| 401 | `unauthenticated` | `UnauthenticatedFailure` |
| 403 | `forbidden` | `ForbiddenFailure` |
| 404 | `not_found` | `NotFoundFailure` |
| 409 | `conflict` | `ConflictFailure` |
| 422 | `validation` | `ValidationFailure(fields)` |
| 429 | `rate_limited` | `RateLimitedFailure` |
| 5xx | `internal` | `ServerFailure` |

Route de santé : `GET /health` (sans jeton) répond `{"status":"ok","branch":"<NEON_BRANCH>"}`.
