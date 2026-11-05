import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "jose";
import { beforeAll, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { createTokenVerifier } from "../src/lib/auth.js";
import type { MediaSigner, MessagingStore } from "../src/messaging/routes.js";

const issuer = "https://auth.test";
const user = "6f1c2a3b-0000-4000-8000-000000000001";
const store = "b1000000-0000-4000-8000-000000000001";
const conv = "c1000000-0000-4000-8000-000000000001";
const msg = "d1000000-0000-4000-8000-000000000001";
const key = "e1000000-0000-4000-8000-000000000001";

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

class FakeStore implements MessagingStore {
  calls: unknown[] = [];
  allowed = true;
  async start(u: string, s: string) {
    this.calls.push({ u, s });
    return { id: conv };
  }
  async send(i: Parameters<MessagingStore["send"]>[0]) {
    this.calls.push(i);
    return { id: msg };
  }
  async uploadAllowed() {
    return this.allowed;
  }
  async mediaKeys(_u: string, ids: string[]): Promise<Record<string, string>> {
    const keys: Record<string, string> = {};
    if (ids.includes(msg)) keys[msg] = `chats/${conv}/x.jpg`;
    return keys;
  }
}

const signer: MediaSigner = {
  presignPut: async (k) => `https://s3.test/put/${k}`,
  presignGet: async (k) => `https://s3.test/get/${k}`,
};

const post = (fake: MessagingStore, path: string, body: unknown, headers: Record<string, string> = {}) =>
  createApp({ verifyToken, messaging: { store: fake, signer } }).request(`http://fn.test${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}`, ...headers },
    body: JSON.stringify(body),
  });

describe("messagerie", () => {
  it("ouvrir une conversation", async () => {
    const fake = new FakeStore();
    expect((await post(fake, "/v1/conversations", { store_id: "x" })).status).toBe(422);
    const res = await post(fake, "/v1/conversations", { store_id: store });
    expect(res.status).toBe(201);
    expect(fake.calls[0]).toEqual({ u: user, s: store });
  });

  it("envoyer : clé d'idempotence obligatoire, type connu", async () => {
    const fake = new FakeStore();
    const path = `/v1/conversations/${conv}/messages`;
    expect((await post(fake, path, { kind: "text", body: "Bonjour" })).status).toBe(400);
    expect((await post(fake, path, { kind: "video" }, { "Idempotency-Key": key })).status).toBe(422);
    const res = await post(fake, path, { kind: "text", body: "Bonjour" }, { "Idempotency-Key": key });
    expect(res.status).toBe(201);
    expect(fake.calls[0]).toMatchObject({ userId: user, conversationId: conv, kind: "text", idempotencyKey: key });
  });

  it("envoi d'image : dans l'espace de la conversation, participante seulement", async () => {
    const fake = new FakeStore();
    const res = await post(fake, `/v1/conversations/${conv}/media-uploads`, { content_type: "image/jpeg" });
    const json = (await res.json()) as { object_key: string; upload_url: string };
    expect(json.object_key).toMatch(new RegExp(`^chats/${conv}/[0-9a-f-]{36}\\.jpg$`));
    fake.allowed = false;
    expect(
      (await post(fake, `/v1/conversations/${conv}/media-uploads`, { content_type: "image/jpeg" })).status,
    ).toBe(404);
  });

  it("liens de lecture : seulement les images visibles", async () => {
    const res = await post(new FakeStore(), "/v1/chat-media/urls", { message_ids: [msg, key] });
    expect(await res.json()).toEqual({
      urls: { [msg]: `https://s3.test/get/chats/${conv}/x.jpg` },
      expires_in: 300,
    });
  });
});
