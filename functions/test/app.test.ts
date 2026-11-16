import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "jose";
import { beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import { createApp } from "../src/app.js";
import { createTokenVerifier } from "../src/lib/auth.js";
import { parseBody } from "../src/lib/validate.js";

const issuer = "https://auth.test";
let privateKey: CryptoKey;
let otherKey: CryptoKey;
let app: ReturnType<typeof createApp>;

async function jwt(
  claims: Record<string, unknown>,
  options: { key?: CryptoKey; expiresIn?: string; iss?: string } = {},
) {
  return new SignJWT(claims)
    .setProtectedHeader({ alg: "EdDSA", kid: "k1" })
    .setIssuer(options.iss ?? issuer)
    .setIssuedAt()
    .setExpirationTime(options.expiresIn ?? "15m")
    .sign(options.key ?? privateKey);
}

beforeAll(async () => {
  const pair = await generateKeyPair("EdDSA", { extractable: true });
  privateKey = pair.privateKey;
  otherKey = (await generateKeyPair("EdDSA")).privateKey;
  const jwk = { ...(await exportJWK(pair.publicKey)), kid: "k1", alg: "EdDSA" };
  app = createApp({
    verifyToken: createTokenVerifier({
      keys: createLocalJWKSet({ keys: [jwk] }),
      issuer,
    }),
    branch: "preview",
  });
  app.post("/echo", async (c) => {
    const body = await parseBody(
      c,
      z.object({ name: z.string().min(1), qty: z.number().int().positive() }),
    );
    return c.json(body);
  });
});

const call = (path: string, init?: RequestInit) =>
  app.request(`http://fn.test${path}`, init);

describe("santé", () => {
  it("répond sans jeton, avec la branche", async () => {
    const res = await call("/health");
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ status: "ok", branch: "preview", features: { google: false } });
  });

  it("route inconnue : 404 normalisé", async () => {
    const res = await call("/nulle-part");
    expect(res.status).toBe(404);
    expect(await res.json()).toMatchObject({ error: { code: "not_found" } });
  });
});

describe("authentification (US3)", () => {
  it("sans jeton : 401 normalisé", async () => {
    const res = await call("/me");
    expect(res.status).toBe(401);
    expect(await res.json()).toMatchObject({
      error: { code: "unauthenticated" },
    });
  });

  it("jeton valide : identité", async () => {
    const token = await jwt({ sub: "user-1" });
    const res = await call("/me", {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ userId: "user-1" });
  });

  it.each([
    ["expiré", async () => jwt({ sub: "u" }, { expiresIn: "-1m" })],
    ["mauvaise clé", async () => jwt({ sub: "u" }, { key: otherKey })],
    ["mauvais émetteur", async () => jwt({ sub: "u" }, { iss: "https://x" })],
    ["sans sujet", async () => jwt({})],
  ])("jeton %s : 401", async (_, make) => {
    const res = await call("/me", {
      headers: { Authorization: `Bearer ${await make()}` },
    });
    expect(res.status).toBe(401);
  });
});

describe("validation des entrées", () => {
  const post = (body: string) =>
    call("/echo", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
    });

  it("corps valide", async () => {
    const res = await post(JSON.stringify({ name: "gari", qty: 2 }));
    expect(res.status).toBe(200);
  });

  it("champs invalides : 422 avec les champs", async () => {
    const res = await post(JSON.stringify({ name: "", qty: -1 }));
    expect(res.status).toBe(422);
    const body = (await res.json()) as {
      error: { code: string; fields: Record<string, string> };
    };
    expect(body.error.code).toBe("validation");
    expect(Object.keys(body.error.fields).sort()).toEqual(["name", "qty"]);
  });

  it("JSON illisible : 400", async () => {
    const res = await post("{pas du json");
    expect(res.status).toBe(400);
  });
});
