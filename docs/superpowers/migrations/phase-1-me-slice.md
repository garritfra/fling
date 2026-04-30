# Phase 1 — `me` slice + API foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the first end-to-end vertical slice. Backend grows `core/api/` middleware (auth, idempotency, request_id, structured logging, error mapping) and a complete `features/me/` (HTTP `GET`/`PATCH /v1/me`, v2-organised auth triggers, repo). Flutter grows `core/api/` (auth-aware client + persistent mutation queue with optimistic-update overlay) and `features/me/` (vertical slice replacing `lib/data/user.dart`). Migration #1 lands the additive user-doc shape, the legacy `cacheJoinHousehold`/`cacheLeaveHousehold` triggers are patched to dual-write the new field name, and `/users/{uid}` is tightened to owner-only **read**.

**Architecture:** Three thin slices that each ship independently.
- **Slice 1** ships `GET /v1/me` end-to-end (middleware + handler + Dart client + Flutter feature/me read path) without changing storage or replacing legacy code.
- **Slice 2** ships `PATCH /v1/me` end-to-end, the full `core/api/mutation_queue.dart` (in-memory + persistent + drain on reconnect + idempotency keys), and the Flutter consumers that switch from direct Firestore writes to the API.
- **Slice 3** swaps in v2 auth triggers (organised under `features/me/triggers.ts`), runs Migration #1 (additive backfill), patches the legacy v1 triggers to dual-write `household_ids`, deletes `lib/data/user.dart`, and tightens the security rule.

Each slice = one PR = one production deploy. The legacy `cacheJoinHousehold`/`cacheLeaveHousehold` callable triggers stay alive (Phase 2 replaces them) but now write both the legacy `households` field and the new `household_ids` field — a surgical bridge that disappears in Phase 2.

**Tech Stack:** Hono + `@hono/zod-openapi`, Firestore Admin SDK, Vitest + `@firebase/rules-unit-testing`, Flutter + `flutter_riverpod` + `freezed` + `dio` (generated), `connectivity_plus`, `shared_preferences`.

**Spec:** [`docs/superpowers/specs/2026-04-24-fling-rewrite-design.md`](../specs/2026-04-24-fling-rewrite-design.md)

**STATUS tracker:** [`docs/superpowers/migrations/STATUS.md`](./STATUS.md)

**Decisions captured during planning** (see Phase 1 brainstorm):

1. **Cross-phase field bridge:** Patch the existing v1 `cacheJoinHousehold` / `cacheLeaveHousehold` triggers to dual-write both `households` and `household_ids` until Phase 2 deletes them.
2. **`PATCH /v1/me` body:** Accept `currentHouseholdId?` **and** `displayName?` (avoids a churn PR later).
3. **`mutation_queue.dart` scope:** Full implementation in Phase 1 (in-memory queue + `shared_preferences` persistence + `connectivity_plus` drain + idempotency-key generation). Phase 3 consumes it without further changes.
4. **Task ordering:** Thin-slice end-to-end. Each of the three slices ships independently.

**Trigger SDK note:** Firebase Functions v2 has no direct `auth.user().onCreate/onDelete` equivalent without Identity Platform blocking triggers. We keep using `firebase-functions/v1`'s `auth.user()` API for the lifecycle triggers but organise them under `features/me/triggers.ts`. Firestore triggers remain on v2 (`firebase-functions/v2/firestore`).

---

## Exit criteria (mirrors STATUS §"Phase 1 — `me` slice + API foundation")

- [ ] `core/api/` middleware: auth, idempotency, request_id, structured logging, error mapping
- [ ] OpenAPI generation → Dart client pipeline working end-to-end (verified by real `me` schemas, not just `Health`)
- [ ] `core/api/mutation_queue.dart` implemented with optimistic-update overlay
- [ ] Backend `features/me/` complete: `GET /v1/me`, `PATCH /v1/me` (full data export and cascading delete ship in Phase 5)
- [ ] Flutter `features/me/` migrated to vertical slice; old `FlingUser` deleted
- [ ] `setupUser` / `deleteUser` v1 functions replaced by v2 triggers in `features/me/triggers.ts` (deletion behaviour matches today: delete user doc only; cascade lands in Phase 5)
- [ ] Migration #1 deployed: user docs gain `email`, `display_name`, `household_ids`, `current_household_id`, audit fields, `schema_version: 1`
- [ ] Rule tightened: `/users/{uid}` is owner-only read

## File map

Created:

```text
functions/src/core/context/request_context.ts
functions/src/core/logger/logger.ts
functions/src/core/errors/app_error.ts
functions/src/core/errors/handler.ts
functions/src/core/middleware/request_id.ts
functions/src/core/middleware/auth.ts
functions/src/core/middleware/idempotency.ts
functions/src/core/idempotency/repo.ts
functions/src/features/me/schemas.ts
functions/src/features/me/repo.ts
functions/src/features/me/service.ts
functions/src/features/me/routes.ts
functions/src/features/me/triggers.ts
functions/src/features/me/events.ts                # placeholder; populated in Phase 5
functions/migrations/001-user-shape.ts
functions/test/core/middleware/request_id.test.ts
functions/test/core/middleware/auth.test.ts
functions/test/core/middleware/idempotency.test.ts
functions/test/core/errors/handler.test.ts
functions/test/features/me/routes.test.ts
functions/test/features/me/triggers.test.ts
functions/test/features/me/service.test.ts
functions/test/migrations/001-user-shape.test.ts
lib/core/api/api_client.dart
lib/core/api/mutation_queue.dart
lib/core/api/idempotency_key.dart
lib/features/me/domain/me.dart
lib/features/me/domain/me.freezed.dart            # generated
lib/features/me/domain/me.g.dart                  # generated
lib/features/me/data/me_repository.dart
lib/features/me/application/me_providers.dart
lib/features/me/presentation/.gitkeep             # already in repo from Phase 0
test/core/api/mutation_queue_test.dart
test/features/me/me_repository_test.dart
test/features/me/me_providers_test.dart
```

Modified:

```text
functions/src/api/app.ts                          # mount middleware + features/me routes
functions/src/index.ts                            # export v2 me triggers; patch legacy triggers; remove v1 setupUser/deleteUser
firestore.rules                                   # tighten /users/{uid} to owner-only read (final task of Slice 3)
firestore.indexes.json                            # add idempotency_keys TTL field config note
lib/main.dart                                     # wrap app in ProviderScope; bootstrap auth interceptor
lib/pages/lists.dart                              # consume me providers instead of FlingUser
lib/pages/templates.dart                          # consume me providers instead of FlingUser
lib/pages/household_add.dart                      # consume me providers instead of FlingUser
lib/pages/home.dart                               # consume me providers instead of FlingUser
lib/pages/list.dart                               # consume me providers instead of FlingUser
lib/pages/template.dart                           # consume me providers instead of FlingUser
lib/layout/drawer.dart                            # use deleteAccount provider
lib/data/household.dart                           # read currentHouseholdId from me providers
docs/superpowers/migrations/STATUS.md             # mark Phase 1 in progress, then complete
```

Deleted at end of phase:

```text
lib/data/user.dart                                # FlingUser replaced by features/me/
```

---

## Task 0: Set up Phase 1 worktree

**Files:**
- None modified inside repo; sets up an isolated working tree

- [ ] **Step 1: Verify clean baseline on `main`**

```bash
cd /Users/garrit/src/garritfra/fling
git fetch origin
git switch main && git pull --ff-only
git status
```

Expected: `nothing to commit, working tree clean`. Phase 0 commit visible in `git log -1`.

- [ ] **Step 2: Create the worktree on a new branch**

```bash
git worktree add .worktrees/phase-1-me-slice -b phase-1-me-slice main
cd .worktrees/phase-1-me-slice
```

Expected: branch `phase-1-me-slice` checked out at `.worktrees/phase-1-me-slice`.

- [ ] **Step 3: Verify baseline tooling works in the worktree**

```bash
( cd functions && npm ci --no-audit && npm run lint && npm run build && npm test )
flutter pub get && flutter analyze && flutter test test/smoke_test.dart
```

Expected: all green.

- [ ] **Step 4: Flip STATUS Phase 1 to In Progress**

In `docs/superpowers/migrations/STATUS.md` change the Phase 1 row in the Overview table from:

```text
| 1 | `me` slice + API foundation | First end-to-end vertical slice. Replaces `setupUser` / `deleteUser`. | ⬜ | _not yet written_ | — | — |
```

to:

```text
| 1 | `me` slice + API foundation | First end-to-end vertical slice. Replaces `setupUser` / `deleteUser`. | 🟡 | [phase-1-me-slice.md](./phase-1-me-slice.md) | YYYY-MM-DD | — |
```

Update **Last updated** to today. Append change-log entry:

```text
| YYYY-MM-DD | 1 | Started | — | Phase 1 plan published (`phase-1-me-slice.md`) |
```

```bash
git add docs/superpowers/migrations/STATUS.md docs/superpowers/migrations/phase-1-me-slice.md
git commit -m "docs(rewrite): start Phase 1 (me slice + API foundation)"
```

---

# SLICE 1 — `GET /v1/me` end-to-end

Goal: a real schema'd endpoint, the auth + request_id + structured logger + error-mapping stack, the OpenAPI → Dart client extension working for non-trivial schemas, and a Flutter `features/me/` that streams the user doc through Riverpod. Storage shape is unchanged; legacy `FlingUser` still exists in parallel.

## Task 1: Backend — `RequestContext` + structured logger

**Files:**
- Create: `functions/src/core/context/request_context.ts`
- Create: `functions/src/core/logger/logger.ts`
- Modify: `functions/src/core/context/index.ts`
- Modify: `functions/src/core/logger/index.ts`
- Test: included with Task 2 (these are pure types/utilities consumed there)

`RequestContext` is the per-request bag threaded through services: `{ uid, email, requestId, householdId? }`. It is set by middleware on the Hono context; services receive it as the first argument.

- [ ] **Step 1: Write `RequestContext`**

Replace `functions/src/core/context/index.ts` with:

```ts
export {RequestContext, getRequestContext} from "./request_context";
```

Create `functions/src/core/context/request_context.ts`:

```ts
import type {Context} from "hono";

export interface RequestContext {
  uid: string;
  email?: string;
  requestId: string;
  householdId?: string;
}

const KEY = "__fling_request_context";

export function setRequestContext(c: Context, ctx: RequestContext): void {
  c.set(KEY, ctx);
}

export function getRequestContext(c: Context): RequestContext {
  const ctx = c.get(KEY) as RequestContext | undefined;
  if (!ctx) throw new Error("RequestContext missing — middleware not mounted");
  return ctx;
}
```

- [ ] **Step 2: Write the structured logger**

Replace `functions/src/core/logger/index.ts` with:

```ts
export {logger, withRequestContext} from "./logger";
export type {Logger} from "./logger";
```

Create `functions/src/core/logger/logger.ts`:

```ts
import type {RequestContext} from "../context/request_context";

export interface Logger {
  info(msg: string, fields?: Record<string, unknown>): void;
  warn(msg: string, fields?: Record<string, unknown>): void;
  error(msg: string, fields?: Record<string, unknown>): void;
}

function emit(level: "INFO" | "WARN" | "ERROR", msg: string, fields?: Record<string, unknown>): void {
  const line = JSON.stringify({severity: level, message: msg, ...fields});
  if (level === "ERROR") console.error(line);
  else if (level === "WARN") console.warn(line);
  else console.log(line);
}

export const logger: Logger = {
  info: (m, f) => emit("INFO", m, f),
  warn: (m, f) => emit("WARN", m, f),
  error: (m, f) => emit("ERROR", m, f),
};

export function withRequestContext(ctx: RequestContext): Logger {
  const base = {request_id: ctx.requestId, uid: ctx.uid};
  return {
    info: (m, f) => emit("INFO", m, {...base, ...f}),
    warn: (m, f) => emit("WARN", m, {...base, ...f}),
    error: (m, f) => emit("ERROR", m, {...base, ...f}),
  };
}
```

