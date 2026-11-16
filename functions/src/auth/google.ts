import { createHash, randomInt } from "node:crypto";
import type { Hono } from "hono";
import { createRemoteJWKSet, type JWTVerifyGetKey, jwtVerify } from "jose";
import type pg from "pg";
import { z } from "zod";
import type { AuthVariables } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";

/**
 * Connexion Google (spec 102). Neon Auth ignore le jeton Google envoyé par l'app (il ne gère que
 * la page web avec redirection). Pont : la Function vérifie le jeton auprès de Google, puis dépose
 * un code de connexion à usage unique (haché, 2 minutes) là où Neon Auth range ses codes e-mail ;
 * l'app ouvre ensuite une session Neon Auth standard par la route de code (`sign-in/email-otp`).
 * Aucun e-mail n'est envoyé, aucune session n'est fabriquée à la main.
 */

/** Identité Google vérifiée. */
export interface GoogleIdentity {
  email: string;
  name: string | null;
}

export type GoogleVerifier = (idToken: string) => Promise<GoogleIdentity>;

/** Dépôt du code de connexion (table `neon_auth.verification`). */
export interface LoginCodeStore {
  issue(email: string, codeHash: string, ttlSeconds: number): Promise<void>;
}

export interface GoogleBridgeDeps {
  verify: GoogleVerifier;
  store: LoginCodeStore;
  /** Générateur de code (tests). */
  code?: () => string;
}

const GOOGLE_ISSUERS = ["https://accounts.google.com", "accounts.google.com"];
const CODE_TTL_SECONDS = 120;

/** Vérifie un `idToken` Google : signature, émetteur, destinataire (nos clients OAuth), e-mail vérifié. */
export function createGoogleVerifier(options: { keys: JWTVerifyGetKey; clientIds: string[] }): GoogleVerifier {
  return async (idToken) => {
    let payload;
    try {
      ({ payload } = await jwtVerify(idToken, options.keys, {
        issuer: GOOGLE_ISSUERS,
        audience: options.clientIds,
      }));
    } catch {
      throw httpErrors.unauthenticated("jeton Google invalide");
    }
    const email = typeof payload.email === "string" ? payload.email.trim().toLowerCase() : "";
    const verified = payload.email_verified === true || payload.email_verified === "true";
    if (!email || !verified) throw httpErrors.unauthenticated("e-mail Google non vérifié");
    return { email, name: typeof payload.name === "string" ? payload.name : null };
  };
}

export function googleVerifier(clientIds: string[]): GoogleVerifier {
  return createGoogleVerifier({
    keys: createRemoteJWKSet(new URL("https://www.googleapis.com/oauth2/v3/certs")),
    clientIds,
  });
}

/** Haché comme Neon Auth (Better Auth, `storeOTP: "hashed"`) : SHA-256 en base64url. */
export function hashLoginCode(code: string): string {
  return createHash("sha256").update(code).digest("base64url");
}

const bodySchema = z.object({ idToken: z.string().min(20).max(8192) });

export function registerGoogleBridge(app: Hono<{ Variables: AuthVariables }>, deps?: GoogleBridgeDeps) {
  app.post("/v1/auth/google", async (c) => {
    if (!deps) return c.json({ error: "unavailable", message: "connexion Google non configurée" }, 503);
    const parsed = bodySchema.safeParse(await c.req.json().catch(() => null));
    if (!parsed.success) throw httpErrors.badRequest("idToken requis");
    const identity = await deps.verify(parsed.data.idToken);
    const code = deps.code?.() ?? String(randomInt(0, 1_000_000)).padStart(6, "0");
    await deps.store.issue(identity.email, hashLoginCode(code), CODE_TTL_SECONDS);
    return c.json({ email: identity.email, code, name: identity.name });
  });
}

export function pgLoginCodeStore(pool: pg.Pool): LoginCodeStore {
  return {
    async issue(email, codeHash, ttlSeconds) {
      const identifier = `sign-in-otp-${email}`;
      const client = await pool.connect();
      try {
        await client.query("begin");
        await client.query("delete from neon_auth.verification where identifier = $1", [identifier]);
        await client.query(
          `insert into neon_auth.verification (id, identifier, value, "expiresAt", "createdAt", "updatedAt")
           values (gen_random_uuid(), $1, $2, now() + make_interval(secs => $3), now(), now())`,
          [identifier, `${codeHash}:0`, ttlSeconds],
        );
        await client.query("commit");
      } catch (error) {
        await client.query("rollback").catch(() => {});
        throw fromPgError(error);
      } finally {
        client.release();
      }
    },
  };
}
