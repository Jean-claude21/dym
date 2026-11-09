#!/usr/bin/env node
// Jeu de données de démonstration (staging ou branche de test, jamais la production).
// Tout passe par les fonctions métier (profils, boutiques, catalogue, panier, commande,
// cycle de vie, paiements simulés, avis, litiges, messages, tickets) pour rester cohérent.
//
//   DATABASE_URL=… DEMO_EMAIL=prenom.nom@proton.me node db/scripts/seed-demo.mjs
//
// Les comptes « à tester » utilisent des alias +xxx de DEMO_EMAIL : le code de connexion
// arrive dans la boîte de DEMO_EMAIL. Les comptes de figuration sont en @example.test.
// Dépendance : `pg` (installé dans functions/).
import { randomUUID } from 'node:crypto';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

if (process.env.DYM_TARGET !== 'staging') {
  console.error('Refus : script de démonstration. Exiger DYM_TARGET=staging (jamais la production finale).');
  process.exit(1);
}
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const pg = createRequire(path.join(ROOT, 'functions/package.json'))('pg');

const url = process.env.DATABASE_URL;
const base = process.env.DEMO_EMAIL;
if (!url || !base?.includes('@')) {
  console.error('usage : DATABASE_URL=… DEMO_EMAIL=moi@exemple.com node db/scripts/seed-demo.mjs');
  process.exit(1);
}
const [local, domain] = base.toLowerCase().split('@');
const alias = (tag) => `${local}+${tag}@${domain}`;

const db = new pg.Client({ connectionString: url.replace('sslmode=require', 'sslmode=verify-full') });
await db.connect();
const q = async (sql, params = []) => (await db.query(sql, params)).rows;
const one = async (sql, params = []) => (await q(sql, params))[0];
let failures = 0;
const attempt = async (label, fn) => {
  try {
    return await fn();
  } catch (e) {
    failures++;
    console.warn(`  ! ${label} : ${e.message}`);
    return null;
  }
};

// Agit comme la personne connectée (claims lus par app.current_user_id()).
const as = (user) =>
  db.query("select set_config('request.jwt.claims', $1, false)", [
    user ? JSON.stringify({ sub: user, role: 'authenticated' }) : '',
  ]);
const rpc = async (user, fn, args = []) => {
  await as(user);
  const ph = args.map((_, i) => `$${i + 1}`).join(', ');
  const r = await one(`select ${fn}(${ph}) as r`, args);
  return r?.r;
};

const rand = (() => {
  let s = 20261105;
  return () => ((s = (s * 1103515245 + 12345) % 2147483648) / 2147483648);
})();
const pick = (a) => a[Math.floor(rand() * a.length)];
const between = (a, b) => a + Math.floor(rand() * (b - a + 1));

if (await one('select 1 from neon_auth."user" where lower(email) = $1', [alias('awa')])) {
  console.log('• données de démonstration déjà présentes (compte ' + alias('awa') + ')');
  process.exit(0);
}

// ---------------------------------------------------------------- référentiel
const zone = async (country, city, slug) =>
  (await one(
    `select z.id from public.zones z join public.cities c on c.id = z.city_id
     where c.country_code = $1 and c.slug = $2 and z.slug = $3`, [country, city, slug]))?.id;
const cityZones = async (country, city) =>
  (await q(`select z.id from public.zones z join public.cities c on c.id = z.city_id
            where c.country_code = $1 and c.slug = $2 and z.is_active`, [country, city])).map((r) => r.id);
const cat = async (slug) => (await one('select id from public.categories where slug = $1', [slug]))?.id;
const unit = async (country, code) =>
  (await one('select id from public.units where country_code = $1 and code = $2', [country, code]))?.id;
const methods = async (country) =>
  q(`select id, provider_code from public.payment_methods where country_code = $1 and is_active order by sort`, [country]);
const zonePos = async (z) => one('select latitude, longitude from public.zones where id = $1', [z]);

// ---------------------------------------------------------------- comptes
const users = {};
async function account(key, email, firstName, country, city, zoneSlug, app) {
  const id = randomUUID();
  await q(
    `insert into neon_auth."user" (id, name, email, "emailVerified", "createdAt", "updatedAt")
     values ($1, $2, $3, true, now() - interval '45 days', now())`, [id, firstName, email]);
  const z = await zone(country, city, zoneSlug);
  await rpc(id, 'public.complete_profile', [firstName, z, app, 'fr']);
  users[key] = { id, email, firstName, country, city, zone: z };
  return users[key];
}

