import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { type LiveEvent, LiveHub, type LiveStore } from "../src/live/gateway.js";

/** Table en mémoire : mêmes règles que `app.live_events_since`. */
function memoryStore() {
  const events: LiveEvent[] = [];
  let calls = 0;
  const store: LiveStore = {
    async since(users, after, limit) {
      calls++;
      return events.filter((e) => users.includes(e.user_id) && e.id > after).slice(0, limit);
    },
    async lastId() {
      return events.reduce((m, e) => Math.max(m, e.id), 0);
    },
  };
  const push = (id: number, user: string, kind = "notification") =>
    events.push({ id, user_id: user, kind, entity_id: null, payload: { kind: "new_order" }, created_at: "" });
  return { store, push, calls: () => calls };
}

function socket(userId: string) {
  const received: Record<string, unknown>[] = [];
  return { client: { userId, send: (m: string) => received.push(JSON.parse(m)) }, received };
}

const events = (r: Record<string, unknown>[]) => r.filter((m) => m.type === "event").map((m) => m.id);

describe("passerelle temps réel", () => {
  it("chaque personne ne reçoit que ses événements, sans doublon", async () => {
    const db = memoryStore();
    db.push(1, "awa");
    const hub = new LiveHub(db.store);
    const awa = socket("awa");
    const kodjo = socket("kodjo");
    await hub.add(awa.client);
    await hub.add(kodjo.client);
    expect(awa.received[0]).toEqual({ type: "ready", cursor: 1 });
    db.push(2, "awa");
    db.push(3, "kodjo");
    await hub.poll();
    await hub.poll(); // relecture avec recouvrement : pas de doublon
    expect(events(awa.received)).toEqual([2]);
    expect(events(kodjo.received)).toEqual([3]);
    hub.stop();
  });

  it("un événement validé en retard (identifiant plus petit) n'est pas perdu", async () => {
    const db = memoryStore();
    const hub = new LiveHub(db.store);
    const awa = socket("awa");
    await hub.add(awa.client);
    db.push(5, "awa");
    await hub.poll();
    db.push(4, "awa"); // transaction plus ancienne, validée après la 5
    await hub.poll();
    expect(events(awa.received).sort()).toEqual([4, 5]);
    hub.stop();
  });

  it("reprise après coupure : les événements manqués sont renvoyés", async () => {
    const db = memoryStore();
    db.push(1, "awa");
    db.push(2, "awa");
    db.push(3, "kodjo");
    const hub = new LiveHub(db.store);
    const awa = socket("awa");
    await hub.add(awa.client, 1);
    expect(events(awa.received)).toEqual([2]);
    hub.stop();
  });

  it("aucune lecture sans connexion (la base peut dormir)", async () => {
    const db = memoryStore();
    const hub = new LiveHub(db.store);
    const awa = socket("awa");
    const release = await hub.add(awa.client);
    release();
    const before = db.calls();
    await hub.poll();
    expect(db.calls()).toBe(before);
    expect(hub.size).toBe(0);
  });

  it("signal de vie envoyé à chaque connexion", async () => {
    const db = memoryStore();
    const hub = new LiveHub(db.store);
    const awa = socket("awa");
    await hub.add(awa.client);
    hub.heartbeat();
    expect(awa.received.at(-1)).toEqual({ type: "ping" });
    hub.stop();
  });

  it("route : jeton exigé, puis passage au WebSocket", async () => {
    const hub = new LiveHub(memoryStore().store);
    const app = createApp({
      verifyToken: async (t) => {
        if (t !== "ok") throw new Error("jeton");
        return { id: "awa", claims: {} };
      },
      live: hub,
    });
    expect((await app.request("http://test/v1/live")).status).toBe(401);
    expect((await app.request("http://test/v1/live?access_token=faux")).status).toBe(401);
    expect((await app.request("http://test/v1/live?access_token=ok")).status).toBe(426);
    expect(
      (await app.request("http://test/v1/live", { headers: { Authorization: "Bearer ok" } })).status,
    ).toBe(426);
    hub.stop();
  });
});
