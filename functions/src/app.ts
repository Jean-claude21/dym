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
  /** Push : file en base et fournisseur (spec 011). */
  push?: { queue: PushQueue; sender: PushSender };
}

/** App HTTP des Functions DYM. Les dépendances sont injectées (tests). */
export function createApp(deps: AppDeps) {
  const app = new Hono<{ Variables: AuthVariables }>();

  app.use(
    "*",
    cors({
      origin: deps.allowedOrigins ?? [],
      allowHeaders: ["Authorization", "Content-Type", "Idempotency-Key"],
      allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    }),
  );

  // Après tout geste réussi qui peut créer des notifications : envoi des push
  // en attente (un échec d'envoi ne fait jamais échouer le geste).
  app.use("/v1/*", async (c, next) => {
    await next();
    if (deps.push && c.req.method === "POST" && c.res.status < 400) {
      await dispatchPushes(deps.push.queue, deps.push.sender).catch((error) =>
        console.error("[push] file en échec", error),
      );
    }
  });

  app.onError((error, c) => {
    const http = toHttpError(error);
    if (http.status >= 500) console.error("[api]", error);
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

  return app;
}