- [ ] **Step 3: Verify it compiles**

```bash
cd functions && npm run build && cd ..
```

Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add functions/src/core/context functions/src/core/logger
git commit -m "feat(core): add RequestContext + structured logger"
```

---

## Task 2: Backend — `AppError` hierarchy + error handler middleware

**Files:**
- Create: `functions/src/core/errors/app_error.ts`
- Create: `functions/src/core/errors/handler.ts`
- Modify: `functions/src/core/errors/index.ts`
- Test: `functions/test/core/errors/handler.test.ts`

The error response shape is fixed by spec §5.3: `{ error: { code, message, details? } }`. We model errors as a single sealed `AppError` class with subclasses; the handler maps unknown errors to `INTERNAL`.

- [ ] **Step 1: Write the failing test**

Create `functions/test/core/errors/handler.test.ts`:

```ts
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
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd functions && npm test -- test/core/errors/handler.test.ts
```

Expected: fails with `Cannot find module '.../app_error'`.

- [ ] **Step 3: Write `AppError`**

Create `functions/src/core/errors/app_error.ts`:

```ts
export class AppError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly status: number,
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "AppError";
  }
}

export class BadRequest extends AppError {
  constructor(message = "Bad request", details?: Record<string, unknown>) {
    super("BAD_REQUEST", message, 400, details);
  }
}

export class Unauthorized extends AppError {
  constructor(message = "Unauthorized") {
    super("UNAUTHORIZED", message, 401);
  }
}

export class Forbidden extends AppError {
  constructor(message = "Forbidden") {
    super("FORBIDDEN", message, 403);
  }
}

export class NotFound extends AppError {
  constructor(message = "Not found") {
    super("NOT_FOUND", message, 404);
  }
}

export class Conflict extends AppError {
  constructor(message = "Conflict", details?: Record<string, unknown>) {
    super("CONFLICT", message, 409, details);
  }
}
```

- [ ] **Step 4: Write the handler**

Create `functions/src/core/errors/handler.ts`:

```ts
import type {Hono} from "hono";
import type {OpenAPIHono} from "@hono/zod-openapi";
import {ZodError} from "zod";
import {AppError, BadRequest} from "./app_error";
import {logger} from "../logger";

export function installErrorHandler(app: Hono | OpenAPIHono): void {
  app.onError((err, c) => {
    if (err instanceof ZodError) {
      const wrapped = new BadRequest("Validation failed", {issues: err.issues});
      return c.json({error: {code: wrapped.code, message: wrapped.message, details: wrapped.details}}, 400);
    }
    if (err instanceof AppError) {
      const body: {error: {code: string; message: string; details?: Record<string, unknown>}} = {
        error: {code: err.code, message: err.message},
      };
      if (err.details) body.error.details = err.details;
      return c.json(body, err.status as 400 | 401 | 403 | 404 | 409 | 418);
    }
    logger.error("Unhandled error", {message: err.message, stack: err.stack});
    return c.json({error: {code: "INTERNAL", message: "Internal server error"}}, 500);
  });
}
```

- [ ] **Step 5: Re-export from the index barrel**

Replace `functions/src/core/errors/index.ts` with:

```ts
export * from "./app_error";
export {installErrorHandler} from "./handler";
```

- [ ] **Step 6: Run the test to verify it passes**

```bash
cd functions && npm test -- test/core/errors/handler.test.ts
```

Expected: 7 tests pass.

- [ ] **Step 7: Commit**

```bash
git add functions/src/core/errors functions/test/core/errors
git commit -m "feat(core): add AppError hierarchy + Hono error handler"
```

---

## Task 3: Backend — `requestId` middleware

**Files:**
- Create: `functions/src/core/middleware/request_id.ts`
- Modify: `functions/src/core/middleware/index.ts`
- Test: `functions/test/core/middleware/request_id.test.ts`

Spec §5.3.1: generate or accept `X-Request-Id`; stamp it on the response and attach to `RequestContext`.

- [ ] **Step 1: Write the failing test**

Create `functions/test/core/middleware/request_id.test.ts`:

```ts
import {describe, it, expect} from "vitest";
import {Hono} from "hono";
import {requestIdMiddleware} from "../../../src/core/middleware/request_id";

function appWithRid(): Hono {
  const app = new Hono();
  app.use("*", requestIdMiddleware());
  app.get("/echo", (c) => c.json({rid: c.get("requestId")}));
  return app;
}

