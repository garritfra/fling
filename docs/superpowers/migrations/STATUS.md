# Fling Rewrite — Migration Status

> Live tracker. Updated **in the same PR** that advances a phase.
>
> Source of truth for "where are we right now?" in the rewrite.

- **Spec:** [`docs/superpowers/specs/2026-04-24-fling-rewrite-design.md`](../specs/2026-04-24-fling-rewrite-design.md)
- **Last updated:** 2026-05-07 (Phase 1 Slice 3 backend + Flutter complete on branch; rule-tighten deferred behind app rollout)

## Status legend

- ⬜ Not started
- 🟡 In progress
- ✅ Complete
- ⏸ Blocked
- ⛔ Cancelled

## Overview

| Phase | Name | Goal (one line) | Status | Plan | Started | Completed |
|---|---|---|---|---|---|---|
| 0 | Foundation | All scaffolding (CI, deps, lint boundaries, empty Hono app, emulator, migrations runner). No user-visible change. | ✅ | [phase-0-foundation.md](./phase-0-foundation.md) | 2026-04-24 | 2026-04-26 |
| 1 | `me` slice + API foundation | First end-to-end vertical slice. Replaces `setupUser` / `deleteUser`. | 🟡 | [phase-1-me-slice.md](./phase-1-me-slice.md) | 2026-04-30 | — |
| 2 | Households + members + invites | New first-class invite flow. Replaces `cacheJoinHousehold` / `cacheLeaveHousehold` / `inviteToHouseholdByEmail`. | ⬜ | _not yet written_ | — | — |
| 3 | Lists | All list and item mutations through API. Offline queue + optimistic updates wired up. | ⬜ | _not yet written_ | — | — |
| 4 | Templates | Same pattern as lists. `:applyTemplate` action live. | ⬜ | _not yet written_ | — | — |
| 5 | Events bus + cross-cutting | Internal wiring. Every service emits events. Data export and cascading account delete shipped. | ⬜ | _not yet written_ | — | — |
| 6 | Compaction | Drop legacy fields, remove dual-write code, delete v1 functions. | ⬜ | _not yet written_ | — | — |

## Per-phase exit criteria

Each phase is **complete** only when every box below is checked. The boxes
mirror the "Done when" of §10 of the spec. Per-phase plan documents (created
just before each phase begins) link back to these.

### Phase 0 — Foundation

- [x] `firestore.rules` committed mirroring current behaviour
- [x] CI workflow runs `backend`, `flutter`, `contracts` jobs on PRs
- [x] Firebase emulator boots locally via `scripts/dev.sh`
- [x] `functions/` includes Hono + Vitest + `@hono/zod-openapi`; empty `api` function deployed
- [x] Flutter deps added: `flutter_riverpod`, `freezed`, `json_serializable`, `go_router`, `connectivity_plus`, `shared_preferences`
- [x] `core/` and `features/` directories scaffolded in both backend and Flutter
- [x] Lint boundary rule active (backend: `eslint-plugin-boundaries`; Flutter: `scripts/check-flutter-imports.sh` — grep-based stand-in because no published `import_lint` version is compatible with Flutter 3.35.6 / Dart 3.9.2. Migrate to `import_lint` when Flutter is bumped past Dart 3.10.)
- [x] `migrations/` runner present with empty initial migration
- [x] No user-visible change in production _(deployed 2026-04-26 via `.github/workflows/ci.yml` deploy job; `GET /v1/healthz` returns `{"status":"ok",...}`; Flutter prod app smoke confirmed)_

### Phase 1 — `me` slice + API foundation

- [ ] `core/api/` middleware: auth, idempotency, request_id, structured logging, error mapping
- [ ] OpenAPI generation → Dart client pipeline working end-to-end
- [ ] `core/api/mutation_queue.dart` implemented with optimistic-update overlay
- [ ] Backend `features/me/` complete: `GET /v1/me`, `PATCH /v1/me` (full data export and cascading delete ship in Phase 5)
- [ ] Flutter `features/me/` migrated to vertical slice; old `FlingUser` deleted
- [ ] `setupUser` / `deleteUser` v1 functions replaced by v2 triggers in `features/me/triggers.ts` (deletion behaviour matches today: delete user doc only; cascade lands in Phase 5)
- [ ] Migration #1 deployed: user docs gain `email`, `display_name`, `household_ids`, `current_household_id`, audit fields, `schema_version: 1`
- [ ] Rule tightened: `/users/{uid}` is owner-only read _(deferred — needs a released app version with the new write path widely deployed first; the deployed v0.11.1 still writes `users/{uid}.current_household` directly via `FlingUser.setCurrentHouseholdId`. Lands in a follow-up PR after the rollout is complete.)_

### Phase 2 — Households + members + invites

