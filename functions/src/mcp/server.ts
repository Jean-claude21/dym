import type { Hono } from "hono";
import type pg from "pg";
import type { AuthVariables } from "../lib/auth.js";
import { fromPgError, withTransaction } from "../lib/db.js";

/**
 * Serveur MCP de l'admin (spec 086), transport « Streamable HTTP » sans
 * session : `POST /mcp` reçoit un message JSON-RPC 2.0 et répond en JSON.
 * Authentification par clé personnelle (`Authorization: Bearer dym_mcp_…`) :
 * chaque appel s'exécute avec les droits de l'admin propriétaire de la clé
 * (rôle, périmètre de pays), vérifiés en SQL par la garde commune.
 */

export interface AdminFunctionArg {
  name: string;
  type: string;
  required: boolean;
}

export interface AdminFunction {
  name: string;
  permission: string;
  writes: boolean;
  args: AdminFunctionArg[];
}

export interface McpStore {
  /** Propriétaire d'une clé valide, sinon `null`. */
  keyUser(key: string): Promise<string | null>;
  functions(userId: string): Promise<AdminFunction[]>;
  call(userId: string, fn: AdminFunction, args: Record<string, unknown>): Promise<unknown>;
  canReadAnalytics(userId: string): Promise<boolean>;
  analyticsSchema(): Promise<Record<string, string[]>>;
  analyticsQuery(sql: string): Promise<Record<string, unknown>[]>;
}

export const ANALYTICS_ROW_LIMIT = 500;
const IDENT = /^[a-z_][a-z0-9_]*$/;

/** Requête d'analyse acceptée : une seule instruction SELECT ou WITH. */
export function analyticsSql(sql: string): string {
  const text = sql.trim().replace(/;\s*$/, "");
  if (!/^(select|with)\b/i.test(text) || text.includes(";")) {
    throw new McpError("analytics_query : une seule requête SELECT est acceptée");
  }
  return `select * from (${text}) as q limit ${ANALYTICS_ROW_LIMIT}`;
}

export function pgMcpStore(pool: pg.Pool): McpStore {
  const value = async <T>(sql: string, params: unknown[]) => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0]?.value as T;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    keyUser: (key) => value<string | null>("select app.mcp_key_user($1) as value", [key]),
    functions: (userId) => value<AdminFunction[]>("select app.mcp_admin_functions($1) as value", [userId]),
    canReadAnalytics: (userId) =>
      value<boolean>("select app.admin_has($1, 'analytics.read') as value", [userId]),
    call: async (userId, fn, args) => {
      if (!IDENT.test(fn.name)) throw new McpError("fonction inconnue");
      const params: unknown[] = [];
      const parts: string[] = [];
      for (const arg of fn.args) {
        if (!(arg.name in args)) continue;
        if (!IDENT.test(arg.name)) throw new McpError("argument invalide");
        const raw = args[arg.name];
        params.push(arg.type === "jsonb" || arg.type === "json" ? JSON.stringify(raw) : raw);
        parts.push(`${arg.name} => $${params.length}::${arg.type}`);
      }
      try {
        return await withTransaction(pool, async (client) => {
          // Identité de l'admin pour la garde SQL (comme un appel de la Data API).
          await client.query("select set_config('request.jwt.claims', $1, true)", [
            JSON.stringify({ sub: userId }),
          ]);
          const { rows } = await client.query(
            `select public.${fn.name}(${parts.join(", ")}) as value`,
            params,
          );
          if (fn.writes) {
            await client.query(
              "select app.audit($1, 'mcp_call', 'function', $2, null, null, null)",
              [userId, fn.name],
            );
          }
          return rows[0]?.value ?? null;
        });
      } catch (error) {
        throw fromPgError(error);
      }
    },
    analyticsSchema: async () => {
      const { rows } = await pool.query(
        `select table_name, string_agg(column_name || ' ' || data_type, ', ' order by ordinal_position) as columns
         from information_schema.columns where table_schema = 'analytics'
         group by table_name order by table_name`,
      );
      return Object.fromEntries(rows.map((r) => [`analytics.${r.table_name}`, String(r.columns).split(", ")]));
    },
    analyticsQuery: async (sql) => {
      const client = await pool.connect();
      try {
        await client.query("begin read only");
        await client.query("set local statement_timeout = '15s'");
        await client.query("set local role analytics_reader");
        const { rows } = await client.query(analyticsSql(sql));
        return rows;
      } catch (error) {
        throw new McpError(`analytics_query : ${(error as Error).message}`);
      } finally {
        await client.query("rollback").catch(() => undefined);
        client.release();
      }
    },
  };
}

export class McpError extends Error {}

const PROTOCOL = "2025-06-18";

