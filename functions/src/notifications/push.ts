import type pg from "pg";
import { importPKCS8, SignJWT } from "jose";
import { fromPgError } from "../lib/db.js";

/** Push prêt à envoyer (texte rendu par la base, dans la langue de la personne). */
export interface PushMessage {
  tokens: string[];
  title: string;
  body: string;
  data: Record<string, string>;
}

export interface PushSendResult {
  sent: number;
  /** Jetons refusés par le fournisseur (téléphone désinstallé). */
  invalidTokens: string[];
}

/** Envoi de notifications push (FCM, ou rien sans identifiants). */
export interface PushSender {
  readonly enabled: boolean;
  send(message: PushMessage): Promise<PushSendResult>;
}

/** Notification réservée dans la file (`app.claim_pushes`). */
export interface ClaimedPush {
  id: string;
  kind: string;
  category: string;
  order_id: string | null;
  purchase_id: string | null;
  allowed: boolean;
  tokens: string[];
  text: { title: string; body: string } | null;
}

export interface PushQueue {
  claim(limit: number): Promise<ClaimedPush[]>;
  result(ids: string[], outcome: "sent" | "skipped" | "failed"): Promise<void>;
  dropTokens(tokens: string[]): Promise<void>;
}

/** Aucun fournisseur configuré : les push sont marqués ignorés. */
export const noPushSender: PushSender = {
  enabled: false,
  async send() {
    return { sent: 0, invalidTokens: [] };
  },
};

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

/**
 * FCM (API HTTP v1) avec un compte de service Firebase : jeton OAuth signé
 * (RS256), mis en cache ; un message par téléphone.
 */
export function fcmPushSender(
  serviceAccountJson: string,
  fetchImpl: typeof fetch = fetch,
): PushSender {
  const account = JSON.parse(serviceAccountJson) as ServiceAccount;
  let cached: { token: string; expiresAt: number } | null = null;

  const accessToken = async () => {
    if (cached && cached.expiresAt > Date.now() + 60_000) return cached.token;
    const key = await importPKCS8(account.private_key, "RS256");
    const now = Math.floor(Date.now() / 1000);
    const assertion = await new SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
      .setProtectedHeader({ alg: "RS256", typ: "JWT" })
      .setIssuer(account.client_email)
      .setAudience("https://oauth2.googleapis.com/token")
      .setIssuedAt(now)
      .setExpirationTime(now + 3600)
      .sign(key);
    const res = await fetchImpl("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    });
    if (!res.ok) throw new Error(`jeton FCM refusé : ${res.status}`);
    const json = (await res.json()) as { access_token: string; expires_in: number };
    cached = { token: json.access_token, expiresAt: Date.now() + json.expires_in * 1000 };
    return cached.token;
  };

  return {
    enabled: true,
    async send(message) {
      const token = await accessToken();
      let sent = 0;
      const invalidTokens: string[] = [];
      for (const device of message.tokens) {
        const res = await fetchImpl(
          `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
            body: JSON.stringify({
              message: {
                token: device,
                notification: { title: message.title, body: message.body },
                data: message.data,
                android: { priority: "high", notification: { sound: "default" } },
              },
            }),
          },
        );
        if (res.ok) sent += 1;
        else if (res.status === 404 || res.status === 400) invalidTokens.push(device);
      }
      return { sent, invalidTokens };
    },
  };
}

/** File de push en base (fonctions `app.*`). */
export function pgPushQueue(pool: pg.Pool): PushQueue {
  return {
    async claim(limit) {
      try {
        const { rows } = await pool.query("select app.claim_pushes($1) as value", [limit]);
        return rows[0].value as ClaimedPush[];
      } catch (error) {
        throw fromPgError(error);
      }
    },
    async result(ids, outcome) {
      if (ids.length === 0) return;
      await pool.query("select app.push_result($1, $2)", [ids, outcome]);
    },
    async dropTokens(tokens) {
      if (tokens.length === 0) return;
      await pool.query("select app.drop_push_tokens($1)", [tokens]);
    },
  };
}

/**
 * Envoie les push en attente : jamais deux fois (réservés en base), seulement
 * aux téléphones enregistrés et pour les catégories autorisées.
 */
export async function dispatchPushes(queue: PushQueue, sender: PushSender, limit = 50) {
  const claimed = await queue.claim(limit);
  const skipped: string[] = [];
  const sent: string[] = [];
  const failed: string[] = [];
  const invalid: string[] = [];
  for (const push of claimed) {
    if (!sender.enabled || !push.allowed || push.tokens.length === 0 || !push.text) {
      skipped.push(push.id);
      continue;
    }
    try {
      const result = await sender.send({
        tokens: push.tokens,
        title: push.text.title,
        body: push.text.body,
        data: {
          kind: push.kind,
          ...(push.order_id ? { order_id: push.order_id } : {}),
          ...(push.purchase_id ? { purchase_id: push.purchase_id } : {}),
        },
      });
      invalid.push(...result.invalidTokens);
      (result.sent > 0 ? sent : failed).push(push.id);
    } catch (error) {
      console.error("[push] envoi en échec", error);
      failed.push(push.id);
    }
  }
  await queue.result(sent, "sent");
  await queue.result(skipped, "skipped");
  await queue.result(failed, "failed");
  await queue.dropTokens(invalid);
  return { sent: sent.length, skipped: skipped.length, failed: failed.length };
}