console.log('→ comptes');
const admin = await one('select id from neon_auth."user" where lower(email) = $1', [base.toLowerCase()]);
if (admin) {
  users.admin = { id: admin.id };
} else {
  await account('admin', base.toLowerCase(), 'Jean-Claude', 'FR', 'paris', 'paris-11', 'client');
}
await q('select app.claim_admin_invite($1)', [users.admin.id]);

const testClients = [
  ['awa', 'Awa', 'FR', 'paris', 'paris-18'],
  ['moussa', 'Moussa', 'FR', 'paris', 'paris-11'],
  ['lea', 'Léa', 'FR', 'lyon', 'croix-rousse'],
  ['kossi', 'Kossi', 'TG', 'lome', 'be'],
];
for (const [k, n, c, ci, z] of testClients) await account(k, alias(k), n, c, ci, z, 'client');

const extraNames = ['Inès', 'Mamadou', 'Sophie', 'Ibrahim', 'Chloé', 'Youssouf', 'Camille', 'Fanta',
  'Lucas', 'Mariam', 'Hugo', 'Aïcha', 'Nadia', 'Thomas', 'Binta', 'Yao', 'Afi', 'Kodjo'];
const extraClients = [];
for (const [i, n] of extraNames.entries()) {
  const tg = i >= 15;
  const z = tg ? pick(['be', 'tokoin', 'nyekonakpoe', 'adidogome']) :
    pick(['paris-10', 'paris-11', 'paris-18', 'paris-19', 'paris-20', 'paris-13']);
  extraClients.push(await account(`c${i}`, `client${i + 1}@example.test`, n,
    tg ? 'TG' : 'FR', tg ? 'lome' : 'paris', z, 'client'));
}

