import { createHmac, timingSafeEqual } from "node:crypto";
import type { NormalizedEvent, PaymentOutcome, PaymentProvider } from "./ports.js";

export const MONEROO = "moneroo";
export const MONEROO_SIGNATURE_HEADER = "x-moneroo-signature";

export interface MonerooConfig {
  secretKey: string;
  /** Secret de signature des webhooks (tableau de bord Moneroo → Développeurs → Webhooks). */
  webhookSecret: string;
  apiUrl?: string;
  fetchImpl?: typeof fetch;
}

/** Décimales ISO 4217 d'une devise (XOF : 0, NGN : 2). */
export function currencyDecimals(code: string): number {
  try {
    return new Intl.NumberFormat("en", { style: "currency", currency: code }).resolvedOptions()
      .maximumFractionDigits ?? 0;
  } catch {
    return 0;
  }
}

/** Montant Moneroo (unités de la devise, entier) depuis des unités mineures DYM. */
export function monerooAmount(amountMinor: number, currencyCode: string): number {
  const amount = amountMinor / 10 ** currencyDecimals(currencyCode);
  if (!Number.isInteger(amount)) throw new Error("montant non entier pour Moneroo");
  return amount;
}

const outcomeOf = (status: unknown): PaymentOutcome | null =>
  status === "success" ? "succeeded" : status === "failed" ? "failed" : status === "cancelled" ? "cancelled" : null;

/**
 * Moneroo (spec 088) : page de paiement hébergée par Moneroo, confirmation par
 * webhook signé (HMAC-SHA256 du corps brut). L'avis du webhook est incomplet :
 * le statut, le montant et la référence DYM sont relus chez Moneroo
 * (`/payments/:id/verify`) avant d'être appliqués. Bac à sable ou réel selon
 * la clé. Seuls l'email et le prénom de la cliente sont transmis (exigés).
 */
export function monerooProvider(config: MonerooConfig): PaymentProvider & {
  resolveEvent(rawBody: string): Promise<NormalizedEvent | null>;
} {
  if (!config.secretKey) throw new Error("clé Moneroo absente");
  const api = (config.apiUrl ?? "https://api.moneroo.io").replace(/\/$/, "");
  const send = config.fetchImpl ?? fetch;
  const headers = {
    Authorization: `Bearer ${config.secretKey}`,
    "Content-Type": "application/json",
    Accept: "application/json",
  };

  return {
    code: MONEROO,
    needsCustomer: true,
    async initiate(input) {
      if (!input.customer?.email || !input.customer.firstName) throw new Error("cliente absente pour Moneroo");
      const res = await send(`${api}/v1/payments/initialize`, {
        method: "POST",
        headers,
        body: JSON.stringify({
          amount: monerooAmount(input.amountMinor, input.currencyCode),
          currency: input.currencyCode,
          description: `DYM ${input.reference}`,
          return_url: `${input.selfOrigin}/v1/payments/return/${input.paymentId}`,
          metadata: { payment_id: input.paymentId, reference: input.reference },
          // Exigé par Moneroo ; DYM ne demande pas de nom de famille.
          customer: {
            email: input.customer.email,
            first_name: input.customer.firstName,
            last_name: input.customer.firstName,
          },
        }),
      });
      const body = (await res.json().catch(() => ({}))) as {
        data?: { id?: string; checkout_url?: string };
        message?: string;
      };
      if (!res.ok || !body.data?.id || !body.data.checkout_url) {
        throw new Error(`Moneroo ${res.status} : ${String(body.message ?? "réponse invalide").slice(0, 200)}`);
      }
      return { providerReference: body.data.id, checkoutUrl: body.data.checkout_url };
    },
    verifyWebhook(rawBody, hdrs) {
      if (!config.webhookSecret) return false;
      const given = hdrs[MONEROO_SIGNATURE_HEADER] ?? "";
      const expected = createHmac("sha256", config.webhookSecret).update(rawBody).digest("hex");
      return given.length === expected.length && timingSafeEqual(Buffer.from(given), Buffer.from(expected));
    },
    // Avis incomplet : identifiant de l'événement seulement ; le reste vient de `resolveEvent`.
    normalizeEvent(rawBody): NormalizedEvent | null {
      try {
        const e = JSON.parse(rawBody) as { event?: string; data?: { id?: string } };
        if (!e.data?.id || !e.event) return null;
        return { eventId: `${e.event}:${e.data.id}`, paymentId: "", outcome: "failed", amountMinor: 0, currencyCode: "" };
      } catch {
        return null;
      }
    },
    async resolveEvent(rawBody) {
      let e: { event?: string; data?: { id?: string } };
      try {
        e = JSON.parse(rawBody);
      } catch {
        return null;
      }
      const id = e.data?.id;
      if (!id || !e.event) return null;
      const res = await send(`${api}/v1/payments/${encodeURIComponent(id)}/verify`, { headers });
      if (!res.ok) throw new Error(`Moneroo verify ${res.status}`);
      const body = (await res.json()) as {
        data?: { status?: string; amount?: number; currency?: { code?: string } | string; metadata?: Record<string, string> };
      };
      const d = body.data ?? {};
      const outcome = outcomeOf(d.status);
      const paymentId = d.metadata?.payment_id;
      const currencyCode = typeof d.currency === "string" ? d.currency : (d.currency?.code ?? "");
      if (!outcome || !paymentId || !currencyCode) return null;
      return {
        eventId: `${e.event}:${id}`,
        paymentId,
        outcome,
        amountMinor: Math.round(Number(d.amount ?? 0) * 10 ** currencyDecimals(currencyCode)),
        currencyCode,
      };
    },
  };
}
