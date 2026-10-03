import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "jose";
import { beforeAll, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import type { DisputeStore } from "../src/disputes/routes.js";
import { createTokenVerifier } from "../src/lib/auth.js";
import { httpErrors } from "../src/lib/errors.js";

const issuer = "https://auth.test";
const user = "6f1c2a3b-0000-4000-8000-000000000001";
const order = "a1000000-0000-4000-8000-000000000001";
const dispute = "d1000000-0000-4000-8000-000000000001";

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

class FakeDisputes implements DisputeStore {
  calls: unknown[] = [];
  async open(u: string, o: string, reason: string, description: string) {
    this.calls.push({ u, o, reason, description });
    return { id: dispute, status: "open" };
  }
  async reply(u: string, d: string, body: string) {
    this.calls.push({ u, d, body });
    return { id: d, status: "open" };
  }
  async resolve(i: Parameters<DisputeStore["resolve"]>[0]) {
    this.calls.push(i);
    if (i.adminId === user) throw httpErrors.forbidden("rôle admin requis");
    return { id: i.disputeId, status: "resolved" };
  }
}

const post = (store: DisputeStore, path: string, body: unknown) =>
  createApp({ verifyToken, disputes: store }).request(`http://fn.test${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });

describe("litiges", () => {
  it("ouverture : raison de la liste, texte de 3 à 500 caractères", async () => {
    const store = new FakeDisputes();
    expect((await post(store, `/v1/orders/${order}/disputes`, { reason: "fâchée", description: "abc" })).status).toBe(422);
    expect((await post(store, `/v1/orders/${order}/disputes`, { reason: "damaged", description: "a" })).status).toBe(422);
    const ok = await post(store, `/v1/orders/${order}/disputes`, { reason: "damaged", description: " Abîmé " });
    expect(ok.status).toBe(201);
    expect(store.calls[0]).toEqual({ u: user, o: order, reason: "damaged", description: "Abîmé" });
  });

  it("message", async () => {
    const res = await post(new FakeDisputes(), `/v1/disputes/${dispute}/messages`, { body: "Merci" });
    expect(res.status).toBe(201);
  });

  it("décision : la base refuse une personne sans rôle admin (403)", async () => {
    const res = await post(new FakeDisputes(), `/v1/admin/disputes/${dispute}/resolve`, {
      resolution: "full_refund",
    });
    expect(res.status).toBe(403);
  });

  it("décision : montant positif seulement", async () => {
    const res = await post(new FakeDisputes(), `/v1/admin/disputes/${dispute}/resolve`, {
      resolution: "partial_refund",
      refund_minor: -5,
    });
    expect(res.status).toBe(422);
  });
});
