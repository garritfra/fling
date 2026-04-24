# Phase 0 — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land all the scaffolding the rewrite needs — security rules, CI, Hono + Vitest backend, Flutter dependency upgrades, lint boundaries, migrations runner, OpenAPI → Dart client pipeline — without changing any user-visible behaviour.

**Architecture:** Single Firebase project, single repo. Existing v1 callable Functions stay live untouched. A new empty Hono `api` function ships behind `/v1/healthz` only. Flutter app keeps its current code paths; new `core/` and `features/` directories sit empty next to `lib/data` and `lib/pages` until Phase 1 starts moving slices in.

**Tech Stack:** Firebase Functions v2 + Hono + `@hono/zod-openapi`, Vitest, ESLint v8 + `eslint-plugin-boundaries`, Firebase emulator suite, Flutter 3.35 + Riverpod + freezed + go_router + `import_lint`, openapi-generator-cli (Dart client), GitHub Actions.

**Spec:** [`docs/superpowers/specs/2026-04-24-fling-rewrite-design.md`](../specs/2026-04-24-fling-rewrite-design.md)

**STATUS tracker:** [`docs/superpowers/migrations/STATUS.md`](./STATUS.md)

---

## Exit criteria (mirrors STATUS §"Phase 0 — Foundation")

- [ ] `firestore.rules` committed mirroring current behaviour
- [ ] CI workflow runs `backend`, `flutter`, `contracts` jobs on PRs
- [ ] Firebase emulator boots locally via `scripts/dev.sh`
- [ ] `functions/` includes Hono + Vitest + `@hono/zod-openapi`; empty `api` function deployed
- [ ] Flutter deps added: `riverpod`, `freezed`, `json_serializable`, `go_router`, `connectivity_plus`, `shared_preferences`
- [ ] `core/` and `features/` directories scaffolded in both backend and Flutter
- [ ] Lint boundary rule active (presentation ↛ data; application ↛ presentation; cross-feature ↛ direct import)
- [ ] `migrations/` runner present with empty initial migration
- [ ] No user-visible change in production

## File map

Created:

```text
firestore.rules
firestore.indexes.json
scripts/dev.sh
scripts/seed.ts
.tool-versions
functions/vitest.config.ts
functions/.eslintrc.cjs                          # replaces .eslintrc.js if present
functions/src/api/app.ts
functions/src/api/adapter.ts                     # Cloud Functions ↔ Hono Web Request bridge
functions/src/core/{auth,errors,events,context,firestore,idempotency,logger,middleware,flags}/index.ts
functions/src/features/{me,households,members,invites,lists,templates}/module.ts
functions/migrations/runner.ts
functions/migrations/000-initial.ts
functions/scripts/openapi.ts
functions/test/api/healthz.test.ts
functions/test/migrations/runner.test.ts
functions/test/setup.ts
openapi/openapi.json                             # generated, committed
lib/core/{api,auth,firestore,errors,logger,router,theme,ui,flags}/.gitkeep
lib/core/api/generated/.gitkeep
lib/features/{auth,me,households,lists,templates}/{data,domain,application,presentation}/.gitkeep
import_lint.yaml
test/smoke_test.dart
.github/workflows/ci.yml
docs/superpowers/migrations/phase-0-foundation.md   # this file
```

Modified:

```text
.gitignore
.firebaserc                                      # add 'staging' alias (skipped if absent — leave as-is for v1)
firebase.json                                    # add firestore + emulators sections
functions/package.json                           # node 20, scripts, deps
functions/tsconfig.json                          # esModuleInterop, moduleResolution=node16
functions/src/index.ts                           # export api alongside existing v1 callables
pubspec.yaml                                     # add deps
docs/superpowers/migrations/STATUS.md            # link plan; flip Phase 0 to In Progress; update at end
.github/workflows/firebase-functions.yml         # delete (superseded by ci.yml)
.github/workflows/build.yml                      # delete (superseded by ci.yml)
```

Deleted at end of phase: none (legacy v1 functions stay live until Phase 6).

---

## Task 0: Set up isolated worktree for Phase 0

**Files:**
- None modified inside repo; creates sibling working tree

- [ ] **Step 1: Verify clean baseline**

```bash
cd /Users/garrit/src/garritfra/fling
git status
```

Expected: working tree clean on branch `v2`.

- [ ] **Step 2: Decide worktree directory and ensure it's gitignored**

```bash
ls -d .worktrees 2>/dev/null || mkdir .worktrees
git check-ignore -q .worktrees && echo "ignored" || echo "NOT ignored"
```

If `NOT ignored`, append a line and commit:

```bash
printf '\n# git worktrees\n.worktrees/\n' >> .gitignore
git add .gitignore
git commit -m "chore: ignore .worktrees/"
```

- [ ] **Step 3: Create worktree on a new branch off `v2`**

```bash
git worktree add .worktrees/phase-0-foundation -b phase-0-foundation v2
cd .worktrees/phase-0-foundation
```

Expected: new branch `phase-0-foundation` checked out at `.worktrees/phase-0-foundation`.

- [ ] **Step 4: Verify baseline tooling installs**

```bash
cd functions && npm ci --no-audit && cd ..
flutter pub get
```

Expected: both succeed. (Node 16 deprecation warnings are OK; we fix them in Task 2.)

- [ ] **Step 5: Commit worktree-only artefacts (none yet)**

No commit. Move to Task 1.

---

## Task 1: Bump Node engines and switch ESLint config to flat-friendly CJS

**Files:**
- Modify: `functions/package.json`
- Modify: `functions/tsconfig.json`
- Create: `.tool-versions`
- Create or modify: `functions/.eslintrc.cjs`

We need Node 20 for `firebase-functions` v6 + Hono + Vitest. We also normalise ESLint config to a single CJS file.

- [ ] **Step 1: Update `functions/package.json` engines, scripts, and devDeps placeholder**

Replace the file with:

```json
{
  "name": "functions",
  "scripts": {
    "lint": "eslint --ext .js,.ts .",
    "lint:fix": "eslint --ext .js,.ts --fix .",
    "build": "tsc",
    "build:watch": "tsc --watch",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:integration": "firebase emulators:exec --only firestore,auth 'vitest run --dir test/api'",
    "openapi:generate": "tsx scripts/openapi.ts",
    "migrate": "tsx migrations/runner.ts",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "20"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^13.7.0",
    "firebase-functions": "^6.3.2"
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^8.58.1",
    "@typescript-eslint/parser": "^8.58.1",
    "eslint": "^8.57.0",
    "eslint-config-google": "^0.14.0",
    "eslint-plugin-import": "^2.32.0",
    "firebase-functions-test": "^3.4.1",
    "tsx": "^4.19.2",
    "typescript": "^5.6.3"
  },
  "private": true
}
```

