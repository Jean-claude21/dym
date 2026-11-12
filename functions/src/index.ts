// Point d'entrée de la Function `api` sur Neon (Node 24) : export par défaut
// d'un objet `fetch`, ici l'app Hono.
import { parseEnv } from "@neon/env";
import config, { CHAT_MEDIA_BUCKET, PRODUCT_PHOTOS_BUCKET } from "../neon.js";
import { createApp } from "./app.js";
import { sentryReporter } from "./lib/report.js";
import {
  aiProductSuggester,
  openAiProviders,
  pgCatalogStore,
  s3PhotoSigner,
} from "./catalog/adapters.js";
import { neonAuthVerifier } from "./lib/auth.js";
import { createPool } from "./lib/db.js";
import { pgOrderStore } from "./orders/adapters.js";
import { pgLifecycleStore } from "./orders/lifecycle.js";
import { pgDisputeStore } from "./disputes/routes.js";
import { pgAdminStore } from "./admin/routes.js";
import { fcmPushSender, noPushSender, pgPushQueue } from "./notifications/push.js";
import { pgPaymentStore } from "./payments/adapters.js";
import { availableProviders } from "./payments/simulator.js";
import { walletProvider } from "./payments/wallet.js";
import { pgVendorRecaps } from "./dashboard/recaps.js";
import { pgDispatchWatch } from "./orders/dispatch.js";
import { LiveHub, pgLiveStore } from "./live/gateway.js";
import { pgMessagingStore, s3MediaSigner } from "./messaging/routes.js";
import { pgReviewStore } from "./reviews/routes.js";
import {
  aiPhotoDescriber,
  aiTranscriber,
  openAiSearchFactories,
  pgSearchAiStore,
} from "./search/adapters.js";
import { aiIntentPlanner, openAiPlannerProviders, pgCopilotStore } from "./copilot/routes.js";
import { pgBroadcastStore } from "./broadcast/routes.js";
import { pgShoppingReminders } from "./shopping/reminders.js";
import { pgAffiliateSettlement } from "./content/affiliation.js";
import { aiReportJudge, aiSupportDrafter, openAiAssistProviders, pgOpsAssistStore } from "./ops/assist.js";
import { pgOrderPhotoStore } from "./orders/photos.js";
import { aiContentClassifier, openAiClassifierProviders, pgCreatorContentStore } from "./content/creators.js";
import { pgTikTokStore, tiktokOEmbedProvider } from "./content/tiktok.js";

// Mode filtré : seules les variables de la plateforme utilisées sont exigées.
// Les variables propres à la Function sont facultatives (vides : désactivées).
const env = parseEnv(config, [
  "DATABASE_URL",
  "NEON_AUTH_BASE_URL",
  "NEON_AUTH_JWKS_URL",
  "AWS_ACCESS_KEY_ID",
  "AWS_SECRET_ACCESS_KEY",
  "AWS_ENDPOINT_URL_S3",
  "AWS_REGION",
]);
const pool = createPool(env.postgres.databaseUrl);
const openAiKey = process.env.OPENAI_API_KEY ?? "";
const allowedOrigins = process.env.ALLOWED_ORIGINS ?? "";
const searchModels = openAiKey ? openAiSearchFactories(openAiKey) : undefined;

const errorDsn = process.env.ERROR_REPORTING_DSN ?? "";

export default createApp({
  reportError: errorDsn
    ? sentryReporter(errorDsn, { environment: process.env.NEON_BRANCH })
    : undefined,
  verifyToken: neonAuthVerifier(env.auth),
  branch: process.env.NEON_BRANCH,
  allowedOrigins: allowedOrigins
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean),
  catalog: {
    store: pgCatalogStore(pool),
    signer: s3PhotoSigner({ ...env.storage, bucket: PRODUCT_PHOTOS_BUCKET }),
    suggester: openAiKey ? aiProductSuggester(openAiProviders(openAiKey)) : undefined,
  },
  orders: { store: pgOrderStore(pool) },
  lifecycle: pgLifecycleStore(pool),
  disputes: pgDisputeStore(pool),
  admin: pgAdminStore(pool),
  recaps: pgVendorRecaps(pool),
  dispatchWatch: pgDispatchWatch(pool),
  live: new LiveHub(pgLiveStore(pool)),
  shoppingReminders: pgShoppingReminders(pool),
  affiliateSettlement: pgAffiliateSettlement(pool),
  opsAssist: {
    store: pgOpsAssistStore(pool),
    judge: openAiKey ? aiReportJudge(openAiAssistProviders(openAiKey)) : undefined,
    drafter: openAiKey ? aiSupportDrafter(openAiAssistProviders(openAiKey)) : undefined,
  },
  creatorContent: {
    store: pgCreatorContentStore(pool),
    signer: s3PhotoSigner({ ...env.storage, bucket: PRODUCT_PHOTOS_BUCKET }),
    classifier: openAiKey ? aiContentClassifier(openAiClassifierProviders(openAiKey)) : undefined,
  },
  tiktok: {
    store: pgTikTokStore(pool),
    provider: tiktokOEmbedProvider(),
    signer: s3PhotoSigner({ ...env.storage, bucket: PRODUCT_PHOTOS_BUCKET }),
    // L'app web est la première origine autorisée.
    webUrl: allowedOrigins.split(",").map((o) => o.trim()).find(Boolean),
  },
  orderPhotos: {
    store: pgOrderPhotoStore(pool),
    signer: s3MediaSigner({ ...env.storage, bucket: CHAT_MEDIA_BUCKET }),
  },
  reviews: pgReviewStore(pool),
  searchAi: {
    store: pgSearchAiStore(pool),
    transcriber: searchModels ? aiTranscriber(searchModels) : undefined,
    describer: searchModels ? aiPhotoDescriber(searchModels) : undefined,
  },
  broadcasts: pgBroadcastStore(pool),
  copilot: {
    store: pgCopilotStore(pool),
    planner: openAiKey ? aiIntentPlanner(openAiPlannerProviders(openAiKey)) : undefined,
  },
  messaging: {
    store: pgMessagingStore(pool),
    signer: s3MediaSigner({ ...env.storage, bucket: CHAT_MEDIA_BUCKET }),
  },
  // Push : FCM dès que le compte de service est fourni ; sinon ignorés.
  push: {
    queue: pgPushQueue(pool),
    sender: process.env.FCM_SERVICE_ACCOUNT ? fcmPushSender(process.env.FCM_SERVICE_ACCOUNT) : noPushSender,
  },
  payments: {
    store: pgPaymentStore(pool),
    // Simulateur : secret présent et branche hors production (spec 010).
    providers: [
      // Wallet DYM : rail interne, toujours disponible (spec 025).
      walletProvider(),
      ...availableProviders({
        branch: process.env.NEON_BRANCH,
        simulatorSecret: process.env.PAYMENTS_SIMULATOR_SECRET ?? "",
      }),
    ],
  },
});
