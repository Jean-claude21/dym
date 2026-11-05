// Politique Neon de DYM (Config-as-Code), lue par `neon dev` et `neon deploy`.
// Aucune valeur secrète ici : les secrets viennent de l'environnement de
// déploiement (`neon deploy --env <fichier non versionné>`).
import { defineConfig } from "@neon/config/v1";

/** Photos des produits : lecture publique, écriture par URL présignée. */
export const PRODUCT_PHOTOS_BUCKET = "product-photos";

export default defineConfig({
  auth: true,
  // Rôle anonyme : lectures publiques sans session (visiteuse), sous RLS.
  dataApi: { settings: { dbAnonRole: "anonymous" } },
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
        // Fournisseur de paiement simulé (spec 010) : jamais en production.
        PAYMENTS_SIMULATOR_SECRET: process.env.PAYMENTS_SIMULATOR_SECRET ?? "",
        // Compte de service Firebase (JSON) pour les push FCM (spec 011).
        FCM_SERVICE_ACCOUNT: process.env.FCM_SERVICE_ACCOUNT ?? "",
      },
    },
  },
  // `main` (production) et `staging` sont durables ; les branches de
  // prévisualisation (une par PR) expirent après 7 jours. La Data API refuse
  // les branches qui expirent : elle n'y est donc pas exposée.
  branch: (branch) => ({
    protected: branch.name === "main",
    ...(branch.isDefault || branch.name === "staging" ? {} : { ttl: "7d" }),
  }),
});
