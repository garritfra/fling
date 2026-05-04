import type {MiddlewareHandler} from "hono";
import {randomUUID} from "node:crypto";

const MAX_INCOMING_LEN = 128;
const SAFE_RID = /^[A-Za-z0-9._\-:]+$/;

export function requestIdMiddleware(): MiddlewareHandler {
  return async (c, next) => {
    const incoming = c.req.header("x-request-id");
    const rid =
      incoming && incoming.length <= MAX_INCOMING_LEN && SAFE_RID.test(incoming) ?
        incoming :
        randomUUID();
    c.set("requestId", rid);
    c.header("x-request-id", rid);
    await next();
  };
}
