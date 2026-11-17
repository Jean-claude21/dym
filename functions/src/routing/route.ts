import type { Hono } from "hono";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { httpErrors } from "../lib/errors.js";

/**
 * Itinéraire dessiné sur la carte (spec 109) : de la position du livreur à la boutique puis à la
 * porte. Fournisseur derrière une interface (OSRM aujourd'hui : serveur public de démonstration sur
 * staging, serveur à soi ou fournisseur payant en production via `ROUTING_URL`).
 */

export type LatLng = [number, number];

export interface Route {
  /** Tracé simplifié, [latitude, longitude]. */
  coordinates: LatLng[];
  distance_m: number;
  duration_s: number;
}

export interface RouteProvider {
  route(points: LatLng[]): Promise<Route>;
}

export function osrmRouteProvider(baseUrl: string, fetchImpl: typeof fetch = fetch): RouteProvider {
  const base = baseUrl.replace(/\/$/, "");
  return {
    async route(points) {
      const path = points.map(([lat, lng]) => `${lng.toFixed(6)},${lat.toFixed(6)}`).join(";");
      const res = await fetchImpl(`${base}/route/v1/driving/${path}?overview=simplified&geometries=geojson`, {
        headers: { Accept: "application/json" },
        signal: AbortSignal.timeout(8000),
      });
      if (!res.ok) throw new Error(`osrm ${res.status}`);
      const body = (await res.json()) as {
        code?: string;
        routes?: { distance: number; duration: number; geometry: { coordinates: [number, number][] } }[];
      };
      const best = body.routes?.[0];
      if (body.code !== "Ok" || !best) throw new Error(`osrm ${body.code ?? "sans itinéraire"}`);
      return {
        coordinates: best.geometry.coordinates.map(([lng, lat]) => [lat, lng] as LatLng),
        distance_m: Math.round(best.distance),
        duration_s: Math.round(best.duration),
      };
    },
  };
}

/** Petit cache : mêmes points (au mètre près) → même tracé pendant 10 minutes. */
export function cachedRouteProvider(inner: RouteProvider, ttlMs = 600_000, max = 500): RouteProvider {
  const cache = new Map<string, { at: number; route: Route }>();
  return {
    async route(points) {
      const key = points.map(([a, b]) => `${a.toFixed(4)},${b.toFixed(4)}`).join(";");
      const hit = cache.get(key);
      if (hit && Date.now() - hit.at < ttlMs) return hit.route;
      const route = await inner.route(points);
      if (cache.size >= max) cache.delete(cache.keys().next().value as string);
      cache.set(key, { at: Date.now(), route });
      return route;
    },
  };
}

const pointSchema = z.tuple([z.number().min(-90).max(90), z.number().min(-180).max(180)]);
const bodySchema = z.object({ points: z.array(pointSchema).min(2).max(4) });

export function registerRouteRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verify: TokenVerifier,
  provider?: RouteProvider,
) {
  app.post("/v1/route", requireUser(verify), async (c) => {
    const body = bodySchema.safeParse(await c.req.json().catch(() => null));
    if (!body.success) throw httpErrors.badRequest("2 à 4 points [latitude, longitude]");
    if (!provider) return c.json({ error: "unavailable", message: "itinéraire non configuré" }, 503);
    try {
      return c.json(await provider.route(body.data.points as LatLng[]));
    } catch (error) {
      console.error("[route]", error);
      // L'app trace alors une ligne droite.
      return c.json({ error: "route_unavailable", message: "itinéraire indisponible" }, 502);
    }
  });
}
