import { describe, expect, it } from "vitest";
import { bunnyStreamProvider, type StreamStore, syncStreams } from "../src/content/streams.js";

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