// ---------------------------------------------------------------- catalogues
// [nom, rayon, unité FR, unité TG, prix FR (centimes), prix TG (F CFA), variantes?]
const CATALOG = {
  legumes: [
    ['Tomates fraîches', 'tomates', 'kilo', 'tas', 349, 500],
    ['Tomates cerises', 'tomates', 'barquette', 'bol', 299, 400],
    ['Gombo frais', 'legumes', 'demi_kilo', 'tas', 450, 300],
    ['Feuilles de manioc', 'feuilles', 'botte', 'botte', 299, 200],
    ['Épinards', 'feuilles', 'botte', 'botte', 249, 150],
    ['Oseille de Guinée', 'feuilles', 'botte', 'botte', 279, 200],
    ['Piment antillais', 'piments-oignons', 'barquette', 'tas', 199, 100],
    ['Oignons rouges', 'piments-oignons', 'kilo', 'tas', 229, 300],
    ['Ail', 'piments-oignons', 'sachet', 'tas', 159, 100],
    ['Aubergines africaines', 'legumes', 'demi_kilo', 'tas', 399, 250],
    ['Poivrons', 'legumes', 'kilo', 'tas', 399, 500],
    ['Carottes', 'legumes', 'kilo', 'tas', 189, 300],
  ],
  fruits: [
    ['Mangues', 'fruits', 'piece', 'piece', 199, 150],
    ['Bananes plantain', 'fruits', 'kilo', 'tas', 349, 500],
    ['Ananas', 'fruits', 'piece', 'piece', 299, 400],
    ['Papaye', 'fruits', 'piece', 'piece', 399, 300],
    ['Avocats', 'fruits', 'piece', 'tas', 149, 300],
    ['Oranges', 'fruits', 'kilo', 'tas', 249, 400],
    ['Citrons verts', 'fruits', 'sachet', 'tas', 199, 200],
    ['Noix de coco', 'fruits', 'piece', 'piece', 249, 300],
  ],
  'fait-maison': [
    ['Jus de bissap', 'jus-maison', 'bouteille', 'bouteille', 450, 500, true],
    ['Jus de gingembre', 'jus-maison', 'bouteille', 'bouteille', 450, 500, true],
    ['Thiéboudienne (portion)', 'plats-sauces', 'piece', 'piece', 1290, 2000],
    ['Mafé poulet (portion)', 'plats-sauces', 'piece', 'piece', 1190, 1800],
    ['Sauce graine', 'plats-sauces', 'piece', 'bol', 990, 1500],
    ['Akassa', 'plats-sauces', 'piece', 'piece', 350, 200],
    ['Beignets haricot (x6)', 'patisseries', 'sachet', 'sachet', 400, 300],
    ['Gâteau coco', 'patisseries', 'piece', 'piece', 600, 500],
  ],
  'poissons-fumes': [
    ['Poisson fumé (chinchard)', 'poissons-fumes', 'piece', 'piece', 599, 700],
    ['Crevettes séchées', 'poissons-fumes', 'sachet', 'sachet', 499, 600],
    ['Machoiron fumé', 'poissons-fumes', 'piece', 'piece', 899, 1500],
    ['Adjovan', 'poissons-fumes', 'sachet', 'sachet', 399, 400],
  ],
  epices: [
    ['Soumbala', 'epices', 'sachet', 'sachet', 349, 200],
    ['Poivre de Penja', 'epices', 'sachet', 'sachet', 690, 1000],
    ['Gingembre en poudre', 'epices', 'sachet', 'sachet', 299, 300],
    ['Piment séché', 'epices', 'sachet', 'sachet', 249, 200],
    ['Cube d\'épices maison', 'epices', 'sachet', 'sachet', 199, 150],
  ],
  'cereales-farines': [
    ['Gari', 'cereales-farines', 'kilo', 'bol', 399, 500],
    ['Farine de manioc', 'cereales-farines', 'kilo', 'bol', 349, 400],
    ['Riz parfumé', 'cereales-farines', 'kilo', 'kilo', 299, 700, true],
    ['Fonio', 'cereales-farines', 'demi_kilo', 'bol', 499, 600],
    ['Mil', 'cereales-farines', 'kilo', 'bol', 329, 400],
  ],
  'huiles-condiments': [
    ['Huile de palme', 'huiles-condiments', 'litre', 'litre', 699, 1200],
    ['Huile d\'arachide', 'huiles-condiments', 'litre', 'litre', 499, 1000],
    ['Pâte d\'arachide', 'huiles-condiments', 'piece', 'boite', 449, 800],
  ],
  tubercules: [
    ['Igname', 'tubercules', 'kilo', 'tas', 399, 600],
    ['Manioc', 'tubercules', 'kilo', 'tas', 299, 300],
    ['Patate douce', 'tubercules', 'kilo', 'tas', 279, 400],
    ['Taro', 'tubercules', 'kilo', 'tas', 349, 500],
  ],
  boissons: [
    ['Bissap séché', 'boissons', 'sachet', 'sachet', 299, 300],
    ['Kinkeliba', 'boissons', 'sachet', 'sachet', 349, 300],
    ['Eau de coco', 'boissons', 'bouteille', 'bouteille', 299, 400],
  ],
  'pagnes-textile': [
    ['Pagne wax 6 yards', 'pagnes-textile', 'piece', 'piece', 3990, 15000, true],
    ['Foulard wax', 'pagnes-textile', 'piece', 'piece', 1290, 4000],
    ['Sac en wax', 'pagnes-textile', 'piece', 'piece', 2490, 8000],
  ],
  beaute: [
    ['Beurre de karité brut', 'beaute', 'piece', 'boite', 899, 2000],
    ['Savon noir', 'beaute', 'piece', 'piece', 499, 500],
    ['Huile de coco vierge', 'beaute', 'bouteille', 'bouteille', 799, 1500],
  ],
  hygiene: [['Éponge végétale', 'hygiene', 'piece', 'piece', 299, 300]],
};

const WEEK = [1, 2, 3, 4, 5, 6].map((d) => ({ weekday: d, opens_at: '08:00', closes_at: '20:00' }))
  .concat([{ weekday: 7, opens_at: '09:00', closes_at: '13:00' }]);

