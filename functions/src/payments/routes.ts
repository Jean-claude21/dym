import type { Context, Hono } from "hono";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";
import type { Purchase } from "../orders/ports.js";
import type { PaymentOutcome, PaymentProvider, PaymentStore } from "./ports.js";
import { SIMULATOR, SIMULATOR_SIGNATURE_HEADER, simulatorProvider } from "./simulator.js";

export interface PaymentDeps {
  store: PaymentStore;
  /** Fournisseurs en ligne disponibles dans ce déploiement. */
  providers: PaymentProvider[];
}

const uuid = z.string().uuid();

/** Paiement courant d'un achat, tel que servi par `app.purchase_json`. */
interface PurchasePayment {
  id: string;
  status: string;
  provider_code: string;
  checkout_url: string | null;
  amount_minor: number;
  reference: string;
}

/** Origine publique de la Function, vue par la requête. */
export const selfOrigin = (c: Context) => new URL(c.req.url).origin;

/**
 * Initie la tentative en attente d'un achat (sans page de paiement) chez son
 * fournisseur. Échec du fournisseur : la tentative passe en échec et la
 * commande est gardée (l'app affiche l'écran 40).
 */
export async function initiatePending(
  deps: PaymentDeps,
  purchase: Purchase,
  origin: string,
): Promise<Purchase> {
  const payment = purchase.payment as PurchasePayment | null | undefined;
  if (!payment || payment.status !== "pending" || payment.checkout_url) return purchase;
  const provider = deps.providers.find((p) => p.code === payment.provider_code);
  if (!provider) return deps.store.initiationFailed(payment.id, "fournisseur indisponible");
  try {
    const started = await provider.initiate({
      paymentId: payment.id,
      amountMinor: Number(payment.amount_minor),
      currencyCode: String(purchase.currency_code),
      reference: payment.reference,
      selfOrigin: origin,
    });
    return await deps.store.initiated(payment.id, started.providerReference, started.checkoutUrl);
  } catch (error) {
    console.error("[payments] initiation en échec", provider.code, error);
    return deps.store.initiationFailed(payment.id, error instanceof Error ? error.message : "échec");
  }
}

/** Traite une confirmation brute : journal, signature, application en base. */
async function handleWebhook(
  deps: PaymentDeps,
  provider: PaymentProvider,
  rawBody: string,
  headers: Record<string, string | undefined>,
): Promise<string> {
  const signatureValid = provider.verifyWebhook(rawBody, headers);
  const event = provider.normalizeEvent(rawBody);
  let payload: unknown;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    payload = { raw: rawBody.slice(0, 2000) };
  }
  return deps.store.applyEvent({
    provider: provider.code,
    eventId: event?.eventId ?? "",
    payload,
    signatureValid: signatureValid && event !== null,
    paymentId: event && uuid.safeParse(event.paymentId).success ? event.paymentId : null,
    outcome: event?.outcome ?? null,
    amountMinor: event ? event.amountMinor : null,
    currencyCode: event?.currencyCode ?? null,
  });
}

const lowerHeaders = (c: Context) => {
  const out: Record<string, string> = {};
  c.req.raw.headers.forEach((value, key) => {
    out[key.toLowerCase()] = value;
  });
  return out;
};

/**
 * Paiements (spec 010) :
 * - `POST /v1/payments/webhooks/:provider` : confirmation d'un fournisseur ;
 * - `POST /v1/purchases/:id/payments` (`Idempotency-Key`) : nouvelle tentative ;
 * - `POST /v1/purchases/:id/cash` : passage au paiement à la livraison ;
 * - `GET|POST /v1/payments/simulator/:paymentId[/:outcome]` : page du simulateur
 *   (seulement s'il est disponible, donc jamais en production).
 */
