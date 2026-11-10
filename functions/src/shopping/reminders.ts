import { parseTriggerInvocation } from "@neon/functions/triggers";
import type { Hono } from "hono";
import type pg from "pg";
import type { AuthVariables } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";

/** Rappels des courses récurrentes (spec 029) : règles en SQL. */
export interface ShoppingReminders {
  create(at: string): Promise<number>;
}

export function pgShoppingReminders(pool: pg.Pool): ShoppingReminders {
  return {
    async create(at) {
      try {
        const result = await pool.query(
          "select app.create_shopping_reminders($1::timestamptz) as count",
          [at],
        );
        return result.rows[0].count as number;
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}

/** Tâche planifiée : le parseur vérifie l'invocation ; SQL protège l'heure et les doublons. */
export function registerShoppingReminders(
  app: Hono<{ Variables: AuthVariables }>,
  reminders?: ShoppingReminders,
) {
  app.post("/v1/jobs/shopping-reminders", async (c) => {
    const parsed = await parseTriggerInvocation(c.req.raw);
    if (!parsed.ok) {
      return c.json({ error: parsed.error }, parsed.error === "invalid_body" ? 400 : 401);
    }
    if (!reminders) return c.json({ error: "unavailable" }, 503);
    const count = await reminders.create(parsed.invocation.data.scheduledAt);
    return c.json({ created: count });
  });
}
