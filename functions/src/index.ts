// Point d'entrée de la Function `api` sur Neon (Node 24) : export par défaut
// d'un objet `fetch`, ici l'app Hono.
import { parseEnv } from "@neon/env";
import config from "../neon.js";
import { createApp } from "./app.js";
import { neonAuthVerifier } from "./lib/auth.js";

const env = parseEnv(config, "api");

export default createApp({
  verifyToken: neonAuthVerifier(env.auth),
  branch: process.env.NEON_BRANCH,
  allowedOrigins: env.function.ALLOWED_ORIGINS.split(",")
    .map((o) => o.trim())
    .filter(Boolean),
});
