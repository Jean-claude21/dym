import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import {
  cleanNeeds,
  type CopilotDeps,
  type CopilotNeed,
  type CopilotStore,
} from "../src/copilot/routes.js";
import { HttpError } from "../src/lib/errors.js";

const zone = "a1000000-0000-4000-8000-000000000001";

class FakeStore implements CopilotStore {
  enabled = true;
  picked: CopilotNeed[] = [];
  log: string[] = [];
  async context() {
    if (!this.enabled) throw new HttpError(422, "validation", "feature_disabled");
    return { provider: "openai", model: "m", params: {} };
  }
  async pick(_zone: string | null, needs: CopilotNeed[]) {
    this.picked = needs;
    return { item_count: needs.length, stores: [], missing: [] };
  }
  async proposed() {
    this.log.push("proposed");
  }
  async failed() {
    this.log.push("failed");
  }
}

const post = (deps: CopilotDeps | undefined, body: unknown) =>
  createApp({ verifyToken: async () => ({ id: "u1", claims: {} }), copilot: deps }).request(
    "http://fn.test/v1/copilot/propose",
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
      body: JSON.stringify(body),
    },
  );

describe("copilote", () => {
  it("intention → besoins nettoyés → panier chiffré par la base", async () => {
    const store = new FakeStore();
    const res = await post(
      {
        store,
        planner: {
          plan: async () => [
            { label: " Gombo  frais ", query: "gombo", quantity: 2 },
            { label: "Huile", query: "x", quantity: 1 },
          ],
        },
      },
      { text: "Une sauce gombo pour 4", zone_id: zone },
    );
    expect(res.status).toBe(200);
    expect(store.picked).toEqual([{ label: "Gombo frais", query: "gombo", quantity: 2 }]);
    expect(store.log).toEqual(["proposed"]);
  });

  it("IA en échec : 503 journalisé (retour à la recherche classique)", async () => {
    const store = new FakeStore();
    const res = await post(
      {
        store,
        planner: {
          plan: async () => {
            throw new Error("timeout");
          },
        },
      },
      { text: "Un anniversaire pour 20" },
    );
    expect(res.status).toBe(503);
    expect(store.log).toEqual(["failed"]);
  });

  it("flag coupé, texte vide, sans fournisseur", async () => {
    const store = new FakeStore();
    store.enabled = false;
    expect((await post({ store, planner: { plan: async () => [] } }, { text: "gombo" })).status).toBe(422);
    expect((await post({ store: new FakeStore() }, { text: " " })).status).toBe(422);
    expect((await post({ store: new FakeStore() }, { text: "gombo" })).status).toBe(503);
  });

  it("besoins : 7 au plus, quantité bornée", () => {
    const many = Array.from({ length: 9 }, (_, i) => ({ label: `p${i}`, query: `produit ${i}`, quantity: 40 }));
    const cleaned = cleanNeeds(many);
    expect(cleaned).toHaveLength(7);
    expect(cleaned[0]?.quantity).toBe(10);
  });
});
