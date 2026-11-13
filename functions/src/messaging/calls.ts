import type { Hono } from "hono";
import { SignJWT } from "jose";
import type pg from "pg";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";

/** Accès au média d'un appel, décidé en SQL (`app.call_media_access`). */
export interface CallMediaAccess {
  room: string;
  identity: string;
  role: string;
  name: string | null;
  video: boolean;
}

export interface CallMediaStore {
  access(userId: string, callId: string): Promise<CallMediaAccess>;
}

export function pgCallMediaStore(pool: pg.Pool): CallMediaStore {
  return {
    access: async (userId, callId) => {
      try {
        const { rows } = await pool.query("select app.call_media_access($1, $2) as value", [userId, callId]);
        return rows[0].value as CallMediaAccess;
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}

/** Projet LiveKit (cloud ou serveur auto-hébergé). */
export interface LiveKitConfig {
  url: string;
  apiKey: string;
  apiSecret: string;
}

/** Durée du jeton : de quoi rejoindre l'appel, pas de quoi le garder. */
export const CALL_TOKEN_TTL_SECONDS = 600;

/**
 * Jeton d'accès LiveKit (JWT HS256 signé avec la clé secrète du projet) :
 * une seule salle (celle de l'appel), publier et recevoir l'audio et la vidéo.
 */
export async function liveKitToken(
  config: LiveKitConfig,
  access: CallMediaAccess,
  now: Date = new Date(),
): Promise<string> {
  const iat = Math.floor(now.getTime() / 1000);
  return new SignJWT({
    name: access.name ?? undefined,
    video: {
      room: access.room,
      roomJoin: true,
      canPublish: true,
      canSubscribe: true,
      canPublishData: false,
    },
  })
    .setProtectedHeader({ alg: "HS256", typ: "JWT" })
    .setIssuer(config.apiKey)
    .setSubject(access.identity)
    .setNotBefore(iat)
    .setIssuedAt(iat)
    .setExpirationTime(iat + CALL_TOKEN_TTL_SECONDS)
    .setJti(`${access.room}:${access.identity}:${iat}`)
    .sign(new TextEncoder().encode(config.apiSecret));
}

export interface CallDeps {
  store: CallMediaStore;
  /** Absent : appels réels non configurés (503). */
  livekit?: LiveKitConfig;
}

const uuid = z.string().uuid();

/**
 * Appels réels (spec 084) :
 * - `POST /v1/calls/:id/media` : adresse du serveur LiveKit et jeton de la
 *   salle de l'appel, pour les deux personnes de la conversation, appel
 *   décroché seulement (la base décide).
 */
export function registerCallRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: CallDeps,
) {
  const auth = requireUser(verifyToken);

  app.post("/v1/calls/:id/media", auth, async (c) => {
    const callId = c.req.param("id");
    if (!uuid.safeParse(callId).success) throw httpErrors.notFound("introuvable");
    if (!deps?.livekit) throw httpErrors.unavailable("appels non configurés");
    const access = await deps.store.access(c.get("user").id, callId);
    const token = await liveKitToken(deps.livekit, access);
    return c.json({ url: deps.livekit.url, token, room: access.room, video: access.video });
  });
}
