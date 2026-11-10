import { describe, expect, it, vi } from "vitest";
import { createApp } from "../src/app.js";
import type { DraftContext, OpsAssistStore, TriageItem } from "../src/ops/assist.js";

const delivery = (name: string) => ({
  version: 1,
  invocation_id: "job-1",
  trigger: { type: "schedule", id: "t9", name },
  data: { scheduled_at: "2026-11-10T10:15:00Z" },
});

const model = { provider: "openai", model: "m", params: {} };
const item: TriageItem = {
  target_type: "product",
  target_id: "11111111-1111-4111-8111-111111111111",
  reasons: ["misleading"],
  notes: [],
  text: "Igname",
};
const context: DraftContext = {
  model,
  subject: "order",
  app: "client",
  locale: "fr",
  order_status: "out_for_delivery",
  messages: [{ role: "user", body: "Ma commande n'est pas arrivée" }],
};

function fakeStore(overrides: Partial<OpsAssistStore> = {}): OpsAssistStore {
  return {
    detectFraud: vi.fn(async () => 2),
    reportsToTriage: vi.fn(async () => ({ model, items: [item, { ...item, target_id: "x" }] })),
    recordTriage: vi.fn(async () => {}),
    draftContext: vi.fn(async () => context),
    ...overrides,
  };
}

const job = (app: ReturnType<typeof createApp>, path: string, invocation?: string) =>
  app.request(`http://test/v1/jobs/${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(invocation ? { "x-neon-trigger-invocation-id": invocation } : {}),
    },
    body: JSON.stringify(delivery(path)),
  });

describe("antifraude et modération assistées (spec 054)", () => {
  it("job de fraude : invocation vérifiée, règles en SQL", async () => {
    const store = fakeStore();
    const app = createApp({ verifyToken: async () => ({ id: "u1", claims: {} }), opsAssist: { store } });
    expect((await job(app, "fraud-signals")).status).toBe(401);
    expect(store.detectFraud).not.toHaveBeenCalled();
    const response = await job(app, "fraud-signals", "job-1");
    expect(await response.json()).toEqual({ signals: 2 });
  });

  it("tri : sans IA, rien n'est jugé", async () => {
    const store = fakeStore();
    const app = createApp({ verifyToken: async () => ({ id: "u1", claims: {} }), opsAssist: { store } });
    expect(await (await job(app, "moderation-triage", "job-1")).json()).toEqual({ triaged: 0, ai: false });
    expect(store.recordTriage).not.toHaveBeenCalled();
  });

  it("tri : un avis par signalement, un échec n'arrête pas la file", async () => {
    const store = fakeStore();
    const judge = {
      judge: vi
        .fn()
        .mockResolvedValueOnce({ verdict: "remove", reason: "Photo trompeuse" })
        .mockRejectedValueOnce(new Error("panne")),
    };
    const app = createApp({ verifyToken: async () => ({ id: "u1", claims: {} }), opsAssist: { store, judge } });
    expect(await (await job(app, "moderation-triage", "job-1")).json()).toEqual({ triaged: 1, ai: true });
    expect(store.recordTriage).toHaveBeenCalledWith(item, "remove", "Photo trompeuse", "m");
  });
});

describe("agent support (spec 054)", () => {
  const post = (app: ReturnType<typeof createApp>, id: string, token = true) =>
    app.request(`http://test/v1/admin/tickets/${id}/draft`, {
      method: "POST",
      headers: token ? { Authorization: "Bearer t" } : {},
    });
  const ticket = "22222222-2222-4222-8222-222222222222";

  it("connexion exigée ; brouillon rédigé pour l'admin", async () => {
    const store = fakeStore();
    const drafter = { draft: vi.fn(async () => "Bonjour Awa, nous regardons votre commande.") };
    const app = createApp({ verifyToken: async () => ({ id: "admin-1", claims: {} }), opsAssist: { store, drafter } });
    expect((await post(app, ticket, false)).status).toBe(401);
    const response = await post(app, ticket);
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ draft: "Bonjour Awa, nous regardons votre commande." });
    expect(store.draftContext).toHaveBeenCalledWith("admin-1", ticket);
  });

  it("sans modèle actif : indisponible, rien d'inventé", async () => {
    const store = fakeStore({ draftContext: vi.fn(async () => ({ ...context, model: null })) });
    const drafter = { draft: vi.fn(async () => "x") };
    const app = createApp({ verifyToken: async () => ({ id: "admin-1", claims: {} }), opsAssist: { store, drafter } });
    expect((await post(app, ticket)).status).toBe(503);
    expect(drafter.draft).not.toHaveBeenCalled();
  });

  it("identifiant invalide : introuvable", async () => {
    const app = createApp({ verifyToken: async () => ({ id: "admin-1", claims: {} }), opsAssist: { store: fakeStore() } });
    expect((await post(app, "abc")).status).toBe(404);
  });
});
