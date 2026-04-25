#!/usr/bin/env bash
# Flutter import-boundary check.
#
# Enforces (under lib/features/**/):
#   1. presentation/ cannot import its own feature's data/
#   2. application/  cannot import its own feature's presentation/
#   3. features/<A>/ cannot import features/<B>/ (cross-feature direct imports)
#
# Designed for Phase 0 as a lightweight, tool-agnostic replacement for
# `import_lint` (which has no published version compatible with Flutter 3.35.6
# / Dart 3.9.2 / cli_util 0.4.x — see docs/superpowers/migrations/phase-0-foundation.md
# Task 9/10 for the dependency-resolution story).
#
# Usage: scripts/check-flutter-imports.sh
# Exit:  0 if clean, 1 if any violations.
#
# When Flutter is bumped to ship Dart >=3.10, consider migrating to
# `import_lint` (see https://pub.dev/packages/import_lint) for IDE
# integration.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Use POSIX grep (-rlF for recursive list-only fixed-string) so this works
# on stock GitHub Actions Ubuntu runners without installing ripgrep.
grep_imports() {
  # grep_imports <needle> <dir>
  # Echoes matching file paths, one per line; empty if no match.
  grep -rlF --include='*.dart' -- "$1" "$2" 2>/dev/null || true
}

FAIL=0
VIOLATIONS=()

if [ ! -d lib/features ]; then
  echo "lib/features/ not found — nothing to check."
  exit 0
fi

for feature_path in lib/features/*/; do
  [ -d "$feature_path" ] || continue
  feature="$(basename "$feature_path")"

  # Rule 1: presentation -> data within same feature
  if [ -d "${feature_path}presentation" ]; then
    hits=$(grep_imports "package:fling/features/${feature}/data/" "${feature_path}presentation")
    if [ -n "$hits" ]; then
      while IFS= read -r f; do
        VIOLATIONS+=("$f imports package:fling/features/${feature}/data/ (presentation -> data within '${feature}')")
      done <<< "$hits"
      FAIL=1
    fi
  fi

  # Rule 2: application -> presentation within same feature
  if [ -d "${feature_path}application" ]; then
    hits=$(grep_imports "package:fling/features/${feature}/presentation/" "${feature_path}application")
    if [ -n "$hits" ]; then
      while IFS= read -r f; do
        VIOLATIONS+=("$f imports package:fling/features/${feature}/presentation/ (application -> presentation within '${feature}')")
      done <<< "$hits"
      FAIL=1
    fi
  fi

  # Rule 3: cross-feature direct import
  for other_path in lib/features/*/; do
    [ -d "$other_path" ] || continue
    other="$(basename "$other_path")"
    [ "$other" = "$feature" ] && continue
    hits=$(grep_imports "package:fling/features/${other}/" "$feature_path")
    if [ -n "$hits" ]; then
      while IFS= read -r f; do
        VIOLATIONS+=("$f imports package:fling/features/${other}/ (cross-feature: '${feature}' -> '${other}')")
      done <<< "$hits"
      FAIL=1
    fi
  done
done

if [ "$FAIL" -ne 0 ]; then
  echo "Flutter import-boundary violations:" >&2
  printf '  %s\n' "${VIOLATIONS[@]}" >&2
  exit 1
fi

echo "Flutter import-boundaries OK."
