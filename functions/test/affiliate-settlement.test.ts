import { describe, expect, it, vi } from "vitest";
import { createApp } from "../src/app.js";

const delivery = {
  version: 1,
  invocation_id: "settle-1",
  trigger: { type: "schedule", id: "t2", name: "affiliateSettlement" },
  data: { scheduled_at: "2026-11-10T10:15:00Z" },
};

describe("versement planifié des commissions", () => {
  const settle = vi.fn(async () => 3);
  const app = createApp({ verifyToken: async () => ({ id: "u1", claims: {} }), affiliateSettlement: { settle } });
  const post = (body: unknown, invocation?: string) => app.request("http://test/v1/jobs/affiliate-settlement", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(invocation ? { "x-neon-trigger-invocation-id": invocation } : {}) },
    body: JSON.stringify(body),
  });

  it("appel public ou identifiant différent refusé avant la base", async () => {
    settle.mockClear();
    expect((await post(delivery)).status).toBe(401);
    expect((await post(delivery, "wrong")).status).toBe(401);
    expect(settle).not.toHaveBeenCalled();
  });
  it("corps invalide refusé", async () => {
    expect((await post({}, "settle-1")).status).toBe(400);
  });
  it("heure planifiée transmise à SQL", async () => {
    settle.mockClear();
    const response = await post(delivery, "settle-1");
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ paid: 3 });
    expect(settle).toHaveBeenCalledWith("2026-11-10T10:15:00Z");
  });
  it("sans base : indisponible", async () => {
    const bare = createApp({ verifyToken: async () => ({ id: "u1", claims: {} }) });
    const response = await bare.request("http://test/v1/jobs/affiliate-settlement", {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-neon-trigger-invocation-id": "settle-1" },
      body: JSON.stringify(delivery),
    });
    expect(response.status).toBe(503);
  });
});
