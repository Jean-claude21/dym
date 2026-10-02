import pg from "pg";
import { afterAll, describe, expect, it } from "vitest";
import { pgCatalogStore } from "../src/catalog/adapters.js";

// Adaptateur Postgres contre une vraie base (`TEST_DATABASE_URL`, migrations
// appliquées) ; ignoré sinon.
const url = process.env.TEST_DATABASE_URL;
const pool = url ? new pg.Pool({ connectionString: url, max: 2 }) : undefined;

afterAll(async () => {
  await pool?.end();
});

describe.skipIf(!pool)("catalogue · Postgres", () => {
  const store = () => pgCatalogStore(pool!);
  const nobody = "00000000-0000-4000-8000-0000000000ff";

  it("sans boutique : 404", async () => {
    await expect(store().photoUploadStore(nobody)).rejects.toMatchObject({ status: 404 });
  });

  it("proposition sans boutique : 404", async () => {
    await expect(
      store().suggestionContext(
        nobody,
        `stores/${nobody}/products/00000000-0000-4000-8000-000000000001.jpg`,
      ),
    ).rejects.toMatchObject({ status: 404 });
  });
});