const stores = {};
async function store(key, owner, name, desc, origin, mainCat, catalogs, opts = {}) {
  const u = users[owner];
  const country = u.country;
  await rpc(u.id, 'public.start_store', [name, desc]);
  await rpc(u.id, 'public.update_store', [{
    origin, zone_id: u.zone, main_category_id: await cat(mainCat), prep_time_minutes: opts.prep ?? 20,
    offers_pickup: opts.pickup ?? true,
  }]);
  const pos = await zonePos(u.zone);
  await rpc(u.id, 'public.set_store_pickup_address', [opts.address ?? `${between(2, 120)} rue du Marché`,
    'Devant l\'entrée', pos?.latitude, pos?.longitude, country === 'FR' ? '+33612345678' : '+22890123456']);
  await rpc(u.id, 'public.set_store_delivery_zones', [await cityZones(country, u.city)]);
  await rpc(u.id, 'public.set_store_payment_methods', [(await methods(country)).map((m) => m.id)]);
  await rpc(u.id, 'public.set_store_hours', [JSON.stringify(opts.hours ?? WEEK)]);
  const s = await rpc(u.id, 'public.publish_store');
  const storeId = (await one('select id from public.stores where owner_id = $1', [u.id])).id;

  // Catégories de la boutique, puis produits.
  const shelves = {};
  for (const c of catalogs) {
    shelves[c] = randomUUID();
    await rpc(u.id, 'public.save_store_category', [shelves[c], CATALOG_LABEL[c] ?? c]);
  }
  const products = [];
  for (const c of catalogs) {
    for (const [pName, catSlug, uFr, uTg, pFr, pTg, multi] of CATALOG[c]) {
      const pid = randomUUID();
      const price = country === 'FR' ? pFr : pTg;
      const variants = multi
        ? [
            { id: randomUUID(), label: 'Petit', price_minor: price, stock_quantity: between(0, 25) },
            { id: randomUUID(), label: 'Grand', price_minor: Math.round(price * 1.8), stock_quantity: between(3, 25) },
          ]
        : [{ id: randomUUID(), label: 'Standard', price_minor: price,
             stock_quantity: rand() < 0.12 ? 0 : rand() < 0.2 ? between(1, 3) : between(8, 60) }];
      const ok = await attempt(`produit ${pName}`, async () => {
        await rpc(u.id, 'public.save_product', [{
          id: pid, name: pName, category_id: await cat(catSlug),
          unit_id: await unit(country, country === 'FR' ? uFr : uTg), price_minor: price,
          photo_keys: [`stores/${storeId}/products/${pid}.jpg`],
          store_category_ids: shelves[c] ? [shelves[c]] : [], variants,
        }]);
        await rpc(u.id, 'public.publish_product', [pid]);
        return true;
      });
      if (ok) products.push({ id: pid, name: pName, variants });
    }
  }
  if (opts.closed) await rpc(u.id, 'public.set_store_open', [false]);
  stores[key] = { id: storeId, owner: u, country, products, closed: Boolean(opts.closed) };
  console.log(`  ✓ ${name} : ${products.length} produits`);
  return stores[key];
}
const CATALOG_LABEL = {
  legumes: 'Légumes', fruits: 'Fruits', 'fait-maison': 'Fait maison', 'poissons-fumes': 'Poissons fumés',
  epices: 'Épices', 'cereales-farines': 'Céréales & farines', 'huiles-condiments': 'Huiles',
  tubercules: 'Tubercules', boissons: 'Boissons', 'pagnes-textile': 'Pagnes', beaute: 'Beauté', hygiene: 'Maison',
};

console.log('→ vendeuses et boutiques');
const testVendors = [
  ['fatou', 'Fatou', 'FR', 'paris', 'paris-18'],
  ['aminata', 'Aminata', 'FR', 'paris', 'paris-11'],
  ['marie', 'Marie', 'FR', 'lyon', 'croix-rousse'],
  ['akossiwa', 'Akossiwa', 'TG', 'lome', 'be'],
];
for (const [k, n, c, ci, z] of testVendors) await account(k, alias(k), n, c, ci, z, 'vendor');
const bgVendors = [
  ['v1', 'Karim', 'FR', 'paris', 'paris-20'], ['v2', 'Ousmane', 'FR', 'paris', 'paris-10'],
  ['v3', 'Mei', 'FR', 'paris', 'paris-13'], ['v4', 'Ndèye', 'FR', 'paris', 'paris-19'],
  ['v5', 'Rokia', 'FR', 'paris', 'paris-18'], ['v6', 'Salimata', 'FR', 'paris', 'paris-17'],
  ['v7', 'Bintou', 'FR', 'lyon', 'guillotiere'], ['v8', 'Rachid', 'FR', 'marseille', 'noailles'],
  ['v9', 'Ablavi', 'TG', 'lome', 'tokoin'], ['v10', 'Komi', 'TG', 'lome', 'kodjoviakope'],
];
for (const [k, n, c, ci, z] of bgVendors) await account(k, `vendeuse.${k}@example.test`, n, c, ci, z, 'vendor');

