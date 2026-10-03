import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";

export type OrderJson = Record<string, unknown> & { id: string; status: string };

/** Règles en SQL (`app.transition_order`, `app.confirm_cash`). */
export interface LifecycleStore {
  transition(input: {
    userId: string;
    orderId: string;
    to: string;
    expected: string;
    reason: string | null;
    note: string | null;
  }): Promise<OrderJson>;
  confirmCash(userId: string, orderId: string): Promise<OrderJson>;
}

export function pgLifecycleStore(pool: pg.Pool): LifecycleStore {
  const one = async (sql: string, params: unknown[]) => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0].value as OrderJson;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    transition: (i) =>
      one("select app.transition_order($1, $2, $3, $4, $5, $6) as value", [
        i.userId,
        i.orderId,
        i.to,
        i.expected,
        i.reason,
        i.note,
      ]),
    confirmCash: (userId, orderId) =>
      one("select app.confirm_cash($1, $2) as value", [userId, orderId]),
  };
}

const statuses = [
  "accepted",
  "preparing",
  "ready",
  "out_for_delivery",
  "delivered",
  "refused",
  "cancelled",
] as const;

/**
 * Cycle de vie (spec 011) :
 * - `POST /v1/orders/:id/transitions` `{to, expected, reason?, note?}` : la
 *   base décide (rôle, mode, statut attendu) ; refus → 422 avec son code ;
 * - `POST /v1/orders/:id/cash-collected` : encaissement du cash.
 */
export function registerLifecycleRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  store?: LifecycleStore,
) {
  const auth = requireUser(verifyToken);
  const uuid = z.string().uuid();
  const need = () => {
    if (!store) throw httpErrors.unavailable("commandes non configurées");
    return store;
  };

  app.post("/v1/orders/:id/transitions", auth, async (c) => {
    const id = c.req.param("id");
    if (!uuid.safeParse(id).success) throw httpErrors.notFound("commande introuvable");
    const body = await parseBody(
      c,
      z.object({
        to: z.enum(statuses),
        expected: z.string().min(1).max(40),
        reason: z.enum(["out_of_stock", "too_busy", "area_not_served", "other"]).nullable().optional(),
        note: z.string().max(200).nullable().optional(),
      }),
    );
    return c.json(
      await need().transition({
        userId: c.get("user").id,
        orderId: id,
        to: body.to,
        expected: body.expected,
        reason: body.reason ?? null,
        note: body.note ?? null,
      }),
    );
  });

  app.post("/v1/orders/:id/cash-collected", auth, async (c) => {
    const id = c.req.param("id");
    if (!uuid.safeParse(id).success) throw httpErrors.notFound("commande introuvable");
    return c.json(await need().confirmCash(c.get("user").id, id));
  });
}
