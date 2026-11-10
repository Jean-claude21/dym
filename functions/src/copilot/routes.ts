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
  /** `text` : gardé seulement si rien n'est proposé (suivi A-AI-03). */
  proposed(
    userId: string,
    proposal: Record<string, unknown>,
    latencyMs: number,
    text: string,
  ): Promise<void>;
  failed(userId: string, latencyMs: number): Promise<void>;
  /** Liste de courses proposée (spec 029) : journal IA, sans le texte. */
  listed(userId: string, count: number, latencyMs: number): Promise<void>;
}

/** Découpe une intention en besoins ([max] au plus, 7 par défaut) ; jamais de prix. */
export interface IntentPlanner {
  plan(input: { model: AiModelConfig; text: string; max?: number }): Promise<CopilotNeed[]>;
}

/** Plafond d'une liste de courses proposée par l'IA (spec 029). */
export const AGENT_LIST_MAX = 15;

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
    await deps.store.proposed(userId, proposal, performance.now() - started, body.text);
    return c.json(proposal);
  });

  // Assistant de courses (spec 029) : description → articles d'une liste, que la personne corrige
  // avant d'enregistrer. Aucun choix de boutique ni prix ici (composition en SQL à l'ouverture).
  app.post("/v1/agent/list", requireUser(verifyToken), async (c) => {
    const body = await parseBody(c, z.object({ text: z.string().trim().min(2).max(300) }));
    if (!deps) throw httpErrors.unavailable("assistant non configuré");
    const userId = c.get("user").id;
    const model = await deps.store.context(userId, null);
    if (!deps.planner) throw httpErrors.unavailable("assistant non configuré");
    const started = performance.now();
    let items: CopilotNeed[];
    try {
      items = cleanNeeds(
        await deps.planner.plan({ model, text: body.text, max: AGENT_LIST_MAX }),
        AGENT_LIST_MAX,
      );
    } catch (error) {
      console.error("[agent] liste en échec", error);
      await deps.store.failed(userId, performance.now() - started);
      throw httpErrors.unavailable("assistant en échec");
    }
    await deps.store.listed(userId, items.length, performance.now() - started);
    return c.json({ items });
  });
}

/** Besoins nettoyés : texte borné, quantité entre 1 et 10, [max] au plus (7 par défaut). */
export function cleanNeeds(needs: CopilotNeed[], max = 7): CopilotNeed[] {
  return needs
    .map((n) => ({
      label: n.label.replace(/\s+/g, " ").trim().slice(0, 60),
      query: n.query.replace(/\s+/g, " ").trim().slice(0, 60),
      quantity: Math.max(1, Math.min(10, Math.round(n.quantity || 1))),
    }))
    .filter((n) => n.label.length > 0 && n.query.length >= 2)
    .slice(0, max);
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
    async proposed(userId, proposal, latencyMs, text) {
      await one("select app.copilot_proposed($1, $2::jsonb, $3, $4) as value", [
        userId,
        JSON.stringify(proposal),
        Math.round(latencyMs),
        text,
      ]);
    },
    async failed(userId, latencyMs) {
      await one("select app.record_ai_request($1, 'intent_copilot', 'failure', $2) as value", [
        userId,
        Math.round(latencyMs),
      ]);
    },
    async listed(userId, count, latencyMs) {
      await one("select app.record_ai_request($1, 'intent_copilot', $2, $3) as value", [
        userId,
        count > 0 ? "success" : "no_result",
        Math.round(latencyMs),
      ]);
    },
  };
}

// ------------------------------------------------------------------ IA

const instructions = (max: number) => [
  "Tu aides une cliente d'un marché d'Afrique de l'Ouest à faire ses courses.",
  "À partir de son intention (un plat, une occasion, une liste, la semaine), liste les produits à acheter :",
  `- 1 à ${max} produits, les plus importants d'abord ;`,
  "- label : le nom affiché, en français (« Gombo frais ») ;",
  "- query : 1 à 3 mots-clés de recherche, au singulier, sans quantité (« gombo ») ;",
  "- quantity : nombre d'unités de vente (tas, bouteille, pièce), entre 1 et 10, d'après le nombre de personnes.",
  "N'invente aucun prix ni aucune boutique. Si l'intention n'est pas une course, renvoie une liste vide.",
].join("\n");

export function aiIntentPlanner(
  providers: Record<string, (model: string) => LanguageModel>,
): IntentPlanner {
  return {
    async plan({ model, text, max = 7 }) {
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
              .max(max),
          }),
        }),
        instructions: instructions(max),
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