- [ ] Backend `features/households/` complete (CRUD)
- [ ] Backend `features/members/` complete (list, leave, kick)
- [ ] Backend `features/invites/` complete: create, cancel, accept, list-mine, expire (scheduled job)
- [ ] New invite UX in Flutter: pending invites surface in onboarding
- [ ] `cacheJoinHousehold` / `cacheLeaveHousehold` / `inviteToHouseholdByEmail` v1 functions deleted
- [ ] Migration #2 deployed: members get `role` + `joined_at`; oldest member becomes `owner`; households get audit fields
- [ ] Flutter `features/households/` migrated; old `HouseholdModel` deleted
- [ ] Rules tightened: households + members + invites are read-only for clients

### Phase 3 — Lists

- [ ] Backend `features/lists/` complete: lists CRUD, list-items CRUD, `:bulkDelete`
- [ ] Idempotency on every POST verified by integration test
- [ ] Flutter `features/lists/` migrated; pending-mutations overlay in use
- [ ] Offline queue persists and drains on reconnect
- [ ] Migration #3 deployed: audit + `schema_version` on lists and items
- [ ] Old `FlingListModel` deleted
- [ ] Rules tightened: lists + items are read-only for clients

### Phase 4 — Templates

- [ ] Backend `features/templates/` complete: templates CRUD, template-items CRUD
- [ ] Backend `:applyTemplate` action on list-items live
- [ ] Flutter `features/templates/` migrated
- [ ] Migration #4 deployed: audit + `schema_version` on templates and items
- [ ] Old `FlingTemplateModel` deleted
- [ ] Rules tightened: templates + items are read-only for clients
- [ ] `functions/src/index.ts` legacy callable removed

### Phase 5 — Events bus + cross-cutting

- [ ] `core/events/` publish + subscribe implemented
- [ ] `onEventCreated` trigger fans out to in-process subscribers
- [ ] Every feature service emits its domain events on writes (verified by integration tests)
- [ ] `GET /v1/me:export` ships and returns a JSON bundle with all the caller's data
- [ ] `DELETE /v1/me` ships and cascades through services to remove all user-owned data
- [ ] `onUserDeleted` trigger upgraded to call the cascading delete service
- [ ] Firestore TTL configured for `events/` and `invites/`

### Phase 6 — Compaction

- [ ] Migration #5 deployed: drop `users.current_household` and `users.households` legacy fields
- [ ] Dual-write code in triggers removed
- [ ] `functions/src/` legacy v1 entrypoint removed
- [ ] All `schema_version` values bumped to current
- [ ] No code references legacy field names (verified by grep)

## Change log

A short append-only log of phase transitions. Entries added in the PR that
moves a phase.

| Date | Phase | Transition | PR | Notes |
|---|---|---|---|---|
| 2026-04-24 | — | Spec approved | — | Initial design committed |
| 2026-04-24 | 0 | Started | — | Phase 0 plan published (`phase-0-foundation.md`) |
| 2026-04-24 | 0 | Implementation complete | — | Tasks 1–13 landed on branch `phase-0-foundation`; Task 14 (prod deploy + smoke) pending PR merge |
| 2026-04-26 | 0 | Completed | [#540](https://github.com/garritfra/fling/pull/540) | Deployed via `ci.yml` deploy job; `api` function live at `/v1/healthz`; Flutter prod app smoke confirmed |
| 2026-04-30 | 1 | Started | — | Phase 1 plan published (`phase-1-me-slice.md`) |
| 2026-05-04 | 1 | Slice 1 merged | [#543](https://github.com/garritfra/fling/pull/543) | `GET /v1/me` end-to-end. Tasks 0–7: core middleware (auth, request_id, errors, logger), `features/me/` schemas/repo/service/route, Flutter `Me` model + repo + Riverpod providers + `ProviderScope` bootstrap. Storage shape unchanged. |
| 2026-05-07 | 1 | Slice 2 implementation complete | [#561](https://github.com/garritfra/fling/pull/561) | `PATCH /v1/me` + idempotency middleware + Flutter mutation queue + me writes wired through API. Tasks 8–13. Pending: merge, enable Firestore TTL on `idempotency_keys.expires_at`, prod smoke. |
| 2026-05-07 | 1 | Slice 3 backend + Flutter complete | [#562](https://github.com/garritfra/fling/pull/562) | v2-organised auth triggers (`features/me/triggers.ts`), additive Migration #1 (`001-user-shape`), legacy member triggers dual-write `household_ids`, FlingUser deleted from Flutter. Tasks 15–18. Task 19 (rule tighten) **deferred**: it would break the deployed v0.11.1 client whose `FlingUser.setCurrentHouseholdId` writes `users/{uid}.current_household` directly. Lands in a follow-up PR once v0.12.0 (which uses PATCH /v1/me writes) is widely deployed. Migration #1 itself is fully back-compat — it preserves legacy `households` / `current_household` fields. |
