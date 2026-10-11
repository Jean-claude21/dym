import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import type { BroadcastStore } from "../src/broadcast/routes.js";
import { HttpError } from "../src/lib/errors.js";

class FakeStore implements BroadcastStore {
  calls: unknown[] = [];
  sentToday = false;
  async send(input: Parameters<BroadcastStore["send"]>[0]) {
    if (this.sentToday) throw new HttpError(422, "validation", "broadcast_daily_limit");
    this.calls.push(input);
    this.sentToday = true;
    return { id: "b1", recipients: 12 };
  }
}

const post = (store: BroadcastStore | undefined, body: unknown) =>
  createApp({ verifyToken: async () => ({ id: "u1", claims: {} }), broadcasts: store }).request(
    "http://fn.test/v1/vendor/broadcasts",
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
      body: JSON.stringify(body),
    },
  );

describe("relance", () => {
  it("segment et message ; une par jour", async () => {
    const store = new FakeStore();
    const res = await post(store, { segment: "regular", message: " Gombo frais ! " });
    expect(res.status).toBe(201);
    expect(await res.json()).toEqual({ id: "b1", recipients: 12 });
    expect(store.calls).toEqual([
      { userId: "u1", segment: "regular", message: "Gombo frais !", productId: null },
    ]);
    expect((await post(store, { segment: "all", message: "Encore" })).status).toBe(422);
  });

  it("entrées refusées, sans base", async () => {
    const store = new FakeStore();
    expect((await post(store, { segment: "vip", message: "Bonjour" })).status).toBe(422);
    expect((await post(store, { segment: "all", message: "x".repeat(301) })).status).toBe(422);
    expect((await post(undefined, { segment: "all", message: "Bonjour" })).status).toBe(503);
  });
});