export function registerPaymentRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: PaymentDeps,
) {
  const auth = requireUser(verifyToken);
  const need = () => {
    if (!deps) throw httpErrors.unavailable("paiements non configurés");
    return deps;
  };

  app.post("/v1/payments/webhooks/:provider", async (c) => {
    const d = need();
    const provider = d.providers.find((p) => p.code === c.req.param("provider"));
    if (!provider) throw httpErrors.notFound("fournisseur inconnu");
    const outcome = await handleWebhook(d, provider, await c.req.text(), lowerHeaders(c));
    if (outcome === "rejected") throw httpErrors.unauthenticated("signature invalide");
    return c.json({ outcome });
  });

  app.post("/v1/purchases/:id/payments", auth, async (c) => {
    const key = c.req.header("Idempotency-Key");
    if (!key || !uuid.safeParse(key).success) {
      throw httpErrors.badRequest("Idempotency-Key (uuid) obligatoire");
    }
    const purchaseId = c.req.param("id");
    if (!uuid.safeParse(purchaseId).success) throw httpErrors.notFound("achat introuvable");
    const body = await parseBody(c, z.object({ payment_method_id: uuid.nullable().optional() }));
    const d = need();
    const retried = await d.store.retry({
      userId: c.get("user").id,
      purchaseId,
      idempotencyKey: key,
      paymentMethodId: body.payment_method_id ?? null,
      providers: d.providers.map((p) => p.code),
    });
    const purchase = await initiatePending(d, retried.purchase, selfOrigin(c));
    return c.json(purchase, retried.replayed ? 200 : 201);
  });

  app.post("/v1/purchases/:id/cash", auth, async (c) => {
    const purchaseId = c.req.param("id");
    if (!uuid.safeParse(purchaseId).success) throw httpErrors.notFound("achat introuvable");
    const d = need();
    return c.json(await d.store.switchToCash(c.get("user").id, purchaseId));
  });

  // Simulateur : page de paiement et issues choisies à la main.
  const simulator = () => {
    const d = need();
    const provider = d.providers.find((p) => p.code === SIMULATOR) as
      | ReturnType<typeof simulatorProvider>
      | undefined;
    if (!provider) throw httpErrors.notFound("simulateur indisponible");
    return { d, provider };
  };

  app.get("/v1/payments/simulator/:paymentId", async (c) => {
    const { d } = simulator();
    const id = c.req.param("paymentId");
    const payment = uuid.safeParse(id).success ? await d.store.summary(id) : null;
    if (!payment || payment.providerCode !== SIMULATOR) throw httpErrors.notFound("paiement inconnu");
    return c.html(simulatorPage(payment, `${selfOrigin(c)}/v1/payments/simulator/${id}`));
  });

  app.post("/v1/payments/simulator/:paymentId/:outcome", async (c) => {
    const { d, provider } = simulator();
    const id = c.req.param("paymentId");
    const outcome = c.req.param("outcome") as PaymentOutcome;
    if (!["succeeded", "failed", "cancelled"].includes(outcome)) throw httpErrors.notFound("issue inconnue");
    const payment = uuid.safeParse(id).success ? await d.store.summary(id) : null;
    if (!payment || payment.providerCode !== SIMULATOR) throw httpErrors.notFound("paiement inconnu");
    // Même chemin qu'un vrai fournisseur : corps signé, vérifié, journalisé.
    const raw = provider.event(id, outcome, payment.amountMinor, payment.currencyCode);
    const result = await handleWebhook(d, provider, raw, {
      [SIMULATOR_SIGNATURE_HEADER]: provider.sign(raw),
    });
    return c.html(simulatorDone(outcome, result));
  });
}

const escape = (s: string) =>
  s.replace(/[&<>"']/g, (ch) => `&#${ch.charCodeAt(0)};`);

const page = (title: string, body: string) => `<!doctype html>
<html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(title)}</title>
<style>
body{margin:0;font-family:system-ui,sans-serif;background:#FBF6EC;color:#1F2A24;display:flex;justify-content:center}
main{max-width:420px;width:100%;padding:24px 16px}
h1{font-size:26px;margin:8px 0}
.card{background:#fff;border-radius:20px;padding:16px;margin:16px 0}
.amount{font-size:30px;font-weight:800;color:#0B5D3F}
.note{color:#5B6B61;font-size:14px}
button{display:block;width:100%;min-height:52px;border-radius:16px;border:0;font-size:17px;font-weight:700;margin:10px 0;cursor:pointer}
.ok{background:#0B5D3F;color:#fff}.ko{background:#B8341E;color:#fff}.no{background:#fff;color:#0B5D3F;border:2px solid #0B5D3F}
.tag{display:inline-block;background:#F2C14E;border-radius:999px;padding:4px 12px;font-weight:700;font-size:13px}
</style></head><body><main>${body}</main></body></html>`;

/** Montant lisible : décimales et symbole du référentiel. */
const formatAmount = (p: { amountMinor: number; minorUnits: number; symbol: string }) =>
  `${(p.amountMinor / 10 ** p.minorUnits).toFixed(p.minorUnits)} ${p.symbol}`;

function simulatorPage(
  payment: {
    status: string;
    amountMinor: number;
    minorUnits: number;
    symbol: string;
    reference: string;
  },
  action: string,
) {
  const open = payment.status === "pending";
  return page(
    "Paiement simulé",
    `<span class="tag">Simulation · aucun argent réel</span>
<h1>Paiement Mobile Money</h1>
<div class="card"><div class="note">Montant à payer</div>
<div class="amount">${escape(formatAmount(payment))}</div>
<div class="note">Référence ${escape(payment.reference)}</div></div>
${
  open
    ? `<form method="post" action="${escape(action)}/succeeded"><button class="ok">Paiement réussi</button></form>
<form method="post" action="${escape(action)}/failed"><button class="ko">Paiement échoué</button></form>
<form method="post" action="${escape(action)}/cancelled"><button class="no">Abandonner</button></form>`
    : `<p>Ce paiement est terminé (${escape(payment.status)}).</p>`
}
<p class="note">Page de test servie par DYM hors production. Revenir ensuite dans l'app.</p>`,
  );
}

function simulatorDone(outcome: PaymentOutcome, result: string) {
  const label = { succeeded: "Paiement réussi", failed: "Paiement échoué", cancelled: "Paiement abandonné" }[outcome];
  return page(
    label,
    `<span class="tag">Simulation</span><h1>${label}</h1>
<div class="card"><p>Confirmation envoyée (${escape(result)}).</p>
<p class="note">Tu peux revenir dans l'app : elle se met à jour toute seule.</p></div>`,
  );
}
