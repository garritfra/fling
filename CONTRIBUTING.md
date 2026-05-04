# Contributing to Fling

## Prerequisites

| Tool | Install |
|------|---------|
| Flutter 3.35+ | https://flutter.dev/docs/get-started/install |
| Node 20 | `brew install node` or via [asdf](https://asdf-vm.com/) / [mise](https://mise.jdx.dev/) (`.tool-versions` is committed) |
| Firebase CLI | `npm i -g firebase-tools` then `firebase login` |
| Java 11+ | Required for the OpenAPI → Dart client generator. `brew install openjdk@21` |
| jq | `brew install jq` — used in test scripts |

---

## Running locally

### 1. Install dependencies

```bash
# Backend
npm ci --no-audit --prefix functions

# Flutter
flutter pub get
```

### 2. Start the Firebase emulators

```bash
./scripts/dev.sh
```

This builds the Cloud Functions (`tsc`) and starts the full emulator suite. Emulator state is persisted to `.emulator-data/` between runs so you keep your test data.

| Service | URL |
|---------|-----|
| Emulator UI | http://localhost:4000 |
| Cloud Functions | http://localhost:5001 |
| Firestore | http://localhost:8080 |
| Auth | http://localhost:9099 |
| Hosting (Flutter web) | http://localhost:5050 |

> **Port conflict on 5050?** macOS reserves 5000 for AirPlay Receiver. If 5050 is also taken, start without hosting: `firebase emulators:start --only auth,functions,firestore`

### 3. Run the Flutter app against the emulators

In a second terminal:

```bash
flutter run -d chrome \
  --dart-define=FLING_API_BASE_URL=http://localhost:5001/fling-list/us-central1/api
```

The app will talk to the local emulators for both Firestore realtime reads and the REST API.

---

## Testing the REST API locally

### Get a test token

Sign up via the Auth emulator and grab an ID token in one step:

```bash
TOKEN=$(curl -s -X POST \
  "http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password","returnSecureToken":true}' \
  | jq -r .idToken)
echo "Token acquired"
```

### Hit the API

```bash
# Health check (no auth required)
curl -s http://localhost:5001/fling-list/us-central1/api/v1/healthz | jq

# Get your user profile
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:5001/fling-list/us-central1/api/v1/me | jq

# Update display name
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"displayName":"Test User"}' \
  http://localhost:5001/fling-list/us-central1/api/v1/me | jq
```

### Browse the OpenAPI docs

The live OpenAPI spec is served by the running emulator:

```
http://localhost:5001/fling-list/us-central1/api/v1/openapi.json
```

Paste it into https://editor.swagger.io or any OpenAPI viewer.

---

## Running tests

### Backend (unit + lint)

```bash
cd functions
npm run lint       # ESLint
npm run build      # tsc
npm test           # Vitest unit tests (no emulator needed)
```

### Backend (integration + rules tests — needs emulator)

```bash
# Starts emulator, runs the tests, stops emulator
firebase emulators:exec --project fling-rules-test --only firestore,auth \
  "cd functions && npx vitest run test/rules test/api test/features test/core/middleware"
```

### Flutter

```bash
flutter analyze    # Dart static analysis
flutter test       # Unit + widget tests (no emulator needed)
```

### All at once (mirrors CI)

```bash
# Backend
( cd functions && npm run lint && npm run build && npm test )

# Flutter
flutter analyze && flutter test
```

---

## Database migrations

Migrations live in `functions/migrations/`. Each file exports a `Migration` object with an `up()` function. The runner tracks applied migrations in `_migrations/{id}` in Firestore.

```bash
# Run pending migrations against the local emulator
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=fling-list \
  npm --prefix functions run migrate

# Run against production (requires Firebase login with deploy permissions)
npm --prefix functions run migrate
```

---

## Regenerating the Dart API client

The client in `lib/core/api/generated/` is generated from the OpenAPI spec. Regenerate it whenever backend schemas change:

```bash
./scripts/generate-dart-client.sh
```

This runs three steps: (1) regenerates `openapi/openapi.json` from the Hono app, (2) runs `openapi-generator-cli` to produce the Dart client, (3) runs `build_runner` for the `built_value` generated code. The output is committed — CI fails if it drifts.

---

## Architecture overview

See [`docs/superpowers/specs/2026-04-24-fling-rewrite-design.md`](docs/superpowers/specs/2026-04-24-fling-rewrite-design.md) for the full design spec.

**Short version:**

- All writes go through the REST API (`functions/src/features/*/routes.ts`). Firestore security rules deny client writes.
- Reads stream directly from Firestore (realtime collaboration + offline cache).
- Each feature is a vertical slice under `functions/src/features/<name>/` (backend) and `lib/features/<name>/` (Flutter).
- The layering rule is `routes → service → repo → Firestore`. Cross-feature interaction uses the events bus (`core/events/`).

**Migration progress:** [`docs/superpowers/migrations/STATUS.md`](docs/superpowers/migrations/STATUS.md)
