import type { MiddlewareHandler } from "hono";
import {
  createRemoteJWKSet,
  type JWTPayload,
  type JWTVerifyGetKey,
  jwtVerify,
} from "jose";
import { httpErrors } from "./errors.js";

/** Utilisateur authentifié par le JWT de Neon Auth. */
export interface AuthUser {
  id: string;
  claims: JWTPayload;
}

export type TokenVerifier = (token: string) => Promise<AuthUser>;

/**
 * Vérifie les JWT de Neon Auth : signature (clés publiques JWKS), émetteur
 * (origine de NEON_AUTH_BASE_URL), expiration, présence de `sub`.
 */
export function createTokenVerifier(options: {
  keys: JWTVerifyGetKey;
  issuer: string;
}): TokenVerifier {
  return async (token) => {
    try {
      const { payload } = await jwtVerify(token, options.keys, {
        issuer: options.issuer,
      });
      if (!payload.sub) throw httpErrors.unauthenticated("jeton sans sujet");
      return { id: payload.sub, claims: payload };
    } catch {
      throw httpErrors.unauthenticated("jeton invalide ou expiré");
    }
  };
}

/** Vérificateur branché sur Neon Auth (JWKS distant, mis en cache par jose). */
export function neonAuthVerifier(env: {
  baseUrl: string;
  jwksUrl: string;
}): TokenVerifier {
  return createTokenVerifier({
    keys: createRemoteJWKSet(new URL(env.jwksUrl)),
    issuer: new URL(env.baseUrl).origin,
  });
}

export interface AuthVariables {
  user: AuthUser;
}

/** Middleware : exige `Authorization: Bearer <JWT>` valide. */
export function requireUser(
  verify: TokenVerifier,
): MiddlewareHandler<{ Variables: AuthVariables }> {
  return async (c, next) => {
    const header = c.req.header("authorization") ?? "";
    const [scheme, token] = header.split(" ");
    if (scheme?.toLowerCase() !== "bearer" || !token) {
      throw httpErrors.unauthenticated();
    }
    c.set("user", await verify(token));
    await next();
  };
}
