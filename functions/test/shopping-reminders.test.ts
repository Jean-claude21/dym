import { describe, expect, it, vi } from "vitest";
import { createApp } from "../src/app.js";

const delivery = {
  version: 1,
  invocation_id: "remind-1",
  trigger: { type: "schedule", id: "t1", name: "shoppingReminders" },
  data: { scheduled_at: "2026-10-05T08:00:00Z" },
};

describe("rappels de courses planifiés", () => {
  const create = vi.fn(async () => 2);
  const app = createApp({ verifyToken: async () => ({ id: "u1", claims: {} }), shoppingReminders: { create } });
  const post = (body: unknown, invocation?: string) => app.request("http://test/v1/jobs/shopping-reminders", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(invocation ? { "x-neon-trigger-invocation-id": invocation } : {}) },
    body: JSON.stringify(body),
  });

  it("appel public ou identifiant différent refusé avant la base", async () => {
    create.mockClear();
    expect((await post(delivery)).status).toBe(401);
    expect((await post(delivery, "wrong")).status).toBe(401);
    expect(create).not.toHaveBeenCalled();
  });
  it("corps invalide refusé", async () => {
    expect((await post({}, "remind-1")).status).toBe(400);
  });
  it("date de la livraison planifiée transmise à SQL", async () => {
    create.mockClear();
    const response = await post(delivery, "remind-1");
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ created: 2 });
    expect(create).toHaveBeenCalledWith("2026-10-05T08:00:00Z");
  });
});
