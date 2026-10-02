import { randomUUID } from "node:crypto";
import type { Hono } from "hono";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";
import type { CatalogStore, PhotoSigner, ProductSuggester } from "./ports.js";

export interface CatalogDeps {
  store: CatalogStore;
  /** Absent : stockage non configuré (503). */
  signer?: PhotoSigner;
  /** Absent : aucun fournisseur d'IA configuré (503, saisie manuelle). */
  suggester?: ProductSuggester;
}

/** Durée de validité d'une URL d'envoi. */
export const UPLOAD_EXPIRES_IN = 300;

const extensions = { "image/jpeg": "jpg", "image/webp": "webp" } as const;

const photoKey = z
  .string()
  .regex(/^stores\/[0-9a-f-]{36}\/products\/[0-9a-f-]{36}\.(jpg|webp)$/, "clé de photo invalide");

/**
 * Catalogue (spec 007) :
 * - `POST /v1/catalog/photo-uploads` : URL présignée pour une photo de produit ;
 * - `POST /v1/catalog/suggestions` : nom, rayon et description proposés.
 */
export function registerCatalogRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: CatalogDeps,
) {
  const auth = requireUser(verifyToken);

  app.post("/v1/catalog/photo-uploads", auth, async (c) => {
    const body = await parseBody(
      c,
      z.object({ content_type: z.enum(["image/jpeg", "image/webp"]) }),
    );
    if (!deps?.signer) throw httpErrors.unavailable("stockage non configuré");
    const storeId = await deps.store.photoUploadStore(c.get("user").id);
    const key = `stores/${storeId}/products/${randomUUID()}.${extensions[body.content_type]}`;
    return c.json({
      object_key: key,
      upload_url: await deps.signer.presignPut(key, body.content_type, UPLOAD_EXPIRES_IN),
      public_url: deps.signer.publicUrl(key),
      expires_in: UPLOAD_EXPIRES_IN,
    });
  });

  app.post("/v1/catalog/suggestions", auth, async (c) => {
    const body = await parseBody(c, z.object({ object_key: photoKey }));
    if (!deps?.signer) throw httpErrors.unavailable("stockage non configuré");
    const userId = c.get("user").id;
    const context = await deps.store.suggestionContext(userId, body.object_key);
    if (!context.model || !deps.suggester) {
      throw httpErrors.unavailable("proposition désactivée");
    }
    let suggestion;
    try {
      suggestion = await deps.suggester.suggest({
        model: context.model,
        imageUrl: deps.signer.publicUrl(body.object_key),
        categories: context.categories,
      });
    } catch (error) {
      console.error("[catalog] proposition en échec", error);
      throw httpErrors.unavailable("proposition en échec");
    }
    const known = new Set(context.categories.map((c) => c.id));
    const cleaned = {
      name: suggestion.name.trim().slice(0, 80),
      categoryId:
        suggestion.categoryId && known.has(suggestion.categoryId) ? suggestion.categoryId : null,
      description: suggestion.description?.trim().slice(0, 500) || null,
    };
    const id = await deps.store.recordSuggestion({
      userId,
      objectKey: body.object_key,
      model: context.model.model,
      suggestion: cleaned,
    });
    return c.json({
      suggestion_id: id,
      name: cleaned.name,
      category_id: cleaned.categoryId,
      description: cleaned.description,
    });
  });
}
