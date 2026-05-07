import type {MiddlewareHandler} from "hono";
import {createHash} from "node:crypto";
import {Conflict} from "../errors/app_error";
import {lookup, save} from "../idempotency/repo";

const WRITE_METHODS = new Set(["POST", "PATCH", "PUT", "DELETE"]);

export function idempotencyMiddleware(): MiddlewareHandler {
  return async (c, next) => {
    if (!WRITE_METHODS.has(c.req.method)) {
      await next();
      return;
    }
    const key = c.req.header("idempotency-key");
    if (!key) {
      await next();
      return;
    }
    const uid = c.get("uid") as string | undefined;
    if (!uid) {
      // Idempotency requires an authenticated principal — pass through
      // if anonymous (auth gate will reject anyway).
      await next();
      return;
    }
    const rawBody = await c.req.raw.clone().text();
    const bodyHash = createHash("sha256").update(rawBody).digest("hex");

    const existing = await lookup(uid, key);
    if (existing) {
      if (existing.bodyHash !== bodyHash) {
        throw new Conflict("Idempotency key reused with different body", {key});
      }
      return c.body(existing.body, existing.status as 200, {"content-type": existing.contentType});
    }

    await next();

    const status = c.res.status;
    const cloned = c.res.clone();
    const body = await cloned.text();
    const contentType = cloned.headers.get("content-type") ?? "application/json";
    if (status >= 200 && status < 300) {
      await save(uid, key, {status, body, bodyHash, contentType, expiresAt: new Date()});
    }
    return;
  };
}
