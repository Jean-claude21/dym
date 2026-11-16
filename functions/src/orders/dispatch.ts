import { parseTriggerInvocation } from "@neon/functions/triggers";
import type { Hono } from "hono";
import type pg from "pg";
import type { AuthVariables } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";

/** Refus automatiques et relances de livreurs d'un passage (spec 066). */
export interface DispatchWatch {
  run(at: string): Promise<{ refused: number; relaunched: number; cartReminders?: number }>;
}

export function pgDispatchWatch(pool: pg.Pool): DispatchWatch {
  return {
    async run(at) {
      try {
        const result = await pool.query("select app.run_dispatch_watch($1::timestamptz) as value", [at]);
        // Ménage des événements en direct de plus de 24 h (spec 067).
        await pool.query("select app.prune_live_events($1::timestamptz)", [at]);
        // Sonneries de plus de 60 s : appels manqués, notifiés (spec 097).
        await pool.query("select app.sweep_missed_calls($1::timestamptz)", [at]);
        // Rappels « Ton panier t'attend » (spec 080) ; envoyés par le push qui suit.
        const carts = await pool.query("select app.remind_carts($1::timestamptz) as value", [at]);
        return {
          ...(result.rows[0].value as { refused: number; relaunched: number }),
          cartReminders: carts.rows[0].value as number,
        };
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}

/** Tâche planifiée : les délais et les règles sont en SQL (réglages du pays). */
export function registerDispatchWatch(app: Hono<{ Variables: AuthVariables }>, watch?: DispatchWatch) {
  app.post("/v1/jobs/dispatch-watch", async (c) => {
    const parsed = await parseTriggerInvocation(c.req.raw);
    if (!parsed.ok) return c.json({ error: parsed.error }, parsed.error === "invalid_body" ? 400 : 401);
    if (!watch) return c.json({ error: "unavailable" }, 503);
    return c.json(await watch.run(parsed.invocation.data.scheduledAt));
  });
}
