import { randomUUID } from "node:crypto";
import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import type { PhotoSigner } from "../catalog/ports.js";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { HttpError, httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";

/** Vidéo publique lue chez le fournisseur (titre, couverture, compte). */
export interface ImportedVideo {
  title: string | null;
  /** Couverture ; absente quand TikTok ne la donne pas (la créatrice en choisit une). */
  thumbnailUrl: string | null;
  authorHandle: string;
}

/**
 * Lecture d'une vidéo publique. Implémentation actuelle : oEmbed de TikTok (sans clé).
 * La propriété n'est pas prouvée (le compte est déclaré par la créatrice) tant que la connexion
 * TikTok (Login Kit) n'est pas disponible : la réponse le signale (`verified: false`).
 */
export interface VideoImportProvider {
  lookup(url: string): Promise<ImportedVideo | null>;
  download(url: string): Promise<{ bytes: ArrayBuffer; contentType: string } | null>;
}

export interface TikTokStore {
  isCreator(userId: string): Promise<boolean>;
  declaredHandle(userId: string): Promise<string | null>;
  /** Contenu d'un lien de partage, pour la page d'accueil ; null : inconnu ou retiré. */
  sharePreview(code: string): Promise<SharePreview | null>;
}

export interface SharePreview {
  caption: string | null;
  mediaKey: string | null;
  isVideo: boolean;
  authorName: string | null;
}

export interface TikTokDeps {
  store: TikTokStore;
  provider?: VideoImportProvider;
  signer?: PhotoSigner;
  /** Adresse de l'app web (premier `ALLOWED_ORIGINS`) ; absente : lien `dym://`. */
  webUrl?: string;
}

const tiktokUrl = /^https:\/\/(www\.|m\.|vm\.)?tiktok\.com\/[A-Za-z0-9@._/?=&%-]{1,250}$/;
const MAX_COVER_BYTES = 2_000_000;

export function normalizeHandle(value: string): string {
  return value.trim().replace(/^@/, "").toLowerCase();
}

/**
 * Pont TikTok (spec 040) :
 * - `POST /v1/creator-content/tiktok-import` `{url}` : vidéo du compte déclaré → couverture copiée dans
 *   `creators/<id>/contents/<contenu>.<ext>`, légende proposée, lien d'origine ;
 * - `GET /s/:code` : page d'accueil d'un lien de partage (aperçu et ouverture de l'app).
 */
export function registerTikTokRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: TikTokDeps,
) {
  const auth = requireUser(verifyToken);

  app.post("/v1/creator-content/tiktok-import", auth, async (c) => {
    const body = await parseBody(c, z.object({ url: z.string().trim().regex(tiktokUrl) }));
    if (!deps?.provider || !deps.signer) throw httpErrors.unavailable("import TikTok non configuré");
    const userId = c.get("user").id;
    if (!(await deps.store.isCreator(userId))) throw httpErrors.forbidden("profil créateur requis");
    const handle = await deps.store.declaredHandle(userId);
    if (!handle) throw httpErrors.validation({ url: "tiktok_handle_required" }, "tiktok_handle_required");
    const video = await deps.provider.lookup(body.url);
    if (!video) throw httpErrors.validation({ url: "tiktok_not_found" }, "tiktok_not_found");
    if (normalizeHandle(video.authorHandle) !== handle) {
      throw httpErrors.validation({ url: "not_owner" }, "not_owner");
    }
    // Couverture copiée chez DYM si TikTok la donne ; sinon la créatrice en choisit une.
    const id = randomUUID();
    let key: string | null = null;
    const cover = video.thumbnailUrl ? await deps.provider.download(video.thumbnailUrl).catch(() => null) : null;
    if (cover && cover.bytes.byteLength <= MAX_COVER_BYTES && ["image/jpeg", "image/webp"].includes(cover.contentType)) {
      const candidate = `creators/${userId}/contents/${id}.${cover.contentType === "image/webp" ? "webp" : "jpg"}`;
      const uploadUrl = await deps.signer.presignPut(candidate, cover.contentType, 300);
      const put = await fetch(uploadUrl, {
        method: "PUT",
        headers: { "Content-Type": cover.contentType },
        body: cover.bytes,
      });
      if (put.ok) key = candidate;
    }
    return c.json({
      content_id: id,
      object_key: key,
      caption: video.title?.slice(0, 500) ?? null,
      source_url: body.url,
      author_handle: handle,
      // Compte déclaré, pas encore prouvé par la connexion TikTok (décision 0015).
      verified: false,
    });
  });

  app.get("/s/:code", async (c) => {
    const code = c.req.param("code").toLowerCase();
    if (!/^[a-z0-9]{8}$/.test(code) || !deps) return c.html(landing(null, null, null), 404);
    const preview = await deps.store.sharePreview(code);
    if (!preview) return c.html(landing(null, null, null), 404);
    const open = deps.webUrl ? `${deps.webUrl.replace(/\/$/, "")}/?share=${code}` : `dym://share/${code}`;
    const image = preview.mediaKey && !preview.isVideo && deps.signer ? deps.signer.publicUrl(preview.mediaKey) : null;
    return c.html(landing(preview, open, image));
  });
}

