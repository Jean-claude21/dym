import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { sentryReporter } from "../src/lib/report.js";

describe("suivi des erreurs", () => {
  it("enveloppe vers le projet, sans donnée personnelle", async () => {
    const sent: { url: string; init: RequestInit }[] = [];
    const report = sentryReporter("https://cle123@erreurs.example.com/7", {
      environment: "staging",
      fetchImpl: (async (url: string, init: RequestInit) => {
        sent.push({ url, init });
        return new Response(null, { status: 200 });
      }) as unknown as typeof fetch,
    });
    await report(new Error("base indisponible"), { method: "POST", path: "/v1/orders" });
    expect(sent).toHaveLength(1);
    expect(sent[0]?.url).toBe("https://erreurs.example.com/api/7/envelope/");
    const headers = sent[0]?.init.headers as Record<string, string>;
    expect(headers["X-Sentry-Auth"]).toContain("sentry_key=cle123");
    const [, , event] = String(sent[0]?.init.body).split("\n");
    const parsed = JSON.parse(event ?? "{}");
    expect(parsed.environment).toBe("staging");
    expect(parsed.tags.route).toBe("POST /v1/orders");
    expect(parsed.exception.values[0].value).toBe("base indisponible");
    expect(parsed.user).toBeUndefined();
    expect(parsed.request).toBeUndefined();
  });

  it("envoi en échec : jamais propagé ; DSN invalide refusé", async () => {
    const report = sentryReporter("https://cle@erreurs.example.com/1", {
      fetchImpl: (async () => {
        throw new Error("réseau");
      }) as unknown as typeof fetch,
    });
    await expect(report(new Error("x"), { method: "GET", path: "/" })).resolves.toBeUndefined();
    expect(() => sentryReporter("http://cle@erreurs.example.com/1")).toThrow();
    expect(() => sentryReporter("https://erreurs.example.com/1")).toThrow();
  });

  it("seules les erreurs 5xx sont remontées", async () => {
    const reported: string[] = [];
    const app = createApp({
      verifyToken: async () => ({ id: "u1", claims: {} }),
      reviews: {
        leave: async () => {
          throw new Error("base indisponible");
        },
        reply: async () => ({ id: "r" }),
      },
      reportError: async (_error, context) => {
        reported.push(`${context.method} ${context.path}`);
      },
    });
    const order = "a1000000-0000-4000-8000-000000000001";
    const failed = await app.request(`http://fn.test/v1/orders/${order}/review`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
      body: JSON.stringify({ rating: 5 }),
    });
    expect(failed.status).toBe(500);
    const invalid = await app.request(`http://fn.test/v1/orders/${order}/review`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
      body: JSON.stringify({ rating: 9 }),
    });
    expect(invalid.status).toBe(422);
    expect((await app.request("http://fn.test/inconnue")).status).toBe(404);
    expect(reported).toEqual([`POST /v1/orders/${order}/review`]);
  });
});
