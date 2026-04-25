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
