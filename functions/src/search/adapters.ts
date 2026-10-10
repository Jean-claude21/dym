import { createOpenAI } from "@ai-sdk/openai";
import {
  generateText,
  NoTranscriptGeneratedError,
  Output,
  transcribe,
  type LanguageModel,
  type TranscriptionModel,
} from "ai";
import type pg from "pg";
import { z } from "zod";
import type { AiModelConfig } from "../catalog/ports.js";
import { fromPgError } from "../lib/db.js";
import type { PhotoDescriber, SearchAiStore, Transcriber } from "./ports.js";

// ------------------------------------------------------------------ base

/** Fonctions SQL `app.*` (rôle propriétaire de la Function). */
export function pgSearchAiStore(pool: pg.Pool): SearchAiStore {
  return {
    async context(userId, usage) {
      try {
        const { rows } = await pool.query("select app.search_ai_context($1, $2) as value", [
          userId,
          usage,
        ]);
        return rows[0].value.model as AiModelConfig;
      } catch (error) {
        throw fromPgError(error);
      }
    },
    async record(userId, usage, outcome, latencyMs) {
      try {
        await pool.query("select app.record_ai_request($1, $2, $3, $4)", [
          userId,
          usage,
          outcome,
          Math.round(latencyMs),
        ]);
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}

// ------------------------------------------------------------------ IA

/** Fournisseurs reconnus (`ai_models.provider`). */
export interface SearchModelFactories {
  language: Record<string, (model: string) => LanguageModel>;
  transcription: Record<string, (model: string) => TranscriptionModel>;
}

export function aiTranscriber(factories: SearchModelFactories): Transcriber {
  return {
    async transcribe({ model, audio }) {
      const factory = factories.transcription[model.provider];
      if (!factory) throw new Error(`fournisseur d'IA inconnu : ${model.provider}`);
      try {
        const { text } = await transcribe({ model: factory(model.model), audio, maxRetries: 1 });
        return text;
      } catch (error) {
        // Silence ou bruit : aucun texte, ce n'est pas une panne.
        if (NoTranscriptGeneratedError.isInstance(error)) return null;
        throw error;
      }
    },
  };
}

const INSTRUCTIONS = [
  "Tu aides une cliente d'un marché d'Afrique de l'Ouest à retrouver un produit à partir d'une photo.",
  "Réponds par le texte qu'elle taperait dans la recherche : le nom courant du produit en français,",
  "2 à 4 mots, avec l'état s'il est visible (frais, séché, en poudre), sans marque inventée.",
  "Si la photo ne montre aucun produit alimentaire ou ménager reconnaissable, réponds found = false.",
].join("\n");

export function aiPhotoDescriber(factories: SearchModelFactories): PhotoDescriber {
  return {
    async describe({ model, image, mediaType }) {
      const factory = factories.language[model.provider];
      if (!factory) throw new Error(`fournisseur d'IA inconnu : ${model.provider}`);
      const temperature =
        typeof model.params.temperature === "number" ? model.params.temperature : undefined;
      const { output } = await generateText({
        model: factory(model.model),
        output: Output.object({
          schema: z.object({ found: z.boolean(), query: z.string().max(60).nullable() }),
        }),
        instructions: INSTRUCTIONS,
        temperature,
        maxRetries: 1,
        messages: [
          { role: "user", content: [{ type: "image", image, mediaType }] },
        ],
      });
      return output.found ? (output.query ?? null) : null;
    },
  };
}

/** OpenAI, clé en variable de la Function (jamais dans une app). */
export function openAiSearchFactories(apiKey: string): SearchModelFactories {
  const openai = createOpenAI({ apiKey });
  return {
    language: { openai: (model) => openai(model) },
    transcription: { openai: (model) => openai.transcription(model) },
  };
}
