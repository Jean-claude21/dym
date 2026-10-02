import type { Context } from "hono";
import type { z } from "zod";
import { httpErrors } from "./errors.js";

/** Lit et valide le corps JSON ; 400 si illisible, 422 avec les champs en cause. */
export async function parseBody<S extends z.ZodType>(
  c: Context,
  schema: S,
): Promise<z.infer<S>> {
  let json: unknown;
  try {
    json = await c.req.json();
  } catch {
    throw httpErrors.badRequest("corps JSON illisible");
  }
  const result = schema.safeParse(json);
  if (!result.success) {
    const fields: Record<string, string> = {};
    for (const issue of result.error.issues) {
      const key = issue.path.length ? issue.path.join(".") : "_";
      fields[key] ??= issue.message;
    }
    throw httpErrors.validation(fields);
  }
  return result.data;
}
