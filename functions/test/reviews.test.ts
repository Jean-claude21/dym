import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import type { ReviewStore } from "../src/reviews/routes.js";

const order = "a1000000-0000-4000-8000-000000000001";
const review = "b1000000-0000-4000-8000-000000000001";

class FakeReviews implements ReviewStore {
  calls: unknown[] = [];
  async leave(i: Parameters<ReviewStore["leave"]>[0]) {
    this.calls.push(i);
    return { id: review };
  }
  async reply(u: string, r: string, text: string) {
    this.calls.push({ u, r, text });
    return { id: r };
  }
}

const post = (store: ReviewStore, path: string, body: unknown) =>
  createApp({ verifyToken: async () => ({ id: "u1", claims: {} }), reviews: store }).request(
    `http://fn.test${path}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
      body: JSON.stringify(body),
    },
  );

describe("avis", () => {
  it("note de 1 à 5, étiquettes connues seulement", async () => {
    const store = new FakeReviews();
    expect((await post(store, `/v1/orders/${order}/review`, { rating: 6 })).status).toBe(422);
    expect((await post(store, `/v1/orders/${order}/review`, { rating: 5, tags: ["autre"] })).status).toBe(422);
    const ok = await post(store, `/v1/orders/${order}/review`, { rating: 4, tags: ["fresh"], comment: " Top " });
    expect(ok.status).toBe(201);
    expect(store.calls[0]).toEqual({ userId: "u1", orderId: order, rating: 4, tags: ["fresh"], comment: "Top" });
  });

  it("commentaire vide : nul", async () => {
    const store = new FakeReviews();
    await post(store, `/v1/orders/${order}/review`, { rating: 5, comment: "   " });
    expect((store.calls[0] as { comment: unknown }).comment).toBeNull();
  });

  it("réponse : texte exigé", async () => {
    const store = new FakeReviews();
    expect((await post(store, `/v1/reviews/${review}/reply`, { reply: " " })).status).toBe(422);
    expect((await post(store, `/v1/reviews/${review}/reply`, { reply: "Merci" })).status).toBe(200);
  });
});
