import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { cachedRouteProvider, osrmRouteProvider, type RouteProvider } from "../src/routing/route.js";

const verifyToken = async () => ({ id: "u", claims: {} });
const post = (a: ReturnType<typeof createApp>, body: unknown) =>
  a.request("/v1/route", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
    body: JSON.stringify(body),
  });

describe("itinéraire (spec 109)", () => {
  it("OSRM : points en longitude,latitude, tracé rendu en latitude,longitude", async () => {
    let url = "";
    const provider = osrmRouteProvider("https://osrm.test/", (async (u: string) => {
      url = u;
      return new Response(
        JSON.stringify({
          code: "Ok",
          routes: [{ distance: 1234.4, duration: 300.6, geometry: { coordinates: [[1.2, 6.1], [1.3, 6.2]] } }],
        }),
      );
    }) as unknown as typeof fetch);
    const route = await provider.route([[6.1, 1.2], [6.2, 1.3]]);
    expect(url).toContain("/route/v1/driving/1.200000,6.100000;1.300000,6.200000");
    expect(route).toEqual({ coordinates: [[6.1, 1.2], [6.2, 1.3]], distance_m: 1234, duration_s: 301 });
  });

  it("cache : mêmes points, un seul appel", async () => {
    let calls = 0;
    const inner: RouteProvider = {
      route: async () => {
        calls += 1;
        return { coordinates: [], distance_m: 1, duration_s: 1 };
      },
    };
    const cached = cachedRouteProvider(inner);
    await cached.route([[6.1, 1.2], [6.2, 1.3]]);
    await cached.route([[6.10001, 1.20001], [6.2, 1.3]]);
    expect(calls).toBe(1);
  });

  it("route : jeton exigé, points vérifiés, repli si le fournisseur échoue", async () => {
    const ok = createApp({
      verifyToken,
      routes: { route: async () => ({ coordinates: [[6.1, 1.2]], distance_m: 10, duration_s: 5 }) },
    });
    expect((await ok.request("/v1/route", { method: "POST", body: "{}" })).status).toBe(401);
    expect((await post(ok, { points: [[6.1, 1.2]] })).status).toBe(400);
    expect((await post(ok, { points: [[6.1, 1.2], [6.2, 1.3]] })).status).toBe(200);
    const down = createApp({ verifyToken, routes: { route: async () => { throw new Error("x"); } } });
    expect((await post(down, { points: [[6.1, 1.2], [6.2, 1.3]] })).status).toBe(502);
  });
});
