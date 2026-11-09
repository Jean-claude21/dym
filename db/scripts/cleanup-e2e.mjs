#!/usr/bin/env node
// Range les données des essais de bout en bout (order_flow_live_test) : leurs boutiques sont
// suspendues et fermées, jamais supprimées (l'historique des commandes et le grand livre restent).
// Ne touche qu'aux comptes `dym-e2e-…@example.com`. Chaque boutique rangée est auditée.
//
//   node db/scripts/cleanup-e2e.mjs --url <DATABASE_URL>
// Dépendance : `pg` (installé dans functions/).
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const pg = createRequire(path.join(ROOT, 'functions/package.json'))('pg');

const i = process.argv.indexOf('--url');
const url = i > 0 ? process.argv[i + 1] : process.env.DATABASE_URL;
if (!url) {
  console.error('usage : node db/scripts/cleanup-e2e.mjs --url <DATABASE_URL>');
  process.exit(1);
}

const db = new pg.Client({ connectionString: url.replace('sslmode=require', 'sslmode=verify-full') });
await db.connect();
try {
  await db.query('begin');
  const { rows } = await db.query(
    `with target as (
       select s.id, s.status, s.is_open
       from public.stores s join neon_auth."user" u on u.id = s.owner_id
       where u.email like 'dym-e2e-%@example.com'
         and (s.status <> 'suspended' or s.is_open))
     update public.stores s set status = 'suspended', is_open = false
     from target t where s.id = t.id
     returning s.id, t.status as old_status, t.is_open as old_open`);
  for (const r of rows) {
    await db.query(
      `select app.audit(null, 'store_status_changed', 'store', $1,
         jsonb_build_object('status', $2::text, 'is_open', $3::boolean),
         jsonb_build_object('status', 'suspended', 'is_open', false),
         'rangement des essais de bout en bout')`,
      [r.id, r.old_status, r.old_open]);
  }
  await db.query('commit');
  console.log(`✓ ${rows.length} boutique(s) d'essai rangée(s)`);
} catch (error) {
  await db.query('rollback');
  console.error(`✗ ${error.message}`);
  process.exitCode = 1;
} finally {
  await db.end();
}
