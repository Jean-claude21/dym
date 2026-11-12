// Politique Neon de DYM (Config-as-Code), lue par `neon dev` et `neon deploy`.
// Aucune valeur secrète ici : les secrets viennent de l'environnement de
// déploiement (`neon deploy --env <fichier non versionné>`).
import { defineConfig } from "@neon/config/v1";

/** Photos des produits : lecture publique, écriture par URL présignée. */
export const PRODUCT_PHOTOS_BUCKET = "product-photos";

/** Images des conversations : privées, lues par liens signés courts. */
export const CHAT_MEDIA_BUCKET = "chat-media";

export default defineConfig({
  auth: true,
  // Rôle anonyme : lectures publiques sans session (visiteuse), sous RLS.
  dataApi: { settings: { dbAnonRole: "anonymous" } },
  buckets: {
    [PRODUCT_PHOTOS_BUCKET]: { access: "public_read" },
    [CHAT_MEDIA_BUCKET]: { access: "private" },
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
  triggers: {
    dispatchWatch: {
      type: "schedule",
      function: "api",
      functionPath: "/v1/jobs/dispatch-watch",
      // SQL refuse les commandes sans réponse et relance les livreurs selon les délais du pays (spec 066).
      cron: "*/5 * * * *",
      enabled: true,
    },
    vendorRecaps: {
      type: "schedule",
      function: "api",
      functionPath: "/v1/jobs/vendor-recaps",
      // SQL applique 19 h dans chaque fuseau ; un seul récap par boutique/jour.
      cron: "*/15 * * * *",
      enabled: true,
    },
    shoppingReminders: {
      type: "schedule",
      function: "api",
      functionPath: "/v1/jobs/shopping-reminders",
      // SQL applique 8 h dans chaque fuseau ; un seul rappel par échéance (spec 029).
      cron: "*/15 * * * *",
      enabled: true,
    },
    affiliateSettlement: {
      type: "schedule",
      function: "api",
      functionPath: "/v1/jobs/affiliate-settlement",
      // SQL verse les commissions dont le délai de réclamation est passé, une fois chacune (spec 039).
      cron: "*/15 * * * *",
      enabled: true,
    },
    fraudSignals: {
      type: "schedule",
      function: "api",
      functionPath: "/v1/jobs/fraud-signals",
      // Règles SQL des dernières 24 h ; un signal par règle, sujet et jour (spec 054).
      cron: "*/15 * * * *",
      enabled: true,
    },
    moderationTriage: {
      type: "schedule",
      function: "api",
      functionPath: "/v1/jobs/moderation-triage",
      // Avis de l'IA sur les signalements sans avis ; l'équipe décide (spec 054).
      cron: "*/15 * * * *",
      enabled: true,
    },
  },
  // prévisualisation (une par PR) expirent après 7 jours. La Data API refuse
  // les branches qui expirent : elle n'y est donc pas exposée.
  branch: (branch) => ({
    protected: branch.name === "main",
    ...(branch.isDefault || branch.name === "staging" ? {} : { ttl: "7d" }),
  }),
});