Notes:
- Drop TypeScript v6 (was misversioned in repo; latest stable is 5.x).
- `tsx` lets us run `.ts` files directly for `migrate` and `openapi:generate`.

- [ ] **Step 2: Pin Node via `.tool-versions` (asdf / mise) at repo root**

```bash
echo "nodejs 20.18.0" > /Users/garrit/src/garritfra/fling/.worktrees/phase-0-foundation/.tool-versions
```

- [ ] **Step 3: Tighten `functions/tsconfig.json`**

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "es2022",
    "lib": ["es2022"],
    "moduleResolution": "node",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true
  },
  "compileOnSave": true,
  "include": ["src"],
  "exclude": ["test", "scripts", "migrations"]
}
```

- [ ] **Step 4: Replace `functions/.eslintrc.js` (if any) with `functions/.eslintrc.cjs`**

```bash
ls functions/.eslintrc* 2>/dev/null
# delete any pre-existing variants:
rm -f functions/.eslintrc.js functions/.eslintrc.json
```

Create `functions/.eslintrc.cjs`:

```js
module.exports = {
  root: true,
  env: { es2022: true, node: true },
  parser: "@typescript-eslint/parser",
  parserOptions: { ecmaVersion: 2022, sourceType: "module", project: ["tsconfig.json"] },
  plugins: ["@typescript-eslint", "import"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "google",
  ],
  ignorePatterns: ["lib/**", "node_modules/**", "scripts/**", "migrations/**", "test/**"],
  rules: {
    "quotes": ["error", "double", { "avoidEscape": true }],
    "max-len": ["warn", { "code": 100 }],
    "@typescript-eslint/no-explicit-any": "off",
    "require-jsdoc": "off",
    "valid-jsdoc": "off"
  }
};
```

- [ ] **Step 5: Install upgraded deps**

```bash
cd functions && rm -rf node_modules package-lock.json && npm install --no-audit && cd ..
```

Expected: install succeeds, no engine warning for Node 20.

- [ ] **Step 6: Verify build still passes**

```bash
cd functions && npm run lint && npm run build && cd ..
```

Expected: both succeed. (Existing v1 callables in `src/index.ts` still type-check.)

- [ ] **Step 7: Commit**

```bash
cd /Users/garrit/src/garritfra/fling/.worktrees/phase-0-foundation
git add .tool-versions functions/package.json functions/package-lock.json functions/tsconfig.json functions/.eslintrc.cjs
git rm -f functions/.eslintrc.js functions/.eslintrc.json 2>/dev/null || true
git commit -m "chore(functions): bump Node 20, TS 5, normalise ESLint config"
```

---

## Task 2: Commit `firestore.rules` mirroring current behaviour

**Files:**
- Create: `firestore.rules`
- Create: `firestore.indexes.json`
- Modify: `firebase.json` (add `firestore` block)
- Test: `functions/test/rules/baseline.test.ts`

The repo currently has no rules file. The deployed project rules grant household-scoped read/write to members and self read/write on user docs (inferred from the Flutter app paths in `lib/data/*` and the v1 callables).

- [ ] **Step 1: Author `firestore.rules` (root of repo)**

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function signedIn() { return request.auth != null; }

    function isMember(hid) {
      return signedIn()
        && exists(/databases/$(db)/documents/households/$(hid)/members/$(request.auth.uid));
    }

    // Users can read & write their own user doc (current Flutter behaviour).
    match /users/{uid} {
      allow read, write: if signedIn() && request.auth.uid == uid;
    }

    // Households + nested data: any household member can read & write.
    // Phase 1+ tightens this collection-by-collection.
    match /households/{hid} {
      allow read, write: if isMember(hid)
                         || (signedIn() && request.method == 'create');

      match /members/{uid} {
        allow read, write: if isMember(hid)
                           || (signedIn() && request.auth.uid == uid && request.method == 'create');
      }

      match /lists/{lid}/{document=**} {
        allow read, write: if isMember(hid);
      }

      match /templates/{tid}/{document=**} {
        allow read, write: if isMember(hid);
      }
    }
  }
}
```

Rationale notes (in plan, not in file):
- The `request.method == 'create'` carve-outs preserve the current "any signed-in user can create a household and add themselves as the first member" flow that `lib/pages/household_add.dart` triggers.
- No `invites/` rule yet — the v1 invite path goes through a callable, not a client-side write.

- [ ] **Step 2: Add empty `firestore.indexes.json`**

```json
{
  "indexes": [],
  "fieldOverrides": []
}
```

- [ ] **Step 3: Wire `firebase.json` to point at the rules + indexes**

Replace `firebase.json` with:

```json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log",
        "test",
        "scripts",
        "migrations",
        "vitest.config.ts"
      ],
      "predeploy": [
        "npm --prefix \"$RESOURCE_DIR\" run build"
      ]
    }
  ],
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ]
  },
  "emulators": {
    "auth":      { "port": 9099 },
    "functions": { "port": 5001 },
    "firestore": { "port": 8080 },
    "hosting":   { "port": 5000 },
    "ui":        { "enabled": true, "port": 4000 },
    "singleProjectMode": true
  }
}
```

- [ ] **Step 4: Install `@firebase/rules-unit-testing` for rules tests**

```bash
cd functions && npm install --save-dev @firebase/rules-unit-testing@^4.0.0 && cd ..
```

- [ ] **Step 5: Write the failing rules baseline test**

Create `functions/test/rules/baseline.test.ts`:

```ts
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
```

- [ ] **Step 6: Run the test (will fail because Vitest isn't installed yet)**

```bash
cd functions && npx vitest run test/rules/baseline.test.ts 2>&1 | head
```

Expected: fails because `vitest` not installed. We install it in Task 3 and rerun.

- [ ] **Step 7: Commit (rules + skeleton; the test is also committed but not yet runnable — that's fine, Task 3 wires Vitest)**

```bash
git add firestore.rules firestore.indexes.json firebase.json functions/test/rules/baseline.test.ts functions/package.json functions/package-lock.json
git commit -m "feat(rules): commit baseline firestore.rules mirroring current behaviour"
```

---

## Task 3: Install Vitest and wire it up against the emulator

**Files:**
- Create: `functions/vitest.config.ts`
- Create: `functions/test/setup.ts`
- Modify: `functions/package.json` (already done in Task 1; verify `test`, `test:integration` scripts present)

- [ ] **Step 1: Install Vitest**

```bash
cd functions && npm install --save-dev vitest@^2.1.0 @vitest/coverage-v8@^2.1.0 && cd ..
```

- [ ] **Step 2: Create `functions/vitest.config.ts`**

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: false,
    environment: "node",
    setupFiles: ["./test/setup.ts"],
    include: ["test/**/*.test.ts"],
    testTimeout: 15_000,
  },
});
```

- [ ] **Step 3: Create `functions/test/setup.ts`**

```ts
process.env.GCLOUD_PROJECT ||= "fling-rules-test";
process.env.FIRESTORE_EMULATOR_HOST ||= "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST ||= "127.0.0.1:9099";
```

- [ ] **Step 4: Verify the rules test runs against the emulator**

In one terminal:

```bash
firebase emulators:start --only firestore,auth
```

In another:

```bash
cd functions && npm test -- test/rules/baseline.test.ts
```

Expected: 5 tests pass.

Stop the emulator (Ctrl-C in its terminal).

- [ ] **Step 5: Commit**

```bash
git add functions/vitest.config.ts functions/test/setup.ts functions/package.json functions/package-lock.json
git commit -m "test(functions): add Vitest with rules baseline against emulator"
```

---

## Task 4: Add `scripts/dev.sh` to boot the emulator suite

**Files:**
- Create: `scripts/dev.sh`
- Create: `scripts/seed.ts`

- [ ] **Step 1: Create `scripts/dev.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase-tools not installed. Install with: npm i -g firebase-tools" >&2
  exit 1
