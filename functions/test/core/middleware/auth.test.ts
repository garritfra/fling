import {afterAll, beforeAll, describe, it, expect} from "vitest";
import {OpenAPIHono} from "@hono/zod-openapi";
import {requestIdMiddleware} from "../../../src/core/middleware/request_id";
import {authMiddleware} from "../../../src/core/middleware/auth";
import {installErrorHandler} from "../../../src/core/errors/handler";
import {getRequestContext} from "../../../src/core/context/request_context";
import {initializeApp, deleteApp, getApps} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";

let testToken: string;

beforeAll(async () => {
  if (getApps().length === 0) initializeApp({projectId: "fling-rules-test"});
  const auth = getAuth();
  // Reuse the user if alice already exists (e.g. created by an earlier
  // suite that shares the auth emulator under singleFork mode).
  let user;
  try {
    user = await auth.getUserByEmail("alice@example.com");
  } catch {
    user = await auth.createUser({email: "alice@example.com"});
  }
  // Build a custom token, then exchange it for an ID token via the emulator.
  const customToken = await auth.createCustomToken(user.uid);
  const r = await fetch(
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`,
    {method: "POST", body: JSON.stringify({token: customToken, returnSecureToken: true}), headers: {"Content-Type": "application/json"}},
  );
  const body = await r.json() as {idToken: string};
  testToken = body.idToken;
});

afterAll(async () => {
  for (const a of getApps()) await deleteApp(a);
});

function appWithAuth(): OpenAPIHono {
  const app = new OpenAPIHono();
  installErrorHandler(app);
  app.use("*", requestIdMiddleware());
  app.use("/v1/*", authMiddleware());
  app.get("/v1/whoami", (c) => {
    const {uid, email, requestId} = getRequestContext(c);
    return c.json({uid, email, requestId});
  });
  return app;
}

describe("auth middleware", () => {
  it("rejects 401 when Authorization header is missing", async () => {
    const res = await appWithAuth().request("/v1/whoami");
    expect(res.status).toBe(401);
    expect((await res.json()).error.code).toBe("UNAUTHORIZED");
  });

  it("rejects 401 on a malformed token", async () => {
    const res = await appWithAuth().request("/v1/whoami", {headers: {Authorization: "Bearer not-a-real-token"}});
    expect(res.status).toBe(401);
  });

  it("attaches uid + email to RequestContext on a valid token", async () => {
    const res = await appWithAuth().request("/v1/whoami", {headers: {Authorization: `Bearer ${testToken}`}});
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.uid).toBeTypeOf("string");
    expect(body.email).toBe("alice@example.com");
    expect(body.requestId).toMatch(/^[0-9a-f-]{36}$/);
  });
});
