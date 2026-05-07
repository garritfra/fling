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

# 3) Lift the generated package's Dart SDK lower bound to >=3.0.0 so its
#    language version (and that of its built_value `*.g.dart` parts) matches
#    the parent project's. The generator hardcodes `>=2.18.0`, which gives
#    library files an implicit language version of 2.18 — incompatible with
#    Dart 3 part-file checks once the parent project consumes the package.
#    `-i.bak` is the portable form: GNU sed (CI) and BSD sed (macOS) agree.
sed -i.bak "s|sdk: '>=2.18.0 <4.0.0'|sdk: '>=3.0.0 <4.0.0'|" "$OUT/pubspec.yaml"
rm -f "$OUT/pubspec.yaml.bak"

# 4) Build runner for built_value generated code.
( cd "$OUT" && flutter pub get && dart run build_runner build --delete-conflicting-outputs )
