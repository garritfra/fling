import {describe, it, expect} from "vitest";
import {Hono} from "hono";
import {requestIdMiddleware} from "../../../src/core/middleware/request_id";

function appWithRid(): Hono {
  const app = new Hono();
  app.use("*", requestIdMiddleware());
  app.get("/echo", (c) => c.json({rid: c.get("requestId")}));
  return app;
}

describe("requestId middleware", () => {
  it("generates a UUID-shaped id when X-Request-Id is absent", async () => {
    const app = appWithRid();
    const res = await app.request("/echo");
    const body = await res.json();
    expect(body.rid).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
    expect(res.headers.get("x-request-id")).toBe(body.rid);
  });

  it("honours an incoming X-Request-Id", async () => {
    const app = appWithRid();
    const res = await app.request("/echo", {headers: {"X-Request-Id": "client-abc-123"}});
    const body = await res.json();
    expect(body.rid).toBe("client-abc-123");
    expect(res.headers.get("x-request-id")).toBe("client-abc-123");
  });

  it("rejects an X-Request-Id longer than 128 chars and generates a fresh one", async () => {
    const app = appWithRid();
    const long = "a".repeat(200);
    const res = await app.request("/echo", {headers: {"X-Request-Id": long}});
    const body = await res.json();
    expect(body.rid).not.toBe(long);
    expect(body.rid).toMatch(/^[0-9a-f-]{36}$/);
  });
});
