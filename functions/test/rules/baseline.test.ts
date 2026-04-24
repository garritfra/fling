import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
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
});
