import type {Context} from "hono";

export interface RequestContext {
  uid: string;
  email?: string;
  requestId: string;
  householdId?: string;
}

const KEY = "__fling_request_context";

export function setRequestContext(c: Context, ctx: RequestContext): void {
  c.set(KEY, ctx);
}

export function getRequestContext(c: Context): RequestContext {
  const ctx = c.get(KEY) as RequestContext | undefined;
  if (!ctx) throw new Error("RequestContext missing — middleware not mounted");
  return ctx;
}
