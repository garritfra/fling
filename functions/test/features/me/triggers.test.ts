import {beforeAll, beforeEach, afterAll, describe, it, expect} from "vitest";
import {initializeApp, deleteApp, getApps, type App} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {handleUserCreated, handleUserDeleted} from "../../../src/features/me/triggers";

let app: App;

beforeAll(() => {
  app = getApps()[0] ?? initializeApp({projectId: "fling-rules-test"});
});
beforeEach(async () => {
  const docs = await getFirestore().collection("users").listDocuments();
  await Promise.all(docs.map((d) => d.delete()));
});
afterAll(async () => {
  if (app) await deleteApp(app);
});

describe("me triggers", () => {
  it("handleUserCreated writes the new doc shape", async () => {
    await handleUserCreated({uid: "alice", email: "alice@example.com"});
    const data = (await getFirestore().doc("users/alice").get()).data();
    expect(data?.email).toBe("alice@example.com");
    expect(data?.household_ids).toEqual([]);
    expect(data?.current_household_id).toBeNull();
    expect(data?.households).toEqual([]); // legacy dual-write
    expect(data?.current_household).toBeNull(); // legacy dual-write
    expect(data?.schema_version).toBe(1);
    expect(data?.created_at).toBeDefined();
  });

  it("handleUserDeleted removes the doc", async () => {
    await handleUserCreated({uid: "alice", email: null});
    await handleUserDeleted({uid: "alice"});
    expect((await getFirestore().doc("users/alice").get()).exists).toBe(false);
  });
});
