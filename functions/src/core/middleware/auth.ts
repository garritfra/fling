import type {MiddlewareHandler} from "hono";
import {Unauthorized} from "../errors/app_error";
import {setRequestContext} from "../context/request_context";
import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";

function ensureAdmin() {
  if (getApps().length === 0) initializeApp();
}

export function authMiddleware(): MiddlewareHandler {
  return async (c, next) => {
    ensureAdmin();
    const header = c.req.header("authorization") ?? "";
    const m = /^Bearer\s+(.+)$/.exec(header);
    if (!m) throw new Unauthorized("Missing or malformed Authorization header");
    let decoded;
    try {
      decoded = await getAuth().verifyIdToken(m[1]);
    } catch {
      throw new Unauthorized("Invalid token");
    }
    const requestId = (c.get("requestId") as string | undefined) ?? "";
    setRequestContext(c, {uid: decoded.uid, email: decoded.email, requestId});
    await next();
  };
}
