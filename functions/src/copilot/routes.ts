import { createOpenAI } from "@ai-sdk/openai";
import { generateText, type LanguageModel, Output } from "ai";
import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import type { AiModelConfig } from "../catalog/ports.js";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";

/** Besoin tiré d'une intention : un produit à chercher. */
export interface CopilotNeed {
  label: string;
  query: string;
  quantity: number;
}

/** Règles en SQL : flag, choix des produits, chiffrage, journal. */
export interface CopilotStore {
  /** Modèle `intent_copilot` ; erreur `feature_disabled` si coupé. */
  context(userId: string, zoneId: string | null): Promise<AiModelConfig>;
  pick(zoneId: string | null, needs: CopilotNeed[]): Promise<Record<string, unknown>>;
  proposed(userId: string, proposal: Record<string, unknown>, latencyMs: number): Promise<void>;
  failed(userId: string, latencyMs: number): Promise<void>;
}

/** Découpe une intention en besoins (7 au plus) ; jamais de prix. */
export interface IntentPlanner {
  plan(input: { model: AiModelConfig; text: string }): Promise<CopilotNeed[]>;
}

export interface CopilotDeps {
  store: CopilotStore;
  /** Absent : aucun fournisseur d'IA configuré (503, recherche classique). */
  planner?: IntentPlanner;
}

/**
 * Copilote d'intention (spec 019), derrière le flag `intent_copilot` :
 * `POST /v1/copilot/propose` `{text, zone_id}` → panier proposé, chiffré par
 * la base, groupé par boutique, avec les besoins non trouvés. En cas d'échec
 * de l'IA : 503, l'app revient à la recherche classique.
 */
export function registerCopilotRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: CopilotDeps,
) {
  app.post("/v1/copilot/propose", requireUser(verifyToken), async (c) => {
    const body = await parseBody(
      c,
      z.object({
        text: z.string().trim().min(2).max(300),
        zone_id: z.string().uuid().nullish(),
      }),
    );
    if (!deps) throw httpErrors.unavailable("copilote non configuré");
    const userId = c.get("user").id;
    const zoneId = body.zone_id ?? null;
    const model = await deps.store.context(userId, zoneId);
    if (!deps.planner) throw httpErrors.unavailable("copilote non configuré");
    const started = performance.now();
    let needs: CopilotNeed[];
    try {
      needs = cleanNeeds(await deps.planner.plan({ model, text: body.text }));
    } catch (error) {
      console.error("[copilot] intention en échec", error);
      await deps.store.failed(userId, performance.now() - started);
      throw httpErrors.unavailable("copilote en échec");
    }
    const proposal = await deps.store.pick(zoneId, needs);
    await deps.store.proposed(userId, proposal, performance.now() - started);
    return c.json(proposal);
  });
}

/** Besoins nettoyés : texte borné, quantité entre 1 et 10, 7 au plus. */
export function cleanNeeds(needs: CopilotNeed[]): CopilotNeed[] {
  return needs
    .map((n) => ({
      label: n.label.replace(/\s+/g, " ").trim().slice(0, 60),
      query: n.query.replace(/\s+/g, " ").trim().slice(0, 60),
      quantity: Math.max(1, Math.min(10, Math.round(n.quantity || 1))),
    }))
    .filter((n) => n.query.length >= 2)
    .slice(0, 7);
}

// ------------------------------------------------------------------ base

export function pgCopilotStore(pool: pg.Pool): CopilotStore {
  const one = async <T>(sql: string, params: unknown[]): Promise<T> => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0]?.value as T;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    async context(userId, zoneId) {
      const raw = await one<{ model: AiModelConfig }>(
        "select app.copilot_context($1, $2) as value",
        [userId, zoneId],
      );
      return raw.model;
    },
    pick: (zoneId, needs) =>
      one("select app.copilot_pick($1, $2::jsonb) as value", [zoneId, JSON.stringify(needs)]),
    async proposed(userId, proposal, latencyMs) {
      await one("select app.copilot_proposed($1, $2::jsonb, $3) as value", [
        userId,
        JSON.stringify(proposal),
        Math.round(latencyMs),
      ]);
    },
    async failed(userId, latencyMs) {
      await one("select app.record_ai_request($1, 'intent_copilot', 'failure', $2) as value", [
        userId,
        Math.round(latencyMs),
      ]);
    },
  };
}

// ------------------------------------------------------------------ IA

const INSTRUCTIONS = [
  "Tu aides une cliente d'un marché d'Afrique de l'Ouest à faire ses courses.",
  "À partir de son intention (un plat, une occasion, une liste), liste les produits à acheter :",
  "- 1 à 7 produits, les plus importants d'abord ;",
  "- label : le nom affiché, en français (« Gombo frais ») ;",
  "- query : 1 à 3 mots-clés de recherche, au singulier, sans quantité (« gombo ») ;",
  "- quantity : nombre d'unités de vente (tas, bouteille, pièce), entre 1 et 10, d'après le nombre de personnes.",
  "N'invente aucun prix ni aucune boutique. Si l'intention n'est pas une course, renvoie une liste vide.",
].join("\n");

export function aiIntentPlanner(
  providers: Record<string, (model: string) => LanguageModel>,
): IntentPlanner {
  return {
    async plan({ model, text }) {
      const factory = providers[model.provider];
      if (!factory) throw new Error(`fournisseur d'IA inconnu : ${model.provider}`);
      const temperature =
        typeof model.params.temperature === "number" ? model.params.temperature : undefined;
      const { output } = await generateText({
        model: factory(model.model),
        output: Output.object({
          schema: z.object({
            needs: z
              .array(
                z.object({
                  label: z.string().max(60),
                  query: z.string().max(60),
                  quantity: z.number().int().min(1).max(10),
                }),
              )
              .max(7),
          }),
        }),
        instructions: INSTRUCTIONS,
        temperature,
        maxRetries: 1,
        prompt: text,
      });
      return output.needs;
    },
  };
}

export function openAiPlannerProviders(apiKey: string) {
  const openai = createOpenAI({ apiKey });
  return { openai: (model: string) => openai(model) };
}
