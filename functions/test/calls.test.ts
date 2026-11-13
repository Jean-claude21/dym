import { createLocalJWKSet, exportJWK, generateKeyPair, jwtVerify, SignJWT } from "jose";
import { beforeAll, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { createTokenVerifier } from "../src/lib/auth.js";
import { httpErrors } from "../src/lib/errors.js";
import type { CallMediaAccess, CallMediaStore } from "../src/messaging/calls.js";

const issuer = "https://auth.test";
const user = "6f1c2a3b-0000-4000-8000-000000000001";
const call = "c2000000-0000-4000-8000-000000000001";
const livekit = { url: "wss://dym.livekit.test", apiKey: "APIkey", apiSecret: "secret-de-test-assez-long-pour-hs256" };

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

class FakeStore implements CallMediaStore {
  seen: unknown[] = [];
  refuse = false;
  async access(userId: string, callId: string): Promise<CallMediaAccess> {
    this.seen.push({ userId, callId });
    if (this.refuse) throw httpErrors.validation({ _: "call_not_active" }, "call_not_active");
    return { room: `call-${callId}`, identity: userId, role: "client", name: "Awa", video: true };
  }
}

const post = (app: ReturnType<typeof createApp>, path: string, auth = true) =>
  app.request(path, { method: "POST", headers: auth ? { Authorization: `Bearer ${token}` } : {} });

describe("POST /v1/calls/:id/media", () => {
  it("émet un jeton LiveKit limité à la salle de l'appel", async () => {
    const store = new FakeStore();
    const app = createApp({ verifyToken, calls: { store, livekit } });
    const res = await post(app, `/v1/calls/${call}/media`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { url: string; token: string; room: string; video: boolean };
    expect(body).toMatchObject({ url: livekit.url, room: `call-${call}`, video: true });
    const { payload } = await jwtVerify(body.token, new TextEncoder().encode(livekit.apiSecret));
    expect(payload.iss).toBe(livekit.apiKey);
    expect(payload.sub).toBe(user);
    expect(payload.video).toEqual({
      room: `call-${call}`,
      roomJoin: true,
      canPublish: true,
      canSubscribe: true,
      canPublishData: false,
    });
    expect((payload.exp ?? 0) - (payload.iat ?? 0)).toBe(600);
    expect(store.seen).toEqual([{ userId: user, callId: call }]);
  });

  it("refus de la base propagé, aucun jeton", async () => {
    const store = new FakeStore();
    store.refuse = true;
    const app = createApp({ verifyToken, calls: { store, livekit } });
    const res = await post(app, `/v1/calls/${call}/media`);
    expect(res.status).toBe(422);
    expect(JSON.stringify(await res.json())).not.toContain("token");
  });

  it("sans projet LiveKit : 503, sans jeton de session : 401, identifiant invalide : 404", async () => {
    const store = new FakeStore();
    expect((await post(createApp({ verifyToken, calls: { store } }), `/v1/calls/${call}/media`)).status).toBe(503);
    const app = createApp({ verifyToken, calls: { store, livekit } });
    expect((await post(app, `/v1/calls/${call}/media`, false)).status).toBe(401);
    expect((await post(app, "/v1/calls/pas-un-uuid/media")).status).toBe(404);
    expect(store.seen).toEqual([]);
  });
});
