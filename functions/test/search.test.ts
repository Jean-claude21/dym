import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { HttpError } from "../src/lib/errors.js";
import type { AiOutcome, SearchAiStore, SearchAiUsage } from "../src/search/ports.js";
import { cleanQuery, type SearchAiDeps } from "../src/search/routes.js";

const model = { provider: "openai", model: "m", params: {} };

class FakeStore implements SearchAiStore {
  enabled = true;
  records: [SearchAiUsage, AiOutcome][] = [];
  async context(_user: string, _usage: SearchAiUsage) {
    if (!this.enabled) throw new HttpError(422, "validation", "feature_disabled");
    return model;
  }
  async record(_user: string, usage: SearchAiUsage, outcome: AiOutcome) {
    this.records.push([usage, outcome]);
  }
}

const audio = Buffer.from("fake-audio-bytes").toString("base64");
const image = Buffer.from("fake-image-bytes").toString("base64");

const post = (deps: SearchAiDeps | undefined, path: string, body: unknown) =>
  createApp({ verifyToken: async () => ({ id: "u1", claims: {} }), searchAi: deps }).request(
    `http://fn.test${path}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
      body: JSON.stringify(body),
    },
  );

describe("recherche IA", () => {
  it("voix : texte nettoyé, requête journalisée", async () => {
    const store = new FakeStore();
    const res = await post(
      { store, transcriber: { transcribe: async () => " Des tomates et du gombo. " } },
      "/v1/search/voice",
      { audio, media_type: "audio/mp4" },
    );
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ query: "Des tomates et du gombo" });
    expect(store.records).toEqual([["search_transcription", "success"]]);
  });

  it("photo non reconnue : requête nulle, journalisée sans résultat", async () => {
    const store = new FakeStore();
    const res = await post(
      { store, describer: { describe: async () => null } },
      "/v1/search/photo",
      { image, media_type: "image/jpeg" },
    );
    expect(await res.json()).toEqual({ query: null });
    expect(store.records).toEqual([["search_from_photo", "no_result"]]);
  });

  it("fonction coupée pour le pays : refus", async () => {
    const store = new FakeStore();
    store.enabled = false;
    const res = await post(
      { store, describer: { describe: async () => "gombo" } },
      "/v1/search/photo",
      { image, media_type: "image/jpeg" },
    );
    expect(res.status).toBe(422);
    expect(store.records).toEqual([]);
  });

  it("fournisseur en échec : 503, échec journalisé", async () => {
    const store = new FakeStore();
    const res = await post(
      {
        store,
        transcriber: {
          transcribe: async () => {
            throw new Error("timeout");
          },
        },
      },
      "/v1/search/voice",
      { audio, media_type: "audio/mp4" },
    );
    expect(res.status).toBe(503);
    expect(store.records).toEqual([["search_transcription", "failure"]]);
  });

  it("entrées refusées : type inconnu, base64 invalide, sans fournisseur", async () => {
    const store = new FakeStore();
    const deps = { store, describer: { describe: async () => "x" } };
    expect((await post(deps, "/v1/search/photo", { image, media_type: "image/gif" })).status).toBe(422);
    expect((await post(deps, "/v1/search/photo", { image: "pas du base64 !", media_type: "image/jpeg" })).status).toBe(422);
    expect((await post({ store }, "/v1/search/voice", { audio, media_type: "audio/mp4" })).status).toBe(503);
    expect((await post(undefined, "/v1/search/voice", { audio, media_type: "audio/mp4" })).status).toBe(503);
  });

  it("texte de recherche : ponctuation retirée, trop court nul", () => {
    expect(cleanQuery("« gombo frais »")).toBe("gombo frais");
    expect(cleanQuery("a")).toBeNull();
    expect(cleanQuery("x".repeat(120))).toHaveLength(80);
  });
});