describe("requestId middleware", () => {
  it("generates a UUID-shaped id when X-Request-Id is absent", async () => {
    const app = appWithRid();
    const res = await app.request("/echo");
    const body = await res.json();
    expect(body.rid).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
    expect(res.headers.get("x-request-id")).toBe(body.rid);
  });

  it("honours an incoming X-Request-Id", async () => {
    const app = appWithRid();
    const res = await app.request("/echo", {headers: {"X-Request-Id": "client-abc-123"}});
    const body = await res.json();
    expect(body.rid).toBe("client-abc-123");
    expect(res.headers.get("x-request-id")).toBe("client-abc-123");
  });

  it("rejects an X-Request-Id longer than 128 chars and generates a fresh one", async () => {
    const app = appWithRid();
    const long = "a".repeat(200);
    const res = await app.request("/echo", {headers: {"X-Request-Id": long}});
    const body = await res.json();
    expect(body.rid).not.toBe(long);
    expect(body.rid).toMatch(/^[0-9a-f-]{36}$/);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd functions && npm test -- test/core/middleware/request_id.test.ts
```

Expected: fails with `Cannot find module`.

- [ ] **Step 3: Implement the middleware**

Create `functions/src/core/middleware/request_id.ts`:

```ts
import type {MiddlewareHandler} from "hono";
import {randomUUID} from "node:crypto";

const MAX_INCOMING_LEN = 128;
const SAFE_RID = /^[A-Za-z0-9._\-:]+$/;

export function requestIdMiddleware(): MiddlewareHandler {
  return async (c, next) => {
    const incoming = c.req.header("x-request-id");
    const rid = incoming && incoming.length <= MAX_INCOMING_LEN && SAFE_RID.test(incoming)
      ? incoming
      : randomUUID();
    c.set("requestId", rid);
    c.header("x-request-id", rid);
    await next();
  };
}
```

- [ ] **Step 4: Update the barrel**

Replace `functions/src/core/middleware/index.ts` with:

```ts
export {requestIdMiddleware} from "./request_id";
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd functions && npm test -- test/core/middleware/request_id.test.ts
```

Expected: 3 tests pass.

- [ ] **Step 6: Commit**

```bash
git add functions/src/core/middleware/request_id.ts functions/src/core/middleware/index.ts functions/test/core/middleware/request_id.test.ts
git commit -m "feat(core): add requestId middleware"
```

---

## Task 4: Backend — `auth` middleware (Firebase ID token verification)

**Files:**
- Create: `functions/src/core/middleware/auth.ts`
- Modify: `functions/src/core/middleware/index.ts`
- Modify: `functions/src/core/auth/index.ts`
- Test: `functions/test/core/middleware/auth.test.ts`

The auth middleware verifies the Firebase ID token from `Authorization: Bearer <token>`, rejects with `401` on missing/invalid, and writes `RequestContext { uid, email?, requestId }` to the context.

- [ ] **Step 1: Write the failing test (uses the Auth emulator)**

Create `functions/test/core/middleware/auth.test.ts`:

```ts
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
  const user = await auth.createUser({email: "alice@example.com"});
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
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
firebase emulators:exec --only firestore,auth \
  "cd functions && npx vitest run test/core/middleware/auth.test.ts"
```

Expected: fails with `Cannot find module 'auth'`.

- [ ] **Step 3: Implement the middleware**

Create `functions/src/core/middleware/auth.ts`:

```ts
import type {MiddlewareHandler} from "hono";
import {Unauthorized} from "../errors/app_error";
import {setRequestContext} from "../context/request_context";
import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";

function ensureAdmin() {
  if (getApps().length === 0) initializeApp();
}

export function authMiddleware(): MiddlewareHandler {
  return async (c, next) => {
    ensureAdmin();
    const header = c.req.header("authorization") ?? "";
    const m = /^Bearer\s+(.+)$/.exec(header);
    if (!m) throw new Unauthorized("Missing or malformed Authorization header");
    let decoded;
    try {
      decoded = await getAuth().verifyIdToken(m[1]);
    } catch {
      throw new Unauthorized("Invalid token");
    }
    const requestId = (c.get("requestId") as string | undefined) ?? "";
    setRequestContext(c, {uid: decoded.uid, email: decoded.email, requestId});
    await next();
  };
}
```

- [ ] **Step 4: Update barrels**

Update `functions/src/core/middleware/index.ts`:

```ts
export {requestIdMiddleware} from "./request_id";
export {authMiddleware} from "./auth";
```

Update `functions/src/core/auth/index.ts`:

```ts
export {authMiddleware} from "../middleware/auth";
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
firebase emulators:exec --only firestore,auth \
  "cd functions && npx vitest run test/core/middleware/auth.test.ts"
```

Expected: 3 tests pass.

- [ ] **Step 6: Commit**

```bash
git add functions/src/core/middleware/auth.ts functions/src/core/middleware/index.ts functions/src/core/auth/index.ts functions/test/core/middleware/auth.test.ts
git commit -m "feat(core): add auth middleware (Firebase ID token verification)"
```

---

## Task 5: Backend — `features/me` schemas + repo + service + GET route

**Files:**
- Create: `functions/src/features/me/schemas.ts`
- Create: `functions/src/features/me/repo.ts`
- Create: `functions/src/features/me/service.ts`
- Create: `functions/src/features/me/routes.ts`
- Create: `functions/src/features/me/events.ts`
- Modify: `functions/src/features/me/module.ts`
- Test: `functions/test/features/me/service.test.ts`
- Test: `functions/test/features/me/routes.test.ts`

The `me` slice is a thin adapter over the user doc. The repo reads the doc; the service applies any defaults; the route validates, calls service, returns JSON.

- [ ] **Step 1: Write the schemas**

Create `functions/src/features/me/schemas.ts`:

```ts
import {z} from "@hono/zod-openapi";

export const MeSchema = z.object({
  uid: z.string(),
  email: z.string().email().nullable(),
  displayName: z.string().nullable(),
  householdIds: z.array(z.string()),
  currentHouseholdId: z.string().nullable(),
}).openapi("Me");

export const PatchMeSchema = z.object({
  currentHouseholdId: z.string().min(1).max(128).optional(),
  displayName: z.string().min(1).max(128).optional(),
}).strict().openapi("PatchMe");

export type Me = z.infer<typeof MeSchema>;
export type PatchMe = z.infer<typeof PatchMeSchema>;
```

- [ ] **Step 2: Write the repo**

Create `functions/src/features/me/repo.ts`:

```ts
import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import type {Me} from "./schemas";

function db() {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}

interface RawUserDoc {
  email?: string;
  display_name?: string;
  household_ids?: string[];
  current_household_id?: string;
  // legacy field names — read for backwards compatibility until Phase 6
  households?: string[];
  current_household?: string;
}

export async function readUserDoc(uid: string): Promise<Me | null> {
  const snap = await db().collection("users").doc(uid).get();
  if (!snap.exists) return null;
  const raw = snap.data() as RawUserDoc;
  return {
    uid,
    email: raw.email ?? null,
    displayName: raw.display_name ?? null,
    householdIds: raw.household_ids ?? raw.households ?? [],
    currentHouseholdId: raw.current_household_id ?? raw.current_household ?? null,
  };
}

export async function patchUserDoc(uid: string, patch: {
  currentHouseholdId?: string;
  displayName?: string;
}): Promise<void> {
  const update: Record<string, unknown> = {
    updated_at: FieldValue.serverTimestamp(),
  };
  if (patch.currentHouseholdId !== undefined) {
    update.current_household_id = patch.currentHouseholdId;
    // Dual-write the legacy field while Flutter clients still read it.
    update.current_household = patch.currentHouseholdId;
  }
  if (patch.displayName !== undefined) {
    update.display_name = patch.displayName;
  }
  await db().collection("users").doc(uid).set(update, {merge: true});
}

export async function createUserDoc(uid: string, email: string | null): Promise<void> {
  await db().collection("users").doc(uid).set({
    email: email ?? null,
    display_name: null,
    household_ids: [],
    current_household_id: null,
    households: [],            // legacy, dual-write
    current_household: null,   // legacy, dual-write
    schema_version: 1,
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
    created_by_uid: uid,
  }, {merge: true});
}

export async function deleteUserDoc(uid: string): Promise<void> {
  await db().collection("users").doc(uid).delete();
}
```

- [ ] **Step 3: Write the service**

Create `functions/src/features/me/service.ts`:

```ts
import type {RequestContext} from "../../core/context/request_context";
import {NotFound} from "../../core/errors/app_error";
import type {Me, PatchMe} from "./schemas";
import * as repo from "./repo";

export async function getMe(ctx: RequestContext): Promise<Me> {
  const me = await repo.readUserDoc(ctx.uid);
  if (!me) throw new NotFound("User document not provisioned yet");
  // Auth-token email always wins over the persisted denormalised value.
  return {...me, email: ctx.email ?? me.email};
}

export async function patchMe(ctx: RequestContext, patch: PatchMe): Promise<Me> {
  await repo.patchUserDoc(ctx.uid, patch);
  return getMe(ctx);
}

export async function createUser(uid: string, email: string | null): Promise<void> {
  await repo.createUserDoc(uid, email);
}

export async function deleteUser(uid: string): Promise<void> {
  // Phase 1: delete the user doc only. Phase 5 upgrades this to cascade.
  await repo.deleteUserDoc(uid);
}
```

- [ ] **Step 4: Write the GET route**

Create `functions/src/features/me/routes.ts`:

```ts
import {OpenAPIHono, createRoute} from "@hono/zod-openapi";
import {MeSchema, PatchMeSchema} from "./schemas";
import {getRequestContext} from "../../core/context/request_context";
import * as service from "./service";

const errorBody = {
  "application/json": {
    schema: PatchMeSchema, // placeholder; replaced below
  },
};

const getMeRoute = createRoute({
  method: "get",
  path: "/v1/me",
  tags: ["me"],
  responses: {
    200: {description: "The caller", content: {"application/json": {schema: MeSchema}}},
  },
});

const patchMeRoute = createRoute({
  method: "patch",
  path: "/v1/me",
  tags: ["me"],
  request: {body: {required: true, content: {"application/json": {schema: PatchMeSchema}}}},
  responses: {
    200: {description: "Updated", content: {"application/json": {schema: MeSchema}}},
  },
});

export function registerMeRoutes(app: OpenAPIHono): void {
  app.openapi(getMeRoute, async (c) => {
    const me = await service.getMe(getRequestContext(c));
    return c.json(me, 200);
  });

  app.openapi(patchMeRoute, async (c) => {
    const patch = c.req.valid("json");
    const me = await service.patchMe(getRequestContext(c), patch);
    return c.json(me, 200);
  });
}

// Mark `errorBody` as used to keep the import section honest.
void errorBody;
```

- [ ] **Step 5: Stub events module (populated in Phase 5)**

Create `functions/src/features/me/events.ts`:

```ts
// features/me/events: populated in Phase 5 (events bus).
// Domain events emitted: `me.created.v1`, `me.deleted.v1`, `me.updated.v1`.
export {};
```

- [ ] **Step 6: Update the module placeholder**

Replace `functions/src/features/me/module.ts` with:

```ts
export const FEATURE_NAME = "me" as const;
export {registerMeRoutes} from "./routes";
```

- [ ] **Step 7: Write the failing service test**

Create `functions/test/features/me/service.test.ts`:

```ts
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
```

- [ ] **Step 8: Write the failing route test**

Create `functions/test/features/me/routes.test.ts`:

```ts
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

async function exchangeCustomTokenForId(customToken: string): Promise<string> {
  const r = await fetch(
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`,
    {method: "POST", body: JSON.stringify({token: customToken, returnSecureToken: true}), headers: {"Content-Type": "application/json"}},
  );
  return ((await r.json()) as {idToken: string}).idToken;
}

beforeAll(async () => {
  firebaseApp = getApps()[0] ?? initializeApp({projectId: "fling-rules-test"});
  const u = await getAuth().createUser({email: "alice@example.com"});
  aliceToken = await exchangeCustomTokenForId(await getAuth().createCustomToken(u.uid));
  await service.createUser(u.uid, "alice@example.com");
});

beforeEach(async () => {
  const db = getFirestore();
  const users = await db.collection("users").listDocuments();
  await Promise.all(users.map((d) => d.delete()));
  // Re-seed alice (token uid is stable across tests).
  const decoded = await getAuth().verifyIdToken(aliceToken);
  await service.createUser(decoded.uid, "alice@example.com");
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
```

- [ ] **Step 9: Mount the routes in the API app**

Edit `functions/src/api/app.ts` to add middleware + me routes. Replace the file with:

```ts
import {OpenAPIHono, createRoute, z} from "@hono/zod-openapi";
import {requestIdMiddleware, authMiddleware} from "../core/middleware";
import {installErrorHandler} from "../core/errors";
import {registerMeRoutes} from "../features/me/module";

const HealthSchema = z.object({
  status: z.literal("ok"),
  version: z.string(),
}).openapi("Health");

const healthzRoute = createRoute({
  method: "get",
  path: "/v1/healthz",
  responses: {
    200: {description: "Health check", content: {"application/json": {schema: HealthSchema}}},
  },
});

export const app = new OpenAPIHono();

installErrorHandler(app);
app.use("*", requestIdMiddleware());

// Public endpoints (no auth) come before the auth middleware mount.
app.openapi(healthzRoute, (c) =>
  c.json({status: "ok" as const, version: process.env.K_REVISION ?? "dev"}),
);

// Authenticated /v1/* routes.
app.use("/v1/*", authMiddleware());
registerMeRoutes(app);

app.doc("/v1/openapi.json", {
  openapi: "3.0.3",
  info: {title: "Fling API", version: "1.0.0"},
});
```

- [ ] **Step 10: Run the tests against the emulator**

```bash
firebase emulators:exec --only firestore,auth \
  "cd functions && npx vitest run test/features/me test/api/healthz.test.ts"
```

Expected: all `me` tests pass; `healthz` test still passes.

- [ ] **Step 11: Regenerate OpenAPI + Dart client**

```bash
./scripts/generate-dart-client.sh
```

Expected: `openapi/openapi.json` now lists `/v1/me` GET + PATCH and includes `Me` + `PatchMe` schemas. `lib/core/api/generated/lib/src/model/me.dart` exists.

- [ ] **Step 12: Verify Flutter still analyses clean**

```bash
flutter analyze && flutter test test/smoke_test.dart
```

Expected: 0 errors.

- [ ] **Step 13: Commit**

```bash
git add functions/src/features/me functions/src/api/app.ts functions/test/features/me functions/test/core openapi/openapi.json lib/core/api/generated
git commit -m "feat(api): add features/me with GET + PATCH /v1/me; regenerate Dart client"
```

---

## Task 6: Flutter — `features/me/` read path + `ProviderScope` bootstrap

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/features/me/domain/me.dart`
- Create: `lib/features/me/data/me_repository.dart`
- Create: `lib/features/me/application/me_providers.dart`
- Test: `test/features/me/me_repository_test.dart`
- Test: `test/features/me/me_providers_test.dart`

This is the Flutter half of Slice 1: Riverpod gets bootstrapped, the `me` feature streams the user doc from Firestore, and a freezed `Me` domain model lands. The legacy `FlingUser` and `provider`-based wiring stay alive in parallel — nothing the user can see has changed.

- [ ] **Step 1: Write the failing repository test**

Create `test/features/me/me_repository_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fling/features/me/data/me_repository.dart';
import 'package:fling/features/me/domain/me.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeRepository.watch', () {
    test('emits Me with new field names when present', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('alice').set({
        'email': 'alice@example.com',
        'display_name': 'Alice',
        'household_ids': ['h1', 'h2'],
        'current_household_id': 'h1',
        'schema_version': 1,
      });
      final repo = MeRepository(firestore: firestore);
      final me = await repo.watch('alice').first;
      expect(me, isNotNull);
      expect(me!.uid, 'alice');
      expect(me.email, 'alice@example.com');
      expect(me.displayName, 'Alice');
      expect(me.householdIds, ['h1', 'h2']);
      expect(me.currentHouseholdId, 'h1');
    });

    test('falls back to legacy field names', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('alice').set({
        'households': ['h1'],
        'current_household': 'h1',
      });
      final repo = MeRepository(firestore: firestore);
      final me = await repo.watch('alice').first;
      expect(me!.householdIds, ['h1']);
      expect(me.currentHouseholdId, 'h1');
      expect(me.displayName, isNull);
      expect(me.email, isNull);
    });

    test('emits null when the doc does not exist', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = MeRepository(firestore: firestore);
      final me = await repo.watch('ghost').first;
      expect(me, isNull);
    });
  });
}
```

- [ ] **Step 2: Add `fake_cloud_firestore` as a dev dep**

Append under `dev_dependencies:` in `pubspec.yaml`:

```yaml
  fake_cloud_firestore: ^2.5.2
  firebase_auth_mocks: ^0.13.0
```

```bash
flutter pub get
```

- [ ] **Step 3: Run the test (it will fail to compile)**

```bash
flutter test test/features/me/me_repository_test.dart
```

Expected: fails — files don't exist.

- [ ] **Step 4: Define the freezed `Me` model**

Create `lib/features/me/domain/me.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'me.freezed.dart';
part 'me.g.dart';

@freezed
class Me with _$Me {
  const factory Me({
    required String uid,
    String? email,
    String? displayName,
    @Default(<String>[]) List<String> householdIds,
    String? currentHouseholdId,
  }) = _Me;

  factory Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);

  factory Me.fromFirestoreDoc(String uid, Map<String, dynamic> data) {
    return Me(
      uid: uid,
      email: data['email'] as String?,
      displayName: data['display_name'] as String?,
      householdIds: List<String>.from(
        (data['household_ids'] ?? data['households'] ?? const <String>[]) as List,
      ),
      currentHouseholdId: (data['current_household_id'] ?? data['current_household']) as String?,
    );
  }
}
```

- [ ] **Step 5: Run build_runner to generate the freezed parts**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `me.freezed.dart` + `me.g.dart` written.

- [ ] **Step 6: Implement the repository**

Create `lib/features/me/data/me_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fling/features/me/domain/me.dart';

class MeRepository {
  MeRepository({required this.firestore});

  final FirebaseFirestore firestore;

  Stream<Me?> watch(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return Me.fromFirestoreDoc(uid, data);
    });
  }
}
```

- [ ] **Step 7: Run the test to verify it passes**

```bash
flutter test test/features/me/me_repository_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 8: Define Riverpod providers**

Create `lib/features/me/application/me_providers.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/features/me/data/me_repository.dart';
import 'package:fling/features/me/domain/me.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final meRepositoryProvider = Provider<MeRepository>((ref) {
  return MeRepository(firestore: ref.watch(firestoreProvider));
});

final meProvider = StreamProvider<Me?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(null);
  return ref.watch(meRepositoryProvider).watch(auth.uid);
});

final currentHouseholdIdProvider = Provider<String?>((ref) {
  return ref.watch(meProvider).valueOrNull?.currentHouseholdId;
});

final householdIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(meProvider).valueOrNull?.householdIds ?? const <String>[];
});
```

