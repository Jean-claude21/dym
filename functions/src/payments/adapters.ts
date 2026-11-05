import type pg from "pg";
import { fromPgError } from "../lib/db.js";
import type { Purchase } from "../orders/ports.js";
import type { PaymentStore, PaymentSummary } from "./ports.js";

/** Fonctions SQL `app.*` des paiements (rôle propriétaire de la Function). */
export function pgPaymentStore(pool: pg.Pool): PaymentStore {
  const one = async <T>(sql: string, params: unknown[]): Promise<T> => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0].value as T;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    initiated: (paymentId, reference, url) =>
      one<Purchase>("select app.payment_initiated($1, $2, $3) as value", [paymentId, reference, url]),
    initiationFailed: (paymentId, error) =>
      one<Purchase>("select app.payment_initiation_failed($1, $2) as value", [paymentId, error]),
    applyEvent: (e) =>
      one<string>("select app.apply_payment_event($1, $2, $3, $4, $5, $6, $7, $8) as value", [
        e.provider,
        e.eventId,
        e.payload ?? {},
        e.signatureValid,
        e.paymentId,
        e.outcome,
        e.amountMinor,
        e.currencyCode,
      ]),
    async retry(input) {
      const raw = await one<{ replayed: boolean; purchase: Purchase }>(
        "select app.retry_payment($1, $2, $3, $4, $5) as value",
        [input.userId, input.purchaseId, input.idempotencyKey, input.paymentMethodId, input.providers],
      );
      return { replayed: raw.replayed, purchase: raw.purchase };
    },
    switchToCash: (userId, purchaseId) =>
      one<Purchase>("select app.switch_to_cash($1, $2) as value", [userId, purchaseId]),
    async summary(paymentId) {
      try {
        const { rows } = await pool.query(
          `select p.id, p.provider_code, p.status, p.amount_minor, p.currency_code,
                  c.minor_units, c.symbol, app.payment_reference(p.id) as reference
           from public.payments p join public.currencies c on c.code = p.currency_code
           where p.id = $1`,
          [paymentId],
        );
        const r = rows[0];
        if (!r) return null;
        return {
          id: r.id,
          providerCode: r.provider_code,
          status: r.status,
          amountMinor: Number(r.amount_minor),
          currencyCode: r.currency_code,
          minorUnits: Number(r.minor_units),
          symbol: r.symbol,
          reference: r.reference,
        } satisfies PaymentSummary;
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}
