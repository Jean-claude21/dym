# Research — 003 Socle technique

Sources consultées le 2026-10-02 :
- [Neon Data API](https://neon.com/docs/data-api/get-started) ;
- [Neon Auth, flux d'authentification](https://neon.com/docs/auth/authentication-flow) ;
- [Managed Better Auth (`neon_auth.user`)](https://neon.com/guides/neon-auth-nextjs) ;
- [Neon Functions, compétence officielle](https://github.com/neondatabase/agent-skills/blob/main/skills/neon-functions/SKILL.md).

## R1. Ce que la base locale doit imiter

- **Decision**: une migration locale `db/local/neon_shims.sql`, jamais appliquée sur Neon, qui crée :
  - les rôles `authenticated` et `anonymous` (NOLOGIN) ;
  - `auth.user_id()`, qui renvoie le `sub` de `request.jwt.claims` en texte ;
  - `auth.uid()`, qui renvoie ce `sub` en uuid, ou NULL s'il n'est pas un uuid ;
  - `neon_auth."user"` avec les colonnes de Better Auth : `id` uuid, `name`, `email`,
    `"emailVerified"`, `image`, `"createdAt"`, `"updatedAt"`, `role`, `banned`, `"banReason"`,
    `"banExpires"`.
- **Rationale**: la Data API de Neon exécute chaque requête sous `authenticated` (ou `anonymous`)
  avec les claims du JWT, et `auth.user_id()`/`auth.uid()` les exposent. Neon Auth stocke ses
  utilisateurs dans `neon_auth.user`. Imiter exactement ces noms rend les politiques RLS et les
  tests identiques en local et sur Neon.
- **Alternatives considered**: écrire nos propres fonctions d'identité (divergence avec Neon) ;
  tester seulement sur Neon (bloquant sans accès, lent).

## R2. Base locale sans conteneur

- **Decision**: un cluster créé par `initdb` dans `.local/pgdata` (ignoré par git) :
  - port 54329 ;
  - authentification `trust` limitée à localhost ;
  - pilotage par `pg_ctl`.

  pgTAP est chargé ainsi :
  - via `CREATE EXTENSION pgtap` s'il est installé (CI, Neon) ;
  - sinon depuis le source pgTAP 1.3.4, téléchargé une fois et transformé en `pgtap.sql`, dans le
    schéma `tap`.
- **Rationale**: le porteur produit refuse Docker. PostgreSQL 17 est déjà installé. pgTAP est écrit
  en PL/pgSQL et n'a pas de partie compilée.
- **Alternatives considered**: Docker (refusé) ; le service PostgreSQL du poste (mot de passe
  inconnu, base partagée).

## R3. Outil de migrations et de tests

- **Decision**:
  - un script Node `db/scripts/dym-db.mjs` sans dépendance npm, qui appelle `psql` ;
  - chaque migration est appliquée dans une transaction avec son enregistrement dans
    `dym_meta.schema_migrations` (version, empreinte SHA-256, date) ;
  - une empreinte différente pour une version déjà appliquée provoque un refus ;
  - chaque test est exécuté ainsi : `BEGIN`, helpers, fichier de test, `ROLLBACK` ;
  - la sortie TAP est analysée : plan, `not ok`, code de sortie de `psql`.
- **Rationale**: c'est multiplateforme et sans Perl (`pg_prove`). Les mêmes commandes servent en
  local, en CI et sur une branche Neon (`--url`).
- **Alternatives considered**: `sqitch` ou `dbmate` (binaire de plus à installer) ; Prisma ou
  Drizzle migrate (ORM inutile, SQL brut voulu).

## R4. Droits par défaut et garde de sécurité

- **Decision**:
  - la migration 0001 révoque les privilèges par défaut que Neon accorde à `authenticated` et
    `anonymous` sur les nouvelles tables de `public` ;
  - chaque table exposée recevra des `GRANT` explicites dans sa propre migration ;
  - un test de garde échoue si une table de `public` n'a pas RLS activé, ou si `anonymous` a un
    droit d'écriture.
- **Rationale**: l'option « Grant public schema access » de Neon donne `SELECT, INSERT, UPDATE,
  DELETE` sur toute nouvelle table. Avec RLS oublié, tout est lisible. La garde rend l'oubli
  impossible à fusionner (constitution V).
- **Alternatives considered**: s'en remettre à la relecture humaine seule.

## R5. Authentification depuis Dart (Better Auth REST)

- **Decision**: `NeonAuthClient` sur `dio`, avec des chemins configurables et ces valeurs par
  défaut :

  | Action | Méthode et chemin | Corps ou détail |
  |---|---|---|
  | Envoyer un code | `POST /email-otp/send-verification-otp` | `{email, type: "sign-in"}` |
  | Vérifier le code | `POST /sign-in/email-otp` | `{email, otp}` |
  | Connexion Google | `POST /sign-in/social` | `{provider: "google", idToken: {token}}` |
  | Session | `GET /get-session` | |
  | Jeton de la Data API | `GET /token` | renvoie `{token}` |
  | Déconnexion | `POST /sign-out` | |

  - Le jeton de session mobile est lu dans l'en-tête `set-auth-token` (plugin bearer de Better
    Auth) et renvoyé en `Authorization: Bearer`.
  - L'expiration du JWT est lue dans son champ `exp`, avec une marge de 60 s.
- **Rationale**: ce sont les routes standard de Better Auth, que Neon gère pour nous. Les cookies
  ne conviennent pas au mobile. Les chemins configurables absorbent un écart découvert lors de la
  validation US5.
- **Alternatives considered**: le SDK JS de Neon Auth dans une WebView (lourd) ; une Function
  intermédiaire d'authentification (un serveur de plus).

## R6. Renouvellement et nouvelle tentative

- **Decision**:
  - **Renouvellement unique** : un `Completer` partagé fait qu'un seul renouvellement est en vol à
    la fois.
  - **Anticipation** : renouvellement si l'expiration est à moins de 60 s.
  - **Sur 401** : un renouvellement puis une seule nouvelle tentative.
  - **Nouvelle tentative** : uniquement sur `DioException` de type connexion ou délai, ou sur 5xx.
    Méthodes GET, HEAD, PUT ou DELETE, ou présence d'un en-tête `Idempotency-Key`. Au plus 3
    tentatives, avec un délai de 300 ms × 2ⁿ et un aléa.
- **Rationale**: c'est la constitution VII et l'architecture §5.
- **Alternatives considered**: `dio_smart_retry` (ne gère pas l'idempotence comme voulu).

## R7. Data API depuis Dart

- **Decision**:
  - le package `postgrest` 2.9 est construit avec un `http.Client` qui injecte le jeton courant,
    renouvelle sur 401 et retente les GET sur erreur réseau ou 5xx ;
  - les erreurs `PostgrestException` sont converties en `Failure` (403, 404, 409, `23505` pour un
    conflit, `P0001` ou `22023` pour une erreur de validation).
- **Rationale**: c'est le client PostgREST officiel en Dart pur, déjà retenu dans `PACKAGES.md`.

## R8. Neon Functions

- **Decision**:
  - `neon.ts` avec `defineConfig` de `@neon/config/v1` ;
  - une app Hono exportée par défaut ;
  - le JWT est vérifié par `jose` (`createRemoteJWKSet(NEON_AUTH_JWKS_URL)`, émetteur égal à
    l'origine de `NEON_AUTH_BASE_URL`) ;
  - les corps sont validés par `zod`, et les erreurs JSON prennent la forme
    `{error: {code, message, fields?}}` ;
  - Postgres est joint par `pg` via `DATABASE_URL`, injecté par Neon ;
  - en test, un JWKS local est généré par `jose`.
- **Rationale**: c'est le format documenté par Neon (Node 24, `fetch` compatible WinterTC, Hono
  recommandé).

## R9. Packages et environnement

- **Decision**:
  - `Result<T>` (scellé : `Ok`, `Err`) et `Failure` (scellé par catégorie) vont dans `dym_core` ;
  - `neon_kit` dépend de `dym_core` pour ces types seulement ;
  - `DymEnvironment.fromDefines()` lit `DYM_ENV`, `DYM_AUTH_URL`, `DYM_DATA_API_URL` et
    `DYM_FUNCTIONS_URL`. En production, toute URL manquante est une erreur fatale au démarrage.
    En dev, les valeurs par défaut sont locales.
- **Rationale**: un seul `Result` dans le monorepo, et aucune URL en dur (architecture §6).
- **Alternatives considered**: un `Result` propre à `neon_kit` (doublon) ; `.env` embarqué (risque
  de secret dans l'app).

## R10. Apps Stacked

- **Decision**: `flutter create` (org `tg.dym`) avec les plateformes suivantes :

  | App | Plateformes |
  |---|---|
  | Cliente | Android, iOS, Web |
  | Vendeuse | Android, iOS, Web |
  | Admin | Web |

  Chaque app contient :
  - `lib/app/app.dart` (`@StackedApp` : routes et `NavigationService`) ;
  - les fichiers générés `app.router.dart` et `app.locator.dart` ;
  - une vue de démarrage `StartupView` avec son `StartupViewModel`.
- **Rationale**: c'est le point 5 de l'architecture §7 : vérifier la génération Stacked sur
  Flutter 3.47.5.
