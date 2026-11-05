#!/usr/bin/env node
// Stories vidéo et statuts écrits de démonstration (staging), pour chaque boutique
// active : une story vidéo (clip de VIDEO_DIR, envoyé par la route d'upload) et un
// statut écrit (texte sur fond de couleur), chacun lié à des produits.
//
//   DATABASE_URL=… DEMO_PASSWORD=… DYM_AUTH_URL=… DYM_FUNCTIONS_URL=… VIDEO_DIR=… node db/scripts/demo-story-mix.mjs
import { randomUUID } from 'node:crypto';
import { readFileSync, readdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const pg = createRequire(path.join(ROOT, 'functions/package.json'))('pg');
const { DATABASE_URL: url, DEMO_PASSWORD: password, DYM_AUTH_URL: authUrl, DYM_FUNCTIONS_URL: fnUrl, VIDEO_DIR: dir } = process.env;
if (!url || !password || !authUrl || !fnUrl || !dir) {
  console.error('usage : DATABASE_URL=… DEMO_PASSWORD=… DYM_AUTH_URL=… DYM_FUNCTIONS_URL=… VIDEO_DIR=… node db/scripts/demo-story-mix.mjs');
  process.exit(1);
}
const clips = readdirSync(dir).filter((f) => f.endsWith('.mp4')).sort();
const TEXTS = [
  ['🍅 Arrivage ce matin : tomates, gombo et piment frais. Livraison en 30 min !', '#c0392b'],
  ['Promo du jour : -10 % sur les jus maison 🥤 jusqu\'à 18 h', '#d35400'],
  ['Nous sommes ouverts tout le week-end. Commandez avant 19 h, livré ce soir 🛵', '#0b5d3b'],
  ['Nouveau : poisson fumé de Kayar, quantité limitée 🐟', '#2c3e50'],
  ['Merci pour vos 50 commandes cette semaine ❤️', '#8e44ad'],
  ['Le thiéboudienne du vendredi est de retour ! Réservez le vôtre 🍲', '#16a085'],
];
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const db = new pg.Client({ connectionString: url.replace('sslmode=require', 'sslmode=verify-full') });
await db.connect();
const q = async (sql, p = []) => (await db.query(sql, p)).rows;
const as = (user) => db.query("select set_config('request.jwt.claims', $1, false)", [JSON.stringify({ sub: user, role: 'authenticated' })]);

const vendors = await q(`
  select u.id, u.email, s.id as store_id, s.name from public.stores s
  join neon_auth."user" u on u.id = s.owner_id
  where s.status = 'active' and (u.email like '%+%@%' or u.email like '%@example.test') order by s.name`);

let videos = 0;
let texts = 0;
for (const [i, v] of vendors.entries()) {
  const products = (await q(`select id from public.products where store_id = $1 and status = 'published' order by random() limit 4`, [v.store_id])).map((r) => r.id);
  // Statut écrit : pas de média, directement par save_content.
  const [text, background] = TEXTS[i % TEXTS.length];
  try {
    await as(v.id);
    await q('select public.save_content($1)', [{ id: randomUUID(), kind: 'story', text, background, product_ids: products.slice(0, 2) }]);
    texts++;
  } catch (e) { console.warn(`  ! ${v.name} (texte) : ${e.message}`); }

  // Story vidéo : envoi par la route d'upload au nom de la vendeuse.
  await pause(4000); // limite de connexions de Neon Auth
  const signIn = await fetch(`${authUrl}/sign-in/email`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Origin: 'http://localhost:5556' },
    body: JSON.stringify({ email: v.email, password }),
  });
  if (!signIn.ok) { console.warn(`  ! ${v.name} : connexion ${signIn.status}`); continue; }
  const cookie = signIn.headers.getSetCookie().map((c) => c.split(';')[0]).join('; ');
  const { token } = await (await fetch(`${authUrl}/token`, { headers: { Cookie: cookie } })).json();
  const up = await fetch(`${fnUrl}/v1/content/uploads`, {
    method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ content_type: 'video/mp4' }),
  });
  if (!up.ok) { console.warn(`  ! ${v.name} : upload ${up.status}`); continue; }
  const { content_id, object_key, upload_url } = await up.json();
  const put = await fetch(upload_url, { method: 'PUT', headers: { 'Content-Type': 'video/mp4' },
    body: readFileSync(path.join(dir, clips[(i + 5) % clips.length])) });
  if (!put.ok) { console.warn(`  ! ${v.name} : PUT ${put.status}`); continue; }
  try {
    await as(v.id);
    await q('select public.save_content($1)', [{ id: content_id, kind: 'story', media_key: object_key,
      caption: 'En direct de la boutique 🎥', product_ids: products.slice(2, 4) }]);
    videos++;
  } catch (e) { console.warn(`  ! ${v.name} (vidéo) : ${e.message}`); }
  console.log(`  ✓ ${v.name}`);
}
await db.query("select set_config('request.jwt.claims', '', false)");
console.log(`✓ ${videos} stories vidéo, ${texts} statuts écrits`);
await db.end();
