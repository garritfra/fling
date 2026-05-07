import {beforeAll, beforeEach, afterAll, describe, it, expect} from "vitest";
import {OpenAPIHono} from "@hono/zod-openapi";
import {initializeApp, deleteApp, getApps, type App} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {registerMeRoutes} from "../../../src/features/me/module";
import {requestIdMiddleware} from "../../../src/core/middleware/request_id";
import {authMiddleware} from "../../../src/core/middleware/auth";
import {idempotencyMiddleware} from "../../../src/core/middleware/idempotency";
import {installErrorHandler} from "../../../src/core/errors/handler";
import * as service from "../../../src/features/me/service";

let firebaseApp: App;
let aliceToken: string;
let aliceUid: string;

async function exchangeCustomTokenForId(customToken: string): Promise<string> {
  const r = await fetch(
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`,
    {method: "POST", body: JSON.stringify({token: customToken, returnSecureToken: true}), headers: {"Content-Type": "application/json"}},
  );
  return ((await r.json()) as {idToken: string}).idToken;
}

beforeAll(async () => {
  firebaseApp = getApps()[0] ?? initializeApp({projectId: "fling-rules-test"});
  // Reuse the user if alice already exists from a prior test run.
  let u;
  try {
    u = await getAuth().getUserByEmail("alice@example.com");
  } catch {
    u = await getAuth().createUser({email: "alice@example.com"});
  }
  aliceUid = u.uid;
  aliceToken = await exchangeCustomTokenForId(await getAuth().createCustomToken(u.uid));
});

beforeEach(async () => {
  const db = getFirestore();
  const users = await db.collection("users").listDocuments();
  await Promise.all(users.map((d) => d.delete()));
  const idemKeys = await db.collection("idempotency_keys").listDocuments();
  await Promise.all(idemKeys.map((d) => d.delete()));
  await service.createUser(aliceUid, "alice@example.com");
});

afterAll(async () => {
  if (firebaseApp) await deleteApp(firebaseApp);
});

function buildApp(): OpenAPIHono {
  const app = new OpenAPIHono();
  installErrorHandler(app);
  app.use("*", requestIdMiddleware());
  app.use("/v1/*", authMiddleware());
  app.use("/v1/*", idempotencyMiddleware());
  registerMeRoutes(app);
  return app;
}

describe("GET /v1/me", () => {
  it("401 without a token", async () => {
    const res = await buildApp().request("/v1/me");
    expect(res.status).toBe(401);
  });

  it("returns the user doc with auth-token email", async () => {
    const res = await buildApp().request("/v1/me", {
      headers: {Authorization: `Bearer ${aliceToken}`},
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.email).toBe("alice@example.com");
    expect(body.householdIds).toEqual([]);
    expect(body.currentHouseholdId).toBeNull();
    expect(body.displayName).toBeNull();
  });
});

describe("PATCH /v1/me", () => {
  it("401 without a token", async () => {
    const res = await buildApp().request("/v1/me", {
      method: "PATCH",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({displayName: "Alice"}),
    });
    expect(res.status).toBe(401);
  });

  it("updates displayName and returns the updated doc", async () => {
    const res = await buildApp().request("/v1/me", {
      method: "PATCH",
      headers: {Authorization: `Bearer ${aliceToken}`, "Content-Type": "application/json"},
      body: JSON.stringify({displayName: "Alice Updated"}),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.displayName).toBe("Alice Updated");
    expect(body.email).toBe("alice@example.com");
  });

  it("updates currentHouseholdId and dual-writes the legacy field", async () => {
    const res = await buildApp().request("/v1/me", {
      method: "PATCH",
      headers: {Authorization: `Bearer ${aliceToken}`, "Content-Type": "application/json"},
      body: JSON.stringify({currentHouseholdId: "h-xyz"}),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.currentHouseholdId).toBe("h-xyz");
  });

  it("400 on unknown field (strict schema)", async () => {
    const res = await buildApp().request("/v1/me", {
      method: "PATCH",
      headers: {Authorization: `Bearer ${aliceToken}`, "Content-Type": "application/json"},
      body: JSON.stringify({unknownField: "x"}),
    });
    expect(res.status).toBe(400);
  });

  it("idempotency: same key + same body returns the same response without re-running", async () => {
    const headers = {
      "Content-Type": "application/json",
      Authorization: `Bearer ${aliceToken}`,
      "Idempotency-Key": "patch-1",
    };
    const body = JSON.stringify({displayName: "Alice"});
    const r1 = await buildApp().request("/v1/me", {method: "PATCH", headers, body});
    const r2 = await buildApp().request("/v1/me", {method: "PATCH", headers, body});
    expect(r1.status).toBe(200);
    expect(r2.status).toBe(200);
    const b1 = await r1.json();
    const b2 = await r2.json();
    expect(b2).toEqual(b1);
  });

  it("idempotency: same key + different body returns 409", async () => {
    const headers = {
      "Content-Type": "application/json",
      Authorization: `Bearer ${aliceToken}`,
      "Idempotency-Key": "patch-2",
    };
    const r1 = await buildApp().request("/v1/me", {
      method: "PATCH",
      headers,
      body: JSON.stringify({displayName: "Alice"}),
    });
    const r2 = await buildApp().request("/v1/me", {
      method: "PATCH",
      headers,
      body: JSON.stringify({displayName: "Bob"}),
    });
    expect(r1.status).toBe(200);
    expect(r2.status).toBe(409);
  });
});
