import { randomUUID } from "node:crypto";
import { createOpenAI } from "@ai-sdk/openai";
import { generateText, type LanguageModel, Output } from "ai";
import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import type { AiModelConfig, PhotoSigner } from "../catalog/ports.js";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";
import { CONTENT_UPLOAD_EXPIRES_IN } from "./routes.js";

export interface CreatorCategory {
  slug: string;
  label: string;
}

/** Règles en SQL : profil créateur, modèle actif, catégories du référentiel. */
export interface CreatorContentStore {
  /** Refus `not_creator` (42501) ou `feature_disabled`. */
  classifierContext(userId: string): Promise<{ model: AiModelConfig; categories: CreatorCategory[] }>;
  isCreator(userId: string): Promise<boolean>;
}

/** Propose une catégorie du référentiel pour une légende ; jamais une autre. */
export interface ContentClassifier {
  classify(input: { model: AiModelConfig; caption: string; categories: CreatorCategory[] }): Promise<string | null>;
}

export interface CreatorContentDeps {
  store: CreatorContentStore;
  signer?: PhotoSigner;
  classifier?: ContentClassifier;
}

const extensions = { "image/jpeg": "jpg", "image/webp": "webp", "video/mp4": "mp4" } as const;

/**
 * Créatrices (spec 036) :
 * - `POST /v1/creator-content/uploads` : URL d'envoi dans `creators/<id>/contents/<contenu>.<ext>` ;
 * - `POST /v1/creator-content/classify` `{caption}` → `{slug}` (catégorie du référentiel, ou nul).
 * La publication passe par `save_creator_content` (Data API), qui vérifie la clé.
 */
export function registerCreatorContentRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: CreatorContentDeps,
) {
  const auth = requireUser(verifyToken);

  app.post("/v1/creator-content/uploads", auth, async (c) => {
    const body = await parseBody(c, z.object({ content_type: z.enum(["image/jpeg", "image/webp", "video/mp4"]) }));
    if (!deps?.signer) throw httpErrors.unavailable("stockage non configuré");
    const userId = c.get("user").id;
    if (!(await deps.store.isCreator(userId))) throw httpErrors.forbidden("profil créateur requis");
    const id = randomUUID();
    const key = `creators/${userId}/contents/${id}.${extensions[body.content_type]}`;
    return c.json({
      content_id: id,
      object_key: key,
      upload_url: await deps.signer.presignPut(key, body.content_type, CONTENT_UPLOAD_EXPIRES_IN),
      public_url: deps.signer.publicUrl(key),
      expires_in: CONTENT_UPLOAD_EXPIRES_IN,
    });
  });

  app.post("/v1/creator-content/classify", auth, async (c) => {
    const body = await parseBody(c, z.object({ caption: z.string().trim().min(3).max(200) }));
    if (!deps) throw httpErrors.unavailable("classement non configuré");
    const { model, categories } = await deps.store.classifierContext(c.get("user").id);
    if (!deps.classifier) return c.json({ slug: null });
    try {
      const slug = await deps.classifier.classify({ model, caption: body.caption, categories });
      return c.json({ slug: categories.some((k) => k.slug === slug) ? slug : null });
    } catch (error) {
      // Jamais bloquant : l'app publie alors en « Autre ».
      console.error("[creator] classement en échec", error);
      return c.json({ slug: null });
    }
  });
}

export function pgCreatorContentStore(pool: pg.Pool): CreatorContentStore {
  const one = async <T>(sql: string, params: unknown[]): Promise<T> => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0]?.value as T;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    classifierContext: (userId) => one("select app.content_classifier_context($1) as value", [userId]),
    isCreator: async (userId) =>
      (await one<boolean>(
        "select exists (select 1 from public.creator_profiles where user_id = $1) as value",
        [userId],
      )) === true,
  };
}

export function aiContentClassifier(providers: Record<string, (model: string) => LanguageModel>): ContentClassifier {
  return {
    async classify({ model, caption, categories }) {
      const factory = providers[model.provider];
      if (!factory) throw new Error(`fournisseur d'IA inconnu : ${model.provider}`);
      const slugs = categories.map((k) => k.slug) as [string, ...string[]];
      const { output } = await generateText({
        model: factory(model.model),
        output: Output.object({ schema: z.object({ slug: z.enum(slugs) }) }),
        instructions: [
          "Classe une publication culinaire (marché, courses, cuisine d'Afrique de l'Ouest).",
          "Réponds par l'identifiant d'une seule catégorie :",
          ...categories.map((k) => `- ${k.slug} : ${k.label}`),
          "Si aucune ne convient, choisis « autre ».",
        ].join("\n"),
        temperature: typeof model.params.temperature === "number" ? model.params.temperature : 0,
        maxRetries: 1,
        prompt: caption,
      });
      return output.slug;
    },
  };
}

export function openAiClassifierProviders(apiKey: string) {
  const openai = createOpenAI({ apiKey });
  return { openai: (model: string) => openai(model) };
}