fi

# Build functions before starting (functions emulator serves from lib/).
( cd functions && npm run build )

# Start full emulator suite (firestore, auth, functions, hosting, ui).
exec firebase emulators:start --import=./.emulator-data --export-on-exit=./.emulator-data
```

- [ ] **Step 2: Add `.emulator-data/` to `.gitignore`**

```bash
printf '\n# firebase emulator state\n.emulator-data/\n' >> .gitignore
```

- [ ] **Step 3: Make the script executable**

```bash
chmod +x scripts/dev.sh
```

- [ ] **Step 4: Smoke-test it boots**

```bash
./scripts/dev.sh &
DEV_PID=$!
sleep 12
curl -fsS http://127.0.0.1:4000 > /dev/null && echo "EMULATOR UI OK"
kill $DEV_PID
wait $DEV_PID 2>/dev/null || true
```

Expected: prints `EMULATOR UI OK`.

- [ ] **Step 5: Create stub `scripts/seed.ts` (fully written in Phase 1)**

```ts
// scripts/seed.ts — populated in Phase 1 once the `me` slice ships.
// For now: a no-op that prints how to use the emulator.
console.log("Seed script is a no-op until Phase 1.");
console.log("Open the Emulator UI at http://127.0.0.1:4000 to seed manually.");
```

- [ ] **Step 6: Commit**

```bash
git add scripts/dev.sh scripts/seed.ts .gitignore
git commit -m "chore(scripts): add scripts/dev.sh for the Firebase emulator suite"
```

---

## Task 5: Add Hono + `@hono/zod-openapi` and ship an empty `api` function

**Files:**
- Create: `functions/src/api/app.ts`
- Create: `functions/src/api/adapter.ts`
- Modify: `functions/src/index.ts`
- Test: `functions/test/api/healthz.test.ts`

- [ ] **Step 1: Install runtime deps**

```bash
cd functions && npm install hono@^4.6.0 @hono/zod-openapi@^0.18.0 zod@^3.23.0 && cd ..
```

- [ ] **Step 2: Write the failing healthz test**

Create `functions/test/api/healthz.test.ts`:

```ts
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
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
cd functions && npm test -- test/api/healthz.test.ts
```

Expected: fail with "Cannot find module '../../src/api/app'".

- [ ] **Step 4: Implement the Hono app**

Create `functions/src/api/app.ts`:

```ts
import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";

const HealthSchema = z.object({
  status: z.literal("ok"),
  version: z.string(),
}).openapi("Health");

const healthzRoute = createRoute({
  method: "get",
  path: "/v1/healthz",
  responses: {
    200: {
      description: "Health check",
      content: { "application/json": { schema: HealthSchema } },
    },
  },
});

export const app = new OpenAPIHono();

app.openapi(healthzRoute, (c) =>
  c.json({ status: "ok" as const, version: process.env.K_REVISION ?? "dev" })
);

app.doc("/v1/openapi.json", {
  openapi: "3.0.3",
  info: { title: "Fling API", version: "1.0.0" },
});
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd functions && npm test -- test/api/healthz.test.ts
```

Expected: 2 tests pass.

- [ ] **Step 6: Implement the Cloud Functions ↔ Hono adapter**

Create `functions/src/api/adapter.ts`:

```ts
import type { Request, Response } from "firebase-functions/v2/https";
import type { Hono } from "hono";

/**
 * Bridge a firebase-functions v2 onRequest invocation into a Hono `app.fetch`
 * call. Hono speaks the WHATWG Fetch API; Cloud Functions hands us node-style
 * (req, res). We translate.
 */
export async function handle(app: Hono, req: Request, res: Response): Promise<void> {
  const protocol = (req.headers["x-forwarded-proto"] as string) || "https";
  const host = req.headers.host ?? "localhost";
  const url = `${protocol}://${host}${req.originalUrl ?? req.url}`;

  const headers = new Headers();
  for (const [k, v] of Object.entries(req.headers)) {
    if (Array.isArray(v)) headers.set(k, v.join(","));
    else if (v !== undefined) headers.set(k, String(v));
  }

  const init: RequestInit = { method: req.method, headers };
  if (!["GET", "HEAD"].includes(req.method)) {
    init.body = req.rawBody ?? Buffer.from(JSON.stringify(req.body ?? {}));
  }

  const fetchRes = await app.fetch(new global.Request(url, init));

  res.status(fetchRes.status);
  fetchRes.headers.forEach((value, key) => res.setHeader(key, value));
  const buf = Buffer.from(await fetchRes.arrayBuffer());
  res.end(buf);
}
```

- [ ] **Step 7: Wire the `api` function into `functions/src/index.ts`**

Replace `functions/src/index.ts` with (preserving all v1 callables):

```ts
import * as functions from "firebase-functions/v1";
import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { app } from "./api/app";
import { handle } from "./api/adapter";

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

// ----- v2: REST API (Hono) -----------------------------------------------
export const api = onRequest(
  { region: "us-central1", cors: true, maxInstances: 10 },
  (req, res) => handle(app, req, res)
);

// ----- v1: legacy callables & triggers (untouched until Phase 1+) --------

exports.cacheJoinHousehold = functions.firestore
  .document("households/{householdId}/members/{memberId}")
  .onCreate((change, context) => {
    const memberId = context.params.memberId;
    const householdId = context.params.householdId;
    return db
      .collection("users")
      .doc(memberId)
      .update({
        households: admin.firestore.FieldValue.arrayUnion(householdId),
      });
  });

