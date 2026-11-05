import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";
import type { PaymentProvider } from "../payments/ports.js";

export type AdminJson = Record<string, unknown> & { id: string };

/** Remboursement réservé pour l'appel au fournisseur (`app.refund_claim`). */
export interface RefundClaim {
  refundId: string;
  amountMinor: number;
  currencyCode: string;
  paymentId: string;
  providerCode: string;
  providerReference: string | null;
}

/** Règles en SQL (fonctions `app.admin_*` et `app.refund_*`) ; la base vérifie le rôle. */
export interface AdminStore {
  forceStatus(adminId: string, orderId: string, to: string, expected: string, reason: string): Promise<AdminJson>;
  cancelOrder(adminId: string, orderId: string, expected: string, reason: string): Promise<AdminJson>;
  assignCourier(adminId: string, orderId: string, name: string, phone: string): Promise<AdminJson>;
  setStoreStatus(adminId: string, storeId: string, status: string, reason: string): Promise<AdminJson>;
  claimRefund(adminId: string, refundId: string): Promise<RefundClaim>;
  refundResult(input: {
    adminId: string;
    refundId: string;
    ok: boolean;
    providerReference: string | null;
    error: string | null;
  }): Promise<AdminJson>;
  markCashRefund(adminId: string, refundId: string): Promise<AdminJson>;
}

export function pgAdminStore(pool: pg.Pool): AdminStore {
  const one = async <T = AdminJson>(sql: string, params: unknown[]) => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0].value as T;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    forceStatus: (a, o, to, expected, reason) =>
      one("select app.admin_force_status($1, $2, $3, $4, $5) as value", [a, o, to, expected, reason]),
    cancelOrder: (a, o, expected, reason) =>
      one("select app.admin_cancel_order($1, $2, $3, $4) as value", [a, o, expected, reason]),
    assignCourier: (a, o, name, phone) =>
      one("select app.admin_assign_courier($1, $2, $3, $4) as value", [a, o, name, phone]),
    setStoreStatus: (a, s, status, reason) =>
      one("select app.admin_set_store_status($1, $2, $3, $4) as value", [a, s, status, reason]),
    async claimRefund(a, r) {
      const raw = await one<Record<string, unknown>>("select app.refund_claim($1, $2) as value", [a, r]);
      return {
        refundId: String(raw.refund_id),
        amountMinor: Number(raw.amount_minor),
        currencyCode: String(raw.currency_code),
        paymentId: String(raw.payment_id),
        providerCode: String(raw.provider_code),
        providerReference: (raw.provider_reference as string | null) ?? null,
      };
    },
    refundResult: (i) =>
      one("select app.refund_result($1, $2, $3, $4, $5) as value", [
        i.adminId,
        i.refundId,
        i.ok,
        i.providerReference,
        i.error,
      ]),
    markCashRefund: (a, r) => one("select app.refund_mark_cash($1, $2) as value", [a, r]),
  };
}

const uuid = z.string().uuid();
const reason = z.string().trim().min(3).max(200);

/**
 * Admin des opérations (spec 013) ; la base vérifie le rôle admin :
 * - `POST /v1/admin/orders/:id/status` `{to, expected, reason}` ;
 * - `POST /v1/admin/orders/:id/cancel` `{expected, reason}` ;
 * - `POST /v1/admin/orders/:id/courier` `{name, phone}` ;
 * - `POST /v1/admin/stores/:id/status` `{status, reason}` ;
 * - `POST /v1/admin/refunds/:id/execute` : appel au fournisseur du paiement ;
 * - `POST /v1/admin/refunds/:id/cash` : remis en main propre.
 */
export function registerAdminRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  store?: AdminStore,
  providers: PaymentProvider[] = [],
) {
  const auth = requireUser(verifyToken);
  const need = () => {
    if (!store) throw httpErrors.unavailable("admin non configuré");
    return store;
  };
  const id = (raw: string) => {
    if (!uuid.safeParse(raw).success) throw httpErrors.notFound("introuvable");
    return raw;
  };

  app.post("/v1/admin/orders/:id/status", auth, async (c) => {
    const orderId = id(c.req.param("id"));
    const body = await parseBody(
      c,
      z.object({
        to: z.enum(["pending", "accepted", "preparing", "ready", "out_for_delivery", "delivered"]),
        expected: z.string().min(1).max(40),
        reason,
      }),
    );
    return c.json(await need().forceStatus(c.get("user").id, orderId, body.to, body.expected, body.reason));
  });

  app.post("/v1/admin/orders/:id/cancel", auth, async (c) => {
    const orderId = id(c.req.param("id"));
    const body = await parseBody(c, z.object({ expected: z.string().min(1).max(40), reason }));
    return c.json(await need().cancelOrder(c.get("user").id, orderId, body.expected, body.reason));
  });

  app.post("/v1/admin/orders/:id/courier", auth, async (c) => {
    const orderId = id(c.req.param("id"));
    const body = await parseBody(
      c,
      z.object({
        name: z.string().trim().min(2).max(60),
        phone: z.string().trim().regex(/^\+?[0-9 ]{6,20}$/),
      }),
    );
    return c.json(await need().assignCourier(c.get("user").id, orderId, body.name, body.phone));
  });

  app.post("/v1/admin/stores/:id/status", auth, async (c) => {
    const storeId = id(c.req.param("id"));
    const body = await parseBody(c, z.object({ status: z.enum(["active", "suspended"]), reason }));
    return c.json(await need().setStoreStatus(c.get("user").id, storeId, body.status, body.reason));
  });

  app.post("/v1/admin/refunds/:id/execute", auth, async (c) => {
    const refundId = id(c.req.param("id"));
    const adminId = c.get("user").id;
    const s = need();
    const claim = await s.claimRefund(adminId, refundId);
    const provider = providers.find((p) => p.code === claim.providerCode);
    let outcome: { ok: boolean; providerReference?: string; error?: string };
    if (!provider?.refund) {
      outcome = { ok: false, error: "provider_unavailable" };
    } else {
      try {
        outcome = await provider.refund({
          refundId: claim.refundId,
          paymentId: claim.paymentId,
          providerReference: claim.providerReference,
          amountMinor: claim.amountMinor,
          currencyCode: claim.currencyCode,
        });
      } catch (error) {
        console.error("[refund] fournisseur en échec", error);
        outcome = { ok: false, error: "provider_error" };
      }
    }
    return c.json(
      await s.refundResult({
        adminId,
        refundId,
        ok: outcome.ok,
        providerReference: outcome.providerReference ?? null,
        error: outcome.ok ? null : (outcome.error ?? "provider_refused"),
      }),
    );
  });

  app.post("/v1/admin/refunds/:id/cash", auth, async (c) => {
    const refundId = id(c.req.param("id"));
    return c.json(await need().markCashRefund(c.get("user").id, refundId));
  });
}
