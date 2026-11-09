#!/usr/bin/env node
// Stories de démonstration (staging) : images de la galerie, envoyées par la vraie
// route (POST /v1/content/uploads → PUT présigné), puis publiées par save_content
// au nom de chaque vendeuse, chacune liée à 2-3 produits de sa boutique.
//
//   DATABASE_URL=… DEMO_PASSWORD=… DYM_AUTH_URL=… DYM_FUNCTIONS_URL=… node db/scripts/demo-stories.mjs
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

if (process.env.DYM_TARGET !== 'staging') {
  console.error('Refus : script de démonstration. Exiger DYM_TARGET=staging (jamais la production finale).');
  process.exit(1);
}
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const pg = createRequire(path.join(ROOT, 'functions/package.json'))('pg');
const { DATABASE_URL: url, DEMO_PASSWORD: password, DYM_AUTH_URL: authUrl, DYM_FUNCTIONS_URL: fnUrl } = process.env;
if (!url || !password || !authUrl || !fnUrl) {
  console.error('usage : DATABASE_URL=… DEMO_PASSWORD=… DYM_AUTH_URL=… DYM_FUNCTIONS_URL=… node db/scripts/demo-stories.mjs');
  process.exit(1);
}
const ASSETS = path.join(ROOT, 'apps/dym_gallery/assets/demo');
const IMAGES = ['stores/etal-akossiwa', 'stores/cour-esi', 'stores/epicerie-kodjo', 'illustrations/panier',
  'illustrations/splash-bassine', 'products/tomates', 'products/bissap', 'products/poisson-fume'];
const CAPTIONS = ['Arrivage de ce matin !', 'Tout frais au marché aujourd\'hui', 'Promo du jour, venez vite',
  'Nos meilleures ventes', 'Préparé avec amour', 'Livraison rapide dans le quartier'];

const db = new pg.Client({ connectionString: url.replace('sslmode=require', 'sslmode=verify-full') });
await db.connect();
const q = async (sql, p = []) => (await db.query(sql, p)).rows;
const vendors = await q(`
  select u.id, u.email, s.id as store_id, s.name from public.stores s
  join neon_auth."user" u on u.id = s.owner_id
  where s.status = 'active' and (u.email like '%+%@%' or u.email like '%@example.test') order by s.name`);

let total = 0;
for (const [i, v] of vendors.entries()) {
  if ((await q('select 1 from public.contents where store_id = $1 limit 1', [v.store_id])).length) continue;
  const signIn = await fetch(`${authUrl}/sign-in/email`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Origin: 'http://localhost:5556' },
    body: JSON.stringify({ email: v.email, password }),
  });
  if (!signIn.ok) { console.warn(`  ! ${v.name} : connexion ${signIn.status}`); continue; }
  const cookie = signIn.headers.getSetCookie().map((c) => c.split(';')[0]).join('; ');
  const { token } = await (await fetch(`${authUrl}/token`, { headers: { Cookie: cookie } })).json();
  const products = (await q(`select id from public.products where store_id = $1 and status = 'published' order by random() limit 6`, [v.store_id])).map((r) => r.id);
  let n = 0;
  for (let k = 0; k < 2; k++) {
    const img = IMAGES[(i * 2 + k) % IMAGES.length];
    const up = await fetch(`${fnUrl}/v1/content/uploads`, {
      method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ content_type: 'image/webp' }),
    });
    if (!up.ok) { console.warn(`  ! ${v.name} : upload ${up.status} ${(await up.text()).slice(0, 100)}`); continue; }
    const { content_id, object_key, upload_url } = await up.json();
    const put = await fetch(upload_url, { method: 'PUT', headers: { 'Content-Type': 'image/webp' },
      body: readFileSync(path.join(ASSETS, `${img}.webp`)) });
    if (!put.ok) { console.warn(`  ! ${v.name} : PUT ${put.status}`); continue; }
    try {
      await db.query("select set_config('request.jwt.claims', $1, false)", [JSON.stringify({ sub: v.id, role: 'authenticated' })]);
      await db.query('select public.save_content($1)', [{
        id: content_id, kind: 'story', media_key: object_key,
        caption: CAPTIONS[(i + k) % CAPTIONS.length], product_ids: products.slice(k * 3, k * 3 + 3),
      }]);
      n++; total++;
    } catch (e) { console.warn(`  ! ${v.name} : ${e.message}`); }
  }
  console.log(`  ✓ ${v.name} : ${n} stories`);
}
await db.query("select set_config('request.jwt.claims', '', false)");
console.log(`✓ ${total} stories`);
await db.end();
