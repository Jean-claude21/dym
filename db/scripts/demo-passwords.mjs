#!/usr/bin/env node
// Mot de passe de test pour les comptes de démonstration (staging seulement).
// Neon Auth (better-auth) : connexion email + mot de passe, sans vérification d'email.
// Le hachage suit better-auth : scrypt(N=16384, r=16, p=1, 64 octets), « selHex:cléHex ».
//
//   DATABASE_URL=… DEMO_EMAIL=moi@exemple.com DEMO_PASSWORD=… node db/scripts/demo-passwords.mjs
//
// Comptes concernés : DEMO_EMAIL, ses alias +xxx et les comptes de figuration @example.test.
import { randomBytes, randomUUID, scryptSync } from 'node:crypto';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const pg = createRequire(path.join(ROOT, 'functions/package.json'))('pg');
const { DATABASE_URL: url, DEMO_EMAIL: base, DEMO_PASSWORD: password } = process.env;
if (!url || !base?.includes('@') || !password || password.length < 8) {
  console.error('usage : DATABASE_URL=… DEMO_EMAIL=… DEMO_PASSWORD=(8 caractères min.) node db/scripts/demo-passwords.mjs');
  process.exit(1);
}

const hash = (plain) => {
  const salt = randomBytes(16).toString('hex');
  const key = scryptSync(plain.normalize('NFKC'), salt, 64, { N: 16384, r: 16, p: 1, maxmem: 128 * 16384 * 16 * 2 });
  return `${salt}:${key.toString('hex')}`;
};

const [local, domain] = base.toLowerCase().split('@');
const db = new pg.Client({ connectionString: url.replace('sslmode=require', 'sslmode=verify-full') });
await db.connect();
const users = (await db.query(
  `select id, email from neon_auth."user"
   where lower(email) = $1 or lower(email) like $2 or lower(email) like '%@example.test'
   order by email`,
  [`${local}@${domain}`, `${local}+%@${domain}`])).rows;
for (const u of users) {
  const secret = hash(password);
  const r = await db.query(
    `update neon_auth.account set password = $2, "updatedAt" = now()
     where "userId" = $1 and "providerId" = 'credential'`, [u.id, secret]);
  if (r.rowCount === 0) {
    await db.query(
      `insert into neon_auth.account (id, "accountId", "providerId", "userId", password, "createdAt", "updatedAt")
       values ($1, $2::text, 'credential', $2::uuid, $3, now(), now())`, [randomUUID(), u.id, secret]);
  }
  await db.query('update neon_auth."user" set "emailVerified" = true where id = $1', [u.id]);
  console.log(`✓ ${u.email}`);
}
console.log(`✓ ${users.length} compte(s)`);
await db.end();
