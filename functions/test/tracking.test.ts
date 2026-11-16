import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";

const token = "abcdefghijklmnopqrstuvwx";
const app = (found: boolean) =>
  createApp({
    verifyToken: async (t) => ({ id: t, claims: {} }),
    tracking: {
      byToken: async (t) => (found && t === token ? { status: "out_for_delivery", eta_minutes: 7 } : null),
    },
  });

describe("lien de suivi (spec 096)", () => {
  it("page publique avec la carte", async () => {
    const res = await app(true).request(`/t/${token}`);
    expect(res.status).toBe(200);
    expect(await res.text()).toContain("maplibre-gl");
  });

  it("données sans compte, jamais en cache", async () => {
    const res = await app(true).request(`/t/${token}/data`);
    expect(res.status).toBe(200);
    expect(res.headers.get("cache-control")).toBe("no-store");
    expect(await res.json()).toMatchObject({ eta_minutes: 7 });
  });

  it("jeton invalide ou expiré : 404", async () => {
    expect((await app(true).request("/t/court")).status).toBe(404);
    expect((await app(false).request(`/t/${token}/data`)).status).toBe(404);
  });
});
