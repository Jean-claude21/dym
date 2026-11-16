import { exportJWK, generateKeyPair, SignJWT, createLocalJWKSet } from "jose";
import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { createGoogleVerifier, hashLoginCode, type LoginCodeStore } from "../src/auth/google.js";

const CLIENT = "web-client.apps.googleusercontent.com";

async function keys() {
  const { publicKey, privateKey } = await generateKeyPair("RS256");
  const jwk = { ...(await exportJWK(publicKey)), kid: "k1", alg: "RS256" };
  const sign = (claims: Record<string, unknown>, aud = CLIENT, iss = "https://accounts.google.com") =>
    new SignJWT(claims)
      .setProtectedHeader({ alg: "RS256", kid: "k1" })
      .setIssuer(iss)
      .setAudience(aud)
      .setIssuedAt()
      .setExpirationTime("5m")
      .sign(privateKey);
  return { jwks: createLocalJWKSet({ keys: [jwk] }), sign };
}

function app(verify: ReturnType<typeof createGoogleVerifier>, issued: unknown[][]) {
  const store: LoginCodeStore = {
    issue: async (...args) => {
      issued.push(args);
    },
  };
  return createApp({
    verifyToken: async () => ({ id: "u", claims: {} }),
    google: { verify, store, code: () => "123456" },
  });
}

const post = (a: ReturnType<typeof createApp>, body: unknown) =>
  a.request("/v1/auth/google", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

describe("connexion Google (spec 102)", () => {
  it("jeton valide : code de connexion haché déposé pour l'e-mail", async () => {
    const { jwks, sign } = await keys();
    const issued: unknown[][] = [];
    const a = app(createGoogleVerifier({ keys: jwks, clientIds: [CLIENT] }), issued);
    const res = await post(a, { idToken: await sign({ email: "Awa@Gmail.com", email_verified: true, name: "Awa" }) });
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ email: "awa@gmail.com", code: "123456", name: "Awa" });
    expect(issued).toEqual([["awa@gmail.com", hashLoginCode("123456"), 120]]);
  });

  it("refuse un autre destinataire, un autre émetteur, un e-mail non vérifié", async () => {
    const { jwks, sign } = await keys();
    const issued: unknown[][] = [];
    const a = app(createGoogleVerifier({ keys: jwks, clientIds: [CLIENT] }), issued);
    for (const token of [
      await sign({ email: "a@gmail.com", email_verified: true }, "autre-client"),
      await sign({ email: "a@gmail.com", email_verified: true }, CLIENT, "https://evil.example"),
      await sign({ email: "a@gmail.com", email_verified: false }),
    ]) {
      expect((await post(a, { idToken: token })).status).toBe(401);
    }
    expect((await post(a, {})).status).toBe(400);
    expect(issued).toEqual([]);
  });

  it("haché comme Neon Auth (SHA-256 base64url)", () => {
    expect(hashLoginCode("123456")).toBe("jZae727K08KaOmKSgOaGzww_XVqGr_PKEgIMkjrcbJI");
  });

  it("sans configuration : indisponible", async () => {
    const res = await post(createApp({ verifyToken: async () => ({ id: "u", claims: {} }) }), { idToken: "x".repeat(30) });
    expect(res.status).toBe(503);
  });
});
