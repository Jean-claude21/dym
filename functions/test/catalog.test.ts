import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "jose";
import { beforeAll, beforeEach, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import type {
  CatalogStore,
  PhotoSigner,
  ProductSuggester,
  SuggestionContext,
} from "../src/catalog/ports.js";
import { createTokenVerifier } from "../src/lib/auth.js";
import { fromPgError } from "../src/lib/db.js";
import { httpErrors } from "../src/lib/errors.js";

const issuer = "https://auth.test";
const user = "6f1c2a3b-0000-4000-8000-000000000001";
const store = "9e2b5484-7bdd-4c08-a7b9-0a750f9de59b";
const boissons = "1b6a6b4e-0000-4000-8000-000000000009";
const key = `stores/${store}/products/0f4c1d2e-0000-4000-8000-000000000001.jpg`;

let token: string;
let verifyToken: ReturnType<typeof createTokenVerifier>;

beforeAll(async () => {
  const pair = await generateKeyPair("EdDSA", { extractable: true });
  const jwk = { ...(await exportJWK(pair.publicKey)), kid: "k1", alg: "EdDSA" };
  verifyToken = createTokenVerifier({ keys: createLocalJWKSet({ keys: [jwk] }), issuer });
  token = await new SignJWT({})
    .setProtectedHeader({ alg: "EdDSA", kid: "k1" })
    .setSubject(user)
    .setIssuer(issuer)
    .setIssuedAt()
    .setExpirationTime("15m")
    .sign(pair.privateKey);
});

class FakeStore implements CatalogStore {
  hasStore = true;
  context: SuggestionContext = {
    storeId: store,
    model: { provider: "openai", model: "gpt-5.4-mini", params: { temperature: 0.2 } },
    categories: [{ id: boissons, label: "Boissons" }],
  };
  recorded: unknown[] = [];

  async photoUploadStore(userId: string) {
    expect(userId).toBe(user);
    if (!this.hasStore) throw httpErrors.notFound("aucune boutique");
    return store;
  }

  async suggestionContext(_userId: string, objectKey: string) {
    if (!objectKey.startsWith(`stores/${store}/`)) throw httpErrors.forbidden("photo d'une autre boutique");
    return this.context;
  }

  async recordSuggestion(input: unknown) {
    this.recorded.push(input);
    return "5c0a0000-0000-4000-8000-000000000001";
  }
}

const signer: PhotoSigner = {
  presignPut: async (k, contentType, expires) => `https://s3.test/product-photos/${k}?sig&ct=${contentType}&e=${expires}`,
  publicUrl: (k) => `https://s3.test/product-photos/${k}`,
};

let fakeStore: FakeStore;
let suggester: ProductSuggester & { calls: unknown[]; fail?: boolean; categoryId?: string | null };

function app(options: { signer?: PhotoSigner | null; suggester?: ProductSuggester | null } = {}) {
  return createApp({
    verifyToken,
    catalog: {
      store: fakeStore,
      signer: options.signer === null ? undefined : (options.signer ?? signer),
      suggester: options.suggester === null ? undefined : (options.suggester ?? suggester),
    },
  });
}

const post = (a: ReturnType<typeof createApp>, path: string, body: unknown, auth = true) =>
  a.request(`http://fn.test${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(auth ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });

beforeEach(() => {
  fakeStore = new FakeStore();
  const calls: unknown[] = [];
  suggester = {
    calls,
    categoryId: boissons,
    async suggest(input) {
      calls.push(input);
      if (suggester.fail) throw new Error("délai dépassé");
      return {
        name: "  Jus de bissap 50 cl ",
        categoryId: suggester.categoryId ?? null,
        description: "Jus de bissap frais au gingembre.",
      };
    },
  };
});

describe("envoi de photo", () => {
  it("sans jeton : 401", async () => {
    const res = await post(app(), "/v1/catalog/photo-uploads", { content_type: "image/jpeg" }, false);
    expect(res.status).toBe(401);
  });

  it("clé sous le préfixe de la boutique, URL présignée et publique", async () => {
    const res = await post(app(), "/v1/catalog/photo-uploads", { content_type: "image/webp" });
    expect(res.status).toBe(200);
    const body = (await res.json()) as Record<string, string | number>;
    expect(body.object_key).toMatch(new RegExp(`^stores/${store}/products/[0-9a-f-]{36}\\.webp$`));
    expect(body.upload_url).toContain(String(body.object_key));
    expect(body.upload_url).toContain("ct=image/webp");
    expect(body.public_url).toBe(`https://s3.test/product-photos/${body.object_key}`);
    expect(body.expires_in).toBe(300);
  });

  it("type non accepté : 422", async () => {
    const res = await post(app(), "/v1/catalog/photo-uploads", { content_type: "image/gif" });
    expect(res.status).toBe(422);
  });

  it("sans boutique : 404", async () => {
    fakeStore.hasStore = false;
    const res = await post(app(), "/v1/catalog/photo-uploads", { content_type: "image/jpeg" });
    expect(res.status).toBe(404);
  });

  it("stockage non configuré : 503", async () => {
    const res = await post(app({ signer: null }), "/v1/catalog/photo-uploads", {
      content_type: "image/jpeg",
    });
    expect(res.status).toBe(503);
    expect(await res.json()).toMatchObject({ error: { code: "unavailable" } });
  });
});

