import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "jose";
import { beforeAll, describe, expect, it } from "vitest";
import type { AdminStore, RefundClaim } from "../src/admin/routes.js";
import { createApp } from "../src/app.js";
import { createTokenVerifier } from "../src/lib/auth.js";
import { httpErrors } from "../src/lib/errors.js";
import type { PaymentProvider, PaymentStore } from "../src/payments/ports.js";
import { simulatorProvider } from "../src/payments/simulator.js";

const issuer = "https://auth.test";
const admin = "6f1c2a3b-0000-4000-8000-000000000001";
const order = "a1000000-0000-4000-8000-000000000001";
const store = "b1000000-0000-4000-8000-000000000001";
const refund = "c1000000-0000-4000-8000-000000000001";

let token: string;
let verifyToken: ReturnType<typeof createTokenVerifier>;

beforeAll(async () => {
  const pair = await generateKeyPair("EdDSA", { extractable: true });
  const jwk = { ...(await exportJWK(pair.publicKey)), kid: "k1", alg: "EdDSA" };
  verifyToken = createTokenVerifier({ keys: createLocalJWKSet({ keys: [jwk] }), issuer });
  token = await new SignJWT({})
    .setProtectedHeader({ alg: "EdDSA", kid: "k1" })
    .setSubject(admin)
    .setIssuer(issuer)
    .setIssuedAt()
    .setExpirationTime("15m")
    .sign(pair.privateKey);
});

class FakeAdmin implements AdminStore {
  calls: unknown[] = [];
  results: unknown[] = [];
  provider = "simulator";
  denied = false;
  async forceStatus(a: string, o: string, to: string, expected: string, reason: string) {
    if (this.denied) throw httpErrors.forbidden("rôle admin requis");
    this.calls.push({ a, o, to, expected, reason });
    return { id: o, status: to };
  }
  async cancelOrder(a: string, o: string, expected: string, reason: string) {
    this.calls.push({ a, o, expected, reason });
    return { id: o, status: "cancelled" };
  }
  async assignCourier(a: string, o: string, name: string, phone: string) {
    this.calls.push({ a, o, name, phone });
    return { id: o };
  }
  async setStoreStatus(a: string, s: string, status: string, reason: string) {
    this.calls.push({ a, s, status, reason });
    return { id: s, status };
  }
  async claimRefund(_a: string, r: string): Promise<RefundClaim> {
    return {
      refundId: r,
      amountMinor: 300,
      currencyCode: "XOF",
      paymentId: "p1",
      providerCode: this.provider,
      providerReference: "sim_p1",
    };
  }
  async refundResult(i: Parameters<AdminStore["refundResult"]>[0]) {
    this.results.push(i);
    return { id: i.refundId, status: i.ok ? "succeeded" : "failed" };
  }
  async markCashRefund(_a: string, r: string) {
    return { id: r, status: "succeeded" };
  }
}

const post = (fake: AdminStore, path: string, body: unknown, providers: PaymentProvider[] = []) =>
  createApp({
    verifyToken,
    admin: fake,
    payments: { store: {} as PaymentStore, providers },
  }).request(`http://fn.test${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });

describe("admin des opérations", () => {
  it("statut forcé : raison obligatoire, statut connu", async () => {
    const fake = new FakeAdmin();
    const path = `/v1/admin/orders/${order}/status`;
    expect((await post(fake, path, { to: "ready", expected: "preparing", reason: "" })).status).toBe(422);
    expect((await post(fake, path, { to: "refused", expected: "preparing", reason: "Essai" })).status).toBe(422);
    const ok = await post(fake, path, { to: "ready", expected: "preparing", reason: " Vendeuse injoignable " });
    expect(ok.status).toBe(200);
    expect(fake.calls[0]).toEqual({ a: admin, o: order, to: "ready", expected: "preparing", reason: "Vendeuse injoignable" });
  });

  it("la base refuse une personne sans rôle admin (403)", async () => {
    const fake = new FakeAdmin();
    fake.denied = true;
    const res = await post(fake, `/v1/admin/orders/${order}/status`, {
      to: "ready",
      expected: "preparing",
      reason: "Essai",
    });
    expect(res.status).toBe(403);
  });

  it("annulation, livreur, boutique", async () => {
    const fake = new FakeAdmin();
    expect((await post(fake, `/v1/admin/orders/${order}/cancel`, { expected: "accepted", reason: "Fermée" })).status).toBe(200);
    expect((await post(fake, `/v1/admin/orders/${order}/courier`, { name: "Yao", phone: "abc" })).status).toBe(422);
    expect((await post(fake, `/v1/admin/orders/${order}/courier`, { name: "Yao", phone: "+228 91 00 00 00" })).status).toBe(200);
    expect((await post(fake, `/v1/admin/stores/${store}/status`, { status: "closed", reason: "Essai" })).status).toBe(422);
    expect((await post(fake, `/v1/admin/stores/${store}/status`, { status: "suspended", reason: "Non conforme" })).status).toBe(200);
    expect(fake.calls).toHaveLength(3);
  });

  it("remboursement : le simulateur rembourse", async () => {
    const fake = new FakeAdmin();
    const res = await post(fake, `/v1/admin/refunds/${refund}/execute`, {}, [simulatorProvider("s3cret")]);
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ id: refund, status: "succeeded" });
    expect(fake.results[0]).toEqual({
      adminId: admin,
      refundId: refund,
      ok: true,
      providerReference: `sim_refund_${refund}`,
      error: null,
    });
  });

  it("remboursement : fournisseur absent ou en panne, échec enregistré", async () => {
    const fake = new FakeAdmin();
    await post(fake, `/v1/admin/refunds/${refund}/execute`, {});
    const broken: PaymentProvider = {
      ...simulatorProvider("s3cret"),
      refund: async () => {
        throw new Error("timeout");
      },
    };
    await post(fake, `/v1/admin/refunds/${refund}/execute`, {}, [broken]);
    expect(fake.results.map((r) => (r as { error: string }).error)).toEqual(["provider_unavailable", "provider_error"]);
  });

  it("remboursement cash", async () => {
    const res = await post(new FakeAdmin(), `/v1/admin/refunds/${refund}/cash`, {});
    expect(res.status).toBe(200);
  });
});