- [ ] **Step 9: Write the providers test**

Create `test/features/me/me_providers_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fling/features/me/application/me_providers.dart';
import 'package:fling/features/me/domain/me.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meProvider streams the current auth user\'s doc', () async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'alice', email: 'alice@example.com'));
    await firestore.collection('users').doc('alice').set({
      'email': 'alice@example.com',
      'household_ids': ['h1'],
      'current_household_id': 'h1',
    });

    final container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      firebaseAuthProvider.overrideWithValue(auth as FirebaseAuth),
    ]);
    addTearDown(container.dispose);

    // Wait for both providers to settle.
    final me = await container.read(meProvider.future);
    expect(me, isA<Me>());
    expect(me!.uid, 'alice');
    expect(me.currentHouseholdId, 'h1');
  });
}
```

- [ ] **Step 10: Run the test to verify it passes**

```bash
flutter test test/features/me
```

Expected: 4 tests pass (3 repo + 1 providers).

- [ ] **Step 11: Wrap the app in `ProviderScope`**

Edit `lib/main.dart`. Replace the `runApp(...)` call and surrounding imports so `ProviderScope` wraps the existing `MultiProvider`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ... existing imports preserved ...

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }

  Stream<FlingUser?> user = FlingUser.currentUser;

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          StreamProvider<FlingUser?>(
            create: (context) => user,
            initialData: null,
          ),
        ],
        child: const FlingApp(),
      ),
    ),
  );
}
```

- [ ] **Step 12: Verify Flutter analyses + tests**

```bash
flutter analyze && flutter test
```

Expected: 0 errors, all tests pass.

- [ ] **Step 13: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart lib/features/me test/features/me
git commit -m "feat(flutter): add features/me Riverpod read path; bootstrap ProviderScope"
```

---

## Task 7: Slice 1 — open PR, deploy, smoke

**Files:** none modified (release task).

- [ ] **Step 1: Push branch and open PR**

```bash
git push -u origin phase-1-me-slice
gh pr create --title "Phase 1 Slice 1 — GET /v1/me end-to-end" --body "$(cat <<'EOF'
## Summary

First slice of Phase 1 (`me` slice + API foundation). No user-visible change.

- core/middleware: requestId, auth (Firebase ID token verification)
- core/errors: AppError hierarchy + Hono onError handler
- features/me: schemas (Me, PatchMe), repo, service, GET /v1/me route
- OpenAPI regenerated; Dart client regenerated and committed
- Flutter: ProviderScope wraps the app; features/me read path streams user doc

## Test plan
- [ ] CI green (backend, flutter, contracts)
- [ ] After merge: `curl -H "Authorization: Bearer $(get-id-token)" https://us-central1-fling-list.cloudfunctions.net/api/v1/me` returns the user doc
- [ ] Flutter app on prod still works exactly as before (no UI consumes the new providers yet)
EOF
)"
```

- [ ] **Step 2: Wait for CI green; merge**

- [ ] **Step 3: Production smoke**

After deploy, exchange a real ID token (or use the Firebase console "Get a sign-in token" tool) and call:

```bash
curl -fsS -H "Authorization: Bearer $TOKEN" \
  "https://us-central1-fling-list.cloudfunctions.net/api/v1/me"
```

Expected: 200 with the doc shape.

---

# SLICE 2 — `PATCH /v1/me` + mutation queue + idempotency

Goal: idempotent mutations. The full `core/api/mutation_queue.dart` lands and `me`'s patch-paths flow through it. Flutter's `setCurrentHouseholdId` consumers stop writing to Firestore directly and start calling the API. Storage is unchanged from Slice 1; legacy reads still work.

## Task 8: Backend — idempotency middleware + repo

**Files:**
- Create: `functions/src/core/idempotency/repo.ts`
- Modify: `functions/src/core/idempotency/index.ts`
- Create: `functions/src/core/middleware/idempotency.ts`
- Modify: `functions/src/core/middleware/index.ts`
- Test: `functions/test/core/middleware/idempotency.test.ts`

Per spec §5.3.3: for write methods (`POST`/`PATCH`/`PUT`/`DELETE`) with `Idempotency-Key`, we look up `idempotency_keys/{uid}_{key}`. On hit with the same body hash + path, replay the stored response. On hit with a different body hash, return 409 `IDEMPOTENCY_CONFLICT`. On miss, run the handler, then store `(status, body, body_hash, expires_at)`. TTL deletion via Firestore TTL on `expires_at`.

> NOTE on TTL config: Firestore TTL must be enabled per-collection-group via the gcloud CLI or the Firebase console. We document and execute this in Task 18 (production deploy).

- [ ] **Step 1: Write the failing test**

Create `functions/test/core/middleware/idempotency.test.ts`:

```ts
import {beforeEach, beforeAll, afterAll, describe, it, expect} from "vitest";
import {OpenAPIHono} from "@hono/zod-openapi";
import {initializeApp, deleteApp, getApps, type App} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {idempotencyMiddleware} from "../../../src/core/middleware/idempotency";
import {installErrorHandler} from "../../../src/core/errors/handler";

let firebaseApp: App;
let calls = 0;

function buildApp(): OpenAPIHono {
  const app = new OpenAPIHono();
  installErrorHandler(app);
  // Pretend RequestContext is already on c (idempotency reads c.get('uid')).
  app.use("*", async (c, next) => {
    c.set("uid", "alice");
    c.set("requestId", "rid");
    await next();
  });
  app.use("*", idempotencyMiddleware());
  app.patch("/echo", async (c) => {
    calls++;
    const body = await c.req.json();
    return c.json({calls, echoed: body}, 200);
  });
  return app;
}

beforeAll(() => {
  firebaseApp = getApps()[0] ?? initializeApp({projectId: "fling-rules-test"});
});
beforeEach(async () => {
  calls = 0;
  const db = getFirestore();
  const docs = await db.collection("idempotency_keys").listDocuments();
  await Promise.all(docs.map((d) => d.delete()));
});
afterAll(async () => {
  if (firebaseApp) await deleteApp(firebaseApp);
});

