import { attachDatabasePool } from "@neon/functions";
import pg from "pg";
import { type HttpError, httpErrors } from "./errors.js";

/**
 * Pool Postgres d'une Function (DATABASE_URL injecté par Neon). Les règles
 * métier restent en SQL : une Function appelle une fonction SQL
 * transactionnelle, puis émet les effets externes (constitution III).
 */
export function createPool(databaseUrl: string): pg.Pool {
  const pool = new pg.Pool({ connectionString: databaseUrl, max: 5 });
  attachDatabasePool(pool);
  return pool;
}

/** Exécute `work` dans une transaction, annulée en cas d'erreur. */
export async function withTransaction<T>(
  pool: pg.Pool,
  work: (client: pg.PoolClient) => Promise<T>,
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query("begin");
    const result = await work(client);
    await client.query("commit");
    return result;
  } catch (error) {
    await client.query("rollback").catch(() => undefined);
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Erreur Postgres → erreur HTTP : les refus décidés en SQL gardent leur sens
 * (propriété 42501, absence P0002, entrée invalide 22023/23514/P0001).
 */
export function fromPgError(error: unknown): HttpError | unknown {
  const code = (error as { code?: string } | null)?.code;
  const message = (error as { message?: string } | null)?.message ?? "erreur";
  switch (code) {
    case "42501":
      return httpErrors.forbidden(message);
    case "P0002":
      return httpErrors.notFound(message);
    case "22023":
    case "23514":
    case "P0001":
      return httpErrors.validation({ _: message }, message);
    default:
      return error;
  }
}
