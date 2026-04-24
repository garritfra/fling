# Fling Rewrite — Design Spec

- **Date:** 2026-04-24
- **Status:** Approved (awaiting implementation plan)
- **Owner:** garritfra
- **Related:**
  - Live progress: [`docs/superpowers/migrations/STATUS.md`](../migrations/STATUS.md)
  - Per-phase plans: `docs/superpowers/migrations/phase-N-*.md` (created just before each phase starts)

---

## 1. Background

Fling is a Flutter shopping-list app backed by Firebase (Firestore + Auth +
Cloud Functions). It started as a minimal client-direct-to-Firestore app and
has grown organically. Today the codebase has accumulated debt that makes it
hard to extend: data models double as persistence, view-models, *and* business
logic; pages directly construct Firestore queries through nested
`Future<Stream<...>>` patterns; there are no security rules in the repo, no
real tests, no shared API contract, and no pattern for adding new feature
domains.

The current scope (auth, users, households, lists, list items, templates,
template items, tags) is appropriate and will be preserved. The goal is to
reorganise the foundations so future features (catalog items, aisle grouping,
recipes, finances, an MCP server, a CLI, AI agents) become mechanical to add.

## 2. Goals

- A **backend-driven** architecture where the app is a thin client that calls a
  real API. The same API serves the Flutter app today and future CLI / MCP /
  agent clients tomorrow.
- **Realtime collaboration** remains a first-class feature.
- **Offline use** of the shopping list remains supported.
- The system is organised into **vertical feature slices** so that adding a
  new feature is dropping a new directory, not editing every layer.
- A **clear contract** exists between client and backend (typed, versioned,
  testable), and between features (typed events).
- The data model has **audit metadata, schema versioning, and explicit
  ownership** of every document.
- Code is **safe to change**: linted, typed, unit-tested, with security rules
  tested against the emulator in CI.
- Migration from today's data is **incremental and shippable**: every PR
  deploys to production; no long-lived branches.

## 3. Non-goals

The following are deliberately out of scope for this rewrite. They are
*unblocked* by the design but will not be built as part of it.

- New product domains: recipes, finances, pantry, prices, stores.
- The MCP server, CLI, AI agent. Their integration is designed for; their
  implementation is later work.
- Catalog items, aisle/category grouping, AI-suggested grouping. Hooks are
  designed in (see §5); no user-visible features are built.
- Activity feed UI. The event bus that would feed it is built; no consumer
  UI is built.
- Migration to Cloud Run, gRPC, GraphQL, event sourcing, multi-region.
- Splitting the API into multiple Functions deployments. One deployment for
  v1.

## 4. Architecture

### 4.1 Topology

Single Firebase project, single repository (monorepo).

```text
┌─────────────────────────┐    HTTPS + Bearer (Firebase ID token)
│   Flutter app (clients) │ ──────────────────────────┐
│   CLI / MCP / agent     │                           │
└─────────────────────────┘                           ▼
            │                              ┌──────────────────────┐
            │  Firestore SDK (read-only,   │  REST API            │
            │  realtime listeners)         │  Firebase Functions  │
            │                              │  v2 + Hono           │
            ▼                              └──────────┬───────────┘
   ┌────────────────────┐                             │
   │     Firestore      │ ◀───────────────────────────┘
   │  (single source    │       (all writes,
   │   of truth)        │        all business logic)
   └────────────────────┘
            ▲
            │ triggers (cache, fanout, audit)
            │
   ┌────────────────────┐
   │ Firestore triggers │
   │ (Functions v2)     │
   └────────────────────┘
```

### 4.2 Invariants

