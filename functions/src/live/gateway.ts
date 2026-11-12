import { upgradeWebSocket } from "@neon/functions/hono";
import type { Hono } from "hono";
import type pg from "pg";
import type { AuthVariables, TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";

/** Événement adressé à une personne (table `live_events`, spec 067). */
export interface LiveEvent {
  id: number;
  user_id: string;
  kind: string;
  entity_id: string | null;
  payload: Record<string, unknown>;
  created_at: string;
}

/** Lecture des événements ; les règles d'adressage sont en SQL. */
export interface LiveStore {
  since(users: string[], after: number, limit: number): Promise<LiveEvent[]>;
  lastId(): Promise<number>;
}

export function pgLiveStore(pool: pg.Pool): LiveStore {
  return {
    async since(users, after, limit) {
      try {
        const { rows } = await pool.query(
          "select id::int8 as id, user_id, kind, entity_id, payload, created_at from app.live_events_since($1::uuid[], $2, $3)",
          [users, after, limit],
        );
        return rows.map((r) => ({ ...r, id: Number(r.id) }));
      } catch (error) {
        throw fromPgError(error);
      }
    },
    async lastId() {
      try {
        const { rows } = await pool.query("select app.live_last_id()::int8 as id");
        return Number(rows[0].id);
      } catch (error) {
        throw fromPgError(error);
      }
    },
  };
}

/** Connexion d'une personne (un appareil). */
export interface LiveClient {
  userId: string;
  send(message: string): void;
}

interface Entry {
  client: LiveClient;
  /** Événements déjà envoyés (relecture avec recouvrement). */
  seen: Set<number>;
  /** Curseur de la connexion : rien d'antérieur n'est envoyé. */
  after: number;
}

/**
 * Concentrateur d'une instance : interroge la base seulement si quelqu'un
 * est connecté (la base peut se mettre en veille), relit une courte fenêtre
 * (les identifiants ne sont pas validés dans l'ordre) et écarte les doublons.
 * Chaque instance a le sien : une connexion n'est servie que par l'instance
 * qui la porte, et toutes lisent la même table.
 */
export class LiveHub {
  readonly #store: LiveStore;
  readonly #pollMs: number;
  readonly #heartbeatMs: number;
  readonly #overlap: number;
  readonly #entries = new Set<Entry>();
  #cursor = 0;
  #poller: ReturnType<typeof setInterval> | undefined;
  #heart: ReturnType<typeof setInterval> | undefined;
  #polling = false;

  constructor(store: LiveStore, options: { pollMs?: number; heartbeatMs?: number; overlap?: number } = {}) {
    this.#store = store;
    this.#pollMs = options.pollMs ?? 1000;
    this.#heartbeatMs = options.heartbeatMs ?? 25_000;
    this.#overlap = options.overlap ?? 50;
  }

  get size(): number {
    return this.#entries.size;
  }

  /**
   * Ajoute une connexion. [after] : dernier événement reçu par l'app avant
   * une coupure ; les événements manqués (dans la fenêtre conservée) sont
   * renvoyés. L'app recharge de toute façon son écran à chaque connexion.
   */
  async add(client: LiveClient, after?: number): Promise<() => void> {
    const last = await this.#store.lastId();
    if (this.#entries.size === 0) this.#cursor = last;
    const entry: Entry = { client, seen: new Set(), after: last };
    if (after !== undefined && after >= 0 && after < last) {
      const missed = await this.#store.since([client.userId], after, 500);
      for (const event of missed) this.#deliver(entry, event, true);
    }
    this.#entries.add(entry);
    client.send(JSON.stringify({ type: "ready", cursor: last }));
    this.#start();
    return () => this.#remove(entry);
  }

  /** Une lecture (appelée par le minuteur ; exposée pour les tests). */
  async poll(): Promise<void> {
    if (this.#polling || this.#entries.size === 0) return;
    this.#polling = true;
    try {
      const users = [...new Set([...this.#entries].map((e) => e.client.userId))];
      const events = await this.#store.since(users, Math.max(0, this.#cursor - this.#overlap), 1000);
      for (const event of events) {
        for (const entry of this.#entries) {
          if (entry.client.userId === event.user_id) this.#deliver(entry, event);
        }
        if (event.id > this.#cursor) this.#cursor = event.id;
      }
      this.#trim();
    } finally {
      this.#polling = false;
    }
  }

  /** Signal de vie : les intermédiaires coupent les connexions muettes. */
  heartbeat(): void {
    for (const entry of this.#entries) entry.client.send('{"type":"ping"}');
  }

  stop(): void {
    if (this.#poller) clearInterval(this.#poller);
    if (this.#heart) clearInterval(this.#heart);
    this.#poller = undefined;
    this.#heart = undefined;
  }

  /** [replay] : reprise après coupure, seul cas où un événement antérieur à
   * la connexion est envoyé. */
  #deliver(entry: Entry, event: LiveEvent, replay = false): void {
    if (!replay && event.id <= entry.after) return;
    if (entry.seen.has(event.id)) return;
    entry.seen.add(event.id);
    entry.client.send(
      JSON.stringify({
        type: "event",
        id: event.id,
        kind: event.kind,
        entity_id: event.entity_id,
        payload: event.payload,
      }),
    );
  }

  #trim(): void {
    const floor = this.#cursor - this.#overlap * 4;
    for (const entry of this.#entries) {
      if (entry.seen.size < 2000) continue;
      for (const id of entry.seen) if (id < floor) entry.seen.delete(id);
    }
  }

  #start(): void {
    this.#poller ??= setInterval(() => {
      this.poll().catch((error) => console.error("[live] lecture en échec", error));
    }, this.#pollMs);
    this.#heart ??= setInterval(() => this.heartbeat(), this.#heartbeatMs);
  }

  #remove(entry: Entry): void {
    this.#entries.delete(entry);
    if (this.#entries.size === 0) this.stop();
  }
}

/**
 * Passerelle `GET /v1/live` (WebSocket). Jeton Neon Auth dans
 * `Authorization: Bearer` (mobile) ou `?access_token=` (web, où un
 * navigateur ne peut pas poser d'en-tête). `?after=` : reprise.
 * Messages envoyés : `ready`, `event`, `ping`. Les messages reçus sont ignorés.
 */
export function registerLiveGateway(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  hub?: LiveHub,
) {
  app.get(
    "/v1/live",
    async (c, next) => {
      if (!hub) return c.json({ error: "unavailable" }, 503);
      const header = c.req.header("authorization") ?? "";
      const [scheme, bearer] = header.split(" ");
      const token = scheme?.toLowerCase() === "bearer" && bearer ? bearer : c.req.query("access_token");
      if (!token) return c.json({ error: "unauthenticated" }, 401);
      try {
        c.set("user", await verifyToken(token));
      } catch {
        return c.json({ error: "unauthenticated" }, 401);
      }
      if (c.req.header("upgrade")?.toLowerCase() !== "websocket") {
        return c.json({ error: "upgrade_required" }, 426);
      }
      await next();
    },
    upgradeWebSocket((c) => {
      const userId = c.get("user").id;
      const afterRaw = Number(c.req.query("after"));
      const after = Number.isFinite(afterRaw) && afterRaw >= 0 ? afterRaw : undefined;
      let release: (() => void) | undefined;
      let closed = false;
      return {
        onOpen(_event, ws) {
          hub!
            .add({ userId, send: (message) => ws.send(message) }, after)
            .then((r) => {
              if (closed) r();
              else release = r;
            })
            .catch((error) => {
              console.error("[live] ouverture en échec", error);
              ws.close(1011, "unavailable");
            });
        },
        onClose() {
          closed = true;
          release?.();
        },
      };
    }),
  );
}
