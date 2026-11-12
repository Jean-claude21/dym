import { describe, expect, it, vi } from "vitest";
import { createApp } from "../src/app.js";

const delivery = {
  version: 1,
  invocation_id: "watch-1",
  trigger: { type: "schedule", id: "t1", name: "dispatchWatch" },
  data: { scheduled_at: "2026-10-05T19:00:00Z" },
};

describe("surveillance des commandes planifiée", () => {
  const run = vi.fn(async () => ({ refused: 1, relaunched: 2 }));
  const app = createApp({ verifyToken: async () => ({ id: "u1", claims: {} }), dispatchWatch: { run } });
  const post = (body: unknown, invocation?: string) => app.request("http://test/v1/jobs/dispatch-watch", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(invocation ? { "x-neon-trigger-invocation-id": invocation } : {}) },
    body: JSON.stringify(body),
  });

  it("appel public ou identifiant différent refusé avant la base", async () => {
    run.mockClear();
    expect((await post(delivery)).status).toBe(401);
    expect((await post(delivery, "wrong")).status).toBe(401);
    expect(run).not.toHaveBeenCalled();
  });
  it("corps invalide refusé", async () => {
    expect((await post({}, "watch-1")).status).toBe(400);
  });
  it("date de la livraison planifiée transmise à SQL", async () => {
    run.mockClear();
    const response = await post(delivery, "watch-1");
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ refused: 1, relaunched: 2 });
    expect(run).toHaveBeenCalledWith("2026-10-05T19:00:00Z");
  });
});