exports.cacheLeaveHousehold = functions.firestore
  .document("households/{householdId}/members/{memberId}")
  .onDelete((change, context) => {
    const memberId = context.params.memberId;
    const householdId = context.params.householdId;
    return db
      .collection("users")
      .doc(memberId)
      .update({
        households: admin.firestore.FieldValue.arrayRemove(householdId),
      });
  });

exports.inviteToHouseholdByEmail = functions.https.onCall(
  async (data, context) => {
    const uid = context?.auth?.uid;
    const householdId = data.householdId;
    const invitedEmail = data.email;

    if (!uid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "The function must be called while authenticated."
      );
    }

    const membersRef = db
      .collection("households")
      .doc(householdId)
      .collection("members");

    const existingMemberSnap = await membersRef.doc(uid).get();
    if (!existingMemberSnap.exists) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "The user calling this function must be a member of the household."
      );
    }

    const invitedUser = await auth.getUserByEmail(invitedEmail);
    if (!invitedUser.uid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "The invited user does not exist."
      );
    }

    return membersRef.doc(invitedUser.uid).create({});
  }
);

exports.setupUser = functions.auth.user().onCreate((user) =>
  db.collection("users").doc(user.uid).set({ households: [] })
);

exports.deleteUser = functions.auth.user().onDelete((user) =>
  db.collection("users").doc(user.uid).delete()
);
```

- [ ] **Step 8: Build and verify**

```bash
cd functions && npm run build && cd ..
```

Expected: clean compile.

- [ ] **Step 9: Boot the emulator and curl `/v1/healthz`**

```bash
./scripts/dev.sh &
DEV_PID=$!
sleep 12
curl -fsS "http://127.0.0.1:5001/$(jq -r .projects.default .firebaserc)/us-central1/api/v1/healthz"
echo
kill $DEV_PID
wait $DEV_PID 2>/dev/null || true
```

Expected: `{"status":"ok","version":"dev"}`.

- [ ] **Step 10: Commit**

```bash
git add functions/src/api/app.ts functions/src/api/adapter.ts functions/src/index.ts functions/test/api/healthz.test.ts functions/package.json functions/package-lock.json
git commit -m "feat(api): add empty Hono v1 API behind /v1/healthz with OpenAPI"
```

---

## Task 6: Scaffold backend `core/` and `features/` directories

**Files:**
- Create: `functions/src/core/{auth,errors,events,context,firestore,idempotency,logger,middleware,flags}/index.ts`
- Create: `functions/src/features/{me,households,members,invites,lists,templates}/module.ts`

Each file is intentionally a near-empty stub that exports a documented placeholder. They give Phase 1+ concrete files to grow into and let the lint boundary plugin (Task 8) detect cross-feature imports immediately.

- [ ] **Step 1: Create core stubs**

For each `<name>` in `auth errors events context firestore idempotency logger middleware flags`, create `functions/src/core/<name>/index.ts` with:

```ts
// core/<name>: populated in Phase 1+.
// See docs/superpowers/specs/2026-04-24-fling-rewrite-design.md §5.
export {};
```

Replace `<name>` literally per directory.

Helper:

```bash
cd functions/src
for d in auth errors events context firestore idempotency logger middleware flags; do
  mkdir -p "core/$d"
  cat > "core/$d/index.ts" <<EOF
// core/$d: populated in Phase 1+.
// See docs/superpowers/specs/2026-04-24-fling-rewrite-design.md §5.
export {};
EOF
done
cd ../..
```

- [ ] **Step 2: Create feature module stubs**

```bash
cd functions/src
for f in me households members invites lists templates; do
  mkdir -p "features/$f"
  cat > "features/$f/module.ts" <<EOF
// features/$f: populated in the corresponding phase.
// See docs/superpowers/specs/2026-04-24-fling-rewrite-design.md §5.
export const FEATURE_NAME = "$f" as const;
EOF
done
cd ../..
```

- [ ] **Step 3: Build to confirm no breakage**

```bash
cd functions && npm run build && cd ..
```

Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add functions/src/core functions/src/features
git commit -m "chore(functions): scaffold core/ and features/ slice directories"
```

---

## Task 7: Migrations runner + initial migration

**Files:**
- Create: `functions/migrations/runner.ts`
- Create: `functions/migrations/000-initial.ts`
- Test: `functions/test/migrations/runner.test.ts`

Per spec §10.1: TS files exporting `up()` (and optional `down()`); state in `_migrations/{id}`; idempotent re-runs.

- [ ] **Step 1: Write the failing runner test**

Create `functions/test/migrations/runner.test.ts`:

```ts
import { describe, it, expect, beforeEach } from "vitest";
import { runMigrations, type Migration, type MigrationState } from "../../migrations/runner";

class InMemoryState implements MigrationState {
  applied = new Set<string>();
  async isApplied(id: string) { return this.applied.has(id); }
  async markApplied(id: string) { this.applied.add(id); }
}

describe("migrations runner", () => {
  let state: InMemoryState;
  beforeEach(() => { state = new InMemoryState(); });

  it("runs a pending migration once", async () => {
    let calls = 0;
    const m: Migration = { id: "001-test", up: async () => { calls++; } };
    await runMigrations([m], state);
    expect(calls).toBe(1);
    expect(await state.isApplied("001-test")).toBe(true);
  });

  it("skips an already-applied migration", async () => {
    let calls = 0;
    const m: Migration = { id: "001-test", up: async () => { calls++; } };
    await runMigrations([m], state);
    await runMigrations([m], state);
    expect(calls).toBe(1);
  });

  it("runs migrations in declared order and stops on failure", async () => {
    const order: string[] = [];
    const ms: Migration[] = [
      { id: "001", up: async () => { order.push("001"); } },
      { id: "002", up: async () => { throw new Error("boom"); } },
      { id: "003", up: async () => { order.push("003"); } },
    ];
    await expect(runMigrations(ms, state)).rejects.toThrow("boom");
    expect(order).toEqual(["001"]);
    expect(await state.isApplied("001")).toBe(true);
    expect(await state.isApplied("002")).toBe(false);
    expect(await state.isApplied("003")).toBe(false);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd functions && npm test -- test/migrations/runner.test.ts
```

Expected: fails with "Cannot find module".

- [ ] **Step 3: Implement the runner**

Create `functions/migrations/runner.ts`:

