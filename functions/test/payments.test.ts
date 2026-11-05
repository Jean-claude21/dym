import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "jose";
import { beforeAll, beforeEach, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { createTokenVerifier } from "../src/lib/auth.js";
import { httpErrors } from "../src/lib/errors.js";
import type { OrderRequest, OrderStore, PlacedOrder, Purchase } from "../src/orders/ports.js";
import type { PaymentStore, PaymentSummary } from "../src/payments/ports.js";
import {
  availableProviders,
  SIMULATOR_SIGNATURE_HEADER,
  simulatorProvider,
} from "../src/payments/simulator.js";

const issuer = "https://auth.test";
const user = "6f1c2a3b-0000-4000-8000-000000000001";
const payId = "e0000000-0000-4000-8000-000000000001";
const purchaseId = "f0000000-0000-4000-8000-000000000001";
const sim = "d0000000-0000-4000-8000-0000000000aa";
const secret = "secret-de-test";

let token: string;
let verifyToken: ReturnType<typeof createTokenVerifier>;

beforeAll(async () => {
  const pair = await generateKeyPair("EdDSA", { extractable: true });
  const jwk = { ...(await exportJWK(pair.publicKey)), kid: "k1", alg: "EdDSA" };
  verifyToken = createTokenVerifier({ keys: createLocalJWKSet({ keys: [jwk] }), issuer });
  token = await new SignJWT({})
    .setProtectedHeader({ alg: "EdDSA", kid: "k1" })
    .setSubject(user)
    .setIssuer(issuer)
    .setIssuedAt()
    .setExpirationTime("15m")
    .sign(pair.privateKey);
});

/** Base simulée : un achat, une tentative, l'état décidé comme en SQL. */
class FakeBase implements PaymentStore, OrderStore {
  payment = { status: "pending", checkout_url: null as string | null, amount_minor: 3600 };
  purchaseStatus = "awaiting_payment";
  events: { eventId: string; signatureValid: boolean; outcome: string | null }[] = [];
  applied = new Set<string>();
  providersSeen: string[] = [];
  initiationErrors: string[] = [];

  purchase(): Purchase {
    return {
      id: purchaseId,
      currency_code: "XOF",
      payment_status: this.purchaseStatus,
      payment: {
        id: payId,
        status: this.payment.status,
        provider_code: "simulator",
        checkout_url: this.payment.checkout_url,
        amount_minor: this.payment.amount_minor,
        reference: "PA-E00000",
      },
    };
  }

  async placeOrder(_u: string, _k: string, _r: OrderRequest, providers: string[]): Promise<PlacedOrder> {
    this.providersSeen = providers;
    if (!providers.includes("simulator")) throw httpErrors.validation({ _: "payment_unavailable" }, "payment_unavailable");
    return { replayed: false, purchase: this.purchase() };
  }

  async initiated(_id: string, _ref: string, url: string) {
    this.payment.checkout_url = url;
    return this.purchase();
  }

  async initiationFailed(_id: string, error: string) {
    this.initiationErrors.push(error);
    this.payment.status = "failed";
    this.purchaseStatus = "failed";
    return this.purchase();
  }

  async applyEvent(e: Parameters<PaymentStore["applyEvent"]>[0]) {
    this.events.push({ eventId: e.eventId, signatureValid: e.signatureValid, outcome: e.outcome });
    if (!e.signatureValid) return "rejected";
    if (this.applied.has(e.eventId) || this.payment.status !== "pending") return "duplicate";
    if (e.outcome === "succeeded" && e.amountMinor !== this.payment.amount_minor) return "ignored";
    this.applied.add(e.eventId);
    this.payment.status = e.outcome!;
    this.purchaseStatus = e.outcome === "succeeded" ? "paid" : "failed";
    return "applied";
  }

  async retry() {
    this.payment = { status: "pending", checkout_url: null, amount_minor: 3600 };
    this.purchaseStatus = "awaiting_payment";
    return { replayed: false, purchase: this.purchase() };
  }

  async switchToCash() {
    this.purchaseStatus = "cash_on_delivery";
    return this.purchase();
  }

  async summary(id: string): Promise<PaymentSummary | null> {
    return id === payId
      ? {
          id,
          providerCode: "simulator",
          status: this.payment.status,
          amountMinor: 3600,
          currencyCode: "XOF",
          minorUnits: 0,
          symbol: "F CFA",
          reference: "PA-E00000",
        }
      : null;
  }
}

let base: FakeBase;
const app = (providers = [simulatorProvider(secret)]) =>
  createApp({ verifyToken, orders: { store: base }, payments: { store: base, providers } });

const order = (a: ReturnType<typeof createApp>) =>
  a.request("http://fn.test/v1/orders", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      "Idempotency-Key": "d0000000-0000-4000-8000-000000000001",
    },
    body: JSON.stringify({ payment_method_id: sim }),
  });

beforeEach(() => {
  base = new FakeBase();
});