await store('fatou', 'fatou', 'Chez Fatou — Épicerie africaine', 'Produits frais d\'Afrique de l\'Ouest, livrés dans le 18e.', 'magasin', 'legumes', ['legumes', 'fruits', 'tubercules', 'cereales-farines', 'huiles-condiments']);
await store('aminata', 'aminata', 'Les Saveurs d\'Aminata', 'Plats et jus faits maison chaque jour.', 'maison', 'fait-maison', ['fait-maison', 'boissons']);
await store('marie', 'marie', 'Primeur de la Croix-Rousse', 'Fruits et légumes du marché.', 'marche', 'legumes', ['legumes', 'fruits']);
await store('akossiwa', 'akossiwa', 'Marché de Bè — Tantie Akossiwa', 'Le meilleur du marché de Bè.', 'marche', 'legumes', ['legumes', 'fruits', 'tubercules', 'epices']);
await store('v1', 'v1', 'Primeur de Belleville', 'Fruits exotiques et légumes.', 'marche', 'fruits', ['fruits', 'legumes']);
await store('v2', 'v2', 'Poissonnerie Dakar', 'Poissons fumés et séchés.', 'magasin', 'poissons-fumes', ['poissons-fumes', 'epices']);
await store('v3', 'v3', 'Épices du Monde', 'Épices, farines et condiments.', 'magasin', 'epices', ['epices', 'cereales-farines', 'huiles-condiments']);
await store('v4', 'v4', 'Boulangerie Teranga', 'Pâtisseries et jus maison.', 'maison', 'fait-maison', ['fait-maison']);
await store('v5', 'v5', 'Wax & Pagnes Paris', 'Tissus wax et accessoires.', 'magasin', 'pagnes-textile', ['pagnes-textile', 'beaute', 'hygiene']);
await store('v6', 'v6', 'Karité & Co', 'Beauté naturelle.', 'maison', 'beaute', ['beaute'], { closed: true });
await store('v7', 'v7', 'Afro Market Guillotière', 'Épicerie africaine à Lyon.', 'magasin', 'legumes', ['legumes', 'tubercules', 'cereales-farines']);
await store('v8', 'v8', 'Noailles Exotique', 'Le marché de Noailles chez vous.', 'marche', 'fruits', ['fruits', 'legumes', 'epices']);
await store('v9', 'v9', 'Jus Maman Ablavi', 'Jus et plats faits maison.', 'maison', 'fait-maison', ['fait-maison', 'boissons']);
await store('v10', 'v10', 'Poissons fumés de Kodjoviakopé', 'Poisson fumé du jour.', 'marche', 'poissons-fumes', ['poissons-fumes']);

// ---------------------------------------------------------------- commandes
const addresses = {};
async function addressOf(u) {
  if (addresses[u.id]) return addresses[u.id];
  const pos = await zonePos(u.zone);
  await rpc(u.id, 'public.save_address', [{
    id: randomUUID(), kind: 'home', label: 'Maison', zone_id: u.zone, landmark: 'Interphone au nom de ' + u.firstName,
    phone: u.country === 'FR' ? '+33698765432' : '+22891234567', latitude: pos?.latitude,
    longitude: pos?.longitude, is_default: true,
  }]);
  addresses[u.id] = (await one('select id from public.customer_addresses where user_id = $1 order by created_at desc limit 1', [u.id])).id;
  return addresses[u.id];
}

// Passe une commande (une boutique) ; renvoie l'id de la commande.
async function order(client, st, { online = false, pickup = false, items = between(1, 4) } = {}) {
  // Stock réel (il baisse au fil des commandes) ; panier vidé des essais précédents.
  const avail = (await q(
    `select v.id from public.product_variants v join public.products p on p.id = v.product_id
     where p.store_id = $1 and p.status = 'published' and v.stock_quantity > 4`, [st.id])).map((r) => r.id);
  if (!avail.length) return null;
  await q('delete from public.cart_items where cart_id in (select id from public.carts where user_id = $1)', [client.id]);
  for (let i = 0; i < items; i++) await rpc(client.id, 'public.cart_add', [pick(avail), between(1, 3)]);
  const ms = await methods(st.country);
  const method = online ? ms.find((m) => m.provider_code === 'simulator') : ms.find((m) => m.provider_code === 'cash');
  const req = { payment_method_id: method.id, substitution_allowed: true };
  if (pickup) req.modes = { [st.id]: 'pickup' };
  else req.address_id = await addressOf(client);
  await as(client.id);
  const r = await one('select app.place_order($1, $2, $3, now(), $4) as r',
    [client.id, randomUUID(), req, ['simulator']]);
  const purchase = r.r.purchase?.id ?? r.r.id ?? r.r.purchase_id;
  const o = await one(
    `select o.id, o.purchase_id from public.orders o join public.purchases p on p.id = o.purchase_id
     where p.user_id = $1 order by o.created_at desc limit 1`, [client.id]);
  if (online) {
    const pay = await one('select id, amount_minor, currency_code from public.payments where purchase_id = $1', [o.purchase_id]);
    if (pay) {
      await q('select app.apply_payment_event($1, $2, $3, true, $4, $5, $6, $7)',
        ['simulator', 'demo-' + randomUUID(), { demo: true }, pay.id, online === 'failed' ? 'failed' : 'succeeded',
          pay.amount_minor, pay.currency_code]);
    }
  }
  void purchase;
  return o.id;
}

