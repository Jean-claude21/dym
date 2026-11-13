import pg from "pg";
import { afterAll, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import type { TokenVerifier } from "../src/lib/auth.js";
import { type AdminFunction, analyticsSql, type McpStore, pgMcpStore } from "../src/mcp/server.js";

const admin = "a0000000-0000-4000-8000-0000000000aa";
const key = "dym_mcp_" + "a".repeat(64);
const verifyToken: TokenVerifier = async () => {
  throw new Error("pas de jeton de session pour le MCP");
};

const orders: AdminFunction = {
  name: "admin_orders",
  permission: "orders.read",
  writes: false,
  args: [{ name: "p_filter", type: "text", required: false }],
};
const commission: AdminFunction = {
  name: "admin_set_commission",
  permission: "catalog.write",
  writes: true,
  args: [
    { name: "p_country", type: "character(2)", required: true },
    { name: "p_rate_bps", type: "integer", required: true },
  ],
};

class FakeStore implements McpStore {
  calls: unknown[] = [];
  analytics = true;
  async keyUser(k: string) {
    return k === key ? admin : null;
  }
  async functions() {
    return [orders, commission];
  }
  async call(userId: string, fn: AdminFunction, args: Record<string, unknown>) {
    this.calls.push({ userId, fn: fn.name, args });
    return [{ id: "o1" }];
  }
  async canReadAnalytics() {
    return this.analytics;
  }
  async analyticsSchema() {
    return { "analytics.daily_orders": ["day date"] };
  }
  async analyticsQuery(sql: string) {
    this.calls.push({ sql });
    return [{ day: "2026-11-13", orders: 3 }];
  }
}

const rpc = (app: ReturnType<typeof createApp>, body: unknown, auth = `Bearer ${key}`) =>
  app.request("/mcp", {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json, text/event-stream", Authorization: auth },
    body: JSON.stringify(body),
  });

const toolText = async (res: Response) => {
  const body = (await res.json()) as { result: { content: { text: string }[]; isError?: boolean } };
  return { text: body.result.content[0]!.text, isError: body.result.isError === true };
};

describe("MCP admin", () => {
  it("clé absente ou fausse : 401", async () => {
    const app = createApp({ verifyToken, mcp: new FakeStore() });
    expect((await rpc(app, { jsonrpc: "2.0", id: 1, method: "ping" }, "")).status).toBe(401);
    expect((await rpc(app, { jsonrpc: "2.0", id: 1, method: "ping" }, "Bearer dym_mcp_faux")).status).toBe(401);
  });

  it("initialisation, notification, liste des outils", async () => {
    const app = createApp({ verifyToken, mcp: new FakeStore() });
    const init = await rpc(app, {
      jsonrpc: "2.0", id: 1, method: "initialize",
      params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "test", version: "1" } },
    });
    const body = (await init.json()) as { result: { serverInfo: { name: string }; capabilities: object } };
    expect(body.result.serverInfo.name).toBe("dym-admin");
    expect(body.result.capabilities).toHaveProperty("tools");
    expect((await rpc(app, { jsonrpc: "2.0", method: "notifications/initialized" })).status).toBe(202);
    const list = (await (await rpc(app, { jsonrpc: "2.0", id: 2, method: "tools/list" })).json()) as {
      result: { tools: { name: string }[] };
    };
    expect(list.result.tools.map((t) => t.name)).toEqual([
      "dym_functions", "dym_call", "analytics_schema", "analytics_query",
    ]);
  });

  it("dym_call : fonction autorisée appelée avec ses arguments, sinon erreur d'outil", async () => {
    const store = new FakeStore();
    const app = createApp({ verifyToken, mcp: store });
    const ok = await rpc(app, {
      jsonrpc: "2.0", id: 3, method: "tools/call",
      params: { name: "dym_call", arguments: { name: "admin_orders", args: { p_filter: "stuck" } } },
    });
    expect(JSON.parse((await toolText(ok)).text)).toEqual([{ id: "o1" }]);
    expect(store.calls).toEqual([{ userId: admin, fn: "admin_orders", args: { p_filter: "stuck" } }]);

    const unknown = await toolText(await rpc(app, {
      jsonrpc: "2.0", id: 4, method: "tools/call",
      params: { name: "dym_call", arguments: { name: "admin_delete_everything" } },
    }));
    expect(unknown.isError).toBe(true);
    const missing = await toolText(await rpc(app, {
      jsonrpc: "2.0", id: 5, method: "tools/call",
      params: { name: "dym_call", arguments: { name: "admin_set_commission", args: { p_country: "TG" } } },
    }));
    expect(missing).toMatchObject({ isError: true, text: "arguments manquants : p_rate_bps" });
  });

  it("analytics : permission exigée, une seule requête SELECT", async () => {
    const store = new FakeStore();
    const app = createApp({ verifyToken, mcp: store });
    const q = await toolText(await rpc(app, {
      jsonrpc: "2.0", id: 6, method: "tools/call",
      params: { name: "analytics_query", arguments: { sql: "select * from analytics.daily_orders" } },
    }));
    expect(q.isError).toBe(false);
    store.analytics = false;
    const denied = await toolText(await rpc(app, {
      jsonrpc: "2.0", id: 7, method: "tools/call",
      params: { name: "analytics_schema", arguments: {} },
    }));
    expect(denied).toMatchObject({ isError: true });
    expect(() => analyticsSql("delete from public.orders")).toThrow();
    expect(() => analyticsSql("select 1; drop table x")).toThrow();
    expect(analyticsSql("select 1;")).toBe("select * from (select 1) as q limit 500");
  });
});

// Contre une vraie base (`TEST_DATABASE_URL`, migrations appliquées) ; ignoré sinon.
const url = process.env.TEST_DATABASE_URL;
const pool = url ? new pg.Pool({ connectionString: url, max: 2 }) : undefined;
afterAll(async () => {
  await pool?.end();
});

describe.skipIf(!pool)("MCP · Postgres", () => {
  it("lecture seule : le lecteur ne voit que analytics", async () => {
    const store = pgMcpStore(pool!);
    await expect(store.analyticsQuery("select count(*) as n from analytics.daily_orders")).resolves.toHaveLength(1);
    await expect(store.analyticsQuery("select count(*) from public.profiles")).rejects.toThrow(/analytics_query/);
    expect(Object.keys(await store.analyticsSchema())).toContain("analytics.daily_funnel");
  });
});
