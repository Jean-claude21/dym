import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";

export type DisputeJson = Record<string, unknown> & { id: string; status: string };

/** Règles en SQL (`app.open_dispute`, `app.dispute_reply`, `app.resolve_dispute`). */
export interface DisputeStore {
  open(userId: string, orderId: string, reason: string, description: string): Promise<DisputeJson>;
  reply(userId: string, disputeId: string, body: string): Promise<DisputeJson>;
  resolve(input: {
    adminId: string;
    disputeId: string;
    resolution: string;
    refundMinor: number | null;
    internalNote: string | null;
    warnVendor: boolean;
  }): Promise<DisputeJson>;
}

export function pgDisputeStore(pool: pg.Pool): DisputeStore {
  const one = async (sql: string, params: unknown[]) => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0].value as DisputeJson;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    open: (u, o, r, d) => one("select app.open_dispute($1, $2, $3, $4) as value", [u, o, r, d]),
    reply: (u, d, b) => one("select app.dispute_reply($1, $2, $3) as value", [u, d, b]),
    resolve: (i) =>
      one("select app.resolve_dispute($1, $2, $3, $4, $5, $6) as value", [
        i.adminId,
        i.disputeId,
        i.resolution,
        i.refundMinor,
        i.internalNote,
        i.warnVendor,
      ]),
  };
}

const uuid = z.string().uuid();

/**
 * Litiges (spec 012) :
 * - `POST /v1/orders/:id/disputes` `{reason, description}` (cliente) ;
 * - `POST /v1/disputes/:id/messages` `{body}` (cliente, vendeuse, équipe) ;
 * - `POST /v1/admin/disputes/:id/resolve` (équipe : la base vérifie le rôle).
 */
export function registerDisputeRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  store?: DisputeStore,
) {
  const auth = requireUser(verifyToken);
  const need = () => {
    if (!store) throw httpErrors.unavailable("litiges non configurés");
    return store;
  };
  const id = (raw: string) => {
    if (!uuid.safeParse(raw).success) throw httpErrors.notFound("introuvable");
    return raw;
  };

  app.post("/v1/orders/:id/disputes", auth, async (c) => {
    const orderId = id(c.req.param("id"));
    const body = await parseBody(
      c,
      z.object({
        reason: z.enum(["missing_item", "wrong_item", "damaged", "quality", "not_delivered", "other"]),
        description: z.string().trim().min(3).max(500),
      }),
    );
    return c.json(await need().open(c.get("user").id, orderId, body.reason, body.description), 201);
  });

  app.post("/v1/disputes/:id/messages", auth, async (c) => {
    const disputeId = id(c.req.param("id"));
    const body = await parseBody(c, z.object({ body: z.string().trim().min(1).max(1000) }));
    return c.json(await need().reply(c.get("user").id, disputeId, body.body), 201);
  });

  app.post("/v1/admin/disputes/:id/resolve", auth, async (c) => {
    const disputeId = id(c.req.param("id"));
    const body = await parseBody(
      c,
      z.object({
        resolution: z.enum(["no_action", "partial_refund", "full_refund"]),
        refund_minor: z.number().int().positive().nullable().optional(),
        internal_note: z.string().max(1000).nullable().optional(),
        warn_vendor: z.boolean().default(false),
      }),
    );
    return c.json(
      await need().resolve({
        adminId: c.get("user").id,
        disputeId,
        resolution: body.resolution,
        refundMinor: body.refund_minor ?? null,
        internalNote: body.internal_note ?? null,
        warnVendor: body.warn_vendor,
      }),
    );
  });
}
