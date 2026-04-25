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
# Requires: gcloud (authed against the project), curl, python3, git.
# Reason: firebase-tools has no command to fetch the live ruleset, so we
# call the Firebase Rules + Firestore Admin REST APIs directly using a
# gcloud user access token. firebase-tools is not used by this script.

set -euo pipefail

PROJECT="fling-list"
PHASE=""
NO_TAG=0
GCLOUD_ACCOUNT=""

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --phase)   PHASE="$2";   shift 2 ;;
    --account) GCLOUD_ACCOUNT="$2"; shift 2 ;;
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

for cmd in git gcloud curl python3; do
  if ! command -v "$cmd" >/dev/null; then
    echo "error: $cmd not on PATH" >&2; exit 2
  fi
done

ACCOUNT_FLAG=()
if [ -n "$GCLOUD_ACCOUNT" ]; then
  ACCOUNT_FLAG=(--account="$GCLOUD_ACCOUNT")
fi

if ! TOKEN=$(gcloud auth print-access-token "${ACCOUNT_FLAG[@]}" 2>/dev/null); then
  echo "error: gcloud auth print-access-token failed. Run 'gcloud auth login' or pass --account <email>." >&2
  exit 2
fi

api() {
  # api <url>
  curl -fsS \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-Goog-User-Project: $PROJECT" \
    "$1"
}

TS="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
OUT="ops/snapshots/$PHASE/$TS"
mkdir -p "$OUT"

echo "==> snapshotting project '$PROJECT' for '$PHASE' at $TS"
echo "    output: $OUT"
echo

echo "[1/4] firestore rules"
RULESET=$(api "https://firebaserules.googleapis.com/v1/projects/$PROJECT/releases/cloud.firestore" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['rulesetName'])")
api "https://firebaserules.googleapis.com/v1/$RULESET" \
  | python3 -c "import json,sys; d=json.load(sys.stdin)
for f in d['source']['files']: print(f['content'], end='')" \
  > "$OUT/firestore.rules"
echo "      $(wc -l < "$OUT/firestore.rules") lines captured (ruleset: $(basename "$RULESET"))"

echo "[2/4] firestore indexes"
api "https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/collectionGroups/-/indexes" \
  | python3 -c "
import json, sys
raw = json.load(sys.stdin).get('indexes', [])
out = []
for ix in raw:
    fields = []
    for f in ix.get('fields', []):
        # __name__ is implicit in firestore.indexes.json format; strip it.
        if f.get('fieldPath') == '__name__':
            continue
        entry = {'fieldPath': f['fieldPath']}
        if 'order' in f: entry['order'] = f['order']
        if 'arrayConfig' in f: entry['arrayConfig'] = f['arrayConfig']
        fields.append(entry)
    out.append({
        'collectionGroup': ix['name'].split('/collectionGroups/')[1].split('/')[0],
        'queryScope': ix.get('queryScope', 'COLLECTION'),
        'fields': fields,
    })
print(json.dumps({'indexes': out, 'fieldOverrides': []}, indent=2))
" > "$OUT/firestore.indexes.json"
INDEX_COUNT=$(python3 -c "import json; print(len(json.load(open('$OUT/firestore.indexes.json'))['indexes']))")
echo "      $INDEX_COUNT composite indexes captured"

echo "[3/4] function metadata (Cloud Functions v1 + v2)"
{
  echo "# Cloud Functions metadata for project=$PROJECT at $TS"
  echo "# Captured via 'gcloud functions list'"
  echo
  gcloud functions list --project="$PROJECT" \
    --format="table(name,state,buildConfig.runtime,buildConfig.entryPoint,buildConfig.source.storageSource.bucket)" \
    "${ACCOUNT_FLAG[@]}" 2>&1 \
    || echo "# gcloud functions list failed (auth? IAM? unsupported region?)"
} > "$OUT/functions.metadata.txt"
echo "      $(grep -cv '^#' "$OUT/functions.metadata.txt" 2>/dev/null || echo 0) lines captured"

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
