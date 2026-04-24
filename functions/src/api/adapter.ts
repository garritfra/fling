import type {Request} from "firebase-functions/v2/https";
import type {Response} from "express";
import type {Hono} from "hono";
import type {OpenAPIHono} from "@hono/zod-openapi";

/**
 * Bridge a firebase-functions v2 onRequest invocation into a Hono `app.fetch`
 * call. Hono speaks the WHATWG Fetch API; Cloud Functions hands us node-style
 * (req, res). We translate.
 *
 * Accepts either a plain Hono app or an OpenAPIHono app; their generic
 * parameters differ so a simple `Hono` type would reject an OpenAPIHono.
 */
export async function handle(
    app: Hono | OpenAPIHono,
    req: Request,
    res: Response,
): Promise<void> {
  const protocol = (req.headers["x-forwarded-proto"] as string) || "https";
  const host = req.headers.host ?? "localhost";
  const url = `${protocol}://${host}${req.originalUrl ?? req.url}`;

  const headers = new Headers();
  for (const [k, v] of Object.entries(req.headers)) {
    if (Array.isArray(v)) headers.set(k, v.join(","));
    else if (v !== undefined) headers.set(k, String(v));
  }

  const init: RequestInit = {method: req.method, headers};
  if (!["GET", "HEAD"].includes(req.method)) {
    // rawBody is a Node Buffer; cast through any to satisfy undici's BodyInit.
    init.body = (req.rawBody ??
      Buffer.from(JSON.stringify(req.body ?? {}))) as any;
  }

  const fetchRes = await app.fetch(new global.Request(url, init));

  res.status(fetchRes.status);
  fetchRes.headers.forEach((value, key) => res.setHeader(key, value));
  const buf = Buffer.from(await fetchRes.arrayBuffer());
  res.end(buf);
}
