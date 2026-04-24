import { afterAll, beforeAll, beforeEach, describe, it } from "vitest";
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
  assertSucceeds,
  assertFails,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "fling-rules-test",
    firestore: {
      rules: readFileSync(resolve(__dirname, "../../../firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

afterAll(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());

describe("firestore.rules baseline", () => {
  it("user can read & write their own /users/{uid} doc", async () => {
    const alice = env.authenticatedContext("alice").firestore();
    await assertSucceeds(alice.doc("users/alice").set({ households: [] }));
    await assertSucceeds(alice.doc("users/alice").get());
  });

  it("user cannot read another user's /users/{uid} doc", async () => {
    const alice = env.authenticatedContext("alice").firestore();
    await assertFails(alice.doc("users/bob").get());
  });

  it("a household member can read household data", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.doc("households/h1").set({ name: "Home" });
      await db.doc("households/h1/members/alice").set({});
      await db.doc("households/h1/lists/l1").set({ name: "Groceries" });
    });
    const alice = env.authenticatedContext("alice").firestore();
    await assertSucceeds(alice.doc("households/h1").get());
    await assertSucceeds(alice.doc("households/h1/lists/l1").get());
  });

  it("a non-member cannot read household data", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.doc("households/h1/members/alice").set({});
    });
    const bob = env.authenticatedContext("bob").firestore();
    await assertFails(bob.doc("households/h1").get());
  });

  it("an unauthenticated request is denied everywhere", async () => {
    const anon = env.unauthenticatedContext().firestore();
    await assertFails(anon.doc("users/alice").get());
    await assertFails(anon.doc("households/h1").get());
  });

  it("a signed-in user can create a brand-new household + first member doc", async () => {
    const alice = env.authenticatedContext("alice").firestore();
    await assertSucceeds(alice.doc("households/h_new").set({ name: "Home" }));
    await assertSucceeds(alice.doc("households/h_new/members/alice").set({}));
  });

  it("known-loose invariant: a non-member CAN add themselves to an existing household (Phase 2 will close this)", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.doc("households/h_bob").set({ name: "Bob's place" });
      await db.doc("households/h_bob/members/bob").set({});
    });
    const alice = env.authenticatedContext("alice").firestore();
    // Alice (not a member of h_bob) self-adds. Currently permitted by the
    // Phase-0 carve-out. If this assertion ever fails, you tightened the
    // members/{uid} rule — confirm that was intentional and update Phase 2.
    await assertSucceeds(alice.doc("households/h_bob/members/alice").set({}));
  });
});
