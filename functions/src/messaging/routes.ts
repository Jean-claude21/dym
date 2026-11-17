import type { AiModelConfig } from "../catalog/ports.js";
import type { Transcriber } from "../search/ports.js";
import { randomUUID } from "node:crypto";
import { GetObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import type { Hono } from "hono";
import type pg from "pg";
import { z } from "zod";
import { type AuthVariables, requireUser, type TokenVerifier } from "../lib/auth.js";
import { fromPgError } from "../lib/db.js";
import { httpErrors } from "../lib/errors.js";
import { parseBody } from "../lib/validate.js";

export type MessagingJson = Record<string, unknown> & { id: string };

/** Règles en SQL (`app.start_conversation`, `app.send_message`…). */
export interface MessagingStore {
  start(userId: string, storeId: string): Promise<MessagingJson>;
  send(input: {
    userId: string;
    conversationId: string;
    kind: string;
    body: string | null;
    mediaKey: string | null;
    productId: string | null;
    idempotencyKey: string;
    /** Vocal (spec 035). */
    durationMs?: number | null;
    /** Document : `{name, size, mime}` (spec 111). */
    payload?: Record<string, unknown> | null;
    /** Message cité (spec 111). */
    replyTo?: string | null;
  }): Promise<MessagingJson>;
  uploadAllowed(userId: string, conversationId: string): Promise<boolean>;
  /** Clés des images lisibles par l'utilisatrice, par message. */
  mediaKeys(userId: string, messageIds: string[]): Promise<Record<string, string>>;
  /** Vocal lisible par la personne (spec 099) ; `null` : introuvable. */
  transcriptTarget(userId: string, messageId: string): Promise<{ media_key: string; transcript: string | null } | null>;
  /** Modèle de transcription du pays ; `null` : coupé ou absent (simulé côté app). */
  transcriptionModel(userId: string): Promise<AiModelConfig | null>;
  setTranscript(messageId: string, text: string): Promise<void>;
}

/** Stockage privé des images de conversation : liens signés courts. */
export interface MediaSigner {
  presignPut(key: string, contentType: string, expiresInSeconds: number): Promise<string>;
  presignGet(key: string, expiresInSeconds: number): Promise<string>;
}

export function pgMessagingStore(pool: pg.Pool): MessagingStore {
  const one = async <T>(sql: string, params: unknown[]) => {
    try {
      const { rows } = await pool.query(sql, params);
      return rows[0].value as T;
    } catch (error) {
      throw fromPgError(error);
    }
  };
  return {
    start: (u, s) => one<MessagingJson>("select app.start_conversation($1, $2) as value", [u, s]),
    send: (i) =>
      one<MessagingJson>("select app.send_message($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) as value", [
        i.userId,
        i.conversationId,
        i.kind,
        i.body,
        i.mediaKey,
        i.productId,
        i.idempotencyKey,
        i.durationMs ?? null,
        i.payload ?? null,
        i.replyTo ?? null,
      ]),
    uploadAllowed: (u, c) => one<boolean>("select app.chat_upload_allowed($1, $2) as value", [u, c]),
    mediaKeys: (u, ids) =>
      one<Record<string, string>>("select app.chat_media_keys($1, $2::uuid[]) as value", [u, ids]),
    transcriptTarget: (u, m) =>
      one<{ media_key: string; transcript: string | null } | null>(
        "select app.transcript_target($1, $2) as value",
        [u, m],
      ),
    transcriptionModel: (u) =>
      one<AiModelConfig | null>("select app.chat_transcription_model($1) as value", [u]),
    setTranscript: async (m, t) => {
      await one<null>("select app.set_transcript($1, $2) as value", [m, t]);
    },
  };
}

export function s3MediaSigner(options: {
  endpoint: string;
  region: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
}): MediaSigner {
  const client = new S3Client({
    endpoint: options.endpoint,
    region: options.region,
    forcePathStyle: true,
    credentials: { accessKeyId: options.accessKeyId, secretAccessKey: options.secretAccessKey },
  });
  return {
    presignPut: (key, contentType, expiresIn) =>
      getSignedUrl(client, new PutObjectCommand({ Bucket: options.bucket, Key: key, ContentType: contentType }), {
        expiresIn,
      }),
    presignGet: (key, expiresIn) =>
      getSignedUrl(client, new GetObjectCommand({ Bucket: options.bucket, Key: key }), { expiresIn }),
  };
}

export interface MessagingDeps {
  store: MessagingStore;
  signer?: MediaSigner;
  /** Transcription des vocaux (spec 099) ; absente : simulée et signalée. */
  transcriber?: Transcriber;
}

const uuid = z.string().uuid();
const UPLOAD_EXPIRES_IN = 600;
const READ_EXPIRES_IN = 300;
const extensions = {
  "image/jpeg": "jpg",
  "image/webp": "webp",
  "audio/wav": "wav",
  "audio/mp4": "m4a",
  "audio/webm": "webm",
  "audio/ogg": "ogg",
  "video/mp4": "mp4",
  "video/webm": "webm",
  "video/quicktime": "mov",
  // Documents (spec 111).
  "application/pdf": "pdf",
  "application/msword": "doc",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
  "application/vnd.ms-excel": "xls",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx",
  "application/vnd.ms-powerpoint": "ppt",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
  "application/vnd.oasis.opendocument.text": "odt",
  "application/vnd.oasis.opendocument.spreadsheet": "ods",
  "text/plain": "txt",
  "text/csv": "csv",
} as const;

const contentTypes = Object.keys(extensions) as [keyof typeof extensions, ...(keyof typeof extensions)[]];

const audioMedia: Record<string, string> = { wav: "audio/wav", m4a: "audio/mp4", webm: "audio/webm", ogg: "audio/ogg" };

/**
 * Messagerie (spec 015) ; la base vérifie la participation :
 * - `POST /v1/conversations` `{store_id}` : ouvrir ou retrouver (cliente) ;
 * - `POST /v1/conversations/:id/messages` `{kind, body?, media_key?, product_id?, reply_to?, file?}`
 *   (en-tête `Idempotency-Key`) : envoyer, prévenir la destinataire ;
 * - `POST /v1/conversations/:id/media-uploads` `{content_type}` : photo, vocal, vidéo, document ;
 * - `POST /v1/chat-media/urls` `{message_ids}` : liens de lecture signés.
 */
export function registerMessagingRoutes(
  app: Hono<{ Variables: AuthVariables }>,
  verifyToken: TokenVerifier,
  deps?: MessagingDeps,
) {
  const auth = requireUser(verifyToken);
  const need = () => {
    if (!deps) throw httpErrors.unavailable("messagerie non configurée");
    return deps;
  };
  const id = (raw: string) => {
    if (!uuid.safeParse(raw).success) throw httpErrors.notFound("introuvable");
    return raw;
  };

  app.post("/v1/conversations", auth, async (c) => {
    const body = await parseBody(c, z.object({ store_id: uuid }));
    return c.json(await need().store.start(c.get("user").id, body.store_id), 201);
  });

  app.post("/v1/conversations/:id/messages", auth, async (c) => {
    const conversationId = id(c.req.param("id"));
    const key = c.req.header("Idempotency-Key");
    if (!key || !uuid.safeParse(key).success) {
      throw httpErrors.badRequest("Idempotency-Key (uuid) obligatoire");
    }
    const body = await parseBody(
      c,
      z.object({
        kind: z.enum(["text", "image", "product", "audio", "video", "file"]),
        body: z.string().max(1000).nullable().optional(),
        media_key: z.string().max(300).nullable().optional(),
        product_id: uuid.nullable().optional(),
        duration_ms: z.number().int().min(500).max(60000).nullable().optional(),
        reply_to: uuid.nullable().optional(),
        file: z
          .object({
            name: z.string().trim().min(1).max(120),
            size: z.number().int().min(1).max(10 * 1024 * 1024),
            mime: z.enum(contentTypes).optional(),
          })
          .nullable()
          .optional(),
      }),
    );
    if (body.kind === "file" && !body.file) throw httpErrors.badRequest("file obligatoire");
    const message = await need().store.send({
      userId: c.get("user").id,
      conversationId,
      kind: body.kind,
      body: body.body ?? null,
      mediaKey: body.media_key ?? null,
      productId: body.product_id ?? null,
      idempotencyKey: key,
      durationMs: body.duration_ms ?? null,
      payload: body.kind === "file" && body.file ? body.file : null,
      replyTo: body.reply_to ?? null,
    });
    return c.json(message, 201);
  });

  app.post("/v1/conversations/:id/media-uploads", auth, async (c) => {
    const conversationId = id(c.req.param("id"));
    const body = await parseBody(c, z.object({
        content_type: z.enum(contentTypes),
      }));
    const d = need();
    if (!d.signer) throw httpErrors.unavailable("stockage non configuré");
    if (!(await d.store.uploadAllowed(c.get("user").id, conversationId))) {
      throw httpErrors.notFound("conversation introuvable");
    }
    const key = `chats/${conversationId}/${randomUUID()}.${extensions[body.content_type]}`;
    return c.json({
      object_key: key,
      upload_url: await d.signer.presignPut(key, body.content_type, UPLOAD_EXPIRES_IN),
      expires_in: UPLOAD_EXPIRES_IN,
    });
  });

  app.post("/v1/chat-media/urls", auth, async (c) => {
    const body = await parseBody(c, z.object({ message_ids: z.array(uuid).min(1).max(50) }));
    const d = need();
    if (!d.signer) throw httpErrors.unavailable("stockage non configuré");
    const keys = await d.store.mediaKeys(c.get("user").id, body.message_ids);
    const urls: Record<string, string> = {};
    for (const [messageId, key] of Object.entries(keys)) {
      urls[messageId] = await d.signer.presignGet(key, READ_EXPIRES_IN);
    }
    return c.json({ urls, expires_in: READ_EXPIRES_IN });
  });

  // Transcription d'un vocal (spec 099) : texte gardé ; sans fournisseur, simulée et signalée.
  app.post("/v1/chat-media/transcribe", auth, async (c) => {
    const body = await parseBody(c, z.object({ message_id: uuid }));
    const d = need();
    const userId = c.get("user").id;
    const target = await d.store.transcriptTarget(userId, body.message_id);
    if (!target) throw httpErrors.notFound("vocal introuvable");
    if (target.transcript) return c.json({ transcript: target.transcript, simulated: false });
    const model = await d.store.transcriptionModel(userId);
    if (!model || !d.transcriber || !d.signer) return c.json({ transcript: null, simulated: true });
    const audio = await fetch(await d.signer.presignGet(target.media_key, READ_EXPIRES_IN));
    if (!audio.ok) throw httpErrors.unavailable("vocal illisible");
    const extension = target.media_key.split(".").pop() ?? "";
    const text = await d.transcriber.transcribe({
      model,
      audio: new Uint8Array(await audio.arrayBuffer()),
      mediaType: audioMedia[extension] ?? "audio/mp4",
    });
    if (text) await d.store.setTranscript(body.message_id, text);
    return c.json({ transcript: text ?? null, simulated: false });
  });

}
