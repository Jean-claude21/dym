import type pg from "pg";
import { fromPgError } from "../lib/db.js";
import type { OrderStore, PlacedOrder } from "./ports.js";

/** `app.place_order` (rôle propriétaire de la Function, utilisatrice du jeton). */
export function pgOrderStore(pool: pg.Pool): OrderStore {
  return {
    async placeOrder(userId, idempotencyKey, request, providers) {
      try {
        const { rows } = await pool.query(
          "select app.place_order_scheduled($1, $2, $3, now(), $4) as value",
          [
            userId,
            idempotencyKey,
            {
              address_id: request.addressId,
              modes: request.modes,
              payment_method_id: request.paymentMethodId,
              substitution_allowed: request.substitutionAllowed,
              expected_total_minor: request.expectedTotalMinor,
              slot: request.slot ? { date: request.slot.date, window_id: request.slot.windowId } : null,
            },
            providers,
          ],
        );
        return rows[0].value as PlacedOrder;
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}
