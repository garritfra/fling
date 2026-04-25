import { describe, it, expect } from "vitest";
import { app } from "../../src/api/app";

describe("GET /v1/healthz", () => {
  it("returns 200 with status ok and a version string", async () => {
    const res = await app.request("/v1/healthz");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toMatchObject({ status: "ok" });
    expect(typeof body.version).toBe("string");
  });

  it("exposes an OpenAPI document at /v1/openapi.json", async () => {
    const res = await app.request("/v1/openapi.json");
    expect(res.status).toBe(200);
    const doc = await res.json();
    expect(doc.openapi).toMatch(/^3\./);
    expect(doc.info?.title).toBe("Fling API");
    expect(doc.paths?.["/v1/healthz"]).toBeDefined();
  });
});
