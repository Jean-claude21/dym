#!/usr/bin/env node
// Vidéos de démonstration (staging) : clips verticaux MP4 (VIDEO_DIR, produits par
// ffmpeg depuis les images de la galerie), envoyés par la vraie route
// (POST /v1/content/uploads → PUT présigné), puis publiés par save_content (kind
// « video ») au nom de chaque vendeuse, chacun lié à 3 produits de sa boutique.
//
//   DATABASE_URL=… DEMO_PASSWORD=… DYM_AUTH_URL=… DYM_FUNCTIONS_URL=… VIDEO_DIR=… node db/scripts/demo-videos.mjs
import { readFileSync, readdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const pg = createRequire(path.join(ROOT, 'functions/package.json'))('pg');
const { DATABASE_URL: url, DEMO_PASSWORD: password, DYM_AUTH_URL: authUrl, DYM_FUNCTIONS_URL: fnUrl, VIDEO_DIR: dir } = process.env;
if (!url || !password || !authUrl || !fnUrl || !dir) {
  console.error('usage : DATABASE_URL=… DEMO_PASSWORD=… DYM_AUTH_URL=… DYM_FUNCTIONS_URL=… VIDEO_DIR=… node db/scripts/demo-videos.mjs');
  process.exit(1);
}
const clips = readdirSync(dir).filter((f) => f.endsWith('.mp4')).sort();
const CAPTIONS = ['Visite de l\'étal ce matin 🍅', 'Tout juste arrivé, regardez !', 'La recette du jour avec nos produits',
  'Frais, local, livré chez vous', 'Nos clientes adorent ça', 'Dernières pièces, commandez vite'];
const pause = (ms) => new Promise((r) => setTimeout(r, ms));

const db = new pg.Client({ connectionString: url.replace('sslmode=require', 'sslmode=verify-full') });
await db.connect();
const q = async (sql, p = []) => (await db.query(sql, p)).rows;
const vendors = await q(`
  select u.id, u.email, s.id as store_id, s.name from public.stores s
  join neon_auth."user" u on u.id = s.owner_id
  where s.status = 'active' and (u.email like '%+%@%' or u.email like '%@example.test') order by s.name`);

let total = 0;
for (const [i, v] of vendors.entries()) {
  if ((await q(`select 1 from public.contents where store_id = $1 and kind = 'video' limit 1`, [v.store_id])).length) continue;
  await pause(4000); // limite de connexions de Neon Auth
  const signIn = await fetch(`${authUrl}/sign-in/email`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Origin: 'http://localhost:5556' },
    body: JSON.stringify({ email: v.email, password }),
  });
  if (!signIn.ok) { console.warn(`  ! ${v.name} : connexion ${signIn.status}`); continue; }
  const cookie = signIn.headers.getSetCookie().map((c) => c.split(';')[0]).join('; ');
  const { token } = await (await fetch(`${authUrl}/token`, { headers: { Cookie: cookie } })).json();
  const products = (await q(`select id from public.products where store_id = $1 and status = 'published' order by random() limit 6`, [v.store_id])).map((r) => r.id);
  const count = v.email.includes('+') ? 3 : 1; // plus de vidéos pour les boutiques de test
  let n = 0;
  for (let k = 0; k < count; k++) {
    const clip = clips[(i * 3 + k) % clips.length];
    const up = await fetch(`${fnUrl}/v1/content/uploads`, {
      method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ content_type: 'video/mp4' }),
    });
    if (!up.ok) { console.warn(`  ! ${v.name} : upload ${up.status} ${(await up.text()).slice(0, 100)}`); continue; }
    const { content_id, object_key, upload_url } = await up.json();
    const put = await fetch(upload_url, { method: 'PUT', headers: { 'Content-Type': 'video/mp4' },
      body: readFileSync(path.join(dir, clip)) });
    if (!put.ok) { console.warn(`  ! ${v.name} : PUT ${put.status}`); continue; }
    try {
      await db.query("select set_config('request.jwt.claims', $1, false)", [JSON.stringify({ sub: v.id, role: 'authenticated' })]);
      await db.query('select public.save_content($1)', [{
        id: content_id, kind: 'video', media_key: object_key,
        caption: CAPTIONS[(i + k) % CAPTIONS.length], product_ids: products.slice((k % 2) * 3, (k % 2) * 3 + 3),
      }]);
      n++; total++;
    } catch (e) { console.warn(`  ! ${v.name} : ${e.message}`); }
  }
  console.log(`  ✓ ${v.name} : ${n} vidéo(s)`);
}
await db.query("select set_config('request.jwt.claims', '', false)");
console.log(`✓ ${total} vidéos`);
await db.end();
