import { createOpenAI } from "@ai-sdk/openai";
import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { generateText, type LanguageModel, Output } from "ai";
import type pg from "pg";
import { z } from "zod";
import { fromPgError } from "../lib/db.js";
import type {
  AiModelConfig,
  CatalogStore,
  PhotoSigner,
  ProductSuggester,
  SuggestionContext,
} from "./ports.js";

// ------------------------------------------------------------------ base

/** Fonctions SQL `app.*` (rôle propriétaire de la Function). */
export function pgCatalogStore(pool: pg.Pool): CatalogStore {
  const one = async <T>(sql: string, params: unknown[]): Promise<T> => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0].value as T;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    photoUploadStore: (userId) =>
      one<string>("select app.photo_upload_store($1) as value", [userId]),
    async suggestionContext(userId, objectKey) {
      const raw = await one<{
        store_id: string;
        model: AiModelConfig | null;
        categories: { id: string; label: string }[];
      }>("select app.suggestion_context($1, $2) as value", [userId, objectKey]);
      return {
        storeId: raw.store_id,
        model: raw.model,
        categories: raw.categories,
      } satisfies SuggestionContext;
    },
    recordSuggestion: ({ userId, objectKey, model, suggestion }) =>
      one<string>("select app.record_product_suggestion($1, $2, $3, $4, $5, $6) as value", [
        userId,
        objectKey,
        model,
        suggestion.name,
        suggestion.categoryId,
        suggestion.description,
      ]),
  };
}

// ------------------------------------------------------------------ stockage

/**
 * Stockage d'objets Neon (S3, adressage par chemin obligatoire). Lecture
 * publique : bucket `public_read`, URL = point d'accès / bucket / clé.
 */
export function s3PhotoSigner(options: {
  endpoint: string;
  region: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
}): PhotoSigner {
  const client = new S3Client({
    endpoint: options.endpoint,
    region: options.region,
    forcePathStyle: true,
    credentials: {
      accessKeyId: options.accessKeyId,
      secretAccessKey: options.secretAccessKey,
    },
  });
  const base = `${options.endpoint.replace(/\/+$/, "")}/${options.bucket}`;
  return {
    presignPut: (key, contentType, expiresIn) =>
      getSignedUrl(
        client,
        new PutObjectCommand({ Bucket: options.bucket, Key: key, ContentType: contentType }),
        { expiresIn },
      ),
    publicUrl: (key) => `${base}/${key}`,
  };
}

// ------------------------------------------------------------------ IA

const INSTRUCTIONS = [
  "Tu aides une vendeuse d'un marché d'Afrique de l'Ouest à mettre un produit en vente.",
  "À partir de la photo, propose :",
  "- un nom court en français (2 à 80 caractères), avec la contenance ou la quantité si elle est visible, sans marque inventée ;",
  "- le rayon le plus proche, par son identifiant dans la liste fournie, ou null si aucun ne convient ;",
  "- une description d'une phrase en français (500 caractères au plus), factuelle, sans prix ni promesse de santé.",
].join("\n");

/** Fournisseurs reconnus (`ai_models.provider`). */
type ModelFactory = (model: string) => LanguageModel;

export function aiProductSuggester(providers: Record<string, ModelFactory>): ProductSuggester {
  return {
    async suggest({ model, imageUrl, categories }) {
      const factory = providers[model.provider];
      if (!factory) throw new Error(`fournisseur d'IA inconnu : ${model.provider}`);
      const ids = categories.map((c) => c.id);
      const schema = z.object({
        name: z.string().min(2).max(80),
        category_id: (ids.length ? z.enum(ids as [string, ...string[]]) : z.null()).nullable(),
        description: z.string().max(500).nullable(),
      });
      const temperature =
        typeof model.params.temperature === "number" ? model.params.temperature : undefined;
      const { output } = await generateText({
        model: factory(model.model),
        output: Output.object({ schema }),
        instructions: INSTRUCTIONS,
        temperature,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Rayons :\n${categories.map((c) => `${c.id} : ${c.label}`).join("\n")}`,
              },
              { type: "image", image: new URL(imageUrl) },
            ],
          },
        ],
      });
      return {
        name: output.name,
        categoryId: output.category_id ?? null,
        description: output.description,
      };
    },
  };
}

/** OpenAI, clé en variable de la Function (jamais dans une app). */
export function openAiProviders(apiKey: string): Record<string, ModelFactory> {
  const openai = createOpenAI({ apiKey });
  return { openai: (model) => openai(model) };
}
