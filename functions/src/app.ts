import { Hono } from "hono";
import { cors } from "hono/cors";
import { type AuthVariables, requireUser, type TokenVerifier } from "./lib/auth.js";
import { type CatalogDeps, registerCatalogRoutes } from "./catalog/routes.js";
import { type OrderDeps, registerOrderRoutes } from "./orders/routes.js";
import { type PaymentDeps, registerPaymentRoutes } from "./payments/routes.js";
import { type LifecycleStore, registerLifecycleRoutes } from "./orders/lifecycle.js";
import { type DisputeStore, registerDisputeRoutes } from "./disputes/routes.js";
import { type AdminStore, registerAdminRoutes } from "./admin/routes.js";
import { dispatchPushes, type PushQueue, type PushSender } from "./notifications/push.js";
import { httpErrors, toHttpError } from "./lib/errors.js";
import type { ErrorReporter } from "./lib/report.js";
import { registerVendorRecaps, type VendorRecaps } from "./dashboard/recaps.js";
import { type DispatchWatch, registerDispatchWatch } from "./orders/dispatch.js";
import { type LiveHub, registerLiveGateway } from "./live/gateway.js";
import { registerShoppingReminders, type ShoppingReminders } from "./shopping/reminders.js";
import { registerAffiliateSettlement, type AffiliateSettlement } from "./content/affiliation.js";
import { type OpsAssistDeps, registerOpsAssist } from "./ops/assist.js";
import { type OrderPhotoDeps, registerOrderPhotoRoutes } from "./orders/photos.js";
import { type CallDeps, registerCallRoutes } from "./messaging/calls.js";
import { type MessagingDeps, registerMessagingRoutes } from "./messaging/routes.js";
import { registerReviewRoutes, type ReviewStore } from "./reviews/routes.js";
import { registerSearchAiRoutes, type SearchAiDeps } from "./search/routes.js";
import { type CopilotDeps, registerCopilotRoutes } from "./copilot/routes.js";
import { type CreatorContentDeps, registerCreatorContentRoutes } from "./content/creators.js";
import { registerTikTokRoutes, type TikTokDeps } from "./content/tiktok.js";
import { registerContentRoutes } from "./content/routes.js";
import { type BroadcastStore, registerBroadcastRoutes } from "./broadcast/routes.js";

export interface AppDeps {
  verifyToken: TokenVerifier;
  /** Nom de la branche Neon (NEON_BRANCH). */
  branch?: string;
  /** Origines web autorisées (admin). Les apps mobiles n'en ont pas besoin. */
  allowedOrigins?: string[];
  /** Catalogue (spec 007) ; absent : routes en 503. */
  catalog?: CatalogDeps;
  /** Commandes (spec 009) ; absent : routes en 503. */
  orders?: OrderDeps;
  /** Paiements en ligne (spec 010) ; absent : cash seulement. */
  payments?: PaymentDeps;
  /** Cycle de vie des commandes (spec 011). */
  lifecycle?: LifecycleStore;
  /** Litiges (spec 012). */
  disputes?: DisputeStore;
  /** Admin des opérations (spec 013). */
  admin?: AdminStore;
  recaps?: VendorRecaps;
  /** Refus automatiques et relances de livreurs (spec 066). */
  dispatchWatch?: DispatchWatch;
  /** Passerelle temps réel (spec 067). */
  live?: LiveHub;
  /** Contenus des créatrices (spec 036). */
  creatorContent?: CreatorContentDeps;
  /** Pont TikTok et liens de partage (spec 040). */
  tiktok?: TikTokDeps;
  /** Photos des commandes (spec 034). */
  orderPhotos?: OrderPhotoDeps;
  /** Rappels des courses récurrentes (spec 029). */
  shoppingReminders?: ShoppingReminders;
  /** Versement des commissions d'affiliation (spec 039). */
  affiliateSettlement?: AffiliateSettlement;
  /** Antifraude, tri des signalements et brouillons du support (spec 054). */
  opsAssist?: OpsAssistDeps;
  /** Messagerie (spec 015). */
  messaging?: MessagingDeps;
  /** Appels réels (spec 084). */
  calls?: CallDeps;
  /** Avis (spec 016). */
  reviews?: ReviewStore;
  /** Recherche vocale et par photo (spec 018). */
  searchAi?: SearchAiDeps;
  /** Copilote d'intention (spec 019). */
  copilot?: CopilotDeps;
  /** Relance des clientes (spec 021). */
  broadcasts?: BroadcastStore;
  /** Suivi des erreurs 5xx (constitution IX) ; absent : journal seulement. */
  reportError?: ErrorReporter;
  /** Push : file en base et fournisseur (spec 011). */
  push?: { queue: PushQueue; sender: PushSender; mediaBase?: string };
}

