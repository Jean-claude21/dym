import { randomUUID } from "node:crypto";
import type { Hono } from "hono";
import { z } from "zod";
import type { CatalogDeps } from "../catalog/routes.js";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";

/** Durée de validité d'une URL d'envoi (une vidéo de 60 s sur 3G). */
export const CONTENT_UPLOAD_EXPIRES_IN = 900;

const extensions = { "image/jpeg": "jpg", "image/webp": "webp", "video/mp4": "mp4" } as const;

/**
 * Contenus shoppables (spec 020) : `POST /v1/content/uploads` donne une URL
 * présignée dans le dossier de la boutique de la vendeuse
 * (`stores/<boutique>/contents/<id>.<ext>`). La publication, elle, passe par
 * `save_content` (Data API), qui vérifie la clé.
 */
export function registerContentRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: CatalogDeps,
) {
  app.post("/v1/content/uploads", requireUser(verifyToken), async (c) => {
    const body = await parseBody(
      c,
      z.object({ content_type: z.enum(["image/jpeg", "image/webp", "video/mp4"]) }),
    );
    if (!deps?.signer) throw httpErrors.unavailable("stockage non configuré");
    const storeId = await deps.store.photoUploadStore(c.get("user").id);
    const id = randomUUID();
    const key = `stores/${storeId}/contents/${id}.${extensions[body.content_type]}`;
    return c.json({
      content_id: id,
      object_key: key,
      upload_url: await deps.signer.presignPut(key, body.content_type, CONTENT_UPLOAD_EXPIRES_IN),
      public_url: deps.signer.publicUrl(key),
      expires_in: CONTENT_UPLOAD_EXPIRES_IN,
    });
  });
}
