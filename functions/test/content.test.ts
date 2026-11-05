import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import type { CatalogStore, PhotoSigner } from "../src/catalog/ports.js";

const store = "c1000000-0000-4000-8000-000000000001";

const catalogStore = {
  photoUploadStore: async () => store,
} as unknown as CatalogStore;

const signer: PhotoSigner = {
  presignPut: async (key) => `https://s3.test/${key}?sig`,
  publicUrl: (key) => `https://s3.test/${key}`,
};

const post = (body: unknown, withSigner = true) =>
  createApp({
    verifyToken: async () => ({ id: "u1", claims: {} }),
    catalog: { store: catalogStore, signer: withSigner ? signer : undefined },
  }).request("http://fn.test/v1/content/uploads", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
    body: JSON.stringify(body),
  });

describe("contenus", () => {
  it("vidéo : clé dans le dossier de la boutique", async () => {
    const res = await post({ content_type: "video/mp4" });
    expect(res.status).toBe(200);
    const json = (await res.json()) as { object_key: string; content_id: string };
    expect(json.object_key).toBe(`stores/${store}/contents/${json.content_id}.mp4`);
  });

  it("type refusé, stockage absent", async () => {
    expect((await post({ content_type: "video/quicktime" })).status).toBe(422);
    expect((await post({ content_type: "image/jpeg" }, false)).status).toBe(503);
  });
});
