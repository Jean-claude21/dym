import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";

export type BroadcastSegment = "regular" | "month" | "all";

/** Règles en SQL : flag `vendor_broadcast`, segment, une relance par jour. */
export interface BroadcastStore {
  send(input: {
    userId: string;
    segment: BroadcastSegment;
    message: string;
    productId: string | null;
  }): Promise<{ id: string; recipients: number }>;
}

/**
 * Relance des clientes (spec 021) : `POST /v1/vendor/broadcasts`
 * `{segment, message, product_id}`. Les notifications sont créées en base ;
 * le push part avec la file habituelle après le geste.
 */
export function registerBroadcastRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  store?: BroadcastStore,
) {
  app.post("/v1/vendor/broadcasts", requireUser(verifyToken), async (c) => {
    const body = await parseBody(
      c,
      z.object({
        segment: z.enum(["regular", "month", "all"]),
        message: z.string().trim().min(2).max(300),
        product_id: z.string().uuid().nullish(),
      }),
    );
    if (!store) throw httpErrors.unavailable("relance non configurée");
    const sent = await store.send({
      userId: c.get("user").id,
      segment: body.segment,
      message: body.message,
      productId: body.product_id ?? null,
    });
    return c.json(sent, 201);
  });
}

export function pgBroadcastStore(pool: pg.Pool): BroadcastStore {
  return {
    async send({ userId, segment, message, productId }) {
      try {
        const { rows } = await pool.query(
          "select app.send_broadcast($1, $2, $3, $4) as value",
          [userId, segment, message, productId],
        );
        return rows[0].value as { id: string; recipients: number };
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}
