import { describe, expect, it } from "vitest";
import { bunnyStreamProvider, onStreamHook, type StreamStore, syncStreams } from "../src/content/streams.js";

const store = () => {
  const sets: unknown[][] = [];
  const s: StreamStore = {
    pending: async () => [
      { id: "c1", media_key: "creators/u/contents/c1.mp4", stream_video_id: null, stream_status: null },
      { id: "c2", media_key: "creators/u/contents/c2.mp4", stream_video_id: "v2", stream_status: "processing" },
    ],
    set: async (...args) => {
      sets.push(args);
    },
  };
  return { s, sets };
};

describe("vidéo adaptative (spec 101)", () => {
  it("envoie les nouvelles vidéos, marque les prêtes", async () => {
    const { s, sets } = store();
    const result = await syncStreams({
      store: s,
      mediaBase: "https://media.test",
      provider: {
        ingest: async (_t, url) => (url.endsWith("c1.mp4") ? "v1" : "x"),
        status: async () => ({ status: "ready", url: "https://cdn.test/v2/playlist.m3u8", thumbs: 8 }),
      },
    });
    expect(result).toMatchObject({ sent: 1, ready: 1 });
    expect(sets).toEqual([
      ["c1", "v1", "processing", null],
      ["c2", null, "ready", "https://cdn.test/v2/playlist.m3u8", 8],
    ]);
  });

  it("sans fournisseur : rien ne change", async () => {
    const { s, sets } = store();
    expect((await syncStreams({ store: s })).skipped).toBe(true);
    expect(sets).toEqual([]);
  });

  it("Bunny : état 4 = prête, adresse HLS du CDN", async () => {
    const provider = bunnyStreamProvider(
      { libraryId: "1", apiKey: "k", cdnHost: "cdn.test" },
      (async () => new Response(JSON.stringify({ status: 4, thumbnailCount: 6 }))) as typeof fetch,
    );
    expect(await provider.status("v9")).toEqual({ status: "ready", url: "https://cdn.test/v9/playlist.m3u8", thumbs: 6 });
  });
});

describe("webhook Bunny Stream (fin de l'interrogation toutes les 5 minutes)", () => {
  const provider = {
    ingest: async () => "x",
    status: async (id: string) =>
      id === "v2"
        ? ({ status: "ready", url: "https://cdn.test/v2/playlist.m3u8", thumbs: 6 } as const)
        : ({ status: "processing", url: null } as const),
  };

  it("relit chez Bunny la vidéo annoncée et la marque prête", async () => {
    const { s, sets } = store();
    const r = await onStreamHook({ store: s, provider, libraryId: "42" }, { VideoLibraryId: 42, VideoGuid: "v2", Status: 3 });
    expect(r).toEqual({ status: 200, body: { updated: true, status: "ready" } });
    expect(sets).toEqual([["c2", null, "ready", "https://cdn.test/v2/playlist.m3u8", 6]]);
  });

  it("ne croit pas le corps : autre bibliothèque, vidéo inconnue ou encore en cours = rien", async () => {
    const { s, sets } = store();
    const deps = { store: s, provider, libraryId: "42" };
    expect((await onStreamHook(deps, { VideoLibraryId: 7, VideoGuid: "v2" })).body).toMatchObject({ updated: false, reason: "other_library" });
    expect((await onStreamHook(deps, { VideoLibraryId: 42, VideoGuid: "pirate" })).body).toMatchObject({ updated: false, reason: "unknown_video" });
    expect((await onStreamHook(deps, { VideoLibraryId: 42 })).status).toBe(400);
    expect(sets).toEqual([]);
  });
});
