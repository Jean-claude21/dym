import { createLocalJWKSet, exportJWK, exportPKCS8, generateKeyPair, SignJWT } from "jose";
import { beforeAll, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { createTokenVerifier } from "../src/lib/auth.js";
import { httpErrors } from "../src/lib/errors.js";
import {
  type ClaimedPush,
  dispatchPushes,
  fcmPushSender,
  noPushSender,
  type PushMessage,
  type PushQueue,
  type PushSender,
} from "../src/notifications/push.js";
import type { LifecycleStore } from "../src/orders/lifecycle.js";

const issuer = "https://auth.test";
const user = "6f1c2a3b-0000-4000-8000-000000000001";
const order = "a1000000-0000-4000-8000-000000000001";

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

class FakeLifecycle implements LifecycleStore {
  calls: unknown[] = [];
  status = "pending";
  async transition(i: Parameters<LifecycleStore["transition"]>[0]) {
    this.calls.push(i);
    if (i.expected !== this.status) throw httpErrors.validation({ _: "status_changed" }, "status_changed");
    this.status = i.to;
    return { id: i.orderId, status: i.to };
  }
  async confirmCash(_u: string, id: string) {
    return { id, status: this.status, cash_collected_at: "2026-10-05T10:00:00Z" };
  }
}

class FakeQueue implements PushQueue {
  constructor(public items: ClaimedPush[]) {}
  results: Record<string, string[]> = {};
  dropped: string[] = [];
  claims = 0;
  async claim() {
    this.claims += 1;
    const out = this.items;
    this.items = [];
    return out;
  }
  async result(ids: string[], outcome: string) {
    this.results[outcome] = [...(this.results[outcome] ?? []), ...ids];
  }
  async dropTokens(tokens: string[]) {
    this.dropped.push(...tokens);
  }
}

const push = (id: string, extra: Partial<ClaimedPush> = {}): ClaimedPush => ({
  id,
  kind: "order_accepted",
  category: "orders",
  order_id: order,
  purchase_id: null,
  allowed: true,
  tokens: ["tok-1"],
  text: { title: "Commande acceptée", body: "Esi a accepté ta commande." },
  ...extra,
});

describe("transitions", () => {
  const post = (a: ReturnType<typeof createApp>, path: string, body: unknown, auth = true) =>
    a.request(`http://fn.test${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...(auth ? { Authorization: `Bearer ${token}` } : {}) },
      body: JSON.stringify(body),
    });

  it("sans jeton : 401 ; statut inconnu : 422", async () => {
    const a = createApp({ verifyToken, lifecycle: new FakeLifecycle() });
    expect((await post(a, `/v1/orders/${order}/transitions`, { to: "accepted", expected: "pending" }, false)).status).toBe(401);
    expect((await post(a, `/v1/orders/${order}/transitions`, { to: "teleported", expected: "pending" })).status).toBe(422);
  });

  it("transition transmise avec le statut attendu ; conflit : 422 status_changed", async () => {
    const store = new FakeLifecycle();
    const a = createApp({ verifyToken, lifecycle: store });
    const ok = await post(a, `/v1/orders/${order}/transitions`, { to: "accepted", expected: "pending" });
    expect(ok.status).toBe(200);
    expect(store.calls[0]).toMatchObject({ userId: user, orderId: order, to: "accepted", expected: "pending" });
    const conflict = await post(a, `/v1/orders/${order}/transitions`, { to: "accepted", expected: "pending" });
    expect(conflict.status).toBe(422);
    expect(((await conflict.json()) as { error: { message: string } }).error.message).toBe("status_changed");
  });

  it("refus : raison dans la liste seulement", async () => {
    const a = createApp({ verifyToken, lifecycle: new FakeLifecycle() });
    const bad = await post(a, `/v1/orders/${order}/transitions`, { to: "refused", expected: "pending", reason: "fâchée" });
    expect(bad.status).toBe(422);
  });

  it("geste réussi : les push en attente partent ; geste refusé : rien", async () => {
    const queue = new FakeQueue([push("n1")]);
    const sent: PushMessage[] = [];
    const sender: PushSender = { enabled: true, async send(m) { sent.push(m); return { sent: 1, invalidTokens: [] }; } };
    const a = createApp({ verifyToken, lifecycle: new FakeLifecycle(), push: { queue, sender } });
    await post(a, `/v1/orders/${order}/transitions`, { to: "refused", expected: "pending", reason: "rien" });
    expect(queue.claims).toBe(0);
    await post(a, `/v1/orders/${order}/transitions`, { to: "accepted", expected: "pending" });
    expect(queue.claims).toBe(1);
    expect(sent[0]).toMatchObject({ tokens: ["tok-1"], title: "Commande acceptée", data: { kind: "order_accepted", order_id: order } });
  });

  it("encaissement", async () => {
    const res = await post(createApp({ verifyToken, lifecycle: new FakeLifecycle() }), `/v1/orders/${order}/cash-collected`, {});
    expect(res.status).toBe(200);
  });
});

describe("file de push", () => {
  it("non autorisé, sans téléphone ou sans fournisseur : ignoré ; jetons refusés retirés", async () => {
    const queue = new FakeQueue([
      push("a"),
      push("b", { allowed: false }),
      push("c", { tokens: [] }),
      push("d", { tokens: ["vieux"] }),
    ]);
    const sender: PushSender = {
      enabled: true,
      async send(m) {
        return m.tokens[0] === "vieux" ? { sent: 0, invalidTokens: ["vieux"] } : { sent: 1, invalidTokens: [] };
      },
    };
    expect(await dispatchPushes(queue, sender)).toEqual({ sent: 1, skipped: 2, failed: 1 });
    expect(queue.results).toEqual({ sent: ["a"], skipped: ["b", "c"], failed: ["d"] });
    expect(queue.dropped).toEqual(["vieux"]);

    const idle = new FakeQueue([push("e")]);
    await dispatchPushes(idle, noPushSender);
    expect(idle.results.skipped).toEqual(["e"]);
  });

  it("FCM : jeton OAuth signé, un message par téléphone, jetons inconnus signalés", async () => {
    const { privateKey } = await generateKeyPair("RS256", { extractable: true });
    const account = JSON.stringify({
      project_id: "dym-test",
      client_email: "push@dym-test.iam.gserviceaccount.com",
      private_key: await exportPKCS8(privateKey),
    });
    const calls: { url: string; body: string }[] = [];
    const fakeFetch = (async (url: string, init?: RequestInit) => {
      calls.push({ url, body: String(init?.body) });
      if (url.includes("oauth2")) return new Response(JSON.stringify({ access_token: "at", expires_in: 3600 }));
      return new Response("{}", { status: String(init?.body).includes("perdu") ? 404 : 200 });
    }) as typeof fetch;
    const sender = fcmPushSender(account, fakeFetch);
    const result = await sender.send({ tokens: ["tel", "perdu"], title: "T", body: "B", data: { kind: "k" } });
    expect(result).toEqual({ sent: 1, invalidTokens: ["perdu"] });
    expect(calls[0]?.url).toBe("https://oauth2.googleapis.com/token");
    expect(calls[1]?.url).toBe("https://fcm.googleapis.com/v1/projects/dym-test/messages:send");
    expect(JSON.parse(calls[1]?.body ?? "{}").message).toMatchObject({ token: "tel", notification: { title: "T", body: "B" } });
    // Jeton OAuth réutilisé.
    await sender.send({ tokens: ["tel"], title: "T", body: "B", data: {} });
    expect(calls.filter((c) => c.url.includes("oauth2"))).toHaveLength(1);
  });
});