describe("idempotency middleware", () => {
  it("passes through when no Idempotency-Key is present", async () => {
    const app = buildApp();
    const r = await app.request("/echo", {method: "PATCH", body: JSON.stringify({a: 1}), headers: {"Content-Type": "application/json"}});
    expect(r.status).toBe(200);
    expect(calls).toBe(1);
  });

  it("dedupes: same key + same body returns the cached response", async () => {
    const app = buildApp();
    const headers = {"Content-Type": "application/json", "Idempotency-Key": "k1"};
    const body = JSON.stringify({a: 1});
    const r1 = await app.request("/echo", {method: "PATCH", body, headers});
    const r2 = await app.request("/echo", {method: "PATCH", body, headers});
    expect(r1.status).toBe(200);
    expect(r2.status).toBe(200);
    expect(calls).toBe(1);
    expect(await r2.json()).toEqual({calls: 1, echoed: {a: 1}});
  });

  it("returns 409 on key reuse with a different body", async () => {
    const app = buildApp();
    const headers = {"Content-Type": "application/json", "Idempotency-Key": "k1"};
    const r1 = await app.request("/echo", {method: "PATCH", body: JSON.stringify({a: 1}), headers});
    expect(r1.status).toBe(200);
    const r2 = await app.request("/echo", {method: "PATCH", body: JSON.stringify({a: 2}), headers});
    expect(r2.status).toBe(409);
    expect((await r2.json()).error.code).toBe("CONFLICT");
  });

  it("partitions keys by uid", async () => {
    // Build an app where a query param overrides uid for the second call.
    const app = new OpenAPIHono();
    installErrorHandler(app);
    app.use("*", async (c, next) => {
      const u = c.req.query("uid") ?? "alice";
      c.set("uid", u);
      c.set("requestId", "rid");
      await next();
    });
    app.use("*", idempotencyMiddleware());
    app.patch("/echo", async (c) => {
      calls++;
      return c.json({calls}, 200);
    });
    const headers = {"Content-Type": "application/json", "Idempotency-Key": "k1"};
    await app.request("/echo?uid=alice", {method: "PATCH", body: "{}", headers});
    const r2 = await app.request("/echo?uid=bob", {method: "PATCH", body: "{}", headers});
    expect(r2.status).toBe(200);
    expect(calls).toBe(2);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
firebase emulators:exec --only firestore,auth \
  "cd functions && npx vitest run test/core/middleware/idempotency.test.ts"
```

Expected: fails — files don't exist.

- [ ] **Step 3: Implement the repo**

Create `functions/src/core/idempotency/repo.ts`:

```ts
import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";

export interface IdempotencyRecord {
  status: number;
  body: string;
  bodyHash: string;
  contentType: string;
  expiresAt: Date;
}

function db() {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}

const TTL_MS = 24 * 60 * 60 * 1000;

export function compositeId(uid: string, key: string): string {
  return `${uid}_${key}`;
}

export async function lookup(uid: string, key: string): Promise<IdempotencyRecord | null> {
  const snap = await db().collection("idempotency_keys").doc(compositeId(uid, key)).get();
  if (!snap.exists) return null;
  const d = snap.data()!;
  return {
    status: d.status,
    body: d.body,
    bodyHash: d.body_hash,
    contentType: d.content_type,
    expiresAt: (d.expires_at as Timestamp).toDate(),
  };
}

export async function save(uid: string, key: string, rec: IdempotencyRecord): Promise<void> {
  await db().collection("idempotency_keys").doc(compositeId(uid, key)).set({
    status: rec.status,
    body: rec.body,
    body_hash: rec.bodyHash,
    content_type: rec.contentType,
    expires_at: Timestamp.fromMillis(Date.now() + TTL_MS),
  });
}
```

Update `functions/src/core/idempotency/index.ts`:

```ts
export * from "./repo";
```

- [ ] **Step 4: Implement the middleware**

Create `functions/src/core/middleware/idempotency.ts`:

```ts
import type {MiddlewareHandler} from "hono";
import {createHash} from "node:crypto";
import {Conflict} from "../errors/app_error";
import {lookup, save} from "../idempotency/repo";

const WRITE_METHODS = new Set(["POST", "PATCH", "PUT", "DELETE"]);

export function idempotencyMiddleware(): MiddlewareHandler {
  return async (c, next) => {
    if (!WRITE_METHODS.has(c.req.method)) {
      await next();
      return;
    }
    const key = c.req.header("idempotency-key");
    if (!key) {
      await next();
      return;
    }
    const uid = c.get("uid") as string | undefined;
    if (!uid) {
      // Idempotency requires an authenticated principal — pass through if anonymous (auth gate will reject anyway).
      await next();
      return;
    }
    const rawBody = await c.req.raw.clone().text();
    const bodyHash = createHash("sha256").update(rawBody).digest("hex");

    const existing = await lookup(uid, key);
    if (existing) {
      if (existing.bodyHash !== bodyHash) {
        throw new Conflict("Idempotency key reused with different body", {key});
      }
      return c.body(existing.body, existing.status as 200, {"content-type": existing.contentType});
    }

    await next();

    const status = c.res.status;
    const cloned = c.res.clone();
    const body = await cloned.text();
    const contentType = cloned.headers.get("content-type") ?? "application/json";
    if (status >= 200 && status < 300) {
      await save(uid, key, {status, body, bodyHash, contentType, expiresAt: new Date()});
    }
  };
}
```

Update `functions/src/core/middleware/index.ts`:

```ts
export {requestIdMiddleware} from "./request_id";
export {authMiddleware} from "./auth";
export {idempotencyMiddleware} from "./idempotency";
```

- [ ] **Step 5: Mount idempotency in `app.ts`**

Edit `functions/src/api/app.ts` — add the middleware after `authMiddleware`:

```ts
app.use("/v1/*", authMiddleware());
app.use("/v1/*", idempotencyMiddleware());
registerMeRoutes(app);
```

(Add `idempotencyMiddleware` to the import from `../core/middleware`.)

- [ ] **Step 6: Run the test to verify it passes**

```bash
firebase emulators:exec --only firestore,auth \
  "cd functions && npx vitest run test/core/middleware/idempotency.test.ts"
```

Expected: 4 tests pass.

- [ ] **Step 7: Commit**

```bash
git add functions/src/core/idempotency functions/src/core/middleware/idempotency.ts functions/src/core/middleware/index.ts functions/src/api/app.ts functions/test/core/middleware/idempotency.test.ts
git commit -m "feat(core): add idempotency middleware backed by idempotency_keys collection"
```

---

## Task 9: Backend — extend the `me` route test for `PATCH /v1/me`

**Files:**
- Modify: `functions/test/features/me/routes.test.ts`

The PATCH handler already exists from Task 5; this task locks in its integration-tested behaviour now that the idempotency middleware sits in front of it.

- [ ] **Step 1: Add PATCH cases to `routes.test.ts`**

Append to the existing file (inside the `describe("GET /v1/me", ...)` group, add a sibling group):

```ts
describe("PATCH /v1/me", () => {
  it("400 on extra fields (zod strict)", async () => {
    const res = await buildApp().request("/v1/me", {
      method: "PATCH",
      headers: {"Content-Type": "application/json", Authorization: `Bearer ${aliceToken}`},
      body: JSON.stringify({foo: "bar"}),
    });
    expect(res.status).toBe(400);
  });

  it("updates currentHouseholdId and dual-writes the legacy field", async () => {
    const res = await buildApp().request("/v1/me", {
      method: "PATCH",
      headers: {"Content-Type": "application/json", Authorization: `Bearer ${aliceToken}`},
      body: JSON.stringify({currentHouseholdId: "h-xyz"}),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.currentHouseholdId).toBe("h-xyz");
  });

  it("updates displayName", async () => {
    const res = await buildApp().request("/v1/me", {
      method: "PATCH",
      headers: {"Content-Type": "application/json", Authorization: `Bearer ${aliceToken}`},
      body: JSON.stringify({displayName: "Alice"}),
    });
    expect(res.status).toBe(200);
    expect((await res.json()).displayName).toBe("Alice");
  });

  it("idempotency: same key + same body returns the same response without re-running", async () => {
    const headers = {"Content-Type": "application/json", Authorization: `Bearer ${aliceToken}`, "Idempotency-Key": "patch-1"};
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
    const headers = {"Content-Type": "application/json", Authorization: `Bearer ${aliceToken}`, "Idempotency-Key": "patch-2"};
    const r1 = await buildApp().request("/v1/me", {method: "PATCH", headers, body: JSON.stringify({displayName: "Alice"})});
    const r2 = await buildApp().request("/v1/me", {method: "PATCH", headers, body: JSON.stringify({displayName: "Bob"})});
    expect(r1.status).toBe(200);
    expect(r2.status).toBe(409);
  });
});
```

- [ ] **Step 2: Run the tests**

```bash
firebase emulators:exec --only firestore,auth \
  "cd functions && npx vitest run test/features/me"
```

Expected: 7 tests pass (2 GET + 5 PATCH).

- [ ] **Step 3: Regenerate Dart client (PATCH endpoint enters the spec)**

```bash
./scripts/generate-dart-client.sh
flutter analyze && flutter test test/smoke_test.dart
```

Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add functions/test/features/me/routes.test.ts openapi/openapi.json lib/core/api/generated
git commit -m "test(me): exercise PATCH /v1/me end-to-end (validation + idempotency)"
```

---

## Task 10: Flutter — `ApiClient` (Dio + Bearer interceptor)

**Files:**
- Create: `lib/core/api/api_client.dart`
- Create: `lib/core/api/idempotency_key.dart`
- Test: `test/core/api/api_client_test.dart`

The generated `dart-dio` client wants a configured Dio with a Bearer auth interceptor. We expose it as a Riverpod provider so feature data layers can inject it.

- [ ] **Step 1: Implement `idempotency_key.dart`**

Create `lib/core/api/idempotency_key.dart`:

```dart
import 'dart:math';

const _alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

String newIdempotencyKey([Random? rng]) {
  final r = rng ?? Random.secure();
  final buf = StringBuffer();
  for (var i = 0; i < 22; i++) {
    buf.write(_alphabet[r.nextInt(_alphabet.length)]);
  }
  return buf.toString();
}
```

- [ ] **Step 2: Implement `api_client.dart`**

Create `lib/core/api/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/core/api/generated/lib/fling_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiBaseUrl {
  ApiBaseUrl(this.url);
  final String url;
}

final apiBaseUrlProvider = Provider<ApiBaseUrl>((_) {
  const url = String.fromEnvironment(
    'FLING_API_BASE_URL',
    defaultValue: 'https://us-central1-fling-list.cloudfunctions.net/api',
  );
  return ApiBaseUrl(url);
});

class _BearerAuthInterceptor extends Interceptor {
  _BearerAuthInterceptor(this._auth);
  final FirebaseAuth _auth;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final user = _auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

final flingApiProvider = Provider<FlingApi>((ref) {
  final base = ref.watch(apiBaseUrlProvider).url;
  final auth = FirebaseAuth.instance;
  final dio = Dio(BaseOptions(baseUrl: base, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 30)));
  dio.interceptors.add(_BearerAuthInterceptor(auth));
  return FlingApi(dio: dio);
});
```

> Note: the exact import path `package:fling/core/api/generated/lib/fling_api.dart` matches the layout the OpenAPI generator produces under `lib/core/api/generated/`. Adjust if a real path inspection in the worktree shows a different filename (the generator emits `<pubName>.dart`, here `fling_api.dart`).

- [ ] **Step 3: Smoke test**

Create `test/core/api/api_client_test.dart`:

```dart
import 'package:fling/core/api/idempotency_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('idempotency keys are 22 chars, alphanumeric', () {
    for (var i = 0; i < 50; i++) {
      final k = newIdempotencyKey();
      expect(k.length, 22);
      expect(RegExp(r'^[0-9A-Za-z]+$').hasMatch(k), isTrue);
    }
  });

  test('idempotency keys are unique across many draws', () {
    final keys = {for (var i = 0; i < 1000; i++) newIdempotencyKey()};
    expect(keys.length, 1000);
  });
}
```

```bash
flutter test test/core/api/api_client_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/core/api/api_client.dart lib/core/api/idempotency_key.dart test/core/api/api_client_test.dart
git commit -m "feat(flutter): add ApiClient (Dio + Bearer auth) and idempotency key generator"
```

---

## Task 11: Flutter — `mutation_queue.dart` (full implementation)

**Files:**
- Create: `lib/core/api/mutation_queue.dart`
- Test: `test/core/api/mutation_queue_test.dart`

Spec §7.5–7.6: optimistic-update overlay, persistent queue, drain on reconnect, idempotent retry. The queue is the merge point between the per-resource Firestore stream (the upstream truth) and the client's pending writes. Because every retry uses the same idempotency key, draining is always safe.

Public surface:

```dart
abstract class MutationQueue {
  Future<T> enqueue<T>(MutationSpec<T> spec);
  Stream<List<PendingMutation>> get pending;
  /// Apply pending mutations on top of upstream snapshot. Resource-keyed.
  T overlay<T>(T upstream, T Function(T base, PendingMutation p) reduce, {required String resourceKey});
  Future<void> drain();
}
```

- [ ] **Step 1: Write the failing test**

Create `test/core/api/mutation_queue_test.dart`:

```dart
import 'dart:async';
import 'package:fling/core/api/mutation_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Connectivity {
  final controller = StreamController<bool>.broadcast();
  Stream<bool> get stream => controller.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueue runs the call once on success and removes from pending', () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    var calls = 0;
    final result = await q.enqueue(MutationSpec<int>(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'Alice'},
      call: (key) async { calls++; return 1; },
    ));
    expect(result, 1);
    expect(calls, 1);
    expect(await q.pending.first, isEmpty);
  });

  test('on transient failure the mutation stays pending until drain succeeds', () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    var attempts = 0;
    final f = q.enqueue(MutationSpec<int>(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'Alice'},
      call: (key) async {
        attempts++;
        if (attempts < 2) throw const NetworkFailure();
        return 1;
      },
    ));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect((await q.pending.first).length, 1);
    connectivity.controller.add(true);
    expect(await f, 1);
    expect(attempts, 2);
    expect(await q.pending.first, isEmpty);
  });

  test('on permanent failure (4xx non-409) the mutation is dropped and rethrown', () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    Object? caught;
    try {
      await q.enqueue(MutationSpec<int>(
        type: 'me.patch',
        resourceKey: 'me/alice',
        body: const {'displayName': ''},
        call: (key) async => throw const ApiFailure(400, 'BAD_REQUEST', 'too short'),
      ));
    } catch (e) { caught = e; }
    expect(caught, isA<ApiFailure>());
    expect(await q.pending.first, isEmpty);
  });

  test('persists pending mutations across instances', () async {
    SharedPreferences.setMockInitialValues({});
    var prefs = await SharedPreferences.getInstance();
    final connectivity1 = _Connectivity();
    final q1 = MutationQueueImpl(prefs: prefs, online: connectivity1.stream);
    // Enqueue without awaiting; force a transient failure by never going online.
    final completer = Completer<int>();
    unawaited(q1.enqueue(MutationSpec<int>(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'A'},
      call: (key) async {
        if (!completer.isCompleted) throw const NetworkFailure();
        return 1;
      },
    )).then(completer.complete, onError: (_) {}));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect((await q1.pending.first).length, 1);

    // Recreate the queue from the same prefs; pending must survive.
    prefs = await SharedPreferences.getInstance();
    final connectivity2 = _Connectivity();
    final q2 = MutationQueueImpl(prefs: prefs, online: connectivity2.stream);
    expect((await q2.pending.first).length, 1);
  });

  test('overlay applies pending mutations to upstream', () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    final completer = Completer<int>();
    unawaited(q.enqueue(MutationSpec<int>(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'Optimistic'},
      call: (key) async {
        await completer.future;
        return 1;
      },
    )));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final base = {'displayName': 'Old'};
    final overlaid = q.overlay<Map<String, Object?>>(
      base,
      (base, p) => {...base, ...p.body},
      resourceKey: 'me/alice',
    );
    expect(overlaid['displayName'], 'Optimistic');
    completer.complete(1);
  });
}
```

- [ ] **Step 2: Run the test (will fail to compile)**

```bash
flutter test test/core/api/mutation_queue_test.dart
```

Expected: fails — file doesn't exist.

- [ ] **Step 3: Implement `mutation_queue.dart`**

Create `lib/core/api/mutation_queue.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fling/core/api/idempotency_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkFailure implements Exception {
  const NetworkFailure();
}

class ApiFailure implements Exception {
  const ApiFailure(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
  @override
  String toString() => 'ApiFailure($status, $code): $message';
}

class MutationSpec<T> {
  MutationSpec({
    required this.type,
    required this.resourceKey,
    required this.body,
    required this.call,
    this.idempotencyKey,
  });
  final String type;
  final String resourceKey;
  final Map<String, Object?> body;
  final String? idempotencyKey;
  final Future<T> Function(String idempotencyKey) call;
}

class PendingMutation {
  PendingMutation({
    required this.idempotencyKey,
    required this.type,
    required this.resourceKey,
    required this.body,
    required this.createdAt,
    this.attempts = 0,
  });
  final String idempotencyKey;
  final String type;
  final String resourceKey;
  final Map<String, Object?> body;
  final DateTime createdAt;
  int attempts;

  Map<String, Object?> toJson() => {
        'idempotencyKey': idempotencyKey,
        'type': type,
        'resourceKey': resourceKey,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
      };

  factory PendingMutation.fromJson(Map<String, Object?> j) => PendingMutation(
        idempotencyKey: j['idempotencyKey']! as String,
        type: j['type']! as String,
        resourceKey: j['resourceKey']! as String,
        body: Map<String, Object?>.from(j['body'] as Map),
        createdAt: DateTime.parse(j['createdAt']! as String),
        attempts: (j['attempts'] as int?) ?? 0,
      );
}

abstract class MutationQueue {
  Future<T> enqueue<T>(MutationSpec<T> spec);
  Stream<List<PendingMutation>> get pending;
  T overlay<T>(T upstream, T Function(T base, PendingMutation p) reduce, {required String resourceKey});
  Future<void> drain();
}

class MutationQueueImpl implements MutationQueue {
  MutationQueueImpl({required this.prefs, required Stream<bool> online})
      : _online = online {
    _load();
    _online.listen((isOnline) {
      if (isOnline) drain();
    });
  }

  static const _prefsKey = 'fling.mutation_queue.v1';
  final SharedPreferences prefs;
  final Stream<bool> _online;
  final _controller = StreamController<List<PendingMutation>>.broadcast();
  final List<PendingMutation> _queue = [];
  final Map<String, Completer<dynamic>> _completers = {};
  final Map<String, Future<dynamic> Function(String)> _calls = {};

  void _load() {
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List).cast<Map<String, Object?>>();
    _queue.addAll(list.map(PendingMutation.fromJson));
    _emit();
  }

  Future<void> _persist() async {
    await prefs.setString(_prefsKey, jsonEncode(_queue.map((p) => p.toJson()).toList()));
  }

  void _emit() {
    _controller.add(List.unmodifiable(_queue));
  }

  @override
  Stream<List<PendingMutation>> get pending {
    Future<void>.microtask(_emit);
    return _controller.stream;
  }

  @override
  Future<T> enqueue<T>(MutationSpec<T> spec) async {
    final key = spec.idempotencyKey ?? newIdempotencyKey();
    final p = PendingMutation(
      idempotencyKey: key,
      type: spec.type,
      resourceKey: spec.resourceKey,
      body: spec.body,
      createdAt: DateTime.now().toUtc(),
    );
    _queue.add(p);
    final completer = Completer<T>();
    _completers[key] = completer;
    _calls[key] = spec.call;
    await _persist();
    _emit();
    unawaited(_runOne(p));
    return completer.future;
  }

  Future<void> _runOne(PendingMutation p) async {
    final call = _calls[p.idempotencyKey];
    final completer = _completers[p.idempotencyKey];
    if (call == null || completer == null) return;
    p.attempts++;
    try {
      final result = await call(p.idempotencyKey);
      _queue.removeWhere((q) => q.idempotencyKey == p.idempotencyKey);
      _completers.remove(p.idempotencyKey);
      _calls.remove(p.idempotencyKey);
      completer.complete(result);
    } on NetworkFailure {
      // Stay pending; retried on next drain / connectivity event.
    } on ApiFailure catch (e) {
      // 409 is conflict — keep pending only if it's an idempotency conflict the server may resolve later.
      // Otherwise drop and rethrow to caller.
      if (e.status >= 400 && e.status < 500 && e.status != 409) {
        _queue.removeWhere((q) => q.idempotencyKey == p.idempotencyKey);
        _completers.remove(p.idempotencyKey);
        _calls.remove(p.idempotencyKey);
        completer.completeError(e);
      }
    } catch (e) {
      // Unknown error — treat as transient.
    } finally {
      await _persist();
      _emit();
    }
  }

  @override
  Future<void> drain() async {
    final snapshot = List<PendingMutation>.from(_queue);
    for (final p in snapshot) {
      await _runOne(p);
    }
  }

  @override
  T overlay<T>(T upstream, T Function(T base, PendingMutation p) reduce, {required String resourceKey}) {
    var acc = upstream;
    for (final p in _queue) {
      if (p.resourceKey == resourceKey) acc = reduce(acc, p);
    }
    return acc;
  }
}

final connectivityOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
});

final mutationQueueProvider = FutureProvider<MutationQueue>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final online = ref
      .watch(connectivityOnlineProvider.stream)
      .asBroadcastStream();
  return MutationQueueImpl(prefs: prefs, online: online);
});
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/core/api/mutation_queue_test.dart
```

Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/api/mutation_queue.dart test/core/api/mutation_queue_test.dart
git commit -m "feat(core/api): full mutation queue (in-memory + persistent + drain on reconnect)"
```

---

## Task 12: Flutter — wire `me` writes through the API + mutation queue

**Files:**
- Modify: `lib/features/me/data/me_repository.dart`
- Modify: `lib/features/me/application/me_providers.dart`
- Test: extend `test/features/me/me_providers_test.dart`

The repo grows two write methods that go through the API client + mutation queue. The `MeRepository` reads through the queue's overlay so the UI stays optimistic until the Firestore stream catches up.

- [ ] **Step 1: Extend the repository**

Replace `lib/features/me/data/me_repository.dart` with:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:fling/core/api/generated/lib/fling_api.dart';
import 'package:fling/core/api/mutation_queue.dart';
import 'package:fling/features/me/domain/me.dart';

class MeRepository {
  MeRepository({
    required this.firestore,
    required this.api,
    required this.mutations,
  });

  final FirebaseFirestore firestore;
  final FlingApi api;
  final MutationQueue mutations;

  Stream<Me?> watch(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      final base = Me.fromFirestoreDoc(uid, data);
      return mutations.overlay<Me>(
        base,
        (b, p) => _applyPatch(b, p.body),
        resourceKey: 'me/$uid',
      );
    });
  }

  Me _applyPatch(Me base, Map<String, Object?> patch) {
    return base.copyWith(
      currentHouseholdId:
          (patch['currentHouseholdId'] as String?) ?? base.currentHouseholdId,
      displayName: (patch['displayName'] as String?) ?? base.displayName,
    );
  }

  Future<void> setCurrentHouseholdId(String uid, String householdId) async {
    final body = {'currentHouseholdId': householdId};
    await mutations.enqueue(MutationSpec<void>(
      type: 'me.patch',
      resourceKey: 'me/$uid',
      body: body,
      call: (key) async {
        try {
          await api.getDefaultApi().patchV1Me(
                idempotencyKey: key,
                patchMe: PatchMe((b) => b..currentHouseholdId = householdId),
              );
        } on DioException catch (e) {
          throw _toFailure(e);
        }
      },
    ));
  }

  Future<void> setDisplayName(String uid, String displayName) async {
    final body = {'displayName': displayName};
    await mutations.enqueue(MutationSpec<void>(
      type: 'me.patch',
      resourceKey: 'me/$uid',
      body: body,
      call: (key) async {
        try {
          await api.getDefaultApi().patchV1Me(
                idempotencyKey: key,
                patchMe: PatchMe((b) => b..displayName = displayName),
              );
        } on DioException catch (e) {
          throw _toFailure(e);
        }
      },
    ));
  }

  Object _toFailure(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) return const NetworkFailure();
    final body = e.response?.data;
    final code = (body is Map && body['error'] is Map)
        ? (body['error']['code'] as String? ?? 'UNKNOWN')
        : 'UNKNOWN';
    final message = (body is Map && body['error'] is Map)
        ? (body['error']['message'] as String? ?? e.message ?? '')
        : (e.message ?? '');
    return ApiFailure(status, code, message);
  }
}
```

> Note: the actual generated method name (`patchV1Me` and the `getDefaultApi()` accessor) reflects what `openapi-generator-cli`'s `dart-dio` template produces from a route tagged `me` with operationId `patchV1Me`. After regenerating in Task 9, confirm the names by reading `lib/core/api/generated/lib/src/api/default_api.dart` (the file is committed) and adjust the calls if the generator chose a different name.

- [ ] **Step 2: Update providers**

Replace `lib/features/me/application/me_providers.dart` with:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/core/api/api_client.dart';
import 'package:fling/core/api/mutation_queue.dart';
import 'package:fling/features/me/data/me_repository.dart';
import 'package:fling/features/me/domain/me.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final meRepositoryProvider = FutureProvider<MeRepository>((ref) async {
  final mutations = await ref.watch(mutationQueueProvider.future);
  return MeRepository(
    firestore: ref.watch(firestoreProvider),
    api: ref.watch(flingApiProvider),
    mutations: mutations,
  );
});

final meProvider = StreamProvider<Me?>((ref) async* {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) {
    yield null;
    return;
  }
  final repo = await ref.watch(meRepositoryProvider.future);
  yield* repo.watch(auth.uid);
});

final currentHouseholdIdProvider = Provider<String?>((ref) {
  return ref.watch(meProvider).valueOrNull?.currentHouseholdId;
});

final householdIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(meProvider).valueOrNull?.householdIds ?? const <String>[];
});

