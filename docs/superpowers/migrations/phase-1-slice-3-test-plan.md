# Phase 1 Slice 3 — Test Plan

Local verification steps for [PR #562](https://github.com/garritfra/fling/pull/562) before merge.

**What's in scope:** v2 auth triggers, Migration #1, dual-write member triggers, FlingUser deletion in Flutter.

**What's NOT in scope:** rule-tighten on `/users/{uid}` (deferred — see STATUS.md change-log entry).

---

## TL;DR

```bash
cd /Users/garrit/.superset/worktrees/fling/migration-next-steps-with-superpowers

# 1. Automated checks — same set CI runs
( cd functions && npm install ) # if not already
( cd functions && npm run lint && npm run build )
firebase emulators:exec --project fling-rules-test --only firestore,auth \
  "cd functions && npx vitest run"
flutter pub get
flutter analyze --no-fatal-infos
flutter test
bash scripts/check-flutter-imports.sh

# 2. Manual smoke against the emulator (instructions below)
bash scripts/dev.sh   # one terminal — keeps emulators alive
flutter run -d chrome --dart-define=FLING_USE_EMULATORS=true   # other terminal

# 3. Migration smoke against the emulator (instructions below)
```

Expected pass rates: backend `50/50`, Flutter `13/13`, analyzer 5 pre-existing info-level findings, boundaries OK.

---

## 1. Automated checks

Run from the worktree root.

### Backend

```bash
cd functions
npm install                                    # first time only
npm run lint                                   # eslint, 1 pre-existing max-len warning
npm run build                                  # tsc, must be silent
cd ..

firebase emulators:exec --project fling-rules-test --only firestore,auth \
  "cd functions && npx vitest run"
# Expect: "Test Files 12 passed (12)", "Tests 50 passed (50)"
```

The new files in scope are checked specifically by:

```bash
firebase emulators:exec --project fling-rules-test --only firestore,auth \
  "cd functions && npx vitest run \
     test/features/me/triggers.test.ts \
     test/migrations/001-user-shape.test.ts"
# Expect: 5 tests passed
```

### Flutter

```bash
flutter pub get
flutter analyze --no-fatal-infos               # 5 pre-existing info-level findings
flutter test                                   # 13/13
bash scripts/check-flutter-imports.sh          # "Flutter import-boundaries OK."
```

---

## 2. Manual smoke against the emulator

This verifies the new client (FlingUser deleted, consumers on Riverpod) end-to-end, and that the v2 auth triggers correctly create / delete user docs.

### 2.1 Boot the emulator suite

```bash
bash scripts/dev.sh
```

This builds the functions and starts firestore + auth + functions + hosting + UI.

Open the **Emulator UI** at <http://127.0.0.1:4000>. Keep the tab open — you'll be inspecting Firestore + Auth records here.

### 2.2 Run the Flutter app against the emulator

In a separate terminal, from the worktree root:

```bash
flutter run -d chrome --dart-define=FLING_USE_EMULATORS=true
```

(`-d chrome` is convenient for click-around testing; any debug target works as long as the emulator host is reachable.)

### 2.3 Smoke matrix

For each row, perform the action in the running app, then verify the side-effect via the Emulator UI.

| # | Action | Expected (UI) | Expected (Firestore Emulator UI) | Expected (Auth Emulator UI) |
|---|---|---|---|---|
| 1 | Sign up a brand-new user (`alice@example.com`) | Lands on the Lists page with empty-households state | A `users/<uid>` doc appears with: `email = "alice@example.com"`, `display_name = null`, `household_ids = []`, `current_household_id = null`, **legacy:** `households = []`, `current_household = null`, `schema_version = 1`, `created_at`, `updated_at`, `created_by_uid = <uid>` | `alice@example.com` listed |
| 2 | Tap "Create household" → name "Home" → submit | List view re-renders, AppBar shows "Lists" | New `households/<hid>` doc; `households/<hid>/members/<uid>` doc; `users/<uid>` now has both `current_household_id = <hid>` AND legacy `current_household = <hid>`; `household_ids = [<hid>]` AND legacy `households = [<hid>]` | unchanged |
| 3 | Add a list "Groceries" → tap → add an item "Bread" | Item appears under the list | `households/<hid>/lists/<lid>` and a list-item doc | unchanged |
| 4 | Open drawer → switch / add a 2nd household ("Other") | Switcher dialog reactive; second household selectable | Same dual-write pattern; both `current_household_id` and `current_household` flip to the new id | unchanged |
| 5 | Drawer → Info → Account delete → confirm | Routes back to login | `users/<uid>` doc is gone (v2 `onUserDeleted` fired) | `alice@example.com` is gone |

If any "legacy" field is missing on rows 1, 2, 4 → **dual-write is broken**. That's a regression in either the v2 trigger (`functions/src/features/me/repo.ts:createUserDoc`) or PATCH /v1/me (`patchUserDoc`).

### 2.4 PATCH /v1/me visible in functions logs

While doing row 4 (household switch), watch the functions log pane in the Emulator UI. You should see a `PATCH /v1/me` line with a `request_id` and the caller's `uid`. If you don't, the new client is not actually going through the API — check `lib/features/me/data/me_repository.dart` and `lib/core/firebase/emulators.dart`.

---

## 3. Migration smoke against the emulator

This verifies Migration #1 is idempotent, additive, and back-fills the right shape on real legacy-shape docs.

### 3.1 Seed legacy-shape data

With the emulator suite running (from §2.1), open a fresh terminal:

```bash
cd functions
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
GCLOUD_PROJECT=fling-list \
npx tsx -e '
  import {initializeApp} from "firebase-admin/app";
  import {getAuth} from "firebase-admin/auth";
  import {getFirestore} from "firebase-admin/firestore";
  initializeApp({projectId: "fling-list"});
  const db = getFirestore();
  const auth = getAuth();
  await auth.createUser({uid: "legacy-1", email: "legacy1@example.com"});
  await auth.createUser({uid: "legacy-2", email: "legacy2@example.com"});
  await db.doc("users/legacy-1").set({households: ["h1", "h2"], current_household: "h1"});
  await db.doc("users/legacy-2").set({households: []});               // no current_household
  await db.doc("users/orphan").set({households: ["h3"]});              // no auth user
  console.log("seeded");
'
```

Verify in the Emulator UI that the three docs exist with **only** the legacy fields.

### 3.2 Run the migration

```bash
cd functions
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
GCLOUD_PROJECT=fling-list \
npm run migrate
# Expect:
#   [migrate] skip 000-initial (already applied)   ← if you've run before
#   [migrate] apply 001-user-shape
#   [migrate] done  001-user-shape
```

Re-run immediately:

```bash
GCLOUD_PROJECT=fling-list npm run migrate
# Expect: only "skip" lines. Idempotent.
```

### 3.3 Verify shape

Open the three docs in the Emulator UI. Each should now show:

| Doc | New fields | Legacy fields (preserved) |
|---|---|---|
| `users/legacy-1` | `email = "legacy1@example.com"`, `household_ids = ["h1","h2"]`, `current_household_id = "h1"`, `schema_version = 1`, `created_at`, `updated_at`, `created_by_uid = "legacy-1"`, `display_name = null` | `households = ["h1","h2"]`, `current_household = "h1"` |
| `users/legacy-2` | `email = "legacy2@example.com"`, `household_ids = []`, `current_household_id = null`, `schema_version = 1`, audit fields | `households = []` |
| `users/orphan` | `email = null` (no auth record), `household_ids = ["h3"]`, `current_household_id = null`, `schema_version = 1`, audit fields | `households = ["h3"]` |

**If any legacy field changed**, the migration is destructive — block merge.

### 3.4 Cleanup the seed (optional)

```bash
cd functions
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
GCLOUD_PROJECT=fling-list \
npx tsx -e '
  import {initializeApp} from "firebase-admin/app";
  import {getAuth} from "firebase-admin/auth";
  import {getFirestore} from "firebase-admin/firestore";
  initializeApp({projectId: "fling-list"});
  for (const uid of ["legacy-1", "legacy-2", "orphan"]) {
    await getFirestore().doc(`users/${uid}`).delete();
    try { await getAuth().deleteUser(uid); } catch {}
  }
'
```

Or just stop the emulator without `--export-on-exit` overwriting the saved state.

---

## 4. Back-compat with v0.11.1 (the deployed app)

The current `firestore.rules` is **unchanged** in this PR (rule-tighten was deferred). Verify the legacy write paths still work.

### 4.1 Simulate v0.11.1's "switch household" via direct Firestore write

This mimics what `FlingUser.setCurrentHouseholdId` does in v0.11.1 — direct Firestore update, no API call.

With the emulator running:

```bash
cd functions
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
GCLOUD_PROJECT=fling-list \
npx tsx -e '
  import {initializeApp} from "firebase-admin/app";
  import {getFirestore} from "firebase-admin/firestore";
  initializeApp({projectId: "fling-list"});
  // Simulate the v0.11.1 client write — using the admin SDK here for ease,
  // but the operation is identical to what the rules would evaluate for a
  // signed-in client writing their own /users/{uid} doc.
  await getFirestore().doc("users/legacy-1").update({current_household: "h2"});
  console.log("legacy write succeeded");
  const data = (await getFirestore().doc("users/legacy-1").get()).data();
  console.log("current_household_id:", data?.current_household_id);
  console.log("current_household:   ", data?.current_household);
'
```

Expected: `legacy write succeeded`. **`current_household` is now `"h2"`.** `current_household_id` is still `"h1"` (legacy clients don't dual-write — that's the gap the rule-tighten + v0.12.0 release closes later).

### 4.2 Verify the new client reads the legacy field correctly

After the legacy write in §4.1, in the running new-client app (§2.2), the household-switcher should reflect `h2` as active because `me_repository.dart` uses `current_household_id ?? current_household` as a fallback. If it doesn't, the read path's legacy fallback is broken — check `functions/src/features/me/repo.ts:readUserDoc` and `lib/features/me/data/me_repository.dart`.

(Note: this only proves the read fallback. The full v0.11.1 ↔ new client interleave story is: the **legacy** write doesn't update the new field, but the new client still reads the right value because of the fallback chain. After v0.12.0 ships and rule-tighten lands, all writes go through PATCH /v1/me which dual-writes.)

### 4.3 Verify v2 trigger replaces v0.11.1's sign-up `set({})`

In the running emulator, sign up a new user via the new client. Then check the Emulator UI's Firestore: there's exactly **one** write to `users/<new-uid>` — from `onUserCreated` — with the full new shape. There's no race or duplicate empty `set({})` overwrite.

If you see two writes (one full, one `set({})` with no fields), the FlingUser deletion in `lib/data/user.dart` was incomplete — search for any remaining `firestore.collection("users").doc(...).set({})` call.

---

## 5. Post-merge / pre-prod checklist

Run on the merged commit, after CI deploy ships to `fling-list`:

- [ ] `firebase deploy --only functions` succeeded (CI deploy job in green)
- [ ] One-time: enable Firestore TTL on `idempotency_keys.expires_at` (Slice 2 leftover):
      ```
      gcloud firestore fields ttls update expires_at \
        --collection-group=idempotency_keys --enable-ttl --project=fling-list
      ```
- [ ] Run Migration #1 against prod once:
      ```
      cd functions && GCLOUD_PROJECT=fling-list npm run migrate
      ```
      Expected: `[migrate] apply 001-user-shape` then `[migrate] done 001-user-shape`. Re-runs print only `skip`.
- [ ] Spot-check 3 user docs in the Firebase console for `schema_version: 1`, `email`, `household_ids`, `current_household_id`, audit fields. Legacy `households` / `current_household` still present.
- [ ] In the prod web app on the new build: sign up → switch household → confirm `PATCH /v1/me` appears in Cloud Logs and both `current_household_id` AND `current_household` are written.
- [ ] In the prod web app on **v0.11.1**: log in → switch household → confirm it still works (the rule isn't tightened yet; legacy direct writes succeed).
- [ ] Sign up a fresh test user → confirm `users/{newUid}` appears with `schema_version: 1` (v2 `onUserCreated` fired).
- [ ] Delete that test user → confirm the doc is removed (`onUserDeleted` fired).

After all green, the only remaining Phase 1 exit criterion is **rule-tighten** — gated on a v0.12.0 release of the new app build reaching the user base. That's a separate small PR, not part of this slice.

---

## Common failure modes

| Symptom | Likely cause | Fix |
|---|---|---|
| `users/{uid}` doc missing legacy fields after sign-up | `createUserDoc` regressed — repo.ts isn't writing dual-shape | Check `functions/src/features/me/repo.ts:createUserDoc` includes `households: []` and `current_household: null` |
| Switching household doesn't update `current_household_id` | `patchUserDoc` not setting both | Same file, `patchUserDoc` should write both keys |
| Migration prints `apply` on second run | Idempotency check broken | Verify `if (data.schema_version === 1) continue` in `migrations/001-user-shape.ts` |
| `npm run migrate` errors on `__name__` ordering | `orderBy("__name__")` requires no other ordering | Pagination cursor must use `startAfter(snapshot)` not a separate `orderBy` |
| New client doesn't show legacy data | `readUserDoc` fallback chain broken | Verify `current_household_id ?? current_household` and `household_ids ?? households` in repo |
| `PATCH /v1/me` not in functions logs | Flutter app pointing at prod, not emulator | Re-launch with `--dart-define=FLING_USE_EMULATORS=true`; check `wireEmulatorsIfEnabled` in `lib/core/firebase/emulators.dart` runs |
