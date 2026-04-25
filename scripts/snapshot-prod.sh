#!/usr/bin/env bash
# scripts/snapshot-prod.sh
#
# Capture a rollback-ready snapshot of the production Firebase project state
# BEFORE merging a phase PR that touches firestore rules, indexes, function
# source, or runtime.
#
# This is a manual operations tool, not run in CI. Run it once on your local
# machine right before merging.
#
# Outputs (under `ops/snapshots/<phase>/<UTC_TIMESTAMP>/`, git-ignored):
#   firestore.rules          live ruleset, deploy-able as-is
#   firestore.indexes.json   live index spec, deploy-able as-is
#   functions.metadata.txt   runtime + entryPoint per Cloud Function
#   git-baseline.txt         the origin/main SHA at snapshot time
#   README.md                rollback recipes specific to this snapshot
#
# Also creates and pushes a git tag `pre-<phase>-rollback` pointing at
# `origin/main` so the pre-deploy commit is easy to find later.
#
# Usage:
#   scripts/snapshot-prod.sh --phase phase-0
#   scripts/snapshot-prod.sh --phase phase-1 --project fling-list
#
# Requires: npx (Node), git.
# Optional: gcloud (used for richer function metadata; skipped if absent).

set -euo pipefail

PROJECT="fling-list"
PHASE=""
NO_TAG=0

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --phase)   PHASE="$2";   shift 2 ;;
    --no-tag)  NO_TAG=1;     shift ;;
    -h|--help) usage 0 ;;
    *) echo "unknown arg: $1" >&2; usage 2 ;;
  esac
done

if [ -z "$PHASE" ]; then
  echo "error: --phase is required (e.g. --phase phase-0)" >&2
  usage 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v git >/dev/null; then
  echo "error: git not on PATH" >&2; exit 2
fi
if ! command -v npx >/dev/null; then
  echo "error: npx (Node) not on PATH" >&2; exit 2
fi

TS="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
OUT="ops/snapshots/$PHASE/$TS"
mkdir -p "$OUT"

echo "==> snapshotting project '$PROJECT' for '$PHASE' at $TS"
echo "    output: $OUT"
echo

FB="npx --yes firebase-tools@^13.29.0"

echo "[1/4] firestore rules"
$FB firestore:rules:get "$PROJECT" > "$OUT/firestore.rules"
echo "      $(wc -l < "$OUT/firestore.rules") lines captured"

echo "[2/4] firestore indexes"
$FB firestore:indexes --project "$PROJECT" > "$OUT/firestore.indexes.json"
INDEX_COUNT=$(node -e "const i=require('$OUT/firestore.indexes.json'); console.log((i.indexes||[]).length)" 2>/dev/null || echo "?")
echo "      $INDEX_COUNT composite indexes captured"

echo "[3/4] function metadata"
if command -v gcloud >/dev/null; then
  {
    echo "# Cloud Functions metadata for project=$PROJECT at $TS"
    echo "# Format: name | runtime | entryPoint | region | gen"
    gcloud functions list --project="$PROJECT" \
      --format="csv[no-heading,separator=' | '](name,buildConfig.runtime,buildConfig.entryPoint,environment.locations,environment)" \
      2>/dev/null \
      || echo "# gcloud functions list failed (auth? IAM?)"
  } > "$OUT/functions.metadata.txt"
  echo "      $(grep -cv '^#' "$OUT/functions.metadata.txt" || true) functions captured"
else
  echo "# gcloud not installed; function metadata skipped." > "$OUT/functions.metadata.txt"
  echo "      gcloud not installed; skipped (run 'brew install --cask google-cloud-sdk' to enable)"
fi

echo "[4/4] git baseline + tag"
git fetch origin main >/dev/null 2>&1 || true
BASELINE_SHA=$(git rev-parse origin/main)
{
  echo "origin/main SHA at snapshot time: $BASELINE_SHA"
  echo "snapshot created at:              $TS"
  echo "phase:                            $PHASE"
  echo "project:                          $PROJECT"
} > "$OUT/git-baseline.txt"

TAG="pre-${PHASE}-rollback"
if [ "$NO_TAG" -eq 0 ]; then
  if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "      tag '$TAG' already exists locally; skipping"
  else
    git tag "$TAG" "$BASELINE_SHA"
    if git push origin "$TAG" >/dev/null 2>&1; then
      echo "      tagged origin/main as '$TAG' (pushed)"
    else
      echo "      tagged origin/main as '$TAG' (LOCAL ONLY — push manually if desired)"
    fi
  fi
else
  echo "      --no-tag passed; skipping tag creation"
fi

cat > "$OUT/README.md" <<EOF
# Rollback snapshot — $PHASE @ $TS

Captured before deploying \`$PHASE\` to project \`$PROJECT\`.
Pre-deploy main commit: \`$BASELINE_SHA\` (also tagged \`$TAG\`).

## Restore firestore rules

\`\`\`bash
mkdir -p _restore && cp firestore.rules _restore/firestore.rules
cat > _restore/firebase.json <<'JSON'
{ "firestore": { "rules": "firestore.rules" } }
JSON
( cd _restore && npx --yes firebase-tools@^13.29.0 deploy --only firestore:rules --project $PROJECT --force )
\`\`\`

## Restore firestore indexes

\`\`\`bash
mkdir -p _restore && cp firestore.indexes.json _restore/
cat > _restore/firebase.json <<'JSON'
{ "firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" } }
JSON
cp firestore.rules _restore/   # rules deploy alongside indexes
( cd _restore && npx --yes firebase-tools@^13.29.0 deploy --only firestore:indexes --project $PROJECT --force )
\`\`\`

Note: dropped composite indexes take **minutes to hours** to rebuild.
Queries depending on them will fail until builds complete.

## Roll back the merge commit (full nuclear)

\`\`\`bash
cd /Users/garrit/src/garritfra/fling
git fetch origin
git checkout main
git revert -m 1 <merge-sha>   # creates a revert commit
git push origin main           # CI redeploys main's prior state
# Then restore rules + indexes from this snapshot using the recipes above
# (revert restores the .json files in the repo, but does NOT recreate
# indexes that Firestore already deleted — only the snapshot can do that).
\`\`\`

## Reset back to the tagged baseline

\`\`\`bash
git checkout main
git reset --hard $TAG
git push --force-with-lease origin main   # WARNING: rewrites history
\`\`\`

Avoid \`--force-with-lease\` unless you accept rewriting shared history.
The \`git revert\` path above is preferred.
EOF

echo
echo "==> snapshot complete"
echo
echo "    $OUT/"
ls -1 "$OUT/" | sed 's/^/      /'
echo
echo "Tag: $TAG -> $BASELINE_SHA"
echo
echo "If something goes wrong after merge, see $OUT/README.md."
