import { createHmac, timingSafeEqual } from "node:crypto";
import type { NormalizedEvent, PaymentOutcome, PaymentProvider } from "./ports.js";

export const SIMULATOR = "simulator";

/** En-tête de signature des confirmations simulées. */
export const SIMULATOR_SIGNATURE_HEADER = "x-dym-signature";

/**
 * Fournisseur de test (spec 010, hors production) : sa page de paiement est
 * servie par la Function ; chaque choix produit une confirmation signée
 * (HMAC-SHA256) envoyée au même webhook que les vrais fournisseurs.
 */
export function simulatorProvider(secret: string): PaymentProvider & {
  sign(rawBody: string): string;
  event(paymentId: string, outcome: PaymentOutcome, amountMinor: number, currencyCode: string): string;
} {
  if (!secret) throw new Error("secret du simulateur absent");
  const sign = (rawBody: string) => createHmac("sha256", secret).update(rawBody).digest("hex");
  return {
    code: SIMULATOR,
    sign,
    event: (paymentId, outcome, amountMinor, currencyCode) =>
      JSON.stringify({
        event_id: `sim_${paymentId}_${outcome}`,
        payment_id: paymentId,
        outcome,
        amount_minor: amountMinor,
        currency_code: currencyCode,
      }),
    async initiate(input) {
      return {
        providerReference: `sim_${input.paymentId}`,
        checkoutUrl: `${input.selfOrigin}/v1/payments/simulator/${input.paymentId}`,
      };
    },
    verifyWebhook(rawBody, headers) {
      const given = headers[SIMULATOR_SIGNATURE_HEADER] ?? "";
      const expected = sign(rawBody);
      return (
        given.length === expected.length &&
        timingSafeEqual(Buffer.from(given), Buffer.from(expected))
      );
    },
    normalizeEvent(rawBody): NormalizedEvent | null {
      try {
        const e = JSON.parse(rawBody) as Record<string, unknown>;
        if (typeof e.event_id !== "string" || typeof e.payment_id !== "string") return null;
        return {
          eventId: e.event_id,
          paymentId: e.payment_id,
          outcome: e.outcome as PaymentOutcome,
          amountMinor: Number(e.amount_minor),
          currencyCode: String(e.currency_code),
        };
      } catch {
        return null;
      }
    },
  };
}

/** Branches de production : le simulateur n'y existe jamais. */
const productionBranches = new Set(["main", "production"]);

/**
 * Fournisseurs en ligne disponibles dans ce déploiement. Le simulateur exige
 * son secret et une branche qui n'est pas la production (double garde).
 */
export function availableProviders(options: {
  branch?: string;
  simulatorSecret?: string;
  others?: PaymentProvider[];
}): PaymentProvider[] {
  const providers = [...(options.others ?? [])];
  const branch = options.branch ?? "";
  if (options.simulatorSecret && branch && !productionBranches.has(branch)) {
    providers.push(simulatorProvider(options.simulatorSecret));
  }
  return providers;
}