const STEPS = ['accepted', 'preparing', 'ready', 'out_for_delivery', 'delivered'];
async function advance(st, orderId, target, { pickup = false, cash = true } = {}) {
  const v = st.owner.id;
  await as(v);
  if (target === 'refused') {
    return q('select app.transition_order($1, $2, $3, $4, $5)', [v, orderId, 'refused', 'pending', 'out_of_stock']);
  }
  const path = pickup ? ['accepted', 'preparing', 'ready', 'delivered'] : STEPS;
  let from = 'pending';
  for (const to of path) {
    await q('select app.transition_order($1, $2, $3, $4)', [v, orderId, to, from]);
    from = to;
    if (to === target) break;
  }
  if (target === 'delivered' && cash) {
    await attempt('encaissement', () => q('select app.confirm_cash($1, $2)', [v, orderId]));
  }
}

async function cancelByClient(client, orderId) {
  await as(client.id);
  await q('select app.transition_order($1, $2, $3, $4, $5)', [client.id, orderId, 'cancelled', 'pending', 'changed_mind']);
}

const delivered = [];
const scenario = async (label, fn) => attempt(label, fn);

console.log('→ commandes des comptes de test (tous les statuts)');
const S = stores;
const U = users;
// Awa (Paris 18) chez Fatou : un exemple de chaque statut.
for (const [target, opts] of [
  ['pending', {}], ['accepted', {}], ['preparing', {}], ['ready', {}], ['out_for_delivery', {}],
  ['delivered', {}], ['delivered', { online: true }], ['delivered', { pickup: true }],
  ['refused', {}], ['cancelled', {}], ['pending', { online: true }], ['pending', { online: 'failed' }],
]) {
  await scenario(`awa ${target}`, async () => {
    const id = await order(U.awa, S.fatou, opts);
    if (target === 'cancelled') await cancelByClient(U.awa, id);
    else if (target !== 'pending') await advance(S.fatou, id, target, { pickup: opts.pickup, cash: !opts.online });
    if (target === 'delivered') delivered.push({ client: U.awa, store: S.fatou, id });
  });
}
// Awa chez d'autres boutiques de Paris.
for (const k of ['aminata', 'v1', 'v2', 'v3', 'v4', 'v5']) {
  await scenario(`awa ${k}`, async () => {
    const id = await order(U.awa, S[k]);
    await advance(S[k], id, 'delivered');
    delivered.push({ client: U.awa, store: S[k], id });
  });
}
// Moussa chez Aminata et Fatou.
for (const [k, target] of [['aminata', 'pending'], ['aminata', 'preparing'], ['aminata', 'delivered'],
  ['fatou', 'delivered'], ['fatou', 'out_for_delivery'], ['v3', 'delivered']]) {
  await scenario(`moussa ${k} ${target}`, async () => {
    const id = await order(U.moussa, S[k]);
    if (target !== 'pending') await advance(S[k], id, target);
    if (target === 'delivered') delivered.push({ client: U.moussa, store: S[k], id });
  });
}
// Léa à Lyon, Kossi à Lomé.
for (const [c, k, target] of [['lea', 'marie', 'pending'], ['lea', 'marie', 'accepted'], ['lea', 'marie', 'delivered'],
  ['lea', 'v7', 'delivered'], ['kossi', 'akossiwa', 'pending'], ['kossi', 'akossiwa', 'ready'],
  ['kossi', 'akossiwa', 'delivered'], ['kossi', 'v9', 'delivered'], ['kossi', 'v10', 'delivered']]) {
  await scenario(`${c} ${k} ${target}`, async () => {
    const id = await order(U[c], S[k]);
    if (target !== 'pending') await advance(S[k], id, target);
    if (target === 'delivered') delivered.push({ client: U[c], store: S[k], id });
  });
}