class MeController {
  MeController(this._ref);
  final Ref _ref;

  Future<void> setCurrentHousehold(String householdId) async {
    final auth = _ref.read(firebaseAuthProvider).currentUser;
    if (auth == null) return;
    final repo = await _ref.read(meRepositoryProvider.future);
    await repo.setCurrentHouseholdId(auth.uid, householdId);
  }

  Future<void> setDisplayName(String displayName) async {
    final auth = _ref.read(firebaseAuthProvider).currentUser;
    if (auth == null) return;
    final repo = await _ref.read(meRepositoryProvider.future);
    await repo.setDisplayName(auth.uid, displayName);
  }
}

final meControllerProvider = Provider<MeController>(MeController.new);
```

- [ ] **Step 3: Verify analyse + tests**

```bash
flutter analyze && flutter test test/features/me test/core
```

Expected: clean. The earlier `me_repository_test.dart` from Task 6 needs updates because the constructor signature changed; update it:

In `test/features/me/me_repository_test.dart`, change every `MeRepository(firestore: firestore)` to:

```dart
MeRepository(firestore: firestore, api: _NoopApi(), mutations: _NoopQueue())
```

Then add at the bottom of the file:

```dart
class _NoopApi implements FlingApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopQueue implements MutationQueue {
  @override
  Future<T> enqueue<T>(MutationSpec<T> spec) => spec.call('test');
  @override
  Stream<List<PendingMutation>> get pending => const Stream.empty();
  @override
  T overlay<T>(T upstream, T Function(T base, PendingMutation p) reduce, {required String resourceKey}) => upstream;
  @override
  Future<void> drain() async {}
}
```

(Add `import 'package:fling/core/api/generated/lib/fling_api.dart';` and `import 'package:fling/core/api/mutation_queue.dart';` to the test file.)

```bash
flutter test test/features/me test/core
```

Expected: all pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/me test/features/me
git commit -m "feat(flutter/me): wire setCurrentHouseholdId + setDisplayName via API + mutation queue"
```

---

## Task 13: Flutter — switch existing pages to the new providers

**Files:**
- Modify: `lib/pages/lists.dart`
- Modify: `lib/pages/templates.dart`
- Modify: `lib/pages/household_add.dart`
- Modify: `lib/data/household.dart`

We swap the four call sites that today write `current_household` directly. `FlingUser` is **not** deleted yet (Slice 3 does that); legacy reads can coexist. The new write goes through the API.

- [ ] **Step 1: Update `lib/pages/household_add.dart`**

Find the call:

```dart
user?.setCurrentHouseholdId(household.id!);
```

Convert the surrounding widget to a `ConsumerStatefulWidget` (or use `Consumer` inline) and replace the call with:

