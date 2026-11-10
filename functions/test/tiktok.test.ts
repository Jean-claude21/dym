import { afterEach, describe, expect, it, vi } from "vitest";
import { createApp } from "../src/app.js";
import { type TikTokDeps, type TikTokStore, tiktokOEmbedProvider, type VideoImportProvider } from "../src/content/tiktok.js";

const store: TikTokStore = {
  isCreator: async (userId) => userId !== "autre",
  declaredHandle: async (userId) => (userId === "sans-compte" ? null : "awa.cuisine"),
  storePreview: async (id) =>
    id === "11111111-1111-4111-8111-111111111111" ? { name: "Étal de Kodjo", zoneName: "Bè", coverKey: null } : null,
  sharePreview: async (code) =>
    code === "ab12cd34"
      ? { caption: "Sauce <gombo>", mediaKey: "creators/u/contents/c.jpg", isVideo: false, authorName: "Awa" }
      : null,
};
const signer = {
  presignPut: async (key: string) => `https://put/${key}`,
  publicUrl: (key: string) => `https://cdn/${key}`,
};
const provider: VideoImportProvider = {
  lookup: async (url) =>
    url.includes("inconnue")
      ? null
      : { title: "Sauce gombo", thumbnailUrl: "https://p16.tiktokcdn.com/cover.jpeg", authorHandle: url.includes("@autre") ? "autre" : "Awa.Cuisine" },
  download: async () => ({ bytes: new Uint8Array([1, 2, 3]).buffer, contentType: "image/jpeg" }),
};

const app = (deps: Partial<TikTokDeps> = {}) =>
  createApp({
    verifyToken: async (token) => ({ id: token, claims: {} }),
    tiktok: { store, provider, signer, webUrl: "https://app.dym.test", ...deps },
  });
const importVideo = (user: string, url: string, deps?: Partial<TikTokDeps>) =>
  app(deps).request("http://fn.test/v1/creator-content/tiktok-import", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${user}` },
    body: JSON.stringify({ url }),
  });

describe("pont TikTok (spec 040)", () => {
  afterEach(() => vi.unstubAllGlobals());

  it("import : couverture copiée chez la créatrice, lien d'origine, compte non vérifié", async () => {
    const put = vi.fn(async () => new Response(null, { status: 200 }));
    vi.stubGlobal("fetch", put);
    const res = await importVideo("u1", "https://www.tiktok.com/@awa.cuisine/video/7300000000000000001");
    expect(res.status).toBe(200);
    const body = (await res.json()) as Record<string, unknown>;
    expect(body.object_key).toBe(`creators/u1/contents/${body.content_id}.jpg`);
    expect(body).toMatchObject({ caption: "Sauce gombo", author_handle: "awa.cuisine", verified: false });
    expect(put).toHaveBeenCalledWith(`https://put/${body.object_key}`, expect.objectContaining({ method: "PUT" }));
  });

  it("refus : hors TikTok, sans profil, sans compte déclaré, vidéo d'un autre ou introuvable", async () => {
    expect((await importVideo("u1", "https://example.com/video")).status).toBe(422);
    expect((await importVideo("autre", "https://www.tiktok.com/@awa.cuisine/video/1")).status).toBe(403);
    const noHandle = await importVideo("sans-compte", "https://www.tiktok.com/@awa.cuisine/video/1");
    expect(noHandle.status).toBe(422);
    expect(JSON.stringify(await noHandle.json())).toContain("tiktok_handle_required");
    const other = await importVideo("u1", "https://www.tiktok.com/@autre/video/1");
    expect(JSON.stringify(await other.json())).toContain("not_owner");
    const missing = await importVideo("u1", "https://www.tiktok.com/@awa.cuisine/video/inconnue");
    expect(JSON.stringify(await missing.json())).toContain("tiktok_not_found");
  });

  it("sans couverture chez TikTok : import sans clé, la créatrice choisira", async () => {
    const res = await importVideo("u1", "https://www.tiktok.com/@awa.cuisine/video/1", {
      provider: { ...provider, lookup: async () => ({ title: null, thumbnailUrl: null, authorHandle: "awa.cuisine" }) },
    });
    expect(res.status).toBe(200);
    expect(((await res.json()) as { object_key: unknown }).object_key).toBeNull();
  });

  it("sans fournisseur : indisponible", async () => {
    expect((await importVideo("u1", "https://www.tiktok.com/@awa.cuisine/video/1", { provider: undefined })).status).toBe(503);
  });

  it("lien de partage : aperçu échappé et ouverture de l'app web", async () => {
    const res = await app().request("http://fn.test/s/AB12CD34");
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html).toContain("Sauce &lt;gombo&gt;");
    expect(html).toContain('href="https://app.dym.test/?share=ab12cd34"');
    expect(html).toContain('og:image" content="https://cdn/creators/u/contents/c.jpg"');
    expect((await app().request("http://fn.test/s/zzzzzzzz")).status).toBe(404);
    expect((await app().request("http://fn.test/s/x")).status).toBe(404);
  });

  it("boutique partagée : page et lien vers l'app web (spec 048)", async () => {
    const res = await app().request("http://fn.test/b/11111111-1111-4111-8111-111111111111");
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html).toContain("Étal de Kodjo");
    expect(html).toContain('href="https://app.dym.test/?store=11111111-1111-4111-8111-111111111111"');
    expect((await app().request("http://fn.test/b/22222222-2222-4222-8222-222222222222")).status).toBe(404);
  });

  it("oEmbed : compte lu dans la réponse ; vidéo inconnue : nulle", async () => {
    const fetchImpl = vi.fn(async (url: string | URL | Request) =>
      String(url).includes("inconnue")
        ? new Response("{}", { status: 400 })
        : String(url).includes("nocover")
          ? Response.json({ type: "video", html: "<iframe></iframe>" })
          : Response.json({ type: "video", title: "Sauce", thumbnail_url: "https://p16.tiktokcdn.com/c.jpeg", author_url: "https://www.tiktok.com/@awa.cuisine" }),
    ) as unknown as typeof fetch;
    const oembed = tiktokOEmbedProvider(fetchImpl);
    expect(await oembed.lookup("https://www.tiktok.com/@awa.cuisine/video/1")).toEqual({
      title: "Sauce",
      thumbnailUrl: "https://p16.tiktokcdn.com/c.jpeg",
      authorHandle: "awa.cuisine",
    });
    expect(await oembed.lookup("https://www.tiktok.com/@x/video/inconnue")).toBeNull();
    // Réponse réduite (constatée) : compte lu dans l'adresse, sans couverture.
    expect(await oembed.lookup("https://www.tiktok.com/@awa.cuisine/video/nocover")).toEqual({
      title: null,
      thumbnailUrl: null,
      authorHandle: "awa.cuisine",
    });
  });
});
