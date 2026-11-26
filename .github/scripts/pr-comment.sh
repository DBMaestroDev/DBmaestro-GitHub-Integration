#!/usr/bin/env bash
# Posts (or updates) one DBmaestro comment on the pull request with the results dbmaestro.sh collected.
#   .github/scripts/pr-comment.sh <pr-number>        needs GH_TOKEN (the workflow's GITHUB_TOKEN)
set -euo pipefail

PR=$1
RESULTS="$RUNNER_TEMP/dbmaestro-results.md"
MARKER="<!-- dbmaestro-precheck -->"
API="$GITHUB_API_URL/repos/$GITHUB_REPOSITORY"
RUN_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
LINK="${DBMAESTRO_UI_URL:-}/project/${DBMAESTRO_PROJECT_ID:-}/pipeline"

if [ ! -s "$RESULTS" ]; then
  rows="| — | — | ❌ DBmaestro did not return a result | see the [workflow run]($RUN_URL) |"
else
  rows=$(cat "$RESULTS")
fi

if grep -q "⛔\|❌" <<<"$rows"; then
  headline="**DBmaestro stopped this change.** Fix it before merging."
elif grep -q "warning" <<<"$rows"; then
  headline="**DBmaestro accepted this change, with policy warnings.** Review them before merging. The same rules may block it in Production."
else
  headline="**DBmaestro accepted this change.** On merge it is released to Release_Source → QA → Prod (with approval)."
fi

body=$(cat <<EOF
$MARKER
## DBmaestro precheck · \`$DBMAESTRO_PROJECT_NAME\`

$headline

| Package | Step | Result | Details |
|---|---|---|---|
$rows

[Workflow run]($RUN_URL) · [Open in DBmaestro]($LINK) · commit \`${GITHUB_SHA:0:7}\`
EOF
)

hdr=(-H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json")
existing=$(curl -fsS "${hdr[@]}" "$API/issues/$PR/comments?per_page=100" \
  | jq -r --arg m "$MARKER" '[.[] | select(.body | startswith($m))][0].id // empty')

payload=$(jq -n --arg b "$body" '{body: $b}')
if [ -n "$existing" ]; then
  curl -fsS -X PATCH "${hdr[@]}" "$API/issues/comments/$existing" -d "$payload" > /dev/null && echo "updated comment $existing"
else
  curl -fsS -X POST "${hdr[@]}" "$API/issues/$PR/comments" -d "$payload" > /dev/null && echo "posted comment"
fi
