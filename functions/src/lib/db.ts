import { attachDatabasePool } from "@neon/functions";
import pg from "pg";

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
