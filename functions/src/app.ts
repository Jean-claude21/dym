import { Hono } from "hono";
import { cors } from "hono/cors";
import { type AuthVariables, requireUser, type TokenVerifier } from "./lib/auth.js";
import { type CatalogDeps, registerCatalogRoutes } from "./catalog/routes.js";
import { type OrderDeps, registerOrderRoutes } from "./orders/routes.js";
import { type PaymentDeps, registerPaymentRoutes } from "./payments/routes.js";
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

  return app;
}
