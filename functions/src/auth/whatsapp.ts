import { randomInt } from "node:crypto";
import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import type { AuthVariables } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";
import { hashLoginCode, type LoginCodeStore } from "./google.js";

/**
 * Connexion WhatsApp (spec 105). Le numéro reçoit un code à 6 chiffres par le modèle
 * d'authentification de WhatsApp (Meta) ; le bon code ouvre une session Neon Auth standard par le
 * même pont que Google (code de connexion à usage unique). Sans compte Meta, le mode simulé
 * (staging seulement) rend le code à l'app, signalé « simulé ».
 */

export interface WhatsAppSender {
  send(phone: string, code: string): Promise<void>;
}

export interface PhoneCodeStore {
  issue(phone: string, codeHash: string): Promise<{ ok: boolean; retryAfter?: number }>;
  /** Adresse du compte si le code est bon, sinon null. */
  check(phone: string, codeHash: string): Promise<string | null>;
}

export interface WhatsAppDeps {
  phones: PhoneCodeStore;
  logins: LoginCodeStore;
  sender?: WhatsAppSender;
  /** Mode simulé : le code revient dans la réponse (jamais en production). */
  simulated?: boolean;
  code?: () => string;
}

const phoneSchema = z.string().regex(/^\+[1-9][0-9]{7,14}$/);
const sixDigits = () => String(randomInt(0, 1_000_000)).padStart(6, "0");

export function registerWhatsAppRoutes(app: Hono<{ Variables: AuthVariables }>, deps?: WhatsAppDeps) {
  const available = Boolean(deps && (deps.sender || deps.simulated));

  app.get("/v1/auth/whatsapp", (c) =>
    c.json({ available, simulated: Boolean(deps?.simulated && !deps?.sender) }),
  );

  app.post("/v1/auth/whatsapp/start", async (c) => {
    if (!deps || !available) return c.json({ error: "unavailable", message: "connexion WhatsApp non configurée" }, 503);
    const body = z.object({ phone: phoneSchema }).safeParse(await c.req.json().catch(() => null));
    if (!body.success) throw httpErrors.badRequest("numéro international requis (+228…)");
    const code = deps.code?.() ?? sixDigits();
    const issued = await deps.phones.issue(body.data.phone, hashLoginCode(code));
    if (!issued.ok) {
      return c.json({ error: "too_many", message: "trop d'envois, réessaie plus tard", retry_after: issued.retryAfter }, 429);
    }
    if (deps.sender) {
      await deps.sender.send(body.data.phone, code);
      return c.json({ sent: true, simulated: false });
    }
    return c.json({ sent: true, simulated: true, code });
  });

  app.post("/v1/auth/whatsapp/verify", async (c) => {
    if (!deps || !available) return c.json({ error: "unavailable", message: "connexion WhatsApp non configurée" }, 503);
    const body = z
      .object({ phone: phoneSchema, code: z.string().regex(/^[0-9]{6}$/) })
      .safeParse(await c.req.json().catch(() => null));
    if (!body.success) throw httpErrors.badRequest("numéro et code requis");
    const email = await deps.phones.check(body.data.phone, hashLoginCode(body.data.code));
    if (!email) throw httpErrors.unauthenticated("code faux ou expiré");
    const login = sixDigits();
    await deps.logins.issue(email, hashLoginCode(login), 120);
    return c.json({ email, code: login });
  });
}

export function pgPhoneCodeStore(pool: pg.Pool): PhoneCodeStore {
  return {
    async issue(phone, codeHash) {
      try {
        const { rows } = await pool.query("select app.phone_code_issue($1, $2) as value", [phone, codeHash]);
        const v = rows[0].value as { ok: boolean; retry_after?: number };
        return { ok: v.ok, retryAfter: v.retry_after };
      } catch (error) {
        throw fromPgError(error);
      }
    },
    async check(phone, codeHash) {
      try {
        const { rows } = await pool.query("select app.phone_code_check($1, $2) as value", [phone, codeHash]);
        return (rows[0].value as string | null) ?? null;
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}

/**
 * WhatsApp Cloud API (Meta) : modèle d'authentification approuvé, code dans le corps et dans le
 * bouton « Copier le code ».
 */
export function metaWhatsAppSender(
  options: { token: string; phoneNumberId: string; template: string; language: string },
  fetchImpl: typeof fetch = fetch,
): WhatsAppSender {
  return {
    async send(phone, code) {
      const res = await fetchImpl(`https://graph.facebook.com/v21.0/${options.phoneNumberId}/messages`, {
        method: "POST",
        headers: { Authorization: `Bearer ${options.token}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          messaging_product: "whatsapp",
          to: phone.replace(/^\+/, ""),
          type: "template",
          template: {
            name: options.template,
            language: { code: options.language },
            components: [
              { type: "body", parameters: [{ type: "text", text: code }] },
              { type: "button", sub_type: "url", index: "0", parameters: [{ type: "text", text: code }] },
            ],
          },
        }),
      });
      if (!res.ok) throw new Error(`whatsapp ${res.status}`);
    },
  };
}
