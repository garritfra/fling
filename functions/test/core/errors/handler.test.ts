import {describe, it, expect} from "vitest";
import {Hono} from "hono";
import {installErrorHandler} from "../../../src/core/errors/handler";
import {
  AppError, BadRequest, Forbidden, NotFound, Conflict, Unauthorized,
} from "../../../src/core/errors/app_error";

function appWithThrower(thrown: unknown): Hono {
  const app = new Hono();
  installErrorHandler(app);
  app.get("/boom", () => {
    throw thrown;
  });
  return app;
}

describe("error handler", () => {
  it("maps Unauthorized → 401", async () => {
    const res = await appWithThrower(new Unauthorized("bad token")).request("/boom");
    expect(res.status).toBe(401);
    const body = await res.json();
    expect(body).toEqual({error: {code: "UNAUTHORIZED", message: "bad token"}});
  });

  it("maps Forbidden → 403", async () => {
    const res = await appWithThrower(new Forbidden("nope")).request("/boom");
    expect(res.status).toBe(403);
    expect((await res.json()).error.code).toBe("FORBIDDEN");
  });

  it("maps NotFound → 404", async () => {
    const res = await appWithThrower(new NotFound("missing")).request("/boom");
    expect(res.status).toBe(404);
    expect((await res.json()).error.code).toBe("NOT_FOUND");
  });

  it("maps Conflict → 409 with details", async () => {
    const err = new Conflict("idempotency conflict", {key: "abc"});
    const res = await appWithThrower(err).request("/boom");
    expect(res.status).toBe(409);
    const body = await res.json();
    expect(body.error.code).toBe("CONFLICT");
    expect(body.error.details).toEqual({key: "abc"});
  });

  it("maps BadRequest → 400", async () => {
    const res = await appWithThrower(new BadRequest("bad")).request("/boom");
    expect(res.status).toBe(400);
    expect((await res.json()).error.code).toBe("BAD_REQUEST");
  });

  it("maps unknown errors → 500 INTERNAL with generic message", async () => {
    const res = await appWithThrower(new Error("kaboom")).request("/boom");
    expect(res.status).toBe(500);
    const body = await res.json();
    expect(body.error.code).toBe("INTERNAL");
    expect(body.error.message).toBe("Internal server error");
  });

  it("does not leak details on AppError without details", async () => {
    const res = await appWithThrower(new AppError("X", "msg", 418)).request("/boom");
    expect(res.status).toBe(418);
    const body = await res.json();
    expect(body.error).toEqual({code: "X", message: "msg"});
  });
});
