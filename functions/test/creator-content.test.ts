import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import type { ContentClassifier, CreatorContentStore } from "../src/content/creators.js";

const categories = [
  { slug: "recettes", label: "Recettes" },
  { slug: "autre", label: "Autre" },
];

const store: CreatorContentStore = {
  classifierContext: async () => ({ model: { provider: "openai", model: "m", params: {} }, categories }),
  isCreator: async (userId) => userId === "creator",
};
const signer = {
  presignPut: async (key: string) => `https://put/${key}`,
  publicUrl: (key: string) => `https://cdn/${key}`,
};

const post = (user: string, path: string, body: unknown, classifier?: ContentClassifier) =>
  createApp({
    verifyToken: async () => ({ id: user, claims: {} }),
    creatorContent: { store, signer, classifier },
  }).request(`http://fn.test${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
    body: JSON.stringify(body),
  });

describe("créatrices (spec 036)", () => {
  it("envoi : dossier de la créatrice ; sans profil : refusé", async () => {
    const res = await post("creator", "/v1/creator-content/uploads", { content_type: "video/mp4" });
    const body = (await res.json()) as { object_key: string; content_id: string };
    expect(body.object_key).toBe(`creators/creator/contents/${body.content_id}.mp4`);
    expect((await post("autre", "/v1/creator-content/uploads", { content_type: "image/jpeg" })).status).toBe(403);
  });

  it("classement : catégorie du référentiel seulement, jamais bloquant", async () => {
    const good: ContentClassifier = { classify: async () => "recettes" };
    const invented: ContentClassifier = { classify: async () => "politique" };
    const failing: ContentClassifier = { classify: async () => Promise.reject(new Error("timeout")) };
    const caption = { caption: "Ma sauce gombo du dimanche" };
    expect(await (await post("creator", "/v1/creator-content/classify", caption, good)).json()).toEqual({
      slug: "recettes",
    });
    expect(await (await post("creator", "/v1/creator-content/classify", caption, invented)).json()).toEqual({
      slug: null,
    });
    expect(await (await post("creator", "/v1/creator-content/classify", caption, failing)).json()).toEqual({
      slug: null,
    });
  });
});