| # | Invariant | Rationale |
|---|---|---|
| I1 | All writes go through the REST API. Security rules deny client writes everywhere. | Single contract for Flutter, CLI, MCP, agents. Validation, business logic, and side effects live in one place. |
| I2 | Reads stream from Firestore directly via security rules scoped to household membership. | Preserves realtime collaboration and offline cache (the "battery-included" Firebase strengths). |
| I3 | Triggers handle only denormalisation the API can't easily do at write time (auth-lifecycle reactions, member-cache maintenance). | Cascade triggers are explicitly avoided — they make the system hard to reason about. |
| I4 | The on-disk Firestore document shape is a public, backend-owned contract — equivalent to an API response. Backend services are the only writer; clients mirror the shape via typed schemas (Zod / freezed). | Lets reads stay direct without coupling clients to ad-hoc storage shapes. |
| I5 | Non-realtime clients (CLI/MCP/agents) use REST endpoints for both reads and writes. | Same auth, same API surface, no Firestore SDK dependency required. |

### 4.3 CQRS-lite

This is, by design, a CQRS-lite architecture: writes are commands through the
API; reads are queries straight from the store. The vocabulary is useful when
discussing trade-offs but no CQRS framework is adopted.

## 5. Backend layout & API design

### 5.1 Layout (vertical slices)

```text
functions/
  src/
    index.ts                     # exports: api (HTTPS), triggers
    api/
      app.ts                     # Hono app: middleware + route mounting
    core/
      auth/                      # ID token verification middleware
      errors/                    # AppError hierarchy + HTTP mapper
      events/                    # publish + subscribe (events collection)
      context/                   # RequestContext { uid, householdId, requestId }
      firestore/                 # Admin SDK init, withConverter helpers
      idempotency/               # Idempotency-Key middleware + repo
      logger/                    # structured logger with request_id
      middleware/                # request_id, validate, rateLimit (slot)
      flags/                     # Remote Config wrapper (slot)
    features/
      me/         { routes.ts, service.ts, repo.ts, schemas.ts, events.ts, triggers.ts, module.ts }
      households/ { ... }
      members/    { ... }
      invites/    { ... }
      lists/      { ... }
      templates/  { ... }
    migrations/                  # versioned, idempotent data migrations + runner
  test/
    services/                    # unit tests with fake repos
    routes/                      # integration tests against emulator
    rules/                       # security rules tests
```

**Layering rule (per feature):** `routes → service → repo → Firestore`. One
direction only, enforced by an ESLint boundary rule. Cross-feature interaction
goes through the events module, not direct imports.

### 5.2 Tech choices

- **HTTP framework:** Hono on Functions v2. Lightweight, modern, excellent TS
  ergonomics.
- **Validation + OpenAPI:** `@hono/zod-openapi` — Zod schemas drive both
  request validation and the generated OpenAPI spec.
- **Test runner:** Vitest.
- **Single deployment** for v1: one HTTPS function (`api`) hosting all
  routes; triggers are separate but live in the same source tree.

### 5.3 Cross-cutting middleware

In order of execution per request:

