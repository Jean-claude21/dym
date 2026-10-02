// Politique Neon de DYM (Config-as-Code), lue par `neon dev` et `neon deploy`.
// Aucune valeur secrète ici : les secrets viennent de l'environnement de
// déploiement (`neon deploy --env <fichier non versionné>`).
import { defineConfig } from "@neon/config/v1";

export default defineConfig({
  auth: true,
  dataApi: true,
  functions: {
    // Une Function HTTP unique, routée par Hono (src/app.ts).
    api: {
      name: "DYM API",
      source: "./src/index.ts",
      env: {
        // Origines web autorisées (admin), séparées par des virgules.
        ALLOWED_ORIGINS: process.env.ALLOWED_ORIGINS ?? "",
      },
    },
  },
  branch: (branch) => ({
    protected: branch.name === "main",
    ...(branch.isDefault ? {} : { ttl: "7d" }),
  }),
});
