#!/usr/bin/env node
// Photos des produits de démonstration (staging) : images de la galerie du design
// system (apps/dym_gallery/assets/demo), envoyées par la vraie route d'upload
// (POST /v1/catalog/photo-uploads → PUT présigné), au nom de chaque vendeuse.
//
//   DATABASE_URL=… DEMO_PASSWORD=… DYM_AUTH_URL=… DYM_FUNCTIONS_URL=… node db/scripts/demo-photos.mjs
//
// Les vendeuses de démonstration (alias +xxx et @example.test) reçoivent le
// mot de passe de test s'il leur manque.
import { randomBytes, randomUUID, scryptSync } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const pg = createRequire(path.join(ROOT, 'functions/package.json'))('pg');
const { DATABASE_URL: url, DEMO_PASSWORD: password, DYM_AUTH_URL: authUrl, DYM_FUNCTIONS_URL: fnUrl } = process.env;
if (!url || !password || !authUrl || !fnUrl) {
  console.error('usage : DATABASE_URL=… DEMO_PASSWORD=… DYM_AUTH_URL=… DYM_FUNCTIONS_URL=… node db/scripts/demo-photos.mjs');
  process.exit(1);
}
const ASSETS = path.join(ROOT, 'apps/dym_gallery/assets/demo');
const ORIGIN = 'http://localhost:5556';

// Mot-clé du nom → image produit ; sinon image du rayon.
const BY_NAME = [
  [/tomate/i, 'products/tomates'], [/gombo/i, 'products/gombo'], [/oignon|ail\b/i, 'products/oignons'],
  [/piment/i, 'products/piment'], [/aubergine|poivron/i, 'products/aubergines'],
  [/gari|farine|fonio|mil\b|riz/i, 'products/gari'], [/huile|arachide/i, 'products/huile-rouge'],
  [/crevette/i, 'products/crevettes'], [/poisson|machoiron|adjovan/i, 'products/poisson-fume'],
  [/bissap/i, 'products/bissap'], [/gingembre/i, 'products/gingembre'], [/jus|eau de coco|kinkeliba/i, 'products/pack-jus'],
  [/feuille|épinard|oseille/i, 'products/ademe'], [/baobab/i, 'products/baobab'],
];
const BY_CATEGORY = {
  legumes: 'aisles/legumes', tomates: 'products/tomates', feuilles: 'products/ademe',
  'piments-oignons': 'products/piment', fruits: 'aisles/fruits', 'fait-maison': 'aisles/fait-maison',
  'jus-maison': 'products/pack-jus', 'plats-sauces': 'aisles/fait-maison', patisseries: 'aisles/fait-maison',
  tubercules: 'aisles/tubercules', 'poissons-fumes': 'products/poisson-fume', epices: 'aisles/epices',
  'cereales-farines': 'products/gari', 'huiles-condiments': 'products/huile-rouge', boissons: 'aisles/boissons',
  hygiene: 'aisles/hygiene', 'pagnes-textile': 'aisles/hygiene', beaute: 'aisles/hygiene',
};
const imageFor = (name, cat) => (BY_NAME.find(([re]) => re.test(name))?.[1]) ?? BY_CATEGORY[cat] ?? 'aisles/legumes';

const hash = (plain) => {
  const salt = randomBytes(16).toString('hex');
  const key = scryptSync(plain.normalize('NFKC'), salt, 64, { N: 16384, r: 16, p: 1, maxmem: 128 * 16384 * 16 * 2 });
  return `${salt}:${key.toString('hex')}`;
};

const db = new pg.Client({ connectionString: url.replace('sslmode=require', 'sslmode=verify-full') });
await db.connect();
const q = async (sql, p = []) => (await db.query(sql, p)).rows;

const vendors = await q(`
  select u.id, u.email, s.id as store_id, s.name
  from public.stores s join neon_auth."user" u on u.id = s.owner_id
  where u.email like '%+%@%' or u.email like '%@example.test'
  order by s.name`);

let uploaded = 0;
for (const v of vendors) {
  // Mot de passe de test (connexion sans vérification d'email).
  const has = await q(`select 1 from neon_auth.account where "userId" = $1 and "providerId" = 'credential'`, [v.id]);
  if (!has.length) {
    await q(`insert into neon_auth.account (id, "accountId", "providerId", "userId", password, "createdAt", "updatedAt")
             values ($1, $2::text, 'credential', $2::uuid, $3, now(), now())`, [randomUUID(), v.id, hash(password)]);
  }
  const signIn = await fetch(`${authUrl}/sign-in/email`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Origin: ORIGIN },
    body: JSON.stringify({ email: v.email, password }),
  });
  if (!signIn.ok) { console.warn(`  ! ${v.name} : connexion ${signIn.status}`); continue; }
  const cookie = signIn.headers.getSetCookie().map((c) => c.split(';')[0]).join('; ');
  const tok = await fetch(`${authUrl}/token`, { headers: { Cookie: cookie, Origin: ORIGIN } });
  const { token } = await tok.json();
  if (!token) { console.warn(`  ! ${v.name} : pas de jeton`); continue; }

  const products = await q(`
    select p.id, p.name, c.slug as cat from public.products p
    left join public.categories c on c.id = p.category_id
    where p.store_id = $1`, [v.store_id]);
  let n = 0;
  for (const p of products) {
    const file = readFileSync(path.join(ASSETS, `${imageFor(p.name, p.cat)}.webp`));
    const up = await fetch(`${fnUrl}/v1/catalog/photo-uploads`, {
      method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', Origin: ORIGIN },
      body: JSON.stringify({ content_type: 'image/webp' }),
    });
    if (!up.ok) { console.warn(`  ! ${p.name} : upload ${up.status} ${(await up.text()).slice(0, 120)}`); continue; }
    const { object_key, upload_url } = await up.json();
    const put = await fetch(upload_url, { method: 'PUT', headers: { 'Content-Type': 'image/webp' }, body: file });
    if (!put.ok) { console.warn(`  ! ${p.name} : PUT ${put.status}`); continue; }
    await q('delete from public.product_photos where product_id = $1', [p.id]);
    await q('insert into public.product_photos (product_id, object_key, sort) values ($1, $2, 0)', [p.id, object_key]);
    n++; uploaded++;
  }
  console.log(`  ✓ ${v.name} : ${n}/${products.length} photos`);
}
console.log(`✓ ${uploaded} photos envoyées`);
await db.end();
