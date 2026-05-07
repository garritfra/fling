import {beforeEach, beforeAll, afterAll, describe, it, expect} from "vitest";
import {OpenAPIHono} from "@hono/zod-openapi";
import {initializeApp, deleteApp, getApps, type App} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {idempotencyMiddleware} from "../../../src/core/middleware/idempotency";
import {installErrorHandler} from "../../../src/core/errors/handler";

let firebaseApp: App;
let calls = 0;

function buildApp(): OpenAPIHono {
  const app = new OpenAPIHono();
  installErrorHandler(app);
  // Pretend RequestContext is already on c (idempotency reads c.get('uid')).
  app.use("*", async (c, next) => {
    c.set("uid", "alice");
    c.set("requestId", "rid");
    await next();
  });
  app.use("*", idempotencyMiddleware());
  app.patch("/echo", async (c) => {
    calls++;
    const body = await c.req.json();
    return c.json({calls, echoed: body}, 200);
  });
  return app;
}

beforeAll(() => {
  firebaseApp = getApps()[0] ?? initializeApp({projectId: "fling-rules-test"});
});
beforeEach(async () => {
  calls = 0;
  const db = getFirestore();
  const docs = await db.collection("idempotency_keys").listDocuments();
  await Promise.all(docs.map((d) => d.delete()));
});
afterAll(async () => {
  if (firebaseApp) await deleteApp(firebaseApp);
});

describe("idempotency middleware", () => {
  it("passes through when no Idempotency-Key is present", async () => {
    const app = buildApp();
    const r = await app.request("/echo", {method: "PATCH", body: JSON.stringify({a: 1}), headers: {"Content-Type": "application/json"}});
    expect(r.status).toBe(200);
    expect(calls).toBe(1);
  });

  it("dedupes: same key + same body returns the cached response", async () => {
    const app = buildApp();
    const headers = {"Content-Type": "application/json", "Idempotency-Key": "k1"};
    const body = JSON.stringify({a: 1});
    const r1 = await app.request("/echo", {method: "PATCH", body, headers});
    const r2 = await app.request("/echo", {method: "PATCH", body, headers});
    expect(r1.status).toBe(200);
    expect(r2.status).toBe(200);
    expect(calls).toBe(1);
    expect(await r2.json()).toEqual({calls: 1, echoed: {a: 1}});
  });

  it("returns 409 on key reuse with a different body", async () => {
    const app = buildApp();
    const headers = {"Content-Type": "application/json", "Idempotency-Key": "k1"};
    const r1 = await app.request("/echo", {method: "PATCH", body: JSON.stringify({a: 1}), headers});
    expect(r1.status).toBe(200);
    const r2 = await app.request("/echo", {method: "PATCH", body: JSON.stringify({a: 2}), headers});
    expect(r2.status).toBe(409);
    expect((await r2.json()).error.code).toBe("CONFLICT");
  });

  it("partitions keys by uid", async () => {
    // Build an app where a query param overrides uid for the second call.
    const app = new OpenAPIHono();
    installErrorHandler(app);
    app.use("*", async (c, next) => {
      const u = c.req.query("uid") ?? "alice";
      c.set("uid", u);
      c.set("requestId", "rid");
      await next();
    });
    app.use("*", idempotencyMiddleware());
    app.patch("/echo", async (c) => {
      calls++;
      return c.json({calls}, 200);
    });
    const headers = {"Content-Type": "application/json", "Idempotency-Key": "k1"};
    await app.request("/echo?uid=alice", {method: "PATCH", body: "{}", headers});
    const r2 = await app.request("/echo?uid=bob", {method: "PATCH", body: "{}", headers});
    expect(r2.status).toBe(200);
    expect(calls).toBe(2);
  });
});
