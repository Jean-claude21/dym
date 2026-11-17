import type pg from "pg";
import { importPKCS8, SignJWT } from "jose";
import { fromPgError } from "../lib/db.js";

/** Push prêt à envoyer (texte rendu par la base, dans la langue de la personne). */
export interface PushMessage {
  tokens: string[];
  title: string;
  body: string;
  data: Record<string, string>;
  /** Canal Android (importance et son propres), créé par l'app. */
  channel?: string;
  /** Regroupement : une nouvelle notification du même sujet remplace l'ancienne. */
  tag?: string;
  /** Grande photo (produit principal de la commande), URL publique. */
  image?: string;
  /**
   * Données seules (spec 097) : l'app affiche elle-même la notification, avec ses boutons
   * (accepter, répondre, décrocher) et, pour un appel, en plein écran avec sonnerie.
   */
  dataOnly?: boolean;
}

/** Notifications à boutons ou appels : affichées par l'app (données seules). */
export function isActionable(kind: string): boolean {
  return (
    kind === "new_order" ||
    kind === "mission_available" ||
    kind.startsWith("incoming_call") ||
    kind.startsWith("new_message")
  );
}

/** Son du canal (fichier `res/raw` des apps), pour les notifications affichées par le système. */
const channelSounds: Record<string, string> = {
  dym_orders_v2: "dym_order",
  dym_messages_v2: "dym_message",
  dym_missions_v2: "dym_mission",
  dym_calls_v2: "dym_ring",
};

/**
 * Bloc iPhone (spec 108) : titre, texte et son de l'événement (WAV embarqués dans l'app iOS),
 * regroupés par sujet ; priorité immédiate.
 */
export function apnsFor(message: { title: string; body: string; channel?: string; tag?: string }) {
  const sound = message.channel && channelSounds[message.channel];
  return {
    headers: { "apns-priority": "10" },
    payload: {
      aps: {
        alert: { title: message.title, body: message.body },
        sound: sound ? `${sound}.wav` : "default",
        ...(message.tag ? { "thread-id": message.tag } : {}),
      },
    },
  };
}

/** Courses du livreur : canal à part, pour un son et une importance dédiés. */
const missionKinds = new Set([
  "mission_available",
  "order_ready_pickup",
  "delivery_assigned",
  "courier_cash_confirmed",
]);

/**
 * Canal Android d'une notification (spec 072) : commandes et paiements,
 * messages, courses du livreur, le reste. Les identifiants sont créés par
 * `PushNotifications` dans les apps.
 */
export function pushChannel(kind: string, category: string): string {
  // Spec 097 : un canal par son ; les appels sonnent en plein écran.
  if (kind.startsWith("incoming_call")) return "dym_calls_v2";
  if (missionKinds.has(kind)) return "dym_missions_v2";
  if (category === "messages") return "dym_messages_v2";
  if (category === "orders" || category === "payments") return "dym_orders_v2";
  return "dym_general_v2";
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
  /** Photo du produit principal d'une commande (clé du catalogue public). */
  image_key?: string | null;
  /** Paramètres du modèle (`conversation_id` pour un message). */
  params?: Record<string, unknown> | null;
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
              message: message.dataOnly
                ? {
                    token: device,
                    // Données seules : titre, texte, canal et sujet passent à l'app.
                    data: {
                      ...message.data,
                      title: message.title,
                      body: message.body,
                      ...(message.channel ? { channel: message.channel } : {}),
                      ...(message.tag ? { tag: message.tag } : {}),
                    },
                    android: { priority: "high", ttl: "60s" },
                    // iPhone (spec 108) : iOS n'affiche pas les données seules ; alerte et son.
                    apns: apnsFor(message),
                  }
                : {
                    token: device,
                    notification: {
                      title: message.title,
                      body: message.body,
                      ...(message.image ? { image: message.image } : {}),
                    },
                    data: message.data,
                    android: {
                      priority: "high",
                      notification: {
                        sound: (message.channel && channelSounds[message.channel]) || "default",
                        ...(message.channel ? { channel_id: message.channel } : {}),
                        ...(message.tag ? { tag: message.tag } : {}),
                      },
                    },
                    apns: apnsFor(message),
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
export async function dispatchPushes(
  queue: PushQueue,
  sender: PushSender,
  limit = 50,
  mediaBase?: string,
) {
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
      const conversation =
        typeof push.params?.conversation_id === "string" ? push.params.conversation_id : null;
      const result = await sender.send({
        tokens: push.tokens,
        title: push.text.title,
        body: push.text.body,
        channel: pushChannel(push.kind, push.category),
        dataOnly: isActionable(push.kind),
        ...(mediaBase && push.image_key
          ? { image: `${mediaBase.replace(/\/$/, "")}/${push.image_key}` }
          : {}),
        ...(conversation ?? push.order_id ? { tag: (conversation ?? push.order_id) as string } : {}),
        data: {
          kind: push.kind,
          ...(push.order_id ? { order_id: push.order_id } : {}),
          ...(push.purchase_id ? { purchase_id: push.purchase_id } : {}),
          // Message : le toucher ouvre la conversation.
          ...(conversation ? { conversation_id: conversation } : {}),
          // Appel : « Refuser » depuis la notification (spec 097).
          ...(typeof push.params?.call_id === "string" ? { call_id: push.params.call_id } : {}),
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