```dart
await ref.read(meControllerProvider).setCurrentHousehold(household.id!);
```

Add `import 'package:fling/features/me/application/me_providers.dart';` and `import 'package:flutter_riverpod/flutter_riverpod.dart';`.

- [ ] **Step 2: Update `lib/pages/lists.dart` and `lib/pages/templates.dart`**

Replace each:

```dart
user?.setCurrentHouseholdId(id);
```

with:

```dart
await ref.read(meControllerProvider).setCurrentHousehold(id);
```

Replace each read of `user?.currentHouseholdId` with `ref.watch(currentHouseholdIdProvider)`.

Make the surrounding widgets `ConsumerWidget` / `ConsumerStatefulWidget` as needed.

- [ ] **Step 3: Update `lib/data/household.dart`**

Replace:

```dart
Future<DocumentReference> get ref async {
  FlingUser? user = await FlingUser.currentUser.first;
  return firestore.collection("households").doc(user?.currentHouseholdId);
}
```

with a method that takes `currentHouseholdId` as a parameter (callers pass `ref.watch(currentHouseholdIdProvider)`):

```dart
DocumentReference refFor(String currentHouseholdId) {
  return firestore.collection("households").doc(currentHouseholdId);
}
```

Update all internal uses (`save`, `leave`, `lists`, `templates`) to take the id as a parameter, and update each caller site to pass `ref.read(currentHouseholdIdProvider)!`.

- [ ] **Step 4: Verify analyse + tests + run app locally**

```bash
flutter analyze && flutter test
./scripts/dev.sh &
DEV_PID=$!
sleep 12
flutter run -d chrome --dart-define=FLING_API_BASE_URL=http://127.0.0.1:5001/fling-list/us-central1/api &
APP_PID=$!
# Manually exercise: log in, switch household, observe lists update.
sleep 30
kill $APP_PID $DEV_PID 2>/dev/null || true
```

Expected: switching household triggers `PATCH /v1/me` (visible in emulator UI logs). Lists page renders after switching.

- [ ] **Step 5: Commit**

```bash
git add lib/pages lib/data/household.dart
git commit -m "refactor(flutter): move household-switch to me API; consume currentHouseholdIdProvider"
```

---

## Task 14: Slice 2 — open PR, deploy, smoke

**Files:** none modified.

- [ ] **Step 1: Push and open PR**

```bash
git push
gh pr create --title "Phase 1 Slice 2 — PATCH /v1/me + mutation queue" --body "$(cat <<'EOF'
## Summary

Second slice of Phase 1.

- core middleware: idempotency (Firestore-backed, partitioned by uid)
- features/me: PATCH /v1/me (currentHouseholdId? + displayName?) with full integration coverage
- Flutter core/api: ApiClient (Dio + Bearer interceptor), idempotency-key generator
- Flutter core/api/mutation_queue.dart: full implementation (in-memory + shared_preferences persist + connectivity_plus drain)
- Flutter features/me/data/me_repository.dart now writes via API + mutation queue, reads via Firestore + optimistic overlay
- Existing pages (lists, templates, household_add, household.dart) consume currentHouseholdIdProvider instead of FlingUser.setCurrentHouseholdId

Storage shape unchanged. Legacy FlingUser still alive (Slice 3 deletes it).

## Test plan
- [ ] CI green
- [ ] After deploy: enable Firestore TTL on idempotency_keys.expires_at (one-time):
      gcloud firestore fields ttls update expires_at \
        --collection-group=idempotency_keys --enable-ttl --project=fling-list
- [ ] Log into prod app; switch household; confirm:
      - UI updates immediately (optimistic overlay)
      - PATCH /v1/me visible in cloud logs with the correct uid
      - users/{uid}.current_household_id and .current_household both updated in Firestore
EOF
)"
```

- [ ] **Step 2: After merge, enable TTL on `idempotency_keys`**

```bash
gcloud firestore fields ttls update expires_at \
  --collection-group=idempotency_keys --enable-ttl --project=fling-list
```

Expected: TTL configuration succeeds. Re-runs are no-ops.

- [ ] **Step 3: Production smoke**

In the prod web app, switch household. Confirm:
- The list view re-renders to the new household's lists (Firestore stream catches up).
- Cloud Functions logs show `PATCH /v1/me` with structured `request_id`.
- `users/{uid}` doc in Firestore shows both `current_household` and `current_household_id`.

---

# SLICE 3 — triggers, migration, rule tighten

Goal: cut the v1 setup/delete triggers, run Migration #1 on prod data, dual-write the legacy member triggers, retire `FlingUser`, and tighten the security rule on `/users/{uid}` to read-only.

## Task 15: Backend — `features/me/triggers.ts` (v2-organised auth lifecycle)

**Files:**
- Create: `functions/src/features/me/triggers.ts`
- Modify: `functions/src/index.ts`
- Test: `functions/test/features/me/triggers.test.ts`