1. `requestId` — generate / accept `X-Request-Id`, attach to logger.
2. `auth` — verify Firebase ID token, attach `{ uid, email }` to context.
3. `idempotency` — for POSTs with `Idempotency-Key`: dedupe via
   `idempotency_keys/{key}` collection (TTL'd).
4. `validate` — Zod request validation against the route's declared schema.
5. `requireMember(:hid)` — for household-scoped routes, verify membership
   via single `members/{uid}` read.
6. (Slot) `rateLimit` — no-op for v1; designed in for later.

Errors throw typed `AppError` subclasses; an error handler maps them to HTTP
status + the canonical response shape:

```json
{ "error": { "code": "FORBIDDEN", "message": "...", "details": {} } }
```

### 5.4 API surface (v1)

All paths are versioned `/v1`. Resource-oriented, predictable verbs.

```text
# Identity
GET    /v1/me
PATCH  /v1/me                                          { currentHouseholdId? }

# Data portability (cross-cutting on `me`) — ships in Phase 5
GET    /v1/me:export                                   → JSON bundle
DELETE /v1/me                                          → cascading account delete

# Households
GET    /v1/households                                  # those the caller belongs to
POST   /v1/households                                  { name }
GET    /v1/households/:hid
PATCH  /v1/households/:hid                             { name? }
DELETE /v1/households/:hid                             # owner only, last member

# Members
GET    /v1/households/:hid/members
DELETE /v1/households/:hid/members/:uid                # leave (self) or kick (owner)

# Invites
GET    /v1/households/:hid/invites
POST   /v1/households/:hid/invites                     { email }
DELETE /v1/households/:hid/invites/:iid                # cancel
GET    /v1/me/invites                                  # invites addressed to caller's email
POST   /v1/invites/:iid:accept

# Lists
GET    /v1/households/:hid/lists
POST   /v1/households/:hid/lists                       { name, tags? }
GET    /v1/households/:hid/lists/:lid
PATCH  /v1/households/:hid/lists/:lid                  { name?, tags? }
DELETE /v1/households/:hid/lists/:lid

# List items
GET    /v1/households/:hid/lists/:lid/items
POST   /v1/households/:hid/lists/:lid/items            { text, tags? }
PATCH  /v1/households/:hid/lists/:lid/items/:iid       { text?, tags?, checked? }
DELETE /v1/households/:hid/lists/:lid/items/:iid
POST   /v1/households/:hid/lists/:lid/items:bulkDelete { onlyChecked?: bool, ids?: string[] }
POST   /v1/households/:hid/lists/:lid/items:applyTemplate { templateId }

# Templates / template items: mirror lists / items
```

Conventions:

- Resource paths fully scope ownership.
- Action endpoints use the AOM-style `:verb` suffix (`:bulkDelete`,
  `:applyTemplate`, `:accept`, `:export`).
- All POST endpoints honour `Idempotency-Key`.
- Pagination is **deferred** for v1 — the data volumes don't warrant it. When
  added it will be cursor-based, opt-in via `?pageSize` / `?pageToken`.

### 5.5 Triggers (Functions v2)

Kept narrow. Each trigger lives next to the feature that owns the data it
mutates.

| Trigger | Source | Effect |
|---|---|---|
| `onUserCreated` | `auth.user().onCreate` | Create `users/{uid}` doc with defaults. |
| `onUserDeleted` | `auth.user().onDelete` | Cascading purge through services (called via `me.service.deleteUser`). |
| `onMemberJoined` | `households/{hid}/members/{uid}` onCreate | Update `users/{uid}.household_ids` cache. |
| `onMemberLeft` | `households/{hid}/members/{uid}` onDelete | Update `users/{uid}.household_ids` cache. |
| `onEventCreated` | `households/{hid}/events/{eid}` onCreate | Fan out to in-process subscribers registered via `core/events`. |

No other cascade triggers. New denormalisations require a written justification
in the relevant feature's `module.ts`.

### 5.6 Domain events

Every service emits domain events after successful writes:

- Events are versioned per kind: `list.item.created.v1`, `invite.accepted.v1`,
  etc. Adding a new kind is additive; consumers ignore unknown kinds.
- Events are written to `households/{hid}/events/{eventId}` and TTL'd
  (~30 days) via Firestore TTL on `expires_at`.
- Subscribers register through `core/events` and run inside the
  `onEventCreated` trigger. Subscribers live in the *consuming* feature's
  `events.ts`, never in the producing feature.

## 6. Data model

### 6.1 Universal document conventions

- **Audit:** every document carries `created_at`, `updated_at`,
  `created_by_uid`, `schema_version`. Backend writes set these; clients never
  do.
- **Naming:** `snake_case` in storage, `camelCase` in code. Repos own the
  translation.
- **IDs:** Firestore-generated, opaque, never parsed.
- **Tenant scoping:** any document related to a household lives under
  `/households/{hid}/...`.
- **No soft deletes** in v1. If a "trash" UX is requested, add a per-feature
  `_trash` subcollection with TTL.

### 6.2 Entity map

```text
users/{uid}
  email                          # denormalised from Auth (simplifies invite lookup)
  display_name?
  household_ids[]                # cache, maintained by triggers
  current_household_id?
  + audit + schema_version

households/{hid}
  name
  owner_uid                      # first creator; transferable via API
  + audit + schema_version

  members/{uid}
    role: 'owner' | 'member'
    joined_at
    invited_by_uid?

  invites/{inviteId}
    email                        # lower-cased
    invited_by_uid
    status: 'pending' | 'accepted' | 'cancelled' | 'expired'
    expires_at                   # Firestore TTL field
    accepted_by_uid?
    accepted_at?
    + audit + schema_version

  lists/{lid}
    name
    tags[]
    + audit + schema_version

    items/{iid}
      text
      checked: bool
      tags[]
      # planned hooks (not built v1):
      # position?: string        # fractional index for manual ordering
      # category_id?: string     # aisle / catalog category reference
      # catalog_item_id?: string # canonical item reference
      + audit + schema_version

  templates/{tid}
    name
    tags[]
    + audit + schema_version

    items/{tiid}
      text
      tags[]
      + audit + schema_version

  events/{eventId}
    kind                         # e.g. 'list.item.created.v1'
    payload: map                 # versioned per kind
    actor_uid
    request_id                   # correlates with API logs
    created_at
    expires_at                   # Firestore TTL
```

### 6.3 Lists vs templates

Kept as **separate document types** sharing a line-item shape in code. Lists
have lifecycle state (checked, bulk-delete-checked); templates do not.
Cross-cutting operations (`save list as template`, `apply template to list`)
live in services.

### 6.4 Invites become first-class

Today, invites require the invitee to already be a Firebase Auth user. The new
flow:

1. `POST /v1/households/:hid/invites { email }` creates a pending invite doc
   with `expires_at`.
2. After signup (or whenever the client lands on the app), the **client**
   calls `GET /v1/me/invites`. The server matches pending invites whose
   `email` equals the caller's auth-token email claim and returns them. The
   app surfaces them in onboarding.
3. `POST /v1/invites/:iid:accept` adds the membership and marks the invite
   accepted.
4. A daily scheduled job marks `pending` invites past `expires_at` as
   `expired`. Firestore TTL deletes them shortly after for cleanup.

### 6.5 Planned extension hooks

Designed in, not built:

- **Manual ordering:** `position?: string` on list items (fractional indexing
  via lexicographic strings).
- **Aisle / category grouping:** `category_id?: string` on list items;
  `households/{hid}/categories/{cid}` collection. Grouping strategies (manual,
  rule-based, AI-derived) live in the application layer.
- **Catalog items:** `catalog_item_id?: string` on list items;
  `households/{hid}/catalog/{cid}` collection with `canonical_name`,
  `default_tags`, `default_unit`. Enables future ingredient matching, price
  tracking, AI suggestions.

These are mentioned in the schema as comments only. They will not appear in
v1 documents.

### 6.6 Schema versioning

Every document carries `schema_version: number`. Repositories check on read;
outdated documents are rewritten lazily by a per-collection migrator. The
`migrations/` directory holds versioned, idempotent scripts; `npm run migrate`
runs pending ones, tracking state in `_migrations/{id}`.

## 7. Flutter app layout & state management

### 7.1 Layout

```text
lib/
  main.dart
  app.dart                       # FlingApp: theme, l10n, router, error zone
  core/
    api/                         # generated OpenAPI client + auth + offline queue
    auth/                        # FirebaseAuth wrapper, session providers
    firestore/                   # instance + withConverter helpers
    errors/                      # AppError, mappers
    logger/                      # structured logger, request_id per action
    router/                      # go_router config
    theme/
    ui/                          # FlingButton, FlingEmptyState, FlingErrorView,
                                 # FlingLoading, FlingConfirmDialog,
                                 # FlingTextField, FlingInputDialog
    flags/                       # Remote Config (slot)
  features/
    auth/               { data/, application/, presentation/ }
    me/                 { data/, domain/, application/, presentation/ }
    households/         { data/, domain/, application/, presentation/ }
    lists/              { data/, domain/, application/, presentation/ }
    templates/          { data/, domain/, application/, presentation/ }
  l10n/
```

### 7.2 Layering inside a feature

- `domain/` — freezed models, no Firebase imports. Mirror the backend Zod
  schemas by hand.
- `data/` — repositories. Reads return `Stream<List<X>>` from Firestore via
  `withConverter`; writes call the generated API client. Single boundary to
  the outside world.
- `application/` — Riverpod notifiers. Own optimistic-update logic. Expose
  `AsyncValue<X>` to UI.
- `presentation/` — pages and widgets. Consume providers only.

Lint rule (enforced): `presentation` does not import `data`; `application`
does not import `presentation`.

### 7.3 Tech choices

- **State:** Riverpod.
- **Models:** freezed + json_serializable.
- **Routing:** go_router with nested routes and a single `redirect` for
  auth + current-household gates.
- **API client:** generated from the backend OpenAPI via
  `openapi-generator-cli` (template `dart-dio`), output to
  `lib/core/api/generated/`. When the CLI / MCP work begins it is extracted
  to `packages/fling_api_client/` (Melos).
- **Offline queue storage:** `shared_preferences` (JSON blob) for v1.
  Adapter interface allows swapping to `drift` / `hive_ce` later.

### 7.4 Read path

```text
Firestore listener → Repository.watchX() → StreamNotifier → AsyncValue<X> → UI
```

UI uses `AsyncValue.when(data:, loading:, error:)`. Errors are typed
`AppError`s.

### 7.5 Write path (pending-mutations overlay)

UI state is the merge of the Firestore stream and a per-resource queue of
pending mutations. Each action:

1. Controller records a pending mutation with a client-generated
   `idempotency_key` and an expected local effect.
2. UI re-renders immediately (optimistic).
3. Controller calls API with the same idempotency key.
4. On success: remove from pending queue. The Firestore stream catches up;
   the merge keeps the UI stable either way.
5. On failure: remove from pending queue, surface a `FlingErrorSnackBar`.
   Revert is automatic because the Firestore stream was the baseline.

This is encapsulated in `core/api/mutation_queue.dart` and reused by every
feature.

### 7.6 Offline writes

The mutation queue persists to disk. On app start and on `connectivity_plus`
online events, drain the queue. Because every POST is idempotent (§5.3),
retry is always safe.

### 7.7 Error model

One sealed `AppError` class:

- `Unauthorized` — token invalid or missing.
- `Forbidden` — not a member.
- `NotFound`.
- `Conflict` — idempotency or version conflict.
- `Offline` — no connectivity, mutation queued.
- `Unknown(cause)` — fallback.

Mappers translate API error responses and `FirebaseException`s into
`AppError`. Errors include `request_id` when available.

### 7.8 Shared UI primitives

Introduced during the rewrite, not after:

- `FlingEmptyState`, `FlingErrorView`, `FlingLoading`.
- `FlingConfirmDialog`, `FlingInputDialog`.
- `FlingListTile` with built-in Dismissible + long-press menu.

## 8. Security rules

Because all writes go through the API, rules collapse to "members can read,
nobody can write".

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function signedIn() { return request.auth != null; }

    function isMember(hid) {
      return signedIn()
        && exists(/databases/$(db)/documents/households/$(hid)/members/$(request.auth.uid));
    }

    match /users/{uid} {
      allow read:  if signedIn() && request.auth.uid == uid;
      allow write: if false;
    }

    match /households/{hid} {
      allow read:  if isMember(hid);
      allow write: if false;

      match /members/{uid}        { allow read: if isMember(hid); allow write: if false; }
      match /invites/{iid}        {
        allow read:  if isMember(hid)
                     || (signedIn() && resource.data.email == request.auth.token.email);
        allow write: if false;
      }
      match /lists/{lid}/{document=**}     { allow read: if isMember(hid); allow write: if false; }
      match /templates/{tid}/{document=**} { allow read: if isMember(hid); allow write: if false; }
      match /events/{eid}         { allow read: if isMember(hid); allow write: if false; }
    }
  }
}
```

Notes:

- `isMember` uses `exists(...)` against the authoritative `members/`
  subcollection, not the denormalised `users/{uid}.household_ids` cache. The
  cache is for UI listing only; rules never trust it.
- Invites are readable by the invitee via the `email` token claim, enabling
  the post-signup invite-claim flow.
- Each `exists()` call is billed as one Firestore read. Acceptable at this
  app's scale.

## 9. Testing & CI

### 9.1 Tiers

| Tier | Location | Tooling | Purpose |
|---|---|---|---|
| Backend unit | `functions/test/services/` | Vitest, fake repos | Business logic in isolation |
| Backend integration | `functions/test/routes/` | Vitest + Firestore/Auth emulator | Auth, validation, real writes, triggers, idempotency |
| Security rules | `functions/test/rules/` | `@firebase/rules-unit-testing` | Per-collection allow/deny matrix |
| Flutter unit | `test/` | `flutter_test`, fake repos | Mappers, controllers, mutation queue |
| Flutter smoke widget | `test/` | `flutter_test`, `ProviderScope` overrides | Critical flows (login, list view, template apply) |

OpenAPI request/response schemas double as contract tests: a handler returning
something off-schema fails its integration test.

### 9.2 Dev loop

```bash
firebase emulators:start          # Auth + Firestore + Functions + Hosting
npm --prefix functions run dev    # tsx watch, attaches Hono to emulator
flutter run -d chrome             # points at emulator via --dart-define
```

A `scripts/dev.sh` orchestrates all three. `scripts/seed.ts` loads a logged-in
user, household, list, and template fixture.

### 9.3 CI (GitHub Actions, parallel jobs per PR)

1. **`backend`** — install, ESLint, `tsc --noEmit`, unit tests, route tests
   against emulator, rules tests.
2. **`flutter`** — `flutter analyze`, `flutter test`.
3. **`contracts`** — regenerate OpenAPI + Dart client, fail if diff non-empty.

A manual-trigger job deploys to a shared `staging` Firebase project for
review.

## 10. Migration & phased delivery

Six phases. Every PR is shippable. Old code coexists with new until the phase
that replaces it ends with a deletion PR. Security rules tighten as the **last
step of each phase**, only after the Flutter app has stopped writing the
relevant collection directly. Schema migrations are additive within a phase;
a single compaction migration in Phase 6 drops legacy fields.

| Phase | Goal | Schema migration | Final rule tighten |
|---|---|---|---|
| 0 — Foundation | All scaffolding (CI, deps, lint boundaries, empty Hono app, emulator, migrations runner). No user-visible change. | none | none |
| 1 — `me` slice + API foundation | First end-to-end vertical slice. Replaces `setupUser` / `deleteUser`. | Additive: `email`, `display_name`, `household_ids`, `current_household_id`, audit fields, `schema_version: 1` on user docs. Old fields populated in parallel. | `users/{uid}` owner-only read |
| 2 — Households + members + invites | New invite flow (first-class invites). Replaces `cacheJoinHousehold` / `cacheLeaveHousehold` / `inviteToHouseholdByEmail`. | Additive: `members/{uid}` gets `role` + `joined_at`; oldest member becomes `owner`. Households get audit fields. | households + members + invites: members read, no client write |
| 3 — Lists | All list and item mutations through API. Offline queue + optimistic updates wired up. | Additive: audit + `schema_version` on lists and items. | lists + items: members read, no client write |
| 4 — Templates | Same pattern as lists. `:applyTemplate` action live. | Additive: audit + `schema_version` on templates and items. | templates + items: members read, no client write |
| 5 — Events bus + cross-cutting | Internal wiring. Every service emits events. Data export and cascading account delete shipped. | none | none |
| 6 — Compaction | Drop legacy fields, remove dual-write code, delete v1 functions. | Drop `users.current_household` + `users.households` (legacy shape). Bump `schema_version`. | none |

### 10.1 Migration mechanics

- Migrations are TypeScript files in `functions/migrations/`, exporting `up()`
  and (where reversible) `down()`.
- `npm run migrate` runs pending migrations against the configured project.
  State tracked in `_migrations/{id}`.
- All migrations are idempotent. Re-running is a no-op.
- Backfills batch-write in chunks of ~400 docs, with retries, logged with
  `request_id`.
- A migration ships in the same PR as the code that depends on it.

### 10.2 Rollback

Each phase is independently revertable until its rule-tightening PR. Once
rules are tight on a collection, the previous client can no longer write to
it — that step is deliberately last. Past that point, the fix is forward
(patch the API, redeploy), not backward.

## 11. Traceability

Three artefacts; each answers a different question.

| Artefact | Path | Question it answers |
|---|---|---|
| Spec doc (this file) | `docs/superpowers/specs/2026-04-24-fling-rewrite-design.md` | "What did we decide and why?" |
| STATUS tracker | `docs/superpowers/migrations/STATUS.md` | "Where are we right now?" |
| Per-phase plan | `docs/superpowers/migrations/phase-N-<name>.md` | "What does done look like for the current phase?" |

Conventions:

- The STATUS tracker is updated **in the same PR** that advances a phase. A
  phase moves from `not started → in progress → complete`.
- Per-phase plans are written via the writing-plans skill **just before** the
  phase begins, not all up front. They include: goal, in/out scope, exit
  criteria checklist, dependencies, PR log.
- Phase exit criteria mirror the "Done when" in §10. The phase is not
  complete until every criterion is checked off in its phase plan and STATUS
  is updated.
- The spec doc itself is immutable once approved; subsequent design changes
  are recorded as ADRs in `docs/superpowers/decisions/` and linked from the
  affected section.

## 12. Open decisions explicitly deferred

These are decisions we have *deliberately* deferred. Each comes back when
its trigger fires.

| Decision | Trigger to revisit |
|---|---|
| Pagination on list/item endpoints | First user with >200 items in a list |
| Splitting `api` into multiple Functions deployments | Cold-start latency becomes user-visible |
| Replace `shared_preferences` queue with `drift`/`hive_ce` | Queue size routinely >100 entries |
| Promote tags to first-class collection | Tag rename or autocomplete is requested |
| Build manual ordering / aisle grouping | First user request, or AI grouping work begins |
| Build catalog items | Recipes work begins, or price-tracking work begins |
| Per-PR preview Firebase projects | Multiple overlapping PRs cause shared-staging conflicts |
| Activity feed UI | First user request |

## 13. Glossary

- **Household** — the tenant. Users belong to one or more households; data
  belongs to exactly one household.
- **Member** — a user's relationship to a household, with a role.
- **Owner** — the member with `role: 'owner'`. First creator by default;
  transferable via API.
- **Invite** — a first-class document representing a pending membership for
  an email address. May predate the invitee's signup.
- **List** — a stateful collection of items with lifecycle (checked / not).
- **Template** — a stateless collection of items, applied to lists to seed
  them.
- **Event** — an append-only domain fact emitted by a service after a
  successful write, consumable by other features.
- **RequestContext** — `{ uid, householdId, requestId }` threaded through
  every service call. Makes "did I scope this query?" a structural concern.
- **Idempotency-Key** — client-generated key on POSTs; lets the server dedupe
  retries.

## 14. Naming conventions

| Concern | Convention |
|---|---|
| Firestore field names | `snake_case` (`created_at`, `current_household_id`) |
| Dart / TypeScript field names | `camelCase` (`createdAt`, `currentHouseholdId`) |
| Firestore collection names | plural `snake_case` (`households`, `template_items`) |
| Event kinds | `dot.path.verb.vN` (`list.item.created.v1`) |
| Error codes | `SCREAMING_SNAKE_CASE` (`FORBIDDEN`, `IDEMPOTENCY_CONFLICT`) |
| Routes | `/v1/<plural-resource>/{id}/<sub-resource>`; actions as `:verb` suffix |
| Migration files | `NNN-description.ts` (`001-add-user-audit-fields.ts`) |
