import {beforeAll, beforeEach, afterAll, describe, it, expect} from "vitest";
import {initializeApp, deleteApp, getApps, type App} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import migration from "../../migrations/001-user-shape";

let app: App;

beforeAll(() => {
  app = getApps()[0] ?? initializeApp({projectId: "fling-rules-test"});
});
beforeEach(async () => {
  const docs = await getFirestore().collection("users").listDocuments();
  await Promise.all(docs.map((d) => d.delete()));
  const users = await getAuth().listUsers();
  await Promise.all(users.users.map((u) => getAuth().deleteUser(u.uid)));
});
afterAll(async () => {
  if (app) await deleteApp(app);
});

describe("migration 001-user-shape", () => {
  it("backfills new fields from legacy fields", async () => {
    await getAuth().createUser({uid: "alice", email: "alice@example.com"});
    await getFirestore().doc("users/alice").set({
      households: ["h1"],
      current_household: "h1",
    });
    await migration.up();
    const data = (await getFirestore().doc("users/alice").get()).data()!;
    expect(data.email).toBe("alice@example.com");
    expect(data.household_ids).toEqual(["h1"]);
    expect(data.current_household_id).toBe("h1");
    expect(data.schema_version).toBe(1);
    expect(data.households).toEqual(["h1"]); // legacy preserved
    expect(data.current_household).toBe("h1"); // legacy preserved
  });

  it("is idempotent — re-running does not re-stamp created_at", async () => {
    await getAuth().createUser({uid: "alice", email: "alice@example.com"});
    await getFirestore().doc("users/alice").set({households: []});
    await migration.up();
    const a = (await getFirestore().doc("users/alice").get()).data()!.created_at;
    await migration.up();
    const b = (await getFirestore().doc("users/alice").get()).data()!.created_at;
    expect(b).toEqual(a);
  });

  it("handles users with no auth record (email becomes null)", async () => {
    await getFirestore().doc("users/orphan").set({households: ["h1"]});
    await migration.up();
    const data = (await getFirestore().doc("users/orphan").get()).data()!;
    expect(data.email).toBeNull();
    expect(data.household_ids).toEqual(["h1"]);
    expect(data.schema_version).toBe(1);
  });
});
