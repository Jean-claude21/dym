import { describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import type { OrderPhotoStore } from "../src/orders/photos.js";

const order = "a0000000-0000-4000-8000-000000000001";

const store: OrderPhotoStore = {
  party: async (userId) => (userId === "client" ? "client" : null),
  photoKeys: async () => [`orders/${order}/p1.jpg`],
};
const signer = {
  presignPut: async (key: string) => `https://put/${key}`,
  presignGet: async (key: string) => `https://get/${key}`,
};

const post = (user: string, path: string, body: unknown, withSigner = true) =>
  createApp({
    verifyToken: async () => ({ id: user, claims: {} }),
    orderPhotos: { store, signer: withSigner ? signer : undefined },
  }).request(`http://fn.test${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: "Bearer t" },
    body: JSON.stringify(body),
  });

describe("photos des commandes (spec 034)", () => {
  it("envoi : clé dans le dossier de la commande", async () => {
    const res = await post("client", `/v1/orders/${order}/photo-uploads`, { content_type: "image/jpeg" });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { object_key: string; upload_url: string };
    expect(body.object_key).toMatch(new RegExp(`^orders/${order}/[0-9a-f-]{36}\.jpg$`));
    expect(body.upload_url).toContain(body.object_key);
  });

  it("lecture : liens signés pour une partie seulement", async () => {
    const ok = await post("client", `/v1/orders/${order}/photos`, {});
    expect(((await ok.json()) as { urls: Record<string, string> }).urls).toEqual({
      [`orders/${order}/p1.jpg`]: `https://get/orders/${order}/p1.jpg`,
    });
    expect((await post("autre", `/v1/orders/${order}/photos`, {})).status).toBe(404);
  });

  it("format refusé ; stockage absent : 503", async () => {
    expect((await post("client", `/v1/orders/${order}/photo-uploads`, { content_type: "image/gif" })).status).toBe(422);
    expect((await post("client", `/v1/orders/${order}/photos`, {}, false)).status).toBe(503);
  });
});