```ts
import { readdirSync } from "node:fs";
import { resolve, join } from "node:path";

export interface Migration {
  id: string;
  up: () => Promise<void>;
  down?: () => Promise<void>;
}

export interface MigrationState {
  isApplied(id: string): Promise<boolean>;
  markApplied(id: string): Promise<void>;
}

export async function runMigrations(
  migrations: Migration[],
  state: MigrationState,
  log: (msg: string) => void = console.log
): Promise<void> {
  for (const m of migrations) {
    if (await state.isApplied(m.id)) {
      log(`[migrate] skip ${m.id} (already applied)`);
      continue;
    }
    log(`[migrate] apply ${m.id}`);
    await m.up();
    await state.markApplied(m.id);
    log(`[migrate] done  ${m.id}`);
  }
}

/** Firestore-backed state used at runtime (lazy-loaded so tests don't need Admin SDK). */
export async function firestoreState(): Promise<MigrationState> {
  const admin = await import("firebase-admin");
  if (admin.apps.length === 0) admin.initializeApp();
  const db = admin.firestore();
  return {
    async isApplied(id) {
      const snap = await db.collection("_migrations").doc(id).get();
      return snap.exists;
    },
    async markApplied(id) {
      await db.collection("_migrations").doc(id).set({
        applied_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    },
  };
}

/** Discover and load all migration modules in this directory (NNN-*.ts). */
export async function loadMigrations(dir = __dirname): Promise<Migration[]> {
  const files = readdirSync(dir)
    .filter((f) => /^\d{3}-.*\.ts$/.test(f) && f !== "runner.ts")
    .sort();
  const mods = await Promise.all(
    files.map((f) => import(resolve(join(dir, f))) as Promise<{ default: Migration }>)
  );
  return mods.map((m) => m.default);
}

// CLI entrypoint: `tsx migrations/runner.ts`
if (require.main === module) {
  (async () => {
    const migrations = await loadMigrations();
    const state = await firestoreState();
    await runMigrations(migrations, state);
  })().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
```

- [ ] **Step 4: Create the empty initial migration**

Create `functions/migrations/000-initial.ts`:

```ts
import type { Migration } from "./runner";

const migration: Migration = {
  id: "000-initial",
  up: async () => {
    // Intentional no-op. Establishes the migrations baseline so subsequent
    // migrations can rely on _migrations/000-initial existing.
  },
};

export default migration;
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd functions && npm test -- test/migrations/runner.test.ts
```

Expected: 3 tests pass.

- [ ] **Step 6: Smoke-test the CLI against the emulator**

```bash
./scripts/dev.sh &
DEV_PID=$!
sleep 12
( cd functions && FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=fling-list npm run migrate )
kill $DEV_PID
wait $DEV_PID 2>/dev/null || true
```

Expected: prints `[migrate] apply 000-initial` then `[migrate] done 000-initial`.

- [ ] **Step 7: Commit**

```bash
git add functions/migrations functions/test/migrations
git commit -m "feat(migrations): add idempotent runner and 000-initial baseline"
```

---

## Task 8: ESLint boundary rule (backend)

**Files:**
- Modify: `functions/.eslintrc.cjs`
- Test: `functions/test/lint/boundaries.test.ts`

Use `eslint-plugin-boundaries` to enforce:
1. `core/**` cannot import from `features/**`
2. `features/<A>/**` cannot import from `features/<B>/**`
3. (Within a feature, layering routes → service → repo is enforced by element types `routes`, `service`, `repo`. We add the elements now; concrete files appear in Phase 1+.)

- [ ] **Step 1: Install plugin**

```bash
cd functions && npm install --save-dev eslint-plugin-boundaries@^4.2.2 && cd ..
```

- [ ] **Step 2: Update `functions/.eslintrc.cjs`**

Replace the file with:

```js
module.exports = {
  root: true,
  env: { es2022: true, node: true },
  parser: "@typescript-eslint/parser",
  parserOptions: { ecmaVersion: 2022, sourceType: "module", project: ["tsconfig.json"] },
  plugins: ["@typescript-eslint", "import", "boundaries"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:boundaries/recommended",
    "google",
  ],
  ignorePatterns: ["lib/**", "node_modules/**", "scripts/**", "migrations/**", "test/**"],
  settings: {
    "boundaries/elements": [
      { type: "core",     pattern: "src/core/*",                   capture: ["domain"] },
      { type: "feature",  pattern: "src/features/*",               capture: ["feature"] },
      { type: "routes",   pattern: "src/features/*/routes.ts",     capture: ["feature"] },
      { type: "service",  pattern: "src/features/*/service.ts",    capture: ["feature"] },
      { type: "repo",     pattern: "src/features/*/repo.ts",       capture: ["feature"] },
      { type: "schemas",  pattern: "src/features/*/schemas.ts",    capture: ["feature"] },
      { type: "events",   pattern: "src/features/*/events.ts",     capture: ["feature"] },
      { type: "triggers", pattern: "src/features/*/triggers.ts",   capture: ["feature"] },
      { type: "module",   pattern: "src/features/*/module.ts",     capture: ["feature"] },
      { type: "api",      pattern: "src/api/*" },
    ],
  },
  rules: {
    "quotes": ["error", "double", { "avoidEscape": true }],
    "max-len": ["warn", { "code": 100 }],
    "@typescript-eslint/no-explicit-any": "off",
    "require-jsdoc": "off",
    "valid-jsdoc": "off",
    "boundaries/element-types": ["error", {
      "default": "allow",
      "rules": [
        // 1) core may not import any feature-internal element
        { "from": "core",
          "disallow": ["feature", "routes", "service", "repo", "schemas", "events", "triggers", "module"] },
        // 2) routes/service/repo flow direction
        { "from": "routes",  "disallow": ["repo"] },
        { "from": "schemas", "disallow": ["routes", "service", "repo"] },
        // 3) cross-feature imports forbidden — features only talk through core/events
        { "from": [["feature", { "feature": "${feature}" }]],
          "disallow": [["feature",  { "feature": "!${feature}" }],
                       ["routes",   { "feature": "!${feature}" }],
                       ["service",  { "feature": "!${feature}" }],
                       ["repo",     { "feature": "!${feature}" }],
                       ["schemas",  { "feature": "!${feature}" }],
                       ["events",   { "feature": "!${feature}" }],
                       ["triggers", { "feature": "!${feature}" }],
                       ["module",   { "feature": "!${feature}" }]] },
        { "from": [["routes",  { "feature": "${feature}" }]],
          "disallow": [["routes",  { "feature": "!${feature}" }],
                       ["service", { "feature": "!${feature}" }],
                       ["repo",    { "feature": "!${feature}" }]] },
        { "from": [["service", { "feature": "${feature}" }]],
          "disallow": [["service", { "feature": "!${feature}" }],
                       ["repo",    { "feature": "!${feature}" }]] }
      ]
    }],
    "boundaries/no-unknown": ["error"],
    "boundaries/no-unknown-files": "off",
    "boundaries/no-private": "off",
    "boundaries/entry-point": "off"
  }
};
```

- [ ] **Step 3: Write the failing boundary test**

