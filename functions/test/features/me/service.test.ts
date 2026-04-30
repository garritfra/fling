import {beforeAll, beforeEach, afterAll, describe, it, expect} from "vitest";
import {initializeApp, deleteApp, getApps, type App} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import * as service from "../../../src/features/me/service";
import {NotFound} from "../../../src/core/errors/app_error";

let app: App;

beforeAll(() => {
  app = getApps()[0] ?? initializeApp({projectId: "fling-rules-test"});
});
beforeEach(async () => {
  const db = getFirestore();
  const docs = await db.collection("users").listDocuments();
  await Promise.all(docs.map((d) => d.delete()));
});
afterAll(async () => {
  if (app) await deleteApp(app);
});

const ctx = {uid: "alice", email: "alice@example.com", requestId: "rid"};

describe("me.service", () => {
  it("getMe throws NotFound when the user doc does not exist", async () => {
    await expect(service.getMe(ctx)).rejects.toThrow(NotFound);
  });

  it("createUser then getMe returns the new doc", async () => {
    await service.createUser("alice", "alice@example.com");
    const me = await service.getMe(ctx);
    expect(me).toEqual({
      uid: "alice",
      email: "alice@example.com",
      displayName: null,
      householdIds: [],
      currentHouseholdId: null,
    });
  });

  it("patchMe sets currentHouseholdId and dual-writes the legacy field", async () => {
    await service.createUser("alice", "alice@example.com");
    await service.patchMe(ctx, {currentHouseholdId: "h1"});
    const raw = (await getFirestore().doc("users/alice").get()).data();
    expect(raw?.current_household_id).toBe("h1");
    expect(raw?.current_household).toBe("h1");
  });

  it("patchMe sets displayName", async () => {
    await service.createUser("alice", "alice@example.com");
    const me = await service.patchMe(ctx, {displayName: "Alice"});
    expect(me.displayName).toBe("Alice");
  });

  it("deleteUser removes the doc", async () => {
    await service.createUser("alice", null);
    await service.deleteUser("alice");
    const snap = await getFirestore().doc("users/alice").get();
    expect(snap.exists).toBe(false);
  });
});