console.log('→ historique (clientes de figuration, 30 derniers jours)');
const history = [];
for (const c of extraClients) {
  const local = Object.values(S).filter((s) => s.country === c.country && s.owner.city === c.city && !s.closed);
  for (let i = 0; i < between(3, 6); i++) {
    const st = pick(local);
    await scenario(`historique ${c.firstName}`, async () => {
      const r = rand();
      const online = r < 0.25;
      const id = await order(c, st, { online });
      if (r < 0.06) await cancelByClient(c, id);
      else if (r < 0.1) await advance(st, id, 'refused');
      else {
        await advance(st, id, 'delivered', { cash: !online });
        delivered.push({ client: c, store: st, id });
      }
      history.push(id);
    });
  }
}
// Commandes en attente chez les vendeuses de test (pour la file « à traiter »).
for (const k of ['fatou', 'fatou', 'fatou', 'aminata', 'aminata', 'marie', 'akossiwa', 'akossiwa']) {
  const c = pick(extraClients.filter((x) => x.country === S[k].country && x.city === S[k].owner.city));
  if (c) await scenario(`attente ${k}`, () => order(c, S[k]));
}

// Dates étalées : l'historique remonte sur 30 jours.
for (const id of history) {
  const days = between(1, 30);
  await attempt('dates', async () => {
    const iv = `${days} days ${between(0, 10)} hours`;
    await q(`update public.orders set created_at = created_at - $2::interval, updated_at = updated_at - $2::interval,
      accepted_at = accepted_at - $2::interval, preparing_at = preparing_at - $2::interval,
      ready_at = ready_at - $2::interval, out_for_delivery_at = out_for_delivery_at - $2::interval,
      delivered_at = delivered_at - $2::interval, refused_at = refused_at - $2::interval,
      cancelled_at = cancelled_at - $2::interval, cash_collected_at = cash_collected_at - $2::interval
      where id = $1`, [id, iv]);
    await q('update public.order_status_events set occurred_at = occurred_at - $2::interval where order_id = $1', [id, iv]);
    await q(`update public.purchases p set created_at = p.created_at - $2::interval
             from public.orders o where o.id = $1 and p.id = o.purchase_id`, [id, iv]);
    await q(`update public.payments y set created_at = y.created_at - $2::interval,
             updated_at = y.updated_at - $2::interval, completed_at = y.completed_at - $2::interval
             from public.orders o where o.id = $1 and y.purchase_id = o.purchase_id`, [id, iv]);
  });
}

// ---------------------------------------------------------------- avis
console.log('→ avis');
const COMMENTS = ['Produits très frais, merci !', 'Livraison rapide et soignée.', 'Comme au pays !',
  'Bon rapport qualité-prix.', 'Un peu de retard mais très bon.', 'Parfait, je recommande.',
  'Il manquait un article, sinon bien.', 'Toujours aussi bon.'];
let reviews = 0;
for (const d of delivered) {
  if (rand() < 0.7) {
    const ok = await attempt('avis', () => q('select app.leave_review($1, $2, $3, $4, $5)', [
      d.client.id, d.id, pick([5, 5, 5, 4, 4, 4, 3, 2]),
      [pick(['fresh', 'well_packed', 'fast', 'friendly'])], pick(COMMENTS)]));
    if (ok) {
      reviews++;
      if (rand() < 0.4) {
        const r = await one('select id from public.reviews where order_id = $1', [d.id]);
        if (r) await attempt('réponse avis', () => q('select app.reply_review($1, $2, $3)',
          [d.store.owner.id, r.id, 'Merci beaucoup, à bientôt !']));
      }
    }
  }
}
console.log(`  ✓ ${reviews} avis`);

