import type { Hono } from "hono";
import type pg from "pg";
import type { AuthVariables } from "../lib/auth.js";

/** Lecture d'un lien de suivi (spec 096) ; `null` si expiré ou inconnu. */
export interface TrackingStore {
  byToken(token: string): Promise<Record<string, unknown> | null>;
}

const TOKEN = /^[A-Za-z0-9_-]{20,64}$/;

/**
 * Suivi partagé (spec 096) : lien ouvert dans n'importe quel navigateur, sans compte ni app.
 * - `GET /t/:token` : page avec la carte (boutique, porte arrondie, livreur) et les minutes restantes ;
 * - `GET /t/:token/data` : le suivi en JSON, relu par la page toutes les 15 s.
 */
export function registerTrackingRoutes(app: Hono<{ Variables: AuthVariables }>, store?: TrackingStore) {
  app.get("/t/:token/data", async (c) => {
    const token = c.req.param("token");
    if (!store || !TOKEN.test(token)) return c.json({ error: "not_found" }, 404);
    const tracking = await store.byToken(token);
    c.header("Cache-Control", "no-store");
    return tracking ? c.json(tracking) : c.json({ error: "not_found" }, 404);
  });

  app.get("/t/:token", (c) => {
    const token = c.req.param("token");
    if (!store || !TOKEN.test(token)) return c.html(page(null), 404);
    c.header("Cache-Control", "no-store");
    return c.html(page(token));
  });
}

export function pgTrackingStore(pool: pg.Pool): TrackingStore {
  return {
    async byToken(token) {
      const { rows } = await pool.query("select public.tracking_by_token($1) as value", [token]);
      return (rows[0]?.value as Record<string, unknown> | null) ?? null;
    },
  };
}

/** Page bilingue (fr par défaut), carte MapLibre et tuiles OpenFreeMap (décision 0022). */
function page(token: string | null): string {
  const head = `<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex">
<title>DYM · Suivi de livraison</title>
<link rel="stylesheet" href="https://unpkg.com/maplibre-gl@5.6.0/dist/maplibre-gl.css">
<style>
:root{--brand:#145C43;--deep:#0E4632;--bg:#FAFAF7;--card:#fff;--text:#16201B;--muted:#4E5852;--line:#E6E7E2;--plantain:#F6C343}
*{box-sizing:border-box}body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;background:var(--bg);color:var(--text)}
header{padding:16px;display:flex;align-items:center;gap:12px}
header b{font-size:20px;color:var(--brand)}#map{height:58vh;min-height:280px}
.card{margin:12px 16px;padding:16px;background:var(--card);border:1px solid var(--line);border-radius:12px}
.eta{font-size:28px;font-weight:700;color:var(--brand)}.muted{color:var(--muted)}
.pin{width:34px;height:34px;border-radius:8px;display:grid;place-items:center;border:2.5px solid;font-size:18px}
</style></head><body>`;
  if (!token) {
    return `${head}<header><b>DYM</b></header><div class="card"><p>Ce lien de suivi a expiré.</p>
<p class="muted">This tracking link has expired.</p></div></body></html>`;
  }
  return `${head}<header><b>DYM</b><span id="store" class="muted"></span></header>
<div id="map" role="img" aria-label="Carte du suivi"></div>
<div class="card"><div id="status" style="font-weight:600"></div><div id="eta" class="eta"></div>
<div id="courier" class="muted"></div></div>
<script src="https://unpkg.com/maplibre-gl@5.6.0/dist/maplibre-gl.js"></script>
<script>
const en = !navigator.language.toLowerCase().startsWith("fr");
const T = en ? {accepted:"Order accepted",preparing:"Being prepared",ready:"Ready, waiting for the courier",
  out_for_delivery:"On the way",delivered:"Delivered",min:"min",courier:"Courier: ",gone:"This link has expired."}
 : {accepted:"Commande acceptée",preparing:"En préparation",ready:"Prête, le livreur arrive",
  out_for_delivery:"En route",delivered:"Livrée",min:"min",courier:"Livreur : ",gone:"Ce lien de suivi a expiré."};
const map = new maplibregl.Map({container:"map",style:"https://tiles.openfreemap.org/styles/positron",center:[0,20],zoom:2});
const marks = {};
function pin(id, lngLat, bg, fg, icon){
  if(!lngLat) return;
  if(!marks[id]){const el=document.createElement("div");el.className="pin";el.style.background=bg;el.style.borderColor=fg;el.textContent=icon;
    marks[id]=new maplibregl.Marker({element:el,anchor:"bottom"}).setLngLat(lngLat).addTo(map);}
  else marks[id].setLngLat(lngLat);
}
const ll = (p) => p && p.latitude != null ? [Number(p.longitude), Number(p.latitude)] : null;
let framed = false;
async function load(){
  const r = await fetch(location.pathname.replace(/\\/$/,"") + "/data", {cache:"no-store"});
  if(!r.ok){document.getElementById("status").textContent=T.gone;return false;}
  const d = await r.json();
  document.getElementById("store").textContent = d.store && d.store.name ? d.store.name : "";
  document.getElementById("status").textContent = T[d.status] || "";
  document.getElementById("eta").textContent = d.eta_minutes > 0 ? "~" + d.eta_minutes + " " + T.min : "";
  document.getElementById("courier").textContent = d.courier && d.courier.name ? T.courier + d.courier.name : "";
  const pts = [["store",ll(d.store),"#E3E6F4","#2E3A8C","🏪"],["door",ll(d.destination),"#E8F2EC","#0E4632","🏠"],
    ["courier",ll(d.courier),"#F6C343","#16201B","🛵"]].filter(p => p[1]);
  pts.forEach(p => pin(...p));
  if(!framed && pts.length){framed=true;const b=new maplibregl.LngLatBounds();pts.forEach(p=>b.extend(p[1]));
    map.fitBounds(b,{padding:60,maxZoom:15,duration:0});}
  return d.status !== "delivered";
}
map.on("load", async () => { if(await load()) setInterval(load, 15000); });
</script></body></html>`;
}
