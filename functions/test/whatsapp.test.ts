import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { hashLoginCode, type LoginCodeStore } from "../src/auth/google.js";
import { metaWhatsAppSender, type PhoneCodeStore, type WhatsAppDeps } from "../src/auth/whatsapp.js";

function deps(over: Partial<WhatsAppDeps> = {}) {
  const codes = new Map<string, string>();
  const logins: unknown[][] = [];
  const phones: PhoneCodeStore = {
    issue: async (phone, hash) => {
      codes.set(phone, hash);
      return { ok: true };
    },
    check: async (phone, hash) => (codes.get(phone) === hash ? "w22890112233@phone.dym.africa" : null),
  };
  const loginStore: LoginCodeStore = {
    issue: async (...args) => {
      logins.push(args);
    },
  };
  return { codes, logins, deps: { phones, logins: loginStore, code: () => "123456", ...over } as WhatsAppDeps };
}

const app = (d?: WhatsAppDeps) => createApp({ verifyToken: async () => ({ id: "u", claims: {} }), whatsapp: d });
const post = (a: ReturnType<typeof createApp>, path: string, body: unknown) =>
  a.request(path, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });

describe("connexion WhatsApp (spec 105)", () => {
  it("simulé : le code revient, puis ouvre une session par le pont", async () => {
    const { deps: d, logins } = deps({ simulated: true });
    const a = app(d);
    expect(await (await a.request("/v1/auth/whatsapp")).json()).toEqual({ available: true, simulated: true });
    const start = await post(a, "/v1/auth/whatsapp/start", { phone: "+22890112233" });
    expect(await start.json()).toEqual({ sent: true, simulated: true, code: "123456" });
    expect((await post(a, "/v1/auth/whatsapp/verify", { phone: "+22890112233", code: "000000" })).status).toBe(401);
    const ok = await post(a, "/v1/auth/whatsapp/verify", { phone: "+22890112233", code: "123456" });
    expect(ok.status).toBe(200);
    expect((await ok.json()).email).toBe("w22890112233@phone.dym.africa");
    expect(logins).toHaveLength(1);
  });

  it("avec Meta : le code part par WhatsApp et ne revient jamais", async () => {
    const sent: string[] = [];
    const { deps: d, codes } = deps({ sender: { send: async (_p, code) => void sent.push(code) } });
    const res = await post(app(d), "/v1/auth/whatsapp/start", { phone: "+22890112233" });
    expect(await res.json()).toEqual({ sent: true, simulated: false });
    expect(sent).toEqual(["123456"]);
    expect(codes.get("+22890112233")).toBe(hashLoginCode("123456"));
  });

  it("numéro invalide, trop d'envois, non configuré", async () => {
    const { deps: d } = deps({ simulated: true });
    expect((await post(app(d), "/v1/auth/whatsapp/start", { phone: "90112233" })).status).toBe(400);
    const limited = deps({ simulated: true }).deps;
    limited.phones.issue = async () => ({ ok: false, retryAfter: 120 });
    expect((await post(app(limited), "/v1/auth/whatsapp/start", { phone: "+22890112233" })).status).toBe(429);
    expect((await post(app(), "/v1/auth/whatsapp/start", { phone: "+22890112233" })).status).toBe(503);
    expect(await (await app().request("/v1/auth/whatsapp")).json()).toEqual({ available: false, simulated: false });
  });

  it("Meta : modèle d'authentification avec le code et le bouton", async () => {
    let body: Record<string, unknown> = {};
    const sender = metaWhatsAppSender(
      { token: "t", phoneNumberId: "42", template: "dym_code", language: "fr" },
      (async (_url: string, init: RequestInit) => {
        body = JSON.parse(String(init.body)) as Record<string, unknown>;
        return new Response("{}");
      }) as unknown as typeof fetch,
    );
    await sender.send("+22890112233", "654321");
    expect(body).toMatchObject({ to: "22890112233", type: "template", template: { name: "dym_code" } });
  });
});