// ---------------------------------------------------------------- litiges
console.log('→ litiges');
const awaDelivered = delivered.filter((d) => d.client === U.awa);
const disputeOn = async (d, reason, text) => {
  await as(d.client.id);
  const r = await one('select app.open_dispute($1, $2, $3, $4) as r', [d.client.id, d.id, reason, text]);
  return (await one('select id from public.disputes where order_id = $1', [d.id]))?.id ?? r?.r?.id;
};
await attempt('litige ouvert', () => disputeOn(awaDelivered[0], 'missing_item', 'Il manquait les oignons dans le sac.'));
await attempt('litige répondu', async () => {
  const id = await disputeOn(awaDelivered[1], 'quality', 'Les mangues étaient trop mûres.');
  await as(awaDelivered[1].store.owner.id);
  await q('select app.dispute_reply($1, $2, $3)', [awaDelivered[1].store.owner.id, id, 'Désolée ! Je vous en remets à la prochaine commande.']);
});
await attempt('litige remboursé', async () => {
  const d = awaDelivered[2];
  const id = await disputeOn(d, 'damaged', 'Le jus a coulé pendant la livraison.');
  await as(users.admin.id);
  await q('select app.resolve_dispute($1, $2, $3, $4, $5)', [users.admin.id, id, 'partial_refund', 200, 'Geste commercial']);
});
await attempt('litige clos', async () => {
  const d = delivered.find((x) => x.client === U.moussa);
  const id = await disputeOn(d, 'other', 'Le livreur n\'a pas sonné.');
  await as(users.admin.id);
  await q('select app.resolve_dispute($1, $2, $3)', [users.admin.id, id, 'no_action']);
});
await attempt('litige Lomé', () => disputeOn(delivered.find((x) => x.client === U.kossi), 'wrong_item', 'J\'ai reçu du manioc au lieu de l\'igname.'));

// ---------------------------------------------------------------- messages
console.log('→ messages');
async function chat(client, st, lines) {
  await as(client.id);
  const c = await one('select app.start_conversation($1, $2) as r', [client.id, st.id]);
  const conv = c.r?.id ?? (await one('select id from public.conversations where store_id = $1 order by created_at desc limit 1', [st.id])).id;
  for (const [who, text, product] of lines) {
    const u = who === 'c' ? client.id : st.owner.id;
    await as(u);
    await q('select app.send_message($1, $2, $3, $4, null, $5, $6)',
      [u, conv, product ? 'product' : 'text', text, product ?? null, randomUUID()]);
  }
}
await attempt('chat awa-fatou', () => chat(U.awa, S.fatou, [
  ['c', 'Bonjour, avez-vous du gombo frais aujourd\'hui ?'],
  ['v', 'Bonjour Awa ! Oui, arrivage de ce matin.'],
  ['v', 'Le voici', S.fatou.products.find((p) => p.name.startsWith('Gombo'))?.id],
  ['c', 'Super, je commande tout de suite. Merci !'],
]));
await attempt('chat moussa-aminata', () => chat(U.moussa, S.aminata, [
  ['c', 'Le thiéboudienne est disponible ce soir ?'],
  ['v', 'Oui, jusqu\'à 20h. Je vous en mets de côté ?'],
]));
await attempt('chat awa-aminata', () => chat(U.awa, S.aminata, [['c', 'Vous livrez dans le 18e ?']]));
await attempt('chat kossi-akossiwa', () => chat(U.kossi, S.akossiwa, [
  ['c', 'Tantie, les tomates sont à combien le tas ?'], ['v', '500 F le tas, bien rouges !']]));

// ---------------------------------------------------------------- aide et recherches
console.log('→ demandes d\'aide et recherches');
await attempt('ticket awa', async () => { await as(U.awa.id); await q("select public.open_ticket('client', 'order', 'Ma commande n''est pas arrivée, pouvez-vous vérifier ?')"); });
await attempt('ticket fatou', async () => { await as(U.fatou.id); await q("select public.open_ticket('vendor', 'payment', 'Je ne vois pas le paiement de ma dernière commande.')"); });
await attempt('ticket lea', async () => { await as(U.lea.id); await q("select public.open_ticket('client', 'account', 'Comment changer mon adresse ?')"); });
for (const s of ['gombo', 'mangue', 'bissap', 'poisson fumé', 'attiéké']) {
  await attempt('recherche', async () => { await as(U.awa.id); await q('select public.remember_search($1)', [s]); });
}

// Admin invité (exemple d'invitation en attente).
await attempt('invitation admin', async () => { await as(users.admin.id); await q('select public.admin_invite_admin($1)', [alias('admin2')]); });

await as(null);
await db.query("notify pgrst, 'reload schema'");
const counts = await one(`select
  (select count(*) from public.stores) boutiques, (select count(*) from public.products) produits,
  (select count(*) from public.orders) commandes, (select count(*) from public.reviews) avis,
  (select count(*) from public.disputes) litiges, (select count(*) from public.messages) messages`);
console.log('✓ terminé', counts, failures ? `(${failures} étape(s) ignorée(s))` : '');
await db.end();
