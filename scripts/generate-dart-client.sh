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
