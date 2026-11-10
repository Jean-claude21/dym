import { parseTriggerInvocation } from "@neon/functions/triggers";
import type { Hono } from "hono";
import type pg from "pg";
import type { AuthVariables } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";

/** Versement des commissions d'affiliation arrivées à échéance (spec 039) : règles en SQL. */
export interface AffiliateSettlement {
  settle(at: string): Promise<number>;
}

export function pgAffiliateSettlement(pool: pg.Pool): AffiliateSettlement {
  return {
    async settle(at) {
      try {
        const result = await pool.query(
          "select app.settle_affiliate_commissions($1::timestamptz) as count",
          [at],
        );
        return result.rows[0].count as number;
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}

/** Tâche planifiée : le parseur vérifie l'invocation ; SQL garantit un versement par commission. */
export function registerAffiliateSettlement(
  app: Hono<{ Variables: AuthVariables }>,
  settlement?: AffiliateSettlement,
) {
  app.post("/v1/jobs/affiliate-settlement", async (c) => {
    const parsed = await parseTriggerInvocation(c.req.raw);
    if (!parsed.ok) {
      return c.json({ error: parsed.error }, parsed.error === "invalid_body" ? 400 : 401);
    }
    if (!settlement) return c.json({ error: "unavailable" }, 503);
    const count = await settlement.settle(parsed.invocation.data.scheduledAt);
    return c.json({ paid: count });
  });
}