const TOOLS = [
  {
    name: "dym_functions",
    description:
      "Liste les fonctions admin de DYM que ta clé peut appeler (nom, arguments typés, permission, écriture). " +
      "Commence par elle avant dym_call.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "dym_call",
    description:
      "Appelle une fonction admin de DYM avec tes droits (rôle, pays). Les écritures sont journalisées. " +
      "args : objet { nom_argument: valeur } (noms en p_…, voir dym_functions). " +
      "Les montants sont en unités mineures (entiers) avec leur devise.",
    inputSchema: {
      type: "object",
      properties: {
        name: { type: "string", description: "Nom de la fonction, par exemple admin_orders" },
        args: { type: "object", description: "Arguments nommés, par exemple { \"p_filter\": \"stuck\" }" },
      },
      required: ["name"],
      additionalProperties: false,
    },
  },
  {
    name: "analytics_schema",
    description: "Décrit les vues d'analyse (schéma analytics, sans donnée personnelle) et leurs colonnes.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "analytics_query",
    description:
      `Exécute une requête SELECT en lecture seule sur le schéma analytics (15 s, ${ANALYTICS_ROW_LIMIT} lignes au plus). ` +
      "Montants en unités mineures par devise : ne jamais additionner deux devises.",
    inputSchema: {
      type: "object",
      properties: { sql: { type: "string", description: "Une seule requête SELECT ou WITH" } },
      required: ["sql"],
      additionalProperties: false,
    },
  },
];

type JsonRpc = { jsonrpc?: string; id?: string | number | null; method?: string; params?: Record<string, unknown> };

const text = (data: unknown) => ({
  content: [{ type: "text", text: typeof data === "string" ? data : JSON.stringify(data, null, 2) }],
});

async function callTool(store: McpStore, userId: string, name: string, args: Record<string, unknown>) {
  switch (name) {
    case "dym_functions":
      return text(await store.functions(userId));
    case "dym_call": {
      const fnName = String(args.name ?? "");
      const fn = (await store.functions(userId)).find((f) => f.name === fnName);
      if (!fn) throw new McpError(`fonction inconnue ou non autorisée : ${fnName}`);
      const callArgs = (args.args ?? {}) as Record<string, unknown>;
      const missing = fn.args.filter((a) => a.required && !(a.name in callArgs)).map((a) => a.name);
      if (missing.length) throw new McpError(`arguments manquants : ${missing.join(", ")}`);
      return text(await store.call(userId, fn, callArgs));
    }
    case "analytics_schema":
    case "analytics_query": {
      if (!(await store.canReadAnalytics(userId))) throw new McpError("permission analytics.read requise");
      return name === "analytics_schema"
        ? text(await store.analyticsSchema())
        : text(await store.analyticsQuery(String(args.sql ?? "")));
    }
    default:
      throw new McpError(`outil inconnu : ${name}`);
  }
}

export function registerMcpRoutes(app: Hono<{ Variables: AuthVariables }>, store?: McpStore) {
  app.get("/mcp", (c) => c.json({ error: "utiliser POST (JSON-RPC)" }, 405));

  app.post("/mcp", async (c) => {
    const reply = (id: JsonRpc["id"], body: Record<string, unknown>) => c.json({ jsonrpc: "2.0", id: id ?? null, ...body });
    const fail = (id: JsonRpc["id"], code: number, message: string) => reply(id, { error: { code, message } });

    if (!store) return fail(null, -32000, "MCP non configuré");
    const auth = c.req.header("Authorization") ?? "";
    const key = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
    const userId = key.startsWith("dym_mcp_") ? await store.keyUser(key) : null;
    if (!userId) return c.json({ jsonrpc: "2.0", id: null, error: { code: -32001, message: "clé MCP invalide" } }, 401);

    let msg: JsonRpc;
    try {
      msg = (await c.req.json()) as JsonRpc;
    } catch {
      return fail(null, -32700, "JSON invalide");
    }
    if (Array.isArray(msg)) return fail(null, -32600, "lots non pris en charge");
    // Notification (sans id) : accusé sans corps.
    if (msg.id === undefined) return c.body(null, 202);

    switch (msg.method) {
      case "initialize":
        return reply(msg.id, {
          result: {
            protocolVersion: String(msg.params?.protocolVersion ?? PROTOCOL),
            capabilities: { tools: { listChanged: false } },
            serverInfo: { name: "dym-admin", version: "1.0.0" },
            instructions:
              "Console d'administration DYM. dym_functions liste ce que ta clé permet ; dym_call agit avec " +
              "tes droits ; analytics_query répond aux questions chiffrées. Montants en unités mineures.",
          },
        });
      case "ping":
        return reply(msg.id, { result: {} });
      case "tools/list":
        return reply(msg.id, { result: { tools: TOOLS } });
      case "tools/call": {
        const name = String(msg.params?.name ?? "");
        const args = (msg.params?.arguments ?? {}) as Record<string, unknown>;
        try {
          return reply(msg.id, { result: await callTool(store, userId, name, args) });
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          return reply(msg.id, { result: { ...text(message), isError: true } });
        }
      }
      default:
        return fail(msg.id, -32601, `méthode inconnue : ${msg.method}`);
    }
  });
}
