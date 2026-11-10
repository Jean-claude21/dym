import { randomUUID } from "node:crypto";
import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";
import type { MediaSigner } from "../messaging/routes.js";

/** Photos d'une commande (spec 034) : remplacement, garantie fraîcheur. */
export interface OrderPhotoStore {
  /** `client`, `vendor`, ou nul si la personne n'est pas une partie. */
  party(userId: string, orderId: string): Promise<"client" | "vendor" | null>;
  photoKeys(userId: string, orderId: string): Promise<string[]>;
}

export interface OrderPhotoDeps {
  store: OrderPhotoStore;
  /** Bucket privé ; absent : stockage non configuré (503). */
  signer?: MediaSigner;
}

const UPLOAD_EXPIRES_IN = 300;
const READ_EXPIRES_IN = 600;
const extensions = { "image/jpeg": "jpg", "image/webp": "webp" } as const;
const uuid = z.string().uuid();

/**
 * - `POST /v1/orders/:id/photo-uploads` `{content_type}` → clé `orders/<id>/…` et URL d'envoi ;
 * - `POST /v1/orders/:id/photos` → liens signés courts des photos de la commande.
 * Réservés à la cliente et à la vendeuse de la commande ; la base vérifie la clé à l'usage.
 */
export function registerOrderPhotoRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: OrderPhotoDeps,
) {
  const auth = requireUser(verifyToken);
  const need = async (userId: string, orderId: string) => {
    if (!deps?.signer) throw httpErrors.unavailable("stockage non configuré");
    if (!(await deps.store.party(userId, orderId))) throw httpErrors.notFound("commande introuvable");
    return { store: deps.store, signer: deps.signer };
  };

  app.post("/v1/orders/:id/photo-uploads", auth, async (c) => {
    const orderId = uuid.parse(c.req.param("id"));
    const body = await parseBody(c, z.object({ content_type: z.enum(["image/jpeg", "image/webp"]) }));
    const { signer } = await need(c.get("user").id, orderId);
    const key = `orders/${orderId}/${randomUUID()}.${extensions[body.content_type]}`;
    return c.json({
      object_key: key,
      upload_url: await signer.presignPut(key, body.content_type, UPLOAD_EXPIRES_IN),
      expires_in: UPLOAD_EXPIRES_IN,
    });
  });

  app.post("/v1/orders/:id/photos", auth, async (c) => {
    const orderId = uuid.parse(c.req.param("id"));
    const userId = c.get("user").id;
    const { store, signer } = await need(userId, orderId);
    const urls: Record<string, string> = {};
    for (const key of await store.photoKeys(userId, orderId)) {
      urls[key] = await signer.presignGet(key, READ_EXPIRES_IN);
    }
    return c.json({ urls, expires_in: READ_EXPIRES_IN });
  });
}

export function pgOrderPhotoStore(pool: pg.Pool): OrderPhotoStore {
  const one = async <T>(sql: string, params: unknown[]): Promise<T> => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0]?.value as T;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    party: (userId, orderId) => one("select app.order_party($1, $2) as value", [userId, orderId]),
    photoKeys: async (userId, orderId) =>
      (await one<string[]>("select app.order_photo_keys($1, $2) as value", [userId, orderId])) ?? [],
  };
}