describe("proposition", () => {
  it("nom, rayon et description proposés, puis conservés", async () => {
    const res = await post(app(), "/v1/catalog/suggestions", { object_key: key });
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({
      suggestion_id: "5c0a0000-0000-4000-8000-000000000001",
      name: "Jus de bissap 50 cl",
      category_id: boissons,
      description: "Jus de bissap frais au gingembre.",
    });
    expect(suggester.calls[0]).toMatchObject({
      imageUrl: `https://s3.test/product-photos/${key}`,
      model: { model: "gpt-5.4-mini" },
    });
    expect(fakeStore.recorded).toHaveLength(1);
  });

  it("rayon inconnu : ignoré", async () => {
    suggester.categoryId = "00000000-0000-4000-8000-000000000000";
    const res = await post(app(), "/v1/catalog/suggestions", { object_key: key });
    expect(((await res.json()) as { category_id: unknown }).category_id).toBeNull();
  });

  it("modèle inactif : 503, aucune valeur inventée", async () => {
    fakeStore.context = { ...fakeStore.context, model: null };
    const res = await post(app(), "/v1/catalog/suggestions", { object_key: key });
    expect(res.status).toBe(503);
    expect(suggester.calls).toHaveLength(0);
    expect(fakeStore.recorded).toHaveLength(0);
  });

  it("aucun fournisseur configuré : 503", async () => {
    const res = await post(app({ suggester: null }), "/v1/catalog/suggestions", { object_key: key });
    expect(res.status).toBe(503);
  });

  it("modèle en échec : 503, rien de conservé", async () => {
    suggester.fail = true;
    const res = await post(app(), "/v1/catalog/suggestions", { object_key: key });
    expect(res.status).toBe(503);
    expect(fakeStore.recorded).toHaveLength(0);
  });

  it("photo d'une autre boutique : 403", async () => {
    const other = key.replace(store, "00000000-0000-4000-8000-000000000000");
    const res = await post(app(), "/v1/catalog/suggestions", { object_key: other });
    expect(res.status).toBe(403);
  });

  it("clé invalide : 422", async () => {
    const res = await post(app(), "/v1/catalog/suggestions", { object_key: "../etc/passwd" });
    expect(res.status).toBe(422);
  });
});

describe("erreurs Postgres", () => {
  it("refus SQL traduits", () => {
    expect(fromPgError({ code: "42501", message: "x" })).toMatchObject({ status: 403 });
    expect(fromPgError({ code: "P0002", message: "x" })).toMatchObject({ status: 404 });
    expect(fromPgError({ code: "22023", message: "x" })).toMatchObject({ status: 422 });
    const other = new Error("connexion perdue");
    expect(fromPgError(other)).toBe(other);
  });
});
