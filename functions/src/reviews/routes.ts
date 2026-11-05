import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";

export type ReviewJson = Record<string, unknown> & { id: string };

/** Règles en SQL (`app.leave_review`, `app.reply_review`). */
export interface ReviewStore {
  leave(input: {
    userId: string;
    orderId: string;
    rating: number;
    tags: string[];
    comment: string | null;
  }): Promise<ReviewJson>;
  reply(userId: string, reviewId: string, reply: string): Promise<ReviewJson>;
}

export function pgReviewStore(pool: pg.Pool): ReviewStore {
  const one = async (sql: string, params: unknown[]) => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0].value as ReviewJson;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    leave: (i) =>
      one("select app.leave_review($1, $2, $3, $4, $5) as value", [
        i.userId,
        i.orderId,
        i.rating,
        i.tags,
        i.comment,
      ]),
    reply: (u, r, text) => one("select app.reply_review($1, $2, $3) as value", [u, r, text]),
  };
}

const uuid = z.string().uuid();

/**
 * Avis (spec 016) ; la base vérifie la commande et la boutique :
 * - `POST /v1/orders/:id/review` `{rating, tags?, comment?}` (cliente) ;
 * - `POST /v1/reviews/:id/reply` `{reply}` (vendeuse).
 */
export function registerReviewRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  store?: ReviewStore,
) {
  const auth = requireUser(verifyToken);
  const need = () => {
    if (!store) throw httpErrors.unavailable("avis non configurés");
    return store;
  };
  const id = (raw: string) => {
    if (!uuid.safeParse(raw).success) throw httpErrors.notFound("introuvable");
    return raw;
  };

  app.post("/v1/orders/:id/review", auth, async (c) => {
    const orderId = id(c.req.param("id"));
    const body = await parseBody(
      c,
      z.object({
        rating: z.number().int().min(1).max(5),
        tags: z.array(z.enum(["fresh", "well_packed", "fast", "friendly"])).max(4).default([]),
        comment: z.string().trim().max(500).nullable().optional(),
      }),
    );
    return c.json(
      await need().leave({
        userId: c.get("user").id,
        orderId,
        rating: body.rating,
        tags: body.tags,
        comment: body.comment ? body.comment : null,
      }),
      201,
    );
  });

  app.post("/v1/reviews/:id/reply", auth, async (c) => {
    const reviewId = id(c.req.param("id"));
    const body = await parseBody(c, z.object({ reply: z.string().trim().min(1).max(500) }));
    return c.json(await need().reply(c.get("user").id, reviewId, body.reply));
  });
}
