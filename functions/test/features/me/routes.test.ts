import {beforeAll, beforeEach, afterAll, describe, it, expect} from "vitest";
import {OpenAPIHono} from "@hono/zod-openapi";
import {initializeApp, deleteApp, getApps, type App} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {registerMeRoutes} from "../../../src/features/me/module";
import {requestIdMiddleware} from "../../../src/core/middleware/request_id";
import {authMiddleware} from "../../../src/core/middleware/auth";
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
  await service.createUser(u.uid, "alice@example.com");
});

beforeEach(async () => {
  const db = getFirestore();
  const users = await db.collection("users").listDocuments();
  await Promise.all(users.map((d) => d.delete()));
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
