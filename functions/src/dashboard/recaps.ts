import { parseTriggerInvocation } from "@neon/functions/triggers";
import type { Hono } from "hono";
import type pg from "pg";
import type { AuthVariables } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";

export interface VendorRecaps {
  create(at: string): Promise<number>;
}

export function pgVendorRecaps(pool: pg.Pool): VendorRecaps {
  return {
    async create(at) {
      try {
        const result = await pool.query("select app.create_vendor_recaps($1::timestamptz) as count", [at]);
        return result.rows[0].count as number;
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}

/** Neon supprime les en-têtes X-Neon-* des appels publics. Le parseur vérifie
 * l'identifiant d'invocation et le corps ; SQL protège les dates et les doublons.
 */
export function registerVendorRecaps(app: Hono<{ Variables: AuthVariables }>, recaps?: VendorRecaps) {
  app.post("/v1/jobs/vendor-recaps", async (c) => {
    const parsed = await parseTriggerInvocation(c.req.raw);
    if (!parsed.ok) return c.json({ error: parsed.error }, parsed.error === "invalid_body" ? 400 : 401);
    if (!recaps) return c.json({ error: "unavailable" }, 503);
    const count = await recaps.create(parsed.invocation.data.scheduledAt);
    return c.json({ created: count });
  });
}
