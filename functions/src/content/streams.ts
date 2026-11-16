import type { Hono } from "hono";
import type pg from "pg";
import type { AuthVariables } from "../lib/auth.js";
import { parseTriggerInvocation } from "@neon/functions/triggers";
import { fromPgError } from "../lib/db.js";

/** Contenu vidéo à rendre adaptatif (HLS). */
export interface PendingStream {
  id: string;
  media_key: string;
  stream_video_id: string | null;
  stream_status: "processing" | null;
}

export interface StreamStore {
  pending(limit: number): Promise<PendingStream[]>;
  set(contentId: string, videoId: string | null, status: "processing" | "ready" | "failed", url: string | null): Promise<void>;
}

/** Fournisseur de vidéo adaptative (Bunny Stream aujourd'hui), derrière une interface. */
export interface StreamProvider {
  /** Crée la vidéo et demande au fournisseur de la récupérer à [sourceUrl]. */
  ingest(title: string, sourceUrl: string): Promise<string>;
  /** État : `processing`, `ready` (avec l'adresse HLS) ou `failed`. */
  status(videoId: string): Promise<{ status: "processing" | "ready" | "failed"; url: string | null }>;
}

export interface StreamDeps {
  store: StreamStore;
  provider?: StreamProvider;
  /** Adresse publique des médias du catalogue (`MEDIA_PUBLIC_URL`). */
  mediaBase?: string;
}

/**
 * Vidéo adaptative des contenus (spec 101) : tâche planifiée qui envoie les nouvelles vidéos au
 * fournisseur puis suit leur conversion. Sans fournisseur, rien ne change : la vidéo d'origine
 * reste lue telle quelle (signalé dans la spec, décision 0015).
 */
export async function syncStreams(deps: StreamDeps, limit = 10) {
  const { provider, mediaBase } = deps;
  if (!provider || !mediaBase) return { sent: 0, ready: 0, failed: 0, skipped: true };
  let sent = 0;
  let ready = 0;
  let failed = 0;
  for (const item of await deps.store.pending(limit)) {
    try {
      if (!item.stream_video_id) {
        const source = `${mediaBase.replace(/\/$/, "")}/${item.media_key}`;
        const id = await provider.ingest(`dym-${item.id}`, source);
        await deps.store.set(item.id, id, "processing", null);
        sent += 1;
        continue;
      }
      const state = await provider.status(item.stream_video_id);
      if (state.status === "processing") continue;
      await deps.store.set(item.id, null, state.status, state.url);
      if (state.status === "ready") ready += 1;
      else failed += 1;
    } catch (error) {
      console.error("[streams] contenu en échec", item.id, error);
    }
  }
  return { sent, ready, failed, skipped: false };
}

export function registerStreamJob(app: Hono<{ Variables: AuthVariables }>, deps?: StreamDeps) {
  app.post("/v1/jobs/content-streams", async (c) => {
    const parsed = await parseTriggerInvocation(c.req.raw);
    if (!parsed.ok) return c.json({ error: parsed.error }, parsed.error === "invalid_body" ? 400 : 401);
    if (!deps) return c.json({ error: "unavailable" }, 503);
    return c.json(await syncStreams(deps));
  });
}

export function pgStreamStore(pool: pg.Pool): StreamStore {
  return {
    async pending(limit) {
      try {
        const { rows } = await pool.query("select app.stream_pending($1) as value", [limit]);
        return rows[0].value as PendingStream[];
      } catch (error) {
        throw fromPgError(error);
      }
    },
    async set(contentId, videoId, status, url) {
      try {
        await pool.query("select app.set_stream($1, $2, $3, $4)", [contentId, videoId, status, url]);
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}

/** Bunny Stream : bibliothèque, clé de la bibliothèque, hôte du CDN. */
export function bunnyStreamProvider(
  options: { libraryId: string; apiKey: string; cdnHost: string },
  fetchImpl: typeof fetch = fetch,
): StreamProvider {
  const base = `https://video.bunnycdn.com/library/${options.libraryId}/videos`;
  const headers = { AccessKey: options.apiKey, Accept: "application/json", "Content-Type": "application/json" };
  return {
    async ingest(title, sourceUrl) {
      // « fetch » : Bunny télécharge la vidéo d'origine et crée l'entrée (un seul appel).
      const res = await fetchImpl(`${base}/fetch`, {
        method: "POST",
        headers,
        body: JSON.stringify({ url: sourceUrl, title }),
      });
      if (!res.ok) throw new Error(`bunny fetch ${res.status}`);
      const body = (await res.json()) as { id?: string; guid?: string };
      const id = body.id ?? body.guid;
      if (!id) throw new Error("bunny fetch : identifiant absent");
      return id;
    },
    async status(videoId) {
      const res = await fetchImpl(`${base}/${videoId}`, { headers });
      if (res.status === 404) return { status: "failed", url: null };
      if (!res.ok) throw new Error(`bunny video ${res.status}`);
      const video = (await res.json()) as { status?: number };
      // 4 : terminée ; 5 et 6 : en échec ; le reste : en cours.
      if (video.status === 4) {
        return { status: "ready", url: `https://${options.cdnHost}/${videoId}/playlist.m3u8` };
      }
      if (video.status === 5 || video.status === 6) return { status: "failed", url: null };
      return { status: "processing", url: null };
    },
  };
}
