# Feature Specification: Connexion Google

**Feature Branch**: `feat/102-connexion-google`

**Created**: 2026-11-16

**Status**: Done

**Input**: Constat (2026-11) : Neon Auth (Better Auth hébergé) ignore le jeton Google envoyé par
l'app et répond par une redirection vers sa page web (`/sign-in/social/init`). Décision du porteur :
solution A, un pont dans les Functions, sans page de navigateur.

## Mécanisme

1. L'app obtient un `idToken` Google (Android, iOS, web) comme avant.
2. `POST /v1/auth/google` (public) : la Function vérifie le jeton auprès de Google (signature JWKS,
   émetteur `accounts.google.com`, destinataire parmi `GOOGLE_CLIENT_IDS`, e-mail vérifié).
3. Elle dépose un code à usage unique (6 chiffres, haché SHA-256 comme Neon Auth, 2 minutes,
   3 essais) dans `neon_auth.verification` (`sign-in-otp-<email>`), sans envoyer d'e-mail.
4. L'app ouvre la session par la route standard `sign-in/email-otp` : session, cookie, JWT et
   renouvellement restent ceux de Neon Auth. Compte créé s'il n'existe pas (e-mail vérifié).

Vérifié sur staging (2026-11-16) : un code déposé ainsi ouvre une session (200, cookie de session).
Une session écrite directement en base est refusée (jeton non signé) : on ne fabrique jamais de
session.

## Risque suivi

Le format interne des codes de Neon Auth (`hash:essais`, SHA-256 base64url) peut changer. Un test
en ligne le vérifie au moment des recettes. Si Neon accepte un jour l'`idToken` natif, le pont
disparaît sans toucher aux écrans.

## Requirements *(mandatory)*

- **FR-001** Function `/v1/auth/google` ; sans `GOOGLE_CLIENT_IDS` : 503 (bouton Google masqué
  comme aujourd'hui côté app si non configuré).
- **FR-002** `neon_kit` : `NeonClient.signInWithGoogleIdToken` (pont puis code) ; appel public sans
  jeton (`postPublic`).
- **FR-003** WhatsApp : même pont plus tard (code envoyé par le modèle d'authentification Meta).