describe("simulateur", () => {
  it("absent en production, même avec son secret", () => {
    expect(availableProviders({ branch: "main", simulatorSecret: secret })).toHaveLength(0);
    expect(availableProviders({ branch: "staging", simulatorSecret: "" })).toHaveLength(0);
    expect(availableProviders({ simulatorSecret: secret })).toHaveLength(0);
    expect(availableProviders({ branch: "staging", simulatorSecret: secret }).map((p) => p.code)).toEqual([
      "simulator",
    ]);
  });

  it("sans fournisseur disponible : la commande en ligne est refusée", async () => {
    const res = await order(app([]));
    expect(res.status).toBe(422);
    expect(base.providersSeen).toEqual([]);
  });

  it("commande : page de paiement du simulateur, puis réussite par le webhook", async () => {
    const a = app();
    const res = await order(a);
    expect(res.status).toBe(201);
    const purchase = (await res.json()) as { payment: { checkout_url: string } };
    expect(base.providersSeen).toEqual(["simulator"]);
    expect(purchase.payment.checkout_url).toBe(`http://fn.test/v1/payments/simulator/${payId}`);

    const pageRes = await a.request(purchase.payment.checkout_url);
    expect(pageRes.status).toBe(200);
    const html = await pageRes.text();
    expect(html).toContain("3600 F CFA");
    expect(html).toContain("Paiement réussi");

    const done = await a.request(`${purchase.payment.checkout_url}/succeeded`, { method: "POST" });
    expect(done.status).toBe(200);
    expect(base.purchaseStatus).toBe("paid");
    expect(base.events.at(-1)).toEqual({
      eventId: `sim_${payId}_succeeded`,
      signatureValid: true,
      outcome: "succeeded",
    });

    // Deuxième clic : même événement, sans effet.
    await a.request(`${purchase.payment.checkout_url}/succeeded`, { method: "POST" });
    expect(base.purchaseStatus).toBe("paid");
    expect(base.applied.size).toBe(1);
  });

  it("échec choisi sur la page : achat en échec", async () => {
    const a = app();
    await order(a);
    await a.request(`http://fn.test/v1/payments/simulator/${payId}/failed`, { method: "POST" });
    expect(base.purchaseStatus).toBe("failed");
  });

  it("issue inconnue ou paiement inconnu : 404", async () => {
    const a = app();
    expect((await a.request(`http://fn.test/v1/payments/simulator/${payId}/stolen`, { method: "POST" })).status).toBe(404);
    expect((await a.request("http://fn.test/v1/payments/simulator/f0000000-0000-4000-8000-0000000000ff")).status).toBe(404);
  });

  it("sans simulateur (production) : la page n'existe pas", async () => {
    const res = await app([]).request(`http://fn.test/v1/payments/simulator/${payId}`);
    expect(res.status).toBe(404);
  });

  it("fournisseur en échec à l'initiation : commande gardée, paiement en échec", async () => {
    const broken = { ...simulatorProvider(secret), initiate: async () => Promise.reject(new Error("délai dépassé")) };
    const res = await order(app([broken]));
    expect(res.status).toBe(201);
    expect(((await res.json()) as { payment_status: string }).payment_status).toBe("failed");
    expect(base.initiationErrors).toEqual(["délai dépassé"]);
  });
});

describe("webhook", () => {
  const provider = simulatorProvider(secret);
  const raw = provider.event(payId, "succeeded", 3600, "XOF");

  it("signature invalide : journalisée, 401, aucun effet", async () => {
    const res = await app().request("http://fn.test/v1/payments/webhooks/simulator", {
      method: "POST",
      headers: { [SIMULATOR_SIGNATURE_HEADER]: "faux" },
      body: raw,
    });
    expect(res.status).toBe(401);
    expect(base.events).toHaveLength(1);
    expect(base.purchaseStatus).toBe("awaiting_payment");
  });

  it("signature valide : appliquée ; rejeu : sans effet", async () => {
    const send = () =>
      app().request("http://fn.test/v1/payments/webhooks/simulator", {
        method: "POST",
        headers: { [SIMULATOR_SIGNATURE_HEADER]: provider.sign(raw) },
        body: raw,
      });
    expect(await (await send()).json()).toEqual({ outcome: "applied" });
    expect(await (await send()).json()).toEqual({ outcome: "duplicate" });
  });

  it("fournisseur inconnu : 404", async () => {
    const res = await app().request("http://fn.test/v1/payments/webhooks/inconnu", { method: "POST", body: "{}" });
    expect(res.status).toBe(404);
  });
});

describe("réessai et cash", () => {
  const post = (path: string, headers: Record<string, string> = {}) =>
    app().request(`http://fn.test${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}`, ...headers },
      body: "{}",
    });

  it("réessai : clé obligatoire, nouvelle page de paiement", async () => {
    expect((await post(`/v1/purchases/${purchaseId}/payments`)).status).toBe(400);
    const res = await post(`/v1/purchases/${purchaseId}/payments`, {
      "Idempotency-Key": "d0000000-0000-4000-8000-000000000009",
    });
    expect(res.status).toBe(201);
    expect(((await res.json()) as { payment: { checkout_url: string } }).payment.checkout_url).toContain(payId);
  });

  it("passage au cash", async () => {
    const res = await post(`/v1/purchases/${purchaseId}/cash`);
    expect(res.status).toBe(200);
    expect(((await res.json()) as { payment_status: string }).payment_status).toBe("cash_on_delivery");
  });
});