Create `functions/test/lint/boundaries.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { ESLint } from "eslint";

const eslint = new ESLint({ overrideConfigFile: ".eslintrc.cjs", cwd: process.cwd() });

const fixtures: Array<{ name: string; filePath: string; code: string; mustError: RegExp }> = [
  {
    name: "core cannot import a feature module",
    filePath: "src/core/auth/bad.ts",
    code: `import { FEATURE_NAME } from "../../features/me/module";\nexport const x = FEATURE_NAME;\n`,
    mustError: /element-types|boundaries/,
  },
  {
    name: "feature cannot import another feature directly",
    filePath: "src/features/lists/bad.ts",
    code: `import { FEATURE_NAME } from "../me/module";\nexport const x = FEATURE_NAME;\n`,
    mustError: /element-types|boundaries/,
  },
];

describe("ESLint boundaries", () => {
  for (const f of fixtures) {
    it(f.name, async () => {
      const results = await eslint.lintText(f.code, { filePath: f.filePath });
      const messages = results.flatMap((r) => r.messages);
      expect(
        messages.some((m) => m.ruleId && /boundaries\//.test(m.ruleId))
      ).toBe(true);
    });
  }
});
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd functions && npm test -- test/lint/boundaries.test.ts
```

Expected: 2 tests pass.

- [ ] **Step 5: Verify the existing source still lints clean**

```bash
cd functions && npm run lint && cd ..
```

Expected: 0 errors.

- [ ] **Step 6: Commit**

```bash
git add functions/.eslintrc.cjs functions/test/lint/boundaries.test.ts functions/package.json functions/package-lock.json
git commit -m "feat(lint): enforce backend boundary rules (no cross-feature, no core->feature)"
```

---

## Task 9: Add Flutter dependencies and scaffold `lib/core/` + `lib/features/`

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/{api,auth,firestore,errors,logger,router,theme,ui,flags}/.gitkeep`
- Create: `lib/core/api/generated/.gitkeep`
- Create: `lib/features/{auth,me,households,lists,templates}/{data,domain,application,presentation}/.gitkeep`
- Create: `test/smoke_test.dart`

- [ ] **Step 1: Add deps to `pubspec.yaml`**

Append the following keys under the existing `dependencies:` block (preserving alphabetical order where it already is):

```yaml
  connectivity_plus: ^6.0.5
  flutter_riverpod: ^2.6.1
  freezed_annotation: ^2.4.4
  go_router: ^14.6.1
  json_annotation: ^4.9.0
  shared_preferences: ^2.3.3
```

And under `dev_dependencies:`:

```yaml
  build_runner: ^2.4.13
  custom_lint: ^0.7.0
  freezed: ^2.5.7
  import_lint: ^2.3.0
  json_serializable: ^6.8.0
  riverpod_lint: ^2.6.1
```

- [ ] **Step 2: Run `flutter pub get`**

```bash
flutter pub get
```

Expected: success (Flutter 3.35 / Dart 3.5+ — confirm with `flutter --version`).

- [ ] **Step 3: Create the empty `core/` + `features/` skeleton**

```bash
cd lib
for d in api auth firestore errors logger router theme ui flags api/generated; do
  mkdir -p "core/$d" && touch "core/$d/.gitkeep"
done
for f in auth me households lists templates; do
  for layer in data domain application presentation; do
    mkdir -p "features/$f/$layer" && touch "features/$f/$layer/.gitkeep"
  done
done
cd ..
```

- [ ] **Step 4: Add a Flutter smoke test that imports each new dep**

Create `test/smoke_test.dart`:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new dependencies are importable', () {
    expect(Connectivity, isNotNull);
    expect(ProviderContainer, isNotNull);
    expect(freezed, isNotNull);
    expect(GoRouter, isNotNull);
    expect(JsonSerializable, isNotNull);
    expect(SharedPreferences, isNotNull);
  });
}
```

- [ ] **Step 5: Run analyze + tests**

```bash
flutter analyze && flutter test test/smoke_test.dart
```

