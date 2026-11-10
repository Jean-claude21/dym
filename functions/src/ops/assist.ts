import { createOpenAI } from "@ai-sdk/openai";
import { parseTriggerInvocation } from "@neon/functions/triggers";
import { generateText, type LanguageModel, Output } from "ai";
import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import type { AiModelConfig } from "../catalog/ports.js";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";

// Antifraude, modération et support assistés (spec 054). L'IA propose, l'équipe décide :
// les règles de fraude sont en SQL, les avis de l'IA sont des suggestions affichées à l'équipe,
// et le brouillon de réponse est relu et envoyé par un humain.

export interface TriageItem {
  target_type: string;
  target_id: string;
  reasons: string[];
  notes: string[];
  text: string | null;
}

export type Verdict = "keep" | "remove" | "unsure";

export interface DraftContext {
  model: AiModelConfig | null;
  subject: string;
  app: string;
  locale: string;
  order_status: string | null;
  messages: { role: "user" | "team"; body: string }[];
}

/** Règles et traces en SQL (fonctions `app.*`, rôle propriétaire de la Function). */
export interface OpsAssistStore {
  detectFraud(): Promise<number>;
  reportsToTriage(limit: number): Promise<{ model: AiModelConfig | null; items: TriageItem[] }>;
  recordTriage(item: TriageItem, verdict: Verdict, reason: string, model: string): Promise<void>;
  draftContext(adminId: string, ticketId: string): Promise<DraftContext>;
}

export interface ReportJudge {
  judge(input: { model: AiModelConfig; item: TriageItem }): Promise<{ verdict: Verdict; reason: string }>;
}

export interface SupportDrafter {
  draft(input: { model: AiModelConfig; context: DraftContext }): Promise<string>;
}

export interface OpsAssistDeps {
  store: OpsAssistStore;
  judge?: ReportJudge;
  drafter?: SupportDrafter;
}

export function pgOpsAssistStore(pool: pg.Pool): OpsAssistStore {
  const value = async <T>(sql: string, params: unknown[]) => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0].value as T;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    detectFraud: () => value<number>("select app.detect_fraud_signals() as value", []),
    reportsToTriage: (limit) => value("select app.reports_to_triage($1) as value", [limit]),
    async recordTriage(item, verdict, reason, model) {
      await value("select app.record_report_triage($1, $2, $3, $4, $5) as value", [
        item.target_type,
        item.target_id,
        verdict,
        reason,
        model,
      ]);
    },
    draftContext: (adminId, ticketId) =>
      value("select app.support_draft_context($1, $2) as value", [adminId, ticketId]),
  };
}

// ------------------------------------------------------------------ IA

const temperature = (model: AiModelConfig, fallback: number) =>
  typeof model.params.temperature === "number" ? model.params.temperature : fallback;

export function aiReportJudge(providers: Record<string, (model: string) => LanguageModel>): ReportJudge {
  return {
    async judge({ model, item }) {
      const factory = providers[model.provider];
      if (!factory) throw new Error(`fournisseur d'IA inconnu : ${model.provider}`);
      const { output } = await generateText({
        model: factory(model.model),
        output: Output.object({
          schema: z.object({ verdict: z.enum(["keep", "remove", "unsure"]), reason: z.string().max(300) }),
        }),
        instructions: [
          "Tu aides l'équipe de modération d'une place de marché alimentaire d'Afrique de l'Ouest.",
          "On te donne un contenu signalé (publication, produit, commentaire ou avis) et les motifs.",
          "Réponds « remove » s'il est clairement trompeur, offensant, interdit ou du spam ;",
          "« keep » s'il est acceptable ; « unsure » si tu hésites. Donne une raison courte en français.",
          "Tu ne décides pas : l'équipe tranche.",
        ].join("\n"),
        temperature: temperature(model, 0),
        maxRetries: 1,
        prompt: JSON.stringify({
          type: item.target_type,
          motifs: item.reasons,
          notes: item.notes,
          texte: item.text ?? "",
        }),
      });
      return output;
    },
  };
}

export function aiSupportDrafter(providers: Record<string, (model: string) => LanguageModel>): SupportDrafter {
  return {
    async draft({ model, context }) {
      const factory = providers[model.provider];
      if (!factory) throw new Error(`fournisseur d'IA inconnu : ${model.provider}`);
      const { text } = await generateText({
        model: factory(model.model),
        instructions: [
          "Tu rédiges un brouillon de réponse pour l'équipe support de DYM (courses de produits frais).",
          `Langue de la personne : ${context.locale}. Ton chaleureux, simple, court (3 à 5 phrases).`,
          "N'invente aucun fait, montant ni délai. Ne promets jamais de remboursement : l'équipe décide.",
          "Si une information manque, pose une question précise.",
        ].join("\n"),
        temperature: temperature(model, 0.3),
        maxRetries: 1,
        prompt: JSON.stringify({
          sujet: context.subject,
          app: context.app,
          statut_commande: context.order_status,
          fil: context.messages,
        }),
      });
      return text.trim();
    },
  };
}

export function openAiAssistProviders(apiKey: string) {
  const openai = createOpenAI({ apiKey });
  return { openai: (model: string) => openai(model) };
}

// ------------------------------------------------------------------ routes

export function registerOpsAssist(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: OpsAssistDeps,
) {
  const trigger = async (request: Request) => {
    const parsed = await parseTriggerInvocation(request);
    return parsed.ok ? null : { error: parsed.error, status: parsed.error === "invalid_body" ? 400 : 401 };
  };

  app.post("/v1/jobs/fraud-signals", async (c) => {
    const refused = await trigger(c.req.raw);
    if (refused) return c.json({ error: refused.error }, refused.status as 400 | 401);
    if (!deps) return c.json({ error: "unavailable" }, 503);
    return c.json({ signals: await deps.store.detectFraud() });
  });

  // Sans modèle actif ni clé : rien n'est trié, l'équipe garde la file telle quelle.
  app.post("/v1/jobs/moderation-triage", async (c) => {
    const refused = await trigger(c.req.raw);
    if (refused) return c.json({ error: refused.error }, refused.status as 400 | 401);
    if (!deps) return c.json({ error: "unavailable" }, 503);
    const { model, items } = await deps.store.reportsToTriage(20);
    if (!model || !deps.judge) return c.json({ triaged: 0, ai: false });
    let triaged = 0;
    for (const item of items) {
      try {
        const { verdict, reason } = await deps.judge.judge({ model, item });
        await deps.store.recordTriage(item, verdict, reason, model.model);
        triaged += 1;
      } catch {
        // Un échec n'arrête pas la file : le signalement reste sans avis et sera repris.
      }
    }
    return c.json({ triaged, ai: true });
  });

  app.post("/v1/admin/tickets/:id/draft", requireUser(verifyToken), async (c) => {
    const ticketId = c.req.param("id");
    if (!z.string().uuid().safeParse(ticketId).success) throw httpErrors.notFound("introuvable");
    if (!deps) throw httpErrors.unavailable("assistance non configurée");
    const context = await deps.store.draftContext(c.get("user").id, ticketId);
    if (!context.model || !deps.drafter) throw httpErrors.unavailable("ai_unavailable");
    return c.json({ draft: await deps.drafter.draft({ model: context.model, context }) });
  });
}
