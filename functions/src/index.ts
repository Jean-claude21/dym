// Point d'entrée de la Function `api` sur Neon (Node 24) : export par défaut
// d'un objet `fetch`, ici l'app Hono.
import { parseEnv } from "@neon/env";
import config, { PRODUCT_PHOTOS_BUCKET } from "../neon.js";
import { createApp } from "./app.js";
import {
  aiProductSuggester,
  openAiProviders,
  pgCatalogStore,
  s3PhotoSigner,
} from "./catalog/adapters.js";
import { neonAuthVerifier } from "./lib/auth.js";
import { createPool } from "./lib/db.js";

const env = parseEnv(config, "api");
const pool = createPool(env.postgres.databaseUrl);
const openAiKey = env.function.OPENAI_API_KEY;

export default createApp({
  verifyToken: neonAuthVerifier(env.auth),
  branch: process.env.NEON_BRANCH,
  allowedOrigins: env.function.ALLOWED_ORIGINS.split(",")
    .map((o) => o.trim())
    .filter(Boolean),
  catalog: {
    store: pgCatalogStore(pool),
    signer: s3PhotoSigner({ ...env.storage, bucket: PRODUCT_PHOTOS_BUCKET }),
    suggester: openAiKey ? aiProductSuggester(openAiProviders(openAiKey)) : undefined,
  },
});