Expected: no analyzer errors; smoke test passes.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core lib/features test/smoke_test.dart
git commit -m "feat(flutter): add riverpod/freezed/go_router/connectivity/prefs deps + scaffold"
```

---

## Task 10: Flutter import boundaries with `import_lint`

**Files:**
- Create: `import_lint.yaml`

Enforce inside Flutter:
1. `lib/features/<X>/presentation/**` cannot import `lib/features/<X>/data/**`
2. `lib/features/<X>/application/**` cannot import `lib/features/<X>/presentation/**`
3. `lib/features/<X>/**` cannot import `lib/features/<Y>/**` (cross-feature direct import)

- [ ] **Step 1: Create `import_lint.yaml` at repo root**

```yaml
import_lint:
  common_rules: []
  rules:
    - name: presentation_does_not_import_data_auth
      target_file_path: 'lib/features/auth/presentation/**'
      not_allow_imports: ['package:fling/features/auth/data/**']
      ignore_imports: []
    - name: application_does_not_import_presentation_auth
      target_file_path: 'lib/features/auth/application/**'
      not_allow_imports: ['package:fling/features/auth/presentation/**']
      ignore_imports: []

    - name: presentation_does_not_import_data_me
      target_file_path: 'lib/features/me/presentation/**'
      not_allow_imports: ['package:fling/features/me/data/**']
      ignore_imports: []
    - name: application_does_not_import_presentation_me
      target_file_path: 'lib/features/me/application/**'
      not_allow_imports: ['package:fling/features/me/presentation/**']
      ignore_imports: []

    - name: presentation_does_not_import_data_households
      target_file_path: 'lib/features/households/presentation/**'
      not_allow_imports: ['package:fling/features/households/data/**']
      ignore_imports: []
    - name: application_does_not_import_presentation_households
      target_file_path: 'lib/features/households/application/**'
      not_allow_imports: ['package:fling/features/households/presentation/**']
      ignore_imports: []

    - name: presentation_does_not_import_data_lists
      target_file_path: 'lib/features/lists/presentation/**'
      not_allow_imports: ['package:fling/features/lists/data/**']
      ignore_imports: []
    - name: application_does_not_import_presentation_lists
      target_file_path: 'lib/features/lists/application/**'
      not_allow_imports: ['package:fling/features/lists/presentation/**']
      ignore_imports: []

    - name: presentation_does_not_import_data_templates
      target_file_path: 'lib/features/templates/presentation/**'
      not_allow_imports: ['package:fling/features/templates/data/**']
      ignore_imports: []
    - name: application_does_not_import_presentation_templates
      target_file_path: 'lib/features/templates/application/**'
      not_allow_imports: ['package:fling/features/templates/presentation/**']
      ignore_imports: []

    - name: features_dont_cross_import
      target_file_path: 'lib/features/auth/**'
      not_allow_imports:
        - 'package:fling/features/me/**'
        - 'package:fling/features/households/**'
        - 'package:fling/features/lists/**'
        - 'package:fling/features/templates/**'
      ignore_imports: []
    - name: features_dont_cross_import_me
      target_file_path: 'lib/features/me/**'
      not_allow_imports:
        - 'package:fling/features/auth/**'
        - 'package:fling/features/households/**'
        - 'package:fling/features/lists/**'
        - 'package:fling/features/templates/**'
      ignore_imports: []
    - name: features_dont_cross_import_households
      target_file_path: 'lib/features/households/**'
      not_allow_imports:
        - 'package:fling/features/auth/**'
        - 'package:fling/features/me/**'
        - 'package:fling/features/lists/**'
        - 'package:fling/features/templates/**'
      ignore_imports: []
    - name: features_dont_cross_import_lists
      target_file_path: 'lib/features/lists/**'
      not_allow_imports:
        - 'package:fling/features/auth/**'
        - 'package:fling/features/me/**'
        - 'package:fling/features/households/**'
        - 'package:fling/features/templates/**'
      ignore_imports: []
    - name: features_dont_cross_import_templates
      target_file_path: 'lib/features/templates/**'
      not_allow_imports:
        - 'package:fling/features/auth/**'
        - 'package:fling/features/me/**'
        - 'package:fling/features/households/**'
        - 'package:fling/features/lists/**'
      ignore_imports: []
```

- [ ] **Step 2: Add a CI hook script — `scripts/lint-flutter.sh`**

```bash
cat > scripts/lint-flutter.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
flutter analyze
dart run import_lint
EOF
chmod +x scripts/lint-flutter.sh
```

- [ ] **Step 3: Verify it runs**

```bash
./scripts/lint-flutter.sh
```

Expected: zero errors. (No source files exist yet under `lib/features/*` beyond `.gitkeep`, so no rules fire.)

- [ ] **Step 4: Add a deliberate-failure check (manual, not committed)**

```bash
# Touch a fake violating file, run import_lint, confirm failure, then delete.
mkdir -p lib/features/lists/presentation && cat > lib/features/lists/presentation/_probe.dart <<EOF
// ignore: unused_import
import 'package:fling/features/lists/data/_probe.dart';
EOF
mkdir -p lib/features/lists/data && cat > lib/features/lists/data/_probe.dart <<EOF
class Probe {}
EOF

dart run import_lint || echo "EXPECTED FAILURE — rules work"

rm -f lib/features/lists/presentation/_probe.dart lib/features/lists/data/_probe.dart
```

Expected: import_lint exits non-zero with a `presentation_does_not_import_data_lists` violation.

- [ ] **Step 5: Commit**

```bash
git add import_lint.yaml scripts/lint-flutter.sh
git commit -m "feat(lint): enforce flutter feature/layer boundaries via import_lint"
```

---

## Task 11: OpenAPI generation script + commit baseline

**Files:**
- Create: `functions/scripts/openapi.ts`
- Create: `openapi/openapi.json` (generated, committed)

- [ ] **Step 1: Create `functions/scripts/openapi.ts`**

```ts
import { writeFileSync, mkdirSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { app } from "../src/api/app";

const out = resolve(__dirname, "../../openapi/openapi.json");
mkdirSync(dirname(out), { recursive: true });

const doc = app.getOpenAPIDocument({
  openapi: "3.0.3",
  info: { title: "Fling API", version: "1.0.0" },
});

writeFileSync(out, JSON.stringify(doc, null, 2) + "\n");
console.log(`Wrote ${out}`);
```

- [ ] **Step 2: Generate the baseline spec**

```bash
cd functions && npm run openapi:generate && cd ..
```

Expected: writes `openapi/openapi.json` with one path (`/v1/healthz`) and the `Health` schema.

- [ ] **Step 3: Commit**

```bash
git add functions/scripts/openapi.ts openapi/openapi.json
git commit -m "feat(api): add openapi:generate script and commit baseline spec"
```

---

## Task 12: Dart client generation pipeline

**Files:**
- Create: `scripts/generate-dart-client.sh`
- Modify: `pubspec.yaml` (add `dio`, `built_value` runtime deps required by `dart-dio` template)
- Generated: `lib/core/api/generated/**` (committed)

- [ ] **Step 1: Add the runtime deps the `dart-dio` template needs**

Append under `dependencies:`:

```yaml
  built_collection: ^5.1.1
  built_value: ^8.9.2
  dio: ^5.7.0
  one_of: ^1.5.0
  one_of_serializer: ^1.5.0
```

And under `dev_dependencies:`:

```yaml
  built_value_generator: ^8.9.2
```

```bash
flutter pub get
```

- [ ] **Step 2: Create `scripts/generate-dart-client.sh`**

```bash
cat > scripts/generate-dart-client.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# 1) Regenerate openapi.json (source of truth lives in functions/src/api/app.ts).
( cd functions && npm run openapi:generate )

# 2) Generate Dart client into lib/core/api/generated/
OUT="lib/core/api/generated"
rm -rf "$OUT"
mkdir -p "$OUT"

npx --yes @openapitools/openapi-generator-cli@^2.13.5 generate \
  -i openapi/openapi.json \
  -g dart-dio \
  -o "$OUT" \
  --additional-properties=pubName=fling_api,pubAuthor=Fling,pubVersion=0.1.0,nullableFields=true,serializationLibrary=built_value

# 3) Build runner for built_value generated code.
( cd "$OUT" && flutter pub get && dart run build_runner build --delete-conflicting-outputs )
EOF
chmod +x scripts/generate-dart-client.sh
```

- [ ] **Step 3: Verify Java is available (openapi-generator-cli requires JRE 11+)**

```bash
java -version 2>&1 | head -1
```

Expected: prints a 11+ version. If absent: `brew install openjdk@21` and follow the brew note to symlink it into the system PATH.

- [ ] **Step 4: Run it**

```bash
./scripts/generate-dart-client.sh
```

Expected: `lib/core/api/generated/` is populated.

If this produces a large amount of generated code, that's expected — it's a real client package.

- [ ] **Step 5: Add the generated package to `lib/.gitattributes` for diff hygiene**

```bash
mkdir -p lib && cat > lib/core/api/generated/.gitattributes <<'EOF'
* linguist-generated=true
EOF
```

- [ ] **Step 6: Verify Flutter still analyses clean**

```bash
flutter analyze && flutter test test/smoke_test.dart
```

Expected: 0 errors.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock scripts/generate-dart-client.sh lib/core/api/generated
git commit -m "feat(api): generate Dart client (dart-dio) from OpenAPI; commit baseline"
```

---

## Task 13: Replace CI workflows with a unified `ci.yml`

**Files:**
- Create: `.github/workflows/ci.yml`
- Delete: `.github/workflows/build.yml`
- Delete: `.github/workflows/firebase-functions.yml`

Three jobs run in parallel on every PR: `backend`, `flutter`, `contracts`.

- [ ] **Step 1: Author `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push: { branches: [ main ] }
  pull_request:

permissions: read-all

jobs:
  backend:
    name: backend (lint + tsc + vitest)
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: functions } }
    steps:
      - uses: actions/checkout@v6.0.2
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm, cache-dependency-path: functions/package-lock.json }
      - run: npm ci --no-audit
      - run: npm run lint
      - run: npx tsc --noEmit
      - run: npm test
      # Integration + rules tests need the emulator. Use firebase-tools.
      - run: npm install -g firebase-tools@^13.29.0
      - run: |
          firebase emulators:exec --only firestore,auth \
            "npx vitest run test/rules test/api"

  flutter:
    name: flutter (analyze + test + import_lint)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6.0.2
      - uses: actions/setup-java@v5
        with: { distribution: 'zulu', java-version: '21' }
      - uses: subosito/flutter-action@v2
        with: { flutter-version-file: pubspec.yaml, cache: true }
      - run: flutter pub get
      - run: flutter analyze
      - run: dart run import_lint
      - run: flutter test

  contracts:
    name: contracts (openapi + dart client diff)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6.0.2
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm, cache-dependency-path: functions/package-lock.json }
      - uses: actions/setup-java@v5
        with: { distribution: 'zulu', java-version: '21' }
      - uses: subosito/flutter-action@v2
        with: { flutter-version-file: pubspec.yaml, cache: true }
      - run: npm ci --no-audit
        working-directory: functions
      - run: ./scripts/generate-dart-client.sh
      - name: Fail if generated artefacts drifted
        run: |
          git diff --exit-code -- openapi/openapi.json lib/core/api/generated \
            || (echo "::error::OpenAPI / Dart client out of date. Run scripts/generate-dart-client.sh and commit." && exit 1)
```

- [ ] **Step 2: Delete the superseded workflows**

```bash
git rm .github/workflows/build.yml .github/workflows/firebase-functions.yml
```

- [ ] **Step 3: Confirm no other workflow references the deleted files**

```bash
grep -r "build.yml\|firebase-functions.yml" .github 2>/dev/null || echo "OK"
```

Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: unified ci.yml with backend, flutter, contracts jobs"
```

---

## Task 14: Deploy the empty `api` function (verify "no user-visible change")

**Files:** none modified.

This is a verification step, not a code change. It is the only thing that changes production state in Phase 0 — and the change is purely additive (a new `api` function with one healthz route).

- [ ] **Step 1: Build & lint locally**

```bash
( cd functions && npm run lint && npm run build )
flutter analyze
```

Expected: clean.

- [ ] **Step 2: Push branch and open PR against `main`**

```bash
git push -u origin phase-0-foundation
gh pr create --title "Phase 0 — Foundation" --body "$(cat <<'EOF'
## Summary

Phase 0 of the rewrite (see `docs/superpowers/specs/2026-04-24-fling-rewrite-design.md`).
All scaffolding — no user-visible change.

- firestore.rules committed (mirrors current behaviour)
- Hono + zod-openapi + Vitest installed; empty `api` function with `/v1/healthz`
- Flutter deps: riverpod, freezed, go_router, connectivity_plus, shared_preferences (+ build_runner / generators)
- core/ + features/ scaffolded backend + flutter
- ESLint boundary rule + Dart import_lint enforce no cross-feature, no presentation→data, no application→presentation
- Migrations runner + 000-initial baseline
- CI rebuilt: parallel backend / flutter / contracts jobs
- OpenAPI → Dart client pipeline working end-to-end (Dart client generated and committed)

## Test plan

- [ ] CI green (all three jobs)
- [ ] After merge: `firebase deploy --only functions` succeeds
- [ ] `curl https://us-central1-fling-list.cloudfunctions.net/api/v1/healthz` returns `{"status":"ok",...}`
- [ ] Flutter app on prod still works exactly as before (smoke: login, create list, add item, mark checked, delete; create template; invite by email)
EOF
)"
```

- [ ] **Step 3: After PR merges to main, observe the auto-deploy (or trigger manual)**

CI handles deploy via the existing release flow. If a manual nudge is needed:

```bash
firebase use default
firebase deploy --only functions:api,firestore
```

Expected: `api` function listed in `firebase functions:list`; `firestore.rules` updated.

- [ ] **Step 4: Production smoke test**

```bash
curl -fsS "https://us-central1-fling-list.cloudfunctions.net/api/v1/healthz"
echo
```

Expected: `{"status":"ok","version":"<revision>"}`.

- [ ] **Step 5: User-visible regression check**

Manually exercise the production Flutter app (web build): login, view lists, add an item, check it off, apply a template, invite a member by email. None of these flows touch the new `api` function — they all still go to v1 callables / direct Firestore. Confirm zero regressions.

---

## Task 15: Close the phase — update STATUS and change log

**Files:**
- Modify: `docs/superpowers/migrations/STATUS.md`

- [ ] **Step 1: In `STATUS.md`, flip Phase 0 to ✅ and link this plan**

In the Overview table change Phase 0 row from:

```text
| 0 | Foundation | All scaffolding (CI, deps, lint boundaries, empty Hono app, emulator, migrations runner). No user-visible change. | ⬜ | _not yet written_ | — | — |
```

to:

```text
| 0 | Foundation | All scaffolding (CI, deps, lint boundaries, empty Hono app, emulator, migrations runner). No user-visible change. | ✅ | [phase-0-foundation.md](./phase-0-foundation.md) | YYYY-MM-DD | YYYY-MM-DD |
```

- [ ] **Step 2: Tick every box in §"Phase 0 — Foundation" exit criteria**

Replace each `- [ ]` with `- [x]` for the nine bullets under that heading.

- [ ] **Step 3: Append change-log entries**

```text
| YYYY-MM-DD | 0 | Started     | <PR-URL> | Phase 0 plan published       |
| YYYY-MM-DD | 0 | Completed   | <PR-URL> | All scaffolding landed       |
```

- [ ] **Step 4: Update "Last updated"**

Change to today's date.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/migrations/STATUS.md
git commit -m "docs(rewrite): close Phase 0 (Foundation)"
```

- [ ] **Step 6: Clean up the worktree**

```bash
cd /Users/garrit/src/garritfra/fling
git worktree remove .worktrees/phase-0-foundation
git branch -D phase-0-foundation     # optional, keep if you want history reachable from a tag
```

---

## Self-review checklist

- [ ] Every spec exit criterion in STATUS §"Phase 0 — Foundation" maps to at least one task above
- [ ] Each task has runnable code blocks (no placeholders, no "implement X here")
- [ ] All imports / type names in later tasks match definitions in earlier tasks (e.g. `Migration` shape used in tests matches `runner.ts` exports)
- [ ] Each commit step shows the exact files staged
- [ ] No deletion of v1 callables until later phases (per spec §10)
