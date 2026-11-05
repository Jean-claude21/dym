# 0013 — Validations techniques sur Neon

**Statut :** En cours · 2026-10-02 · Spec 003 (US5)

## Contexte

L'architecture (§7) liste six points à confirmer avant tout code produit. La spec 003 a construit le
socle en reproduisant Neon en local, sans conteneur. L'accès au projet Neon (Francfort) n'est pas
encore disponible pour l'agent, car les clés sont stockées hors de sa portée. Chaque point est donc
classé selon ce qui a été prouvé.

## Décision et état

| # | Point | Prouvé en local | Reste à prouver sur Neon | Plan B |
|---|---|---|---|---|
| 1 | Better Auth en REST depuis Dart : OTP email, `idToken` Google, JWT, renouvellement | Client `neon_kit` testé contre un serveur simulé : routes standard de Better Auth, en-tête `set-auth-token`, route `token`, renouvellement unique (21 tests) | Le plugin bearer est-il actif sur Neon Auth ? Chemins exacts. Durée du JWT | Chemins configurables (`NeonAuthPaths`). Sans plugin bearer : lire le cookie de session renvoyé et le rejouer en en-tête `Cookie` |
| 2 | Data API via `postgrest`, RLS, RPC | Rôles `authenticated`/`anonymous`, `auth.uid()` et garde RLS imités et testés par pgTAP ; client testé (401, 403, 409) | `auth.uid()` de Neon lit-il les claims comme l'imitation ? Préfixe d'URL de la Data API | Fonctions d'identité locales alignées sur le comportement constaté ; seule l'imitation change |
| 3 | Upload par URL présignée vers Object Storage | Spec 007 : bucket `product-photos` (`public_read`) déclaré dans `neon.ts`, présignature S3 (adressage par chemin) derrière une interface, `PUT` direct sans jeton depuis `neon_kit` (rejoué sur réseau ou 5xx), clé sous le préfixe de la boutique vérifiée en SQL | Présignature réelle avec les identifiants injectés par `@neon/env`, lecture publique à l'URL `point d'accès/bucket/clé` (valeur de `DYM_MEDIA_URL`) | Function qui reçoit l'image et l'écrit elle-même dans le stockage |
| 4 | Déploiement d'une Function, secret, appel depuis l'app, push FCM | Projet `functions/` : `neon.ts`, vérification JWT par JWKS, contrat d'erreurs (11 tests) | `neon deploy`, `/health` et `/me` avec un vrai jeton ; FCM avec `order-lifecycle` | Function sur Coolify (même code Hono) |
| 5 | Stacked, freezed et json_serializable sur Flutter 3.47.5 | **Stacked : validé** (3.5 + `stacked_generator` 2.0.4, 3 apps générées). **json_serializable : validé** (`dym_models`, spec 004). **freezed : no-go** : sur 3.47.5, `flutter_test` fige `test_api` (analyzer < 14), alors que freezed 4 exige analyzer 14 et que freezed 3 exige analyzer ≤ 12, incompatible avec `stacked_generator` 2.0.4 et `build_runner` 2.16 | Réessayer à chaque montée de Flutter (0006) | Classes immuables écrites à la main + `fromJson` par `json_serializable` (en place) |
| 6 | Inscription par téléphone via le webhook `send.otp` | — | Tout (spec `phone-otp`) | OTP email maintenu (décision 0007) |

## Points ajoutés par la spec 005

- **Suppression de compte** : `delete_my_account()` supprime la ligne `neon_auth."user"`, avec
  suppression en cascade des sessions. Il faut vérifier sur Neon que le propriétaire de la base a
  ce droit et que les tables de Better Auth sont liées en cascade. Plan B : une Function qui
  appelle l'API d'administration de Neon Auth.
- **Google** : identifiants OAuth à créer par plateforme et passés à la compilation :
  - `DYM_GOOGLE_SERVER_CLIENT_ID` pour Android ;
  - `DYM_GOOGLE_CLIENT_ID` pour iOS et le web.

  Côté Neon Auth, le fournisseur Google est à activer avec les mêmes identifiants.
- **Premier admin** : à donner par le propriétaire de la base :
  `select app.grant_role('<uuid>', 'admin', 'équipe fondatrice')`.

## Points ajoutés par la spec 007

- **Proposition « photo → fiche »** : `OPENAI_API_KEY` est une variable de la Function, fournie
  au déploiement et jamais dans une app. Le modèle `product_from_photo` reste **inactif** en base
  tant que l'essai réel (H8 : 50 photos de vendeuses) n'a pas eu lieu. Pour l'activer :
  `update ai_models set is_active = true where usage = 'product_from_photo'`.
- **Photos** : `DYM_MEDIA_URL` (base publique du bucket) est à passer à la compilation des apps
  en `staging` et en `production`.

## Procédure dès l'accès Neon

1. `neon link` sur le projet, puis branche `staging` créée depuis `main`.
2. `node db/scripts/dym-db.mjs migrate --url <DATABASE_URL de la branche>`, puis `test --url …`.
   pgTAP y est disponible comme extension.
3. `cd functions && neon deploy --env <fichier hors dépôt>`, puis `GET /health` et `GET /me`.
4. Essai réel de connexion par OTP email depuis `dym_client`, compilé avec
   `--dart-define=DYM_ENV=staging` et les URLs de la branche.
5. Mise à jour de ce document : statut « Acceptée » et résultat par point.

## Conséquences

- Les specs `reference-data` et `auth` avancent sur la base locale : leurs migrations et tests
  pgTAP rejoueront sur Neon sans modification si les points 1 et 2 sont confirmés.
- Toute divergence constatée ne modifie que l'imitation locale ou `NeonAuthPaths`, jamais les apps.