/** App HTTP des Functions DYM. Les dépendances sont injectées (tests). */
export function createApp(deps: AppDeps) {
  const app = new Hono<{ Variables: AuthVariables }>();

  const corsMiddleware = cors({
    origin: deps.allowedOrigins ?? [],
    allowHeaders: ["Authorization", "Content-Type", "Idempotency-Key"],
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  });
  // CORS casse la poignée de main WebSocket (doc Neon) : pas sur /v1/live.
  app.use("*", (c, next) => (c.req.path === "/v1/live" ? next() : corsMiddleware(c, next)));

  // Après tout geste réussi qui peut créer des notifications : envoi des push
  // en attente (un échec d'envoi ne fait jamais échouer le geste).
  app.use("/v1/*", async (c, next) => {
    await next();
    if (deps.push && c.req.method === "POST" && c.res.status < 400) {
      await dispatchPushes(deps.push.queue, deps.push.sender, 50, deps.push.mediaBase).catch((error) =>
        console.error("[push] file en échec", error),
      );
    }
  });

  app.onError((error, c) => {
    const http = toHttpError(error);
    if (http.status >= 500) {
      console.error("[api]", error);
      void deps.reportError?.(error, { method: c.req.method, path: c.req.path });
    }
    return c.json(http.toBody(), http.status);
  });
  app.notFound((c) => {
    const http = httpErrors.notFound("route inconnue");
    return c.json(http.toBody(), http.status);
  });

  // Santé (sans jeton) : vérifie le déploiement et la branche.
  app.get("/health", (c) =>
    c.json({ status: "ok", branch: deps.branch ?? null }),
  );

  // Identité (avec jeton) : vérifie la chaîne Neon Auth → Function (spec 003, US5).
  app.get("/me", requireUser(deps.verifyToken), (c) =>
    c.json({ userId: c.get("user").id }),
  );

  registerCatalogRoutes(app, deps.verifyToken, deps.catalog);
  registerOrderRoutes(app, deps.verifyToken, deps.orders, deps.payments);
  registerPaymentRoutes(app, deps.verifyToken, deps.payments);
  registerLifecycleRoutes(app, deps.verifyToken, deps.lifecycle);
  registerDisputeRoutes(app, deps.verifyToken, deps.disputes);
  registerAdminRoutes(app, deps.verifyToken, deps.admin, deps.payments?.providers ?? []);
  registerVendorRecaps(app, deps.recaps);
  registerDispatchWatch(app, deps.dispatchWatch);
  registerLiveGateway(app, deps.verifyToken, deps.live);
  registerShoppingReminders(app, deps.shoppingReminders);
  registerAffiliateSettlement(app, deps.affiliateSettlement);
  registerOpsAssist(app, deps.verifyToken, deps.opsAssist);
  registerOrderPhotoRoutes(app, deps.verifyToken, deps.orderPhotos);
  registerMessagingRoutes(app, deps.verifyToken, deps.messaging);
  registerCallRoutes(app, deps.verifyToken, deps.calls);
  registerReviewRoutes(app, deps.verifyToken, deps.reviews);
  registerSearchAiRoutes(app, deps.verifyToken, deps.searchAi);
  registerCopilotRoutes(app, deps.verifyToken, deps.copilot);
  registerContentRoutes(app, deps.verifyToken, deps.catalog);
  registerCreatorContentRoutes(app, deps.verifyToken, deps.creatorContent);
  registerTikTokRoutes(app, deps.verifyToken, deps.tiktok);
  registerBroadcastRoutes(app, deps.verifyToken, deps.broadcasts);

  return app;
}