The lifecycle triggers run on user-create / user-delete. We keep the v1 SDK syntax (`firebase-functions/v1`'s `auth.user()` is the supported way until Identity Platform blocking triggers replace it). Organisation moves to `features/me/triggers.ts`.

- [ ] **Step 1: Write the failing test**

Create `functions/test/features/me/triggers.test.ts`:

```ts
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
afterAll(async () => { if (app) await deleteApp(app); });

describe("me triggers", () => {
  it("handleUserCreated writes the new doc shape", async () => {
    await handleUserCreated({uid: "alice", email: "alice@example.com"});
    const data = (await getFirestore().doc("users/alice").get()).data();
    expect(data?.email).toBe("alice@example.com");
    expect(data?.household_ids).toEqual([]);
    expect(data?.current_household_id).toBeNull();
    expect(data?.households).toEqual([]);             // legacy dual-write
    expect(data?.current_household).toBeNull();       // legacy dual-write
    expect(data?.schema_version).toBe(1);
    expect(data?.created_at).toBeDefined();
  });

  it("handleUserDeleted removes the doc", async () => {
    await handleUserCreated({uid: "alice", email: null});
    await handleUserDeleted({uid: "alice"});
    expect((await getFirestore().doc("users/alice").get()).exists).toBe(false);
  });
});
```

- [ ] **Step 2: Run the test (will fail)**

```bash
firebase emulators:exec --only firestore,auth \
  "cd functions && npx vitest run test/features/me/triggers.test.ts"
```

- [ ] **Step 3: Implement the triggers**

Create `functions/src/features/me/triggers.ts`:

```ts
import * as functionsV1 from "firebase-functions/v1";
import {createUser, deleteUser} from "./service";

export interface AuthUserLike {
  uid: string;
  email?: string | null;
}

export async function handleUserCreated(user: AuthUserLike): Promise<void> {
  await createUser(user.uid, user.email ?? null);
}

export async function handleUserDeleted(user: AuthUserLike): Promise<void> {
  await deleteUser(user.uid);
}

export const onUserCreated = functionsV1.auth.user().onCreate((u) =>
  handleUserCreated({uid: u.uid, email: u.email ?? null}),
);

export const onUserDeleted = functionsV1.auth.user().onDelete((u) =>
  handleUserDeleted({uid: u.uid, email: u.email ?? null}),
);
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
firebase emulators:exec --only firestore,auth \
  "cd functions && npx vitest run test/features/me/triggers.test.ts"
```

Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add functions/src/features/me/triggers.ts functions/test/features/me/triggers.test.ts
git commit -m "feat(me): add v2-organised auth lifecycle triggers in features/me/triggers.ts"
```

---

## Task 16: Migration #1 — additive backfill of user-doc shape

**Files:**
- Create: `functions/migrations/001-user-shape.ts`
- Test: `functions/test/migrations/001-user-shape.test.ts`

For every `users/{uid}` doc, set the new fields if missing:
- `email` ← Firebase Auth user record's email (best-effort; null if not found)
- `display_name` ← null
- `household_ids` ← copy of `households` (or `[]`)
- `current_household_id` ← copy of `current_household` (or null)
- `schema_version` ← 1
- `created_at` / `updated_at` ← server timestamp
- `created_by_uid` ← the doc's own uid

Idempotent: skips docs that already have `schema_version: 1`.

- [ ] **Step 1: Write the failing test**

Create `functions/test/migrations/001-user-shape.test.ts`:

```ts
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
afterAll(async () => { if (app) await deleteApp(app); });

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
    expect(data.households).toEqual(["h1"]);          // legacy preserved
    expect(data.current_household).toBe("h1");        // legacy preserved
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
```

- [ ] **Step 2: Implement the migration**

Create `functions/migrations/001-user-shape.ts`:

```ts
import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import type {Migration} from "./runner";

const BATCH = 400;

const migration: Migration = {
  id: "001-user-shape",
  up: async () => {
    if (getApps().length === 0) initializeApp();
    const db = getFirestore();
    const auth = getAuth();
    let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
    while (true) {
      let q = db.collection("users").orderBy("__name__").limit(BATCH);
      if (last) q = q.startAfter(last);
      const snap = await q.get();
      if (snap.empty) break;
      const batch = db.batch();
      for (const doc of snap.docs) {
        const data = doc.data();
        if (data.schema_version === 1) continue; // idempotent
        let email: string | null = data.email ?? null;
        if (!email) {
          try { email = (await auth.getUser(doc.id)).email ?? null; } catch { email = null; }
        }
        batch.set(doc.ref, {
          email,
          display_name: data.display_name ?? null,
          household_ids: data.household_ids ?? data.households ?? [],
          current_household_id: data.current_household_id ?? data.current_household ?? null,
          // Preserve legacy fields untouched (compaction in Phase 6 drops them).
          households: data.households ?? data.household_ids ?? [],
          current_household: data.current_household ?? data.current_household_id ?? null,
          schema_version: 1,
          created_at: data.created_at ?? FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
          created_by_uid: data.created_by_uid ?? doc.id,
        }, {merge: true});
      }
      await batch.commit();
      last = snap.docs[snap.docs.length - 1];
      if (snap.size < BATCH) break;
    }
  },
};

export default migration;
```

- [ ] **Step 3: Run the test to verify it passes**

```bash
firebase emulators:exec --only firestore,auth \
  "cd functions && npx vitest run test/migrations/001-user-shape.test.ts"
```

Expected: 3 tests pass.

- [ ] **Step 4: Commit**

```bash
git add functions/migrations/001-user-shape.ts functions/test/migrations/001-user-shape.test.ts
git commit -m "feat(migrations): 001-user-shape backfills new user-doc fields (additive)"
```

---

## Task 17: Patch v1 `cacheJoinHousehold` / `cacheLeaveHousehold` to dual-write

**Files:**
- Modify: `functions/src/index.ts`
- Test: extend the `routes` integration tests OR add a small focused test

The legacy callable-style triggers now write both `households` and `household_ids`. They will be deleted in Phase 2.

- [ ] **Step 1: Edit `functions/src/index.ts`**

In `cacheJoinHousehold` change:

```ts
.update({
  households: admin.firestore.FieldValue.arrayUnion(householdId),
});
```

to:

```ts
.update({
  households: admin.firestore.FieldValue.arrayUnion(householdId),
  household_ids: admin.firestore.FieldValue.arrayUnion(householdId),
});
```

Mirror the same change in `cacheLeaveHousehold`:

```ts
.update({
  households: admin.firestore.FieldValue.arrayRemove(householdId),
  household_ids: admin.firestore.FieldValue.arrayRemove(householdId),
});
```

Also add a comment marker so Phase 2 deletes the right block:

```ts
// PHASE-2-DELETE-START: legacy member-cache triggers (replaced by features/members/)
exports.cacheJoinHousehold = ...
exports.cacheLeaveHousehold = ...
// PHASE-2-DELETE-END
```

- [ ] **Step 2: Replace v1 setupUser/deleteUser with v2-organised exports**

In the same file, **delete** the existing `exports.setupUser` and `exports.deleteUser` blocks. Replace with:

```ts
// v2-organised auth lifecycle triggers (impl: features/me/triggers.ts).
export {onUserCreated, onUserDeleted} from "./features/me/triggers";
```

- [ ] **Step 3: Build + test**

```bash
cd functions && npm run build && npm run lint && npm test && cd ..
```

Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add functions/src/index.ts
git commit -m "feat(triggers): swap setupUser/deleteUser for v2 me triggers; dual-write legacy member triggers"
```

---

## Task 18: Flutter — delete `lib/data/user.dart`; migrate remaining consumers

**Files:**
- Delete: `lib/data/user.dart`
- Modify: `lib/main.dart`
- Modify: `lib/pages/home.dart`
- Modify: `lib/pages/list.dart`
- Modify: `lib/pages/template.dart`
- Modify: `lib/pages/lists.dart`
- Modify: `lib/pages/templates.dart`
- Modify: `lib/pages/household_add.dart`
- Modify: `lib/layout/drawer.dart`
- Modify: `lib/data/household.dart`

`FlingUser` and the legacy `StreamProvider<FlingUser?>` go away. All consumers move to `meProvider` / `currentHouseholdIdProvider` / `householdIdsProvider` / `meControllerProvider`.

- [ ] **Step 1: Inventory the consumers**

```bash
rg "FlingUser|StreamProvider<FlingUser" lib/ -n
```

Expected list (matches the file map). Confirm none are missed.

- [ ] **Step 2: For each consumer file, do the swap**

The pattern is mechanical:

| Old | New |
|---|---|
| `FlingUser? user = Provider.of<FlingUser?>(context)` | `final me = ref.watch(meProvider).valueOrNull;` |
| `user?.currentHouseholdId` | `ref.watch(currentHouseholdIdProvider)` |
| `user?.householdIds` | `ref.watch(householdIdsProvider)` |
| `user?.setCurrentHouseholdId(id)` | `ref.read(meControllerProvider).setCurrentHousehold(id)` |
| `user?.deleteAccount()` | `await FirebaseAuth.instance.currentUser?.delete()` (the v2 `onUserDeleted` trigger handles the doc cleanup) |
| `await FlingUser.currentUser.first` | `await ref.read(meProvider.future)` |

Convert `StatelessWidget` → `ConsumerWidget` and `StatefulWidget` → `ConsumerStatefulWidget` as needed.

- [ ] **Step 3: Update `lib/main.dart` to drop the old StreamProvider**

Remove the `provider`-based `StreamProvider<FlingUser?>` block:

```dart
// remove these:
import 'package:fling/data/user.dart';
import 'package:provider/provider.dart';

// inside main():
Stream<FlingUser?> user = FlingUser.currentUser;
runApp(ProviderScope(child: MultiProvider(providers: [...], child: const FlingApp())));
```

Replace with:

```dart
runApp(const ProviderScope(child: FlingApp()));
```

If no other code in `main.dart` uses the `provider` package, also remove `provider:` from `pubspec.yaml`'s dependencies (only if no other file imports it — verify with `rg "package:provider/" lib/`).

- [ ] **Step 4: Delete `lib/data/user.dart`**

```bash
git rm lib/data/user.dart
```

- [ ] **Step 5: Verify analyse + tests**

```bash
flutter analyze && flutter test
```

Expected: clean.

- [ ] **Step 6: Commit**

```bash
git add lib pubspec.yaml pubspec.lock
git commit -m "refactor(flutter): delete FlingUser; move all consumers to features/me providers"
```

---

## Task 19: Tighten `firestore.rules` on `/users/{uid}` to owner-only read

**Files:**
- Modify: `firestore.rules`
- Modify: `functions/test/rules/baseline.test.ts`

Now that nothing on the client writes to `/users/{uid}` (the v2 trigger creates the doc; PATCH /v1/me updates it), we can flip writes to `false` and reads to owner-only.

- [ ] **Step 1: Edit `firestore.rules`**

Replace the `/users/{uid}` block with:

```text
match /users/{uid} {
  allow read:  if signedIn() && request.auth.uid == uid;
  allow write: if false;
}
```

- [ ] **Step 2: Update the rules test**

In `functions/test/rules/baseline.test.ts`, replace the "user can read & write their own /users/{uid} doc" case with:

```ts
it("user can read but not write their own /users/{uid} doc (writes go through API)", async () => {
  const alice = env.authenticatedContext("alice").firestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc("users/alice").set({household_ids: []});
  });
  await assertSucceeds(alice.doc("users/alice").get());
  await assertFails(alice.doc("users/alice").set({household_ids: ["h1"]}));
});
```

- [ ] **Step 3: Run the rules test**

```bash
firebase emulators:exec --only firestore,auth \
  "cd functions && npx vitest run test/rules"
```

Expected: pass.

- [ ] **Step 4: Commit**

```bash
git add firestore.rules functions/test/rules/baseline.test.ts
git commit -m "feat(rules): tighten /users/{uid} to owner-only read; deny client writes"
```

---

## Task 20: Slice 3 — open PR, deploy, run migration, smoke

**Files:** none modified.

- [ ] **Step 1: Push and open PR**

```bash
git push
gh pr create --title "Phase 1 Slice 3 — triggers, migration, rule tighten" --body "$(cat <<'EOF'
## Summary

Final slice of Phase 1.

- features/me/triggers.ts: v2-organised onUserCreated / onUserDeleted (replaces v1 setupUser/deleteUser)
- migrations/001-user-shape.ts: idempotent additive backfill of user docs
- v1 cacheJoinHousehold/cacheLeaveHousehold patched to dual-write `household_ids` until Phase 2 deletes them
- FlingUser deleted from Flutter; all consumers consume features/me providers
- firestore.rules: /users/{uid} is owner-only read; no client writes

## Test plan
- [ ] CI green
- [ ] After merge: deploy succeeds (`firebase deploy --only functions,firestore:rules`)
- [ ] Run migration once against prod: `cd functions && GCLOUD_PROJECT=fling-list npm run migrate`
- [ ] Spot-check 3 users in Firestore: each has `schema_version: 1`, `household_ids`, `current_household_id`, `email`
- [ ] On a freshly-signed-up user: confirm v2 onUserCreated wrote the new doc shape
- [ ] On deleting the test user: doc is removed
- [ ] Direct Firestore write to /users/{uid} from the Flutter app fails with permission-denied
- [ ] App still works: log in, switch household, view lists, view templates, log out
EOF
)"
```

- [ ] **Step 2: After merge — run the migration in production**

```bash
cd functions
GCLOUD_PROJECT=fling-list npm run migrate
cd ..
```

Expected: prints `[migrate] apply 001-user-shape` and `[migrate] done 001-user-shape`. Re-running is a no-op.

- [ ] **Step 3: Spot-check 3 user docs in the Firebase console**

Each should have `schema_version: 1`, `household_ids`, `current_household_id`, `email`, `created_at`, `updated_at`, `created_by_uid`. Legacy `households` / `current_household` still present.

- [ ] **Step 4: Production smoke**

In the prod web app:
1. Log in.
2. Switch household — UI updates immediately, list re-renders.
3. View lists, templates — all data loads.
4. Try a deliberate Firestore-direct write from a debug build (`firestore.collection('users').doc(uid).set(...)`) — confirm `permission-denied`.
5. Sign up a fresh test user — confirm a `users/{newUid}` doc appears with `schema_version: 1` (v2 trigger fired).
6. Delete the test user — confirm the `users/{newUid}` doc is gone.

---

## Task 21: Close the phase — STATUS + change log

**Files:**
- Modify: `docs/superpowers/migrations/STATUS.md`

- [ ] **Step 1: Flip Phase 1 to ✅**

In the Overview table change Phase 1 from `🟡` to `✅`. Set the **Completed** column to today.

- [ ] **Step 2: Tick every box in §"Phase 1 — `me` slice + API foundation"**

Replace each `- [ ]` with `- [x]` for the eight bullets under that heading.

- [ ] **Step 3: Append change-log entries**

```text
| YYYY-MM-DD | 1 | Slice 1 deployed | <PR-URL> | GET /v1/me + middleware + Flutter feature read path |
| YYYY-MM-DD | 1 | Slice 2 deployed | <PR-URL> | PATCH /v1/me + idempotency + mutation queue + Flutter writes |
| YYYY-MM-DD | 1 | Slice 3 deployed | <PR-URL> | v2 triggers, migration #1, rule tighten, FlingUser deleted |
| YYYY-MM-DD | 1 | Completed        | <PR-URL> | Phase 1 closed; ready for Phase 2 (households + members + invites) |
```

- [ ] **Step 4: Update "Last updated"** to today.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/migrations/STATUS.md
git commit -m "docs(rewrite): close Phase 1 (me slice + API foundation)"
git push
```

- [ ] **Step 6: Clean up the worktree**

```bash
cd /Users/garrit/src/garritfra/fling
git worktree remove .worktrees/phase-1-me-slice
```

---

## Self-review checklist

- [ ] Every spec exit criterion in STATUS §"Phase 1 — `me` slice + API foundation" maps to at least one task above:
  - middleware (auth, idempotency, request_id, structured logging, error mapping) → Tasks 1, 2, 3, 4, 8
  - OpenAPI → Dart client pipeline working end-to-end → Tasks 5, 9 (regen with real Me schemas)
  - `core/api/mutation_queue.dart` → Task 11
  - Backend `features/me/` complete (`GET`/`PATCH /v1/me`) → Tasks 5, 9
  - Flutter `features/me/` migrated; old `FlingUser` deleted → Tasks 6, 12, 13, 18
  - `setupUser`/`deleteUser` v1 functions replaced by v2 triggers in `features/me/triggers.ts` → Tasks 15, 17
  - Migration #1 deployed → Tasks 16, 20
  - Rule tightened: `/users/{uid}` owner-only read → Task 19

- [ ] Every code step is runnable: file paths exact, no `// implement here` placeholders, full code blocks included for non-trivial files.

- [ ] Type names used in later tasks match earlier definitions: `Me`, `PatchMe`, `RequestContext`, `AppError`, `MutationSpec`, `PendingMutation`, `MutationQueue`, `MeRepository`, `MeController`.

- [ ] Cross-phase compatibility encoded:
  - Backend repo reads both new and legacy field names (Task 5)
  - Backend writes both new and legacy fields on every patch (Task 5: `patchUserDoc`)
  - v2 trigger writes both new and legacy fields on user create (Task 5: `createUserDoc`, used from Task 15)
  - v1 `cacheJoinHousehold`/`cacheLeaveHousehold` dual-write (Task 17)
  - Migration backfills new fields without dropping legacy (Task 16)

- [ ] Each commit step shows the exact files staged.

- [ ] No deletion of v1 callables that Phase 2 owns (`cacheJoinHousehold`, `cacheLeaveHousehold`, `inviteToHouseholdByEmail`).

- [ ] Each slice ends with a deploy + smoke task; every PR is independently shippable.

- [ ] Rule tighten lands **last** (Task 19), only after all client writes to `/users/{uid}` are gone.

- [ ] Open assumptions worth flagging at exec time:
  - The `dart-dio` generator's exact method/class names for `PATCH /v1/me` (referenced as `patchV1Me` and `PatchMe` in Task 12) should be verified against the freshly-generated `lib/core/api/generated/lib/src/api/default_api.dart` after Task 9. Adjust call sites if the generator chose different names.
  - Firestore TTL on `idempotency_keys.expires_at` is enabled out-of-band via `gcloud` after Slice 2 merges (Task 14, Step 2). The middleware functions correctly without it; expired records simply pile up until TTL is enabled.
  - Trigger SDK choice (`firebase-functions/v1`'s `auth.user()`) is intentional and documented in the plan header.
