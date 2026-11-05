import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "jose";
import { beforeAll, beforeEach, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { createTokenVerifier } from "../src/lib/auth.js";
import { httpErrors } from "../src/lib/errors.js";
import type { OrderRequest, OrderStore, PlacedOrder } from "../src/orders/ports.js";

const issuer = "https://auth.test";
const user = "6f1c2a3b-0000-4000-8000-000000000001";
const key = "d0000000-0000-4000-8000-000000000001";
const cash = "c0000000-0000-4000-8000-000000000001";
const store = "9e2b5484-7bdd-4c08-a7b9-0a750f9de59b";

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

class FakeOrders implements OrderStore {
  calls: { userId: string; key: string; request: OrderRequest }[] = [];
  seen = new Set<string>();
  refusal?: string;

  async placeOrder(userId: string, idempotencyKey: string, request: OrderRequest): Promise<PlacedOrder> {
    if (this.refusal) throw httpErrors.validation({ _: this.refusal }, this.refusal);
    this.calls.push({ userId, key: idempotencyKey, request });
    const replayed = this.seen.has(idempotencyKey);
    this.seen.add(idempotencyKey);
    return { replayed, purchase: { id: "p1", total_minor: 3600 } };
  }
}

let orders: FakeOrders;

const post = (body: unknown, headers: Record<string, string> = {}) =>
  createApp({ verifyToken, orders: { store: orders } }).request("http://fn.test/v1/orders", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      "Idempotency-Key": key,
      ...headers,
    },
    body: JSON.stringify(body),
  });

beforeEach(() => {
  orders = new FakeOrders();
});

describe("POST /v1/orders", () => {
  it("sans jeton : 401", async () => {
    const res = await post({ payment_method_id: cash }, { Authorization: "" });
    expect(res.status).toBe(401);
  });

  it("sans clé d'idempotence : 400", async () => {
    const res = await post({ payment_method_id: cash }, { "Idempotency-Key": "" });
    expect(res.status).toBe(400);
    expect(orders.calls).toHaveLength(0);
  });

  it("corps invalide : 422 avec le champ", async () => {
    const res = await post({ payment_method_id: "x", modes: { [store]: "drone" } });
    expect(res.status).toBe(422);
    const body = (await res.json()) as { error: { fields: Record<string, string> } };
    expect(Object.keys(body.error.fields)).toContain("payment_method_id");
  });

  it("création : 201, utilisatrice du jeton, aucun montant transmis hors garde", async () => {
    const res = await post({
      address_id: null,
      modes: { [store]: "pickup" },
      payment_method_id: cash,
      substitution_allowed: false,
      expected_total_minor: 3600,
      total_minor: 1,
    });
    expect(res.status).toBe(201);
    expect(await res.json()).toEqual({ id: "p1", total_minor: 3600 });
    expect(orders.calls[0]).toEqual({
      userId: user,
      key,
      request: {
        addressId: null,
        modes: { [store]: "pickup" },
        paymentMethodId: cash,
        substitutionAllowed: false,
        expectedTotalMinor: 3600,
      },
    });
  });

  it("rejeu de la même clé : 200 et le même achat", async () => {
    await post({ payment_method_id: cash });
    const res = await post({ payment_method_id: cash });
    expect(res.status).toBe(200);
    expect(((await res.json()) as { id: string }).id).toBe("p1");
  });

  it("refus de la base : 422 avec son code", async () => {
    orders.refusal = "cart_blocked";
    const res = await post({ payment_method_id: cash });
    expect(res.status).toBe(422);
    expect(((await res.json()) as { error: { message: string } }).error.message).toBe("cart_blocked");
  });

  it("non configuré : 503", async () => {
    const res = await createApp({ verifyToken }).request("http://fn.test/v1/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}`, "Idempotency-Key": key },
      body: JSON.stringify({ payment_method_id: cash }),
    });
    expect(res.status).toBe(503);
  });
});
