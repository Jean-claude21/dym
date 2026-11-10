import type { Hono } from "hono";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";
import { initiatePending, type PaymentDeps, selfOrigin } from "../payments/routes.js";
import type { OrderStore } from "./ports.js";

export interface OrderDeps {
  store: OrderStore;
}

const uuid = z.string().uuid();

const orderBody = z.object({
  address_id: uuid.nullable().optional(),
  modes: z.record(uuid, z.enum(["delivery", "pickup"])).default({}),
  payment_method_id: uuid,
  substitution_allowed: z.boolean().default(true),
  expected_total_minor: z.number().int().nonnegative().nullable().optional(),
  // Créneau (spec 033) : validé en base, dans la transaction de création.
  slot: z
    .object({ date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/), window_id: uuid })
    .nullable()
    .optional(),
});

/**
 * Commandes (spec 009) :
 * - `POST /v1/orders` (en-tête `Idempotency-Key`) : achat créé à partir du
 *   panier en base ; `201`, ou `200` et le même achat pour une clé déjà vue.
 *   Moyen en ligne : la tentative est initiée chez son fournisseur (spec 010).
 */
export function registerOrderRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: OrderDeps,
  payments?: PaymentDeps,
) {
  const auth = requireUser(verifyToken);

  app.post("/v1/orders", auth, async (c) => {
    const key = c.req.header("Idempotency-Key");
    if (!key || !uuid.safeParse(key).success) {
      throw httpErrors.badRequest("Idempotency-Key (uuid) obligatoire");
    }
    const body = await parseBody(c, orderBody);
    if (!deps) throw httpErrors.unavailable("commandes non configurées");
    const placed = await deps.store.placeOrder(
      c.get("user").id,
      key,
      {
        addressId: body.address_id ?? null,
        modes: body.modes,
        paymentMethodId: body.payment_method_id,
        substitutionAllowed: body.substitution_allowed,
        expectedTotalMinor: body.expected_total_minor ?? null,
        slot: body.slot ? { date: body.slot.date, windowId: body.slot.window_id } : null,
      },
      payments?.providers.map((p) => p.code) ?? [],
    );
    // Moyen en ligne : page de paiement du fournisseur (aussi au rejeu, si
    // l'initiation n'avait pas abouti).
    const purchase = payments
      ? await initiatePending(payments, placed.purchase, selfOrigin(c))
      : placed.purchase;
    return c.json(purchase, placed.replayed ? 200 : 201);
  });
}
