import type { Hono } from "hono";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";
import type { PhotoDescriber, SearchAiStore, SearchAiUsage, Transcriber } from "./ports.js";

export interface SearchAiDeps {
  store: SearchAiStore;
  /** Absents : aucun fournisseur d'IA configuré (503, recherche classique). */
  transcriber?: Transcriber;
  describer?: PhotoDescriber;
}

/** Message vocal : 20 secondes à bas débit tiennent largement. */
export const MAX_AUDIO_BYTES = 1_000_000;
/** Photo compressée sur l'appareil. */
export const MAX_IMAGE_BYTES = 1_500_000;

const audioTypes = ["audio/mp4", "audio/m4a", "audio/aac", "audio/mpeg", "audio/wav", "audio/webm", "audio/ogg"] as const;
const imageTypes = ["image/jpeg", "image/webp", "image/png"] as const;

const base64 = (max: number) =>
  z
    .string()
    .min(8)
    .max(Math.ceil((max * 4) / 3) + 4)
    .regex(/^[A-Za-z0-9+/]+={0,2}$/, "base64 invalide");

/** Texte de recherche : espaces normalisés, 80 caractères au plus. */
export const cleanQuery = (text: string | null | undefined): string | null => {
  const cleaned = (text ?? "").replace(/\s+/g, " ").replace(/^[\s.,;:!?«»"']+|[\s.,;:!?«»"']+$/g, "").slice(0, 80);
  return cleaned.length >= 2 ? cleaned : null;
};

/**
 * Recherche IA (spec 018), derrière le flag `ai_search` :
 * - `POST /v1/search/voice` : message vocal → texte de recherche ;
 * - `POST /v1/search/photo` : photo → texte de recherche.
 * Rien n'est conservé : ni l'audio, ni la photo. Le résultat et la latence
 * sont journalisés (A-AI-01..03).
 */
export function registerSearchAiRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: SearchAiDeps,
) {
  const auth = requireUser(verifyToken);

  async function run(
    userId: string,
    usage: SearchAiUsage,
    work: (model: Awaited<ReturnType<SearchAiStore["context"]>>) => Promise<string | null>,
  ) {
    if (!deps) throw httpErrors.unavailable("recherche IA non configurée");
    const model = await deps.store.context(userId, usage);
    const started = performance.now();
    let query: string | null;
    try {
      query = cleanQuery(await work(model));
    } catch (error) {
      console.error(`[search] ${usage} en échec`, error);
      await deps.store.record(userId, usage, "failure", performance.now() - started);
      throw httpErrors.unavailable("recherche IA en échec");
    }
    await deps.store.record(userId, usage, query ? "success" : "no_result", performance.now() - started);
    return { query };
  }

  app.post("/v1/search/voice", auth, async (c) => {
    const body = await parseBody(
      c,
      z.object({ audio: base64(MAX_AUDIO_BYTES), media_type: z.enum(audioTypes) }),
    );
    const transcriber = deps?.transcriber;
    if (!transcriber) throw httpErrors.unavailable("transcription non configurée");
    const audio = Buffer.from(body.audio, "base64");
    if (audio.byteLength > MAX_AUDIO_BYTES) throw httpErrors.validation({ audio: "trop long" });
    return c.json(
      await run(c.get("user").id, "search_transcription", (model) =>
        transcriber.transcribe({ model, audio, mediaType: body.media_type }),
      ),
    );
  });

  app.post("/v1/search/photo", auth, async (c) => {
    const body = await parseBody(
      c,
      z.object({ image: base64(MAX_IMAGE_BYTES), media_type: z.enum(imageTypes) }),
    );
    const describer = deps?.describer;
    if (!describer) throw httpErrors.unavailable("recherche par photo non configurée");
    const image = Buffer.from(body.image, "base64");
    if (image.byteLength > MAX_IMAGE_BYTES) throw httpErrors.validation({ image: "trop lourde" });
    return c.json(
      await run(c.get("user").id, "search_from_photo", (model) =>
        describer.describe({ model, image, mediaType: body.media_type }),
      ),
    );
  });
}
