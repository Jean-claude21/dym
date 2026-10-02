import pg from "pg";
import { afterAll, describe, expect, it } from "vitest";
import { pgOrderStore } from "../src/orders/adapters.js";

// Adaptateur Postgres contre une vraie base (`TEST_DATABASE_URL`, migrations
// appliquées) ; ignoré sinon. Les cas métier sont couverts par pgTAP (062).
const url = process.env.TEST_DATABASE_URL;
const pool = url ? new pg.Pool({ connectionString: url, max: 2 }) : undefined;

afterAll(async () => {
  await pool?.end();
});

describe.skipIf(!pool)("commandes · Postgres", () => {
  it("panier vide : 422 cart_empty", async () => {
    await expect(
      pgOrderStore(pool!).placeOrder(
        "00000000-0000-4000-8000-0000000000ff",
        "d0000000-0000-4000-8000-0000000000ff",
        {
          addressId: null,
          modes: {},
          paymentMethodId: "00000000-0000-4000-8000-000000000000",
          substitutionAllowed: true,
          expectedTotalMinor: null,
        },
        [],
      ),
    ).rejects.toMatchObject({ status: 422, message: "cart_empty" });
  });
});
