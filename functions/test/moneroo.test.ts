import { createHmac } from "node:crypto";
import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import type { TokenVerifier } from "../src/lib/auth.js";
import { currencyDecimals, MONEROO_SIGNATURE_HEADER, monerooAmount, monerooProvider } from "../src/payments/moneroo.js";
import type { PaymentStore } from "../src/payments/ports.js";

const payId = "aaaaaaaa-0000-4000-8000-000000000001";
const webhookSecret = "whsec_test";

/** Moneroo factice : enregistre les appels, répond comme l'API. */
function fakeMoneroo(status = "success", amount = 3600) {
  const calls: { url: string; body: unknown; auth: string | null }[] = [];
  const fetchImpl = (async (url: string | URL, init?: RequestInit) => {
    const u = String(url);
    calls.push({
      url: u,
      body: init?.body ? JSON.parse(String(init.body)) : null,
      auth: new Headers(init?.headers).get("Authorization"),
    });
    if (u.endsWith("/v1/payments/initialize")) {
      return new Response(JSON.stringify({ message: "ok", data: { id: "mo_123", checkout_url: "https://checkout.moneroo.io/mo_123" } }), { status: 201 });
    }
    if (u.endsWith("/v1/payments/mo_123/verify")) {
      return new Response(JSON.stringify({
        data: { id: "mo_123", status, amount, currency: { code: "XOF" }, metadata: { payment_id: payId } },
      }), { status: 200 });
    }
    return new Response("{}", { status: 404 });
  }) as typeof fetch;
  return { calls, fetchImpl };
}

const sign = (raw: string) => createHmac("sha256", webhookSecret).update(raw).digest("hex");

describe("Moneroo", () => {
  it("montants : unités de la devise, jamais de fraction", () => {
    expect(currencyDecimals("XOF")).toBe(0);
    expect(currencyDecimals("NGN")).toBe(2);
    expect(monerooAmount(3600, "XOF")).toBe(3600);
    expect(monerooAmount(150000, "NGN")).toBe(1500);
    expect(() => monerooAmount(150050, "NGN")).toThrow();
  });

  it("initialisation : page Moneroo, référence DYM en métadonnées, email et prénom seulement", async () => {
    const mo = fakeMoneroo();
    const provider = monerooProvider({ secretKey: "sk_test", webhookSecret, fetchImpl: mo.fetchImpl });
    const started = await provider.initiate({
      paymentId: payId, amountMinor: 3600, currencyCode: "XOF", reference: "PA-ABC123", selfOrigin: "https://fn.test",
      customer: { email: "awa@example.com", firstName: "Awa" },
    });
    expect(started).toEqual({ providerReference: "mo_123", checkoutUrl: "https://checkout.moneroo.io/mo_123" });
    expect(mo.calls[0]!.auth).toBe("Bearer sk_test");
    expect(mo.calls[0]!.body).toEqual({
      amount: 3600,
      currency: "XOF",
      description: "DYM PA-ABC123",
      return_url: `https://fn.test/v1/payments/return/${payId}`,
      metadata: { payment_id: payId, reference: "PA-ABC123" },
      customer: { email: "awa@example.com", first_name: "Awa", last_name: "Awa" },
    });
    await expect(provider.initiate({
      paymentId: payId, amountMinor: 3600, currencyCode: "XOF", reference: "PA-ABC123", selfOrigin: "https://fn.test",
    })).rejects.toThrow(/cliente absente/);
  });

  it("webhook : signature, statut relu chez Moneroo", async () => {
    const mo = fakeMoneroo();
    const provider = monerooProvider({ secretKey: "sk_test", webhookSecret, fetchImpl: mo.fetchImpl });
    const raw = JSON.stringify({ event: "payment.success", data: { id: "mo_123" } });
    expect(provider.verifyWebhook(raw, { [MONEROO_SIGNATURE_HEADER]: sign(raw) })).toBe(true);
    expect(provider.verifyWebhook(raw, { [MONEROO_SIGNATURE_HEADER]: "faux" })).toBe(false);
    expect(await provider.resolveEvent(raw)).toEqual({
      eventId: "payment.success:mo_123", paymentId: payId, outcome: "succeeded", amountMinor: 3600, currencyCode: "XOF",
    });
  });

  it("route : appliqué une fois ; paiement encore en cours : rien d'appliqué", async () => {
    const applied: { outcome: string | null; signatureValid: boolean; paymentId: string | null }[] = [];
    const store = {
      async applyEvent(e: Parameters<PaymentStore["applyEvent"]>[0]) {
        applied.push({ outcome: e.outcome, signatureValid: e.signatureValid, paymentId: e.paymentId });
        return e.outcome ? "applied" : "ignored";
      },
    } as unknown as PaymentStore;
    const verifyToken: TokenVerifier = async () => {
      throw new Error("sans session");
    };
    const send = async (status: string) => {
      const mo = fakeMoneroo(status);
      const app = createApp({
        verifyToken,
        payments: { store, providers: [monerooProvider({ secretKey: "sk_test", webhookSecret, fetchImpl: mo.fetchImpl })] },
      });
      const raw = JSON.stringify({ event: `payment.${status}`, data: { id: "mo_123" } });
      return app.request("http://fn.test/v1/payments/webhooks/moneroo", {
        method: "POST",
        headers: { [MONEROO_SIGNATURE_HEADER]: sign(raw), "Content-Type": "application/json" },
        body: raw,
      });
    };
    expect((await send("success")).status).toBe(200);
    expect((await send("pending")).status).toBe(200);
    expect(applied).toEqual([
      { outcome: "succeeded", signatureValid: true, paymentId: payId },
      { outcome: null, signatureValid: true, paymentId: null },
    ]);
  });

  it("page de retour servie", async () => {
    const app = createApp({ verifyToken: (async () => { throw new Error(); }) as TokenVerifier, payments: { store: {} as PaymentStore, providers: [] } });
    const res = await app.request(`http://fn.test/v1/payments/return/${payId}`);
    expect(res.status).toBe(200);
    expect(await res.text()).toContain("Retourne dans l'app DYM");
  });
});
