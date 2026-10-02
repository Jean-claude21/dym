// Politique Neon de DYM (Config-as-Code), lue par `neon dev` et `neon deploy`.
// Aucune valeur secrète ici : les secrets viennent de l'environnement de
// déploiement (`neon deploy --env <fichier non versionné>`).
import { defineConfig } from "@neon/config/v1";

/** Photos des produits : lecture publique, écriture par URL présignée. */
export const PRODUCT_PHOTOS_BUCKET = "product-photos";

export default defineConfig({
  auth: true,
  dataApi: true,
  buckets: {
    [PRODUCT_PHOTOS_BUCKET]: { access: "public_read" },
  },
  functions: {
    // Une Function HTTP unique, routée par Hono (src/app.ts).
    api: {
      name: "DYM API",
      source: "./src/index.ts",
      env: {
        // Origines web autorisées (admin), séparées par des virgules.
        ALLOWED_ORIGINS: process.env.ALLOWED_ORIGINS ?? "",
        // Proposition « photo → fiche » (spec 007). Vide : saisie manuelle.
        OPENAI_API_KEY: process.env.OPENAI_API_KEY ?? "",
      },
    },
  },
  branch: (branch) => ({
    protected: branch.name === "main",
    ...(branch.isDefault ? {} : { ttl: "7d" }),
  }),
});