const escape = (value: string) =>
  value.replace(/[&<>"']/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[ch]!);

/** Page minimale, bilingue, sans script : aperçu pour les réseaux et bouton d'ouverture. */
function landing(preview: SharePreview | null, open: string | null, image: string | null): string {
  const title = preview?.caption ? escape(preview.caption.slice(0, 120)) : "DYM";
  const by = preview?.authorName ? escape(preview.authorName) : null;
  return `<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title>
<meta property="og:title" content="${title}">
<meta property="og:description" content="Tout pour la faire, livré par les vendeuses du quartier · Everything to make it, delivered">
${image ? `<meta property="og:image" content="${escape(image)}">` : ""}
<style>body{font-family:system-ui,sans-serif;margin:0;padding:24px 16px;background:#f7f5ef;color:#1d2b20}
main{max-width:480px;margin:0 auto}img{width:100%;border-radius:16px}
a{display:block;margin-top:16px;padding:16px;border-radius:12px;background:#1f6b3a;color:#fff;text-align:center;text-decoration:none;font-weight:600}</style>
</head><body><main>
${image ? `<img src="${escape(image)}" alt="">` : ""}
<h1>${title}</h1>
${by ? `<p>${by}</p>` : ""}
${open
    ? `<a href="${escape(open)}">Tout pour la faire · Everything to make it</a>`
    : "<p>Ce lien n'existe plus · This link no longer exists</p>"}
</main></body></html>`;
}

/** oEmbed public de TikTok : titre, couverture et compte d'une vidéo. */
export function tiktokOEmbedProvider(fetchImpl: typeof fetch = fetch): VideoImportProvider {
  return {
    async lookup(url) {
      // Lien court (vm.tiktok.com) : l'adresse finale porte le compte (`/@compte/video/<id>`).
      let canonical = url;
      if (!/\/@[^/]+\/video\//.test(url)) {
        const head = await fetchImpl(url, { method: "HEAD", redirect: "follow", signal: AbortSignal.timeout(8000) });
        canonical = head.url || url;
      }
      const response = await fetchImpl(`https://www.tiktok.com/oembed?url=${encodeURIComponent(canonical)}`, {
        signal: AbortSignal.timeout(8000),
      });
      if (response.status === 400 || response.status === 404) return null;
      if (!response.ok) throw httpErrors.unavailable("TikTok indisponible");
      const json = z.object({
        type: z.literal("video"),
        title: z.string().nullish(),
        thumbnail_url: z.string().url().nullish(),
        author_unique_id: z.string().min(1).nullish(),
        author_url: z.string().url().nullish(),
      }).safeParse(await response.json());
      if (!json.success) return null;
      const fromUrl = (value?: string | null) => value?.split("/@")[1]?.split(/[/?]/)[0];
      const handle = json.data.author_unique_id ?? fromUrl(json.data.author_url) ?? fromUrl(canonical);
      if (!handle) return null;
      return { title: json.data.title ?? null, thumbnailUrl: json.data.thumbnail_url ?? null, authorHandle: handle };
    },
    async download(url) {
      const response = await fetchImpl(url, { signal: AbortSignal.timeout(8000) });
      if (!response.ok) return null;
      const contentType = (response.headers.get("content-type") ?? "").split(";")[0]!.trim();
      return { bytes: await response.arrayBuffer(), contentType };
    },
  };
}

export function pgTikTokStore(pool: pg.Pool): TikTokStore {
  const one = async <T>(sql: string, params: unknown[]): Promise<T> => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0]?.value as T;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    isCreator: async (userId) =>
      (await one<boolean>(
        "select exists (select 1 from public.creator_profiles where user_id = $1) as value",
        [userId],
      )) === true,
    declaredHandle: (userId) => one<string | null>("select app.creator_tiktok_handle($1) as value", [userId]),
    async sharePreview(code) {
      try {
        // Ouverture comptée par SQL (événement `share_link_opened`).
        const { rows } = await pool.query("select public.open_share_link($1) as value", [code]);
        const content = rows[0]?.value as
          | { caption?: string | null; media_key?: string | null; media_type?: string | null; author?: { display_name?: string } | null }
          | undefined;
        if (!content) return null;
        return {
          caption: content.caption ?? null,
          mediaKey: content.media_key ?? null,
          isVideo: (content.media_type ?? "").startsWith("video/"),
          authorName: content.author?.display_name ?? null,
        };
      } catch (error) {
        const mapped = fromPgError(error);
        if (mapped instanceof HttpError && mapped.status === 404) return null;
        throw mapped;
      }
    },
  };
}
