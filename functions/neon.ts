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
        // Adresse publique des photos du catalogue (grande photo des push, spec 080).
        MEDIA_PUBLIC_URL: process.env.MEDIA_PUBLIC_URL ?? "",
        // Suivi des erreurs (Sentry, projet « dym-functions ») ; vide : rien n'est envoyé.
        ERROR_REPORTING_DSN: process.env.ERROR_REPORTING_DSN ?? "",
        // Appels réels du chat (LiveKit, spec 084) ; vides : appels simulés seulement.
        LIVEKIT_URL: process.env.LIVEKIT_URL ?? "",
        LIVEKIT_API_KEY: process.env.LIVEKIT_API_KEY ?? "",
        LIVEKIT_API_SECRET: process.env.LIVEKIT_API_SECRET ?? "",
        // Moneroo (spec 088) : clé secrète (bac à sable ou réelle) et secret des webhooks.
        MONEROO_SECRET_KEY: process.env.MONEROO_SECRET_KEY ?? "",
        MONEROO_WEBHOOK_SECRET: process.env.MONEROO_WEBHOOK_SECRET ?? "",
        // Bunny Stream (spec 101) : vidéo adaptative des contenus ; vide : vidéo d'origine.
        BUNNY_STREAM_LIBRARY_ID: process.env.BUNNY_STREAM_LIBRARY_ID ?? "",
        BUNNY_STREAM_API_KEY: process.env.BUNNY_STREAM_API_KEY ?? "",
        BUNNY_STREAM_CDN: process.env.BUNNY_STREAM_CDN ?? "",
        GOOGLE_CLIENT_IDS: process.env.GOOGLE_CLIENT_IDS ?? "",
        // Connexion WhatsApp (spec 105) : compte Meta ; WHATSAPP_SIMULATED=1 sur staging seulement.
        WHATSAPP_TOKEN: process.env.WHATSAPP_TOKEN ?? "",
        WHATSAPP_PHONE_NUMBER_ID: process.env.WHATSAPP_PHONE_NUMBER_ID ?? "",
        WHATSAPP_TEMPLATE: process.env.WHATSAPP_TEMPLATE ?? "",
        WHATSAPP_TEMPLATE_LANG: process.env.WHATSAPP_TEMPLATE_LANG ?? "",
        WHATSAPP_SIMULATED: process.env.WHATSAPP_SIMULATED ?? "",
        // Itinéraires (spec 109) : serveur OSRM ; vide = serveur public de démonstration.
        ROUTING_URL: process.env.ROUTING_URL ?? "",
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
    contentStreams: {
      type: "schedule",
      function: "api",
      functionPath: "/v1/jobs/content-streams",
      // Vidéos des contenus envoyées à Bunny puis suivies jusqu'à la lecture HLS (spec 101).
      cron: "*/5 * * * *",
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
