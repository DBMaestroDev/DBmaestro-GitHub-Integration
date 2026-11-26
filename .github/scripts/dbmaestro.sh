#!/usr/bin/env bash
# Runs one DBmaestro CI/CD library step and reports DBmaestro's verdict on the GitHub console.
#
#   .github/scripts/dbmaestro.sh <create-package|precheck-package|upgrade-environment> <package>
#
# The step itself is the library's core script (dbmaestro-cicd/core/scripts/sh/<step>.sh, checked out
# at v1), configured through the DBMAESTRO_* environment variables like the library's own actions.
# This wrapper only adds the GitHub side:
#   - ::error:: / ::warning:: annotations for policy violations, drift and failures (run page + PR checks)
#   - a row in the job summary
#   - a line in $RUNNER_TEMP/dbmaestro-results.md, which pr-comment.sh posts on the pull request
set -uo pipefail

STEP=$1; PKG=$2
LIB="$GITHUB_WORKSPACE/dbmaestro-cicd/core/scripts/sh"
ENV_LABEL=${DBMAESTRO_TARGET_ENV:-}
LOG=$(mktemp)
RESULTS="$RUNNER_TEMP/dbmaestro-results.md"

case "$STEP" in
  create-package)      WHAT="Package created in DBmaestro" ;;
  precheck-package)    WHAT="Precheck" ;;
  upgrade-environment) WHAT="Deploy to $ENV_LABEL" ;;
  *) echo "unknown step $STEP" >&2; exit 2 ;;
esac

echo "::group::DBmaestro $STEP $PKG ${ENV_LABEL}"
bash "$LIB/$STEP.sh" 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
echo "::endgroup::"

# Strip the CLI's "FINE 2026/11/26 02:24:56 " prefixes and keep the message.
clean() { sed -E 's/^(FINE|INFO|SEVERE|WARNING) [0-9\/]+ [0-9:]+ //; s/\r$//' "$LOG"; }

# Policy Engine lines look like:  Block: 'Data Loss Risk', 'Drop Table is not allowed', 'Contains Drop Table'
mapfile -t BLOCKS   < <(clean | grep -oE "Block: .*"   | sort -u)
mapfile -t WARNINGS < <(clean | grep -oE "Warning: '.*" | sort -u)
mapfile -t SCRIPTS  < <(clean | grep -oE "In Script [^,]+" | sed 's/In Script //' | sort -u)
DRIFT=$(clean | grep -E "Pre-Validation|[Dd]rift" | head -3)
ERRORS=$(clean | grep -iE "SEVERE|ERROR|failed" | grep -vE "Block:|Warning:" | head -5)
SCRIPT_TXT=${SCRIPTS[*]:-}

title="DBmaestro · $PKG · $WHAT"
for b in "${BLOCKS[@]}";   do echo "::error title=$title — blocked by policy::$b ${SCRIPT_TXT:+(script: $SCRIPT_TXT)}"; done
for w in "${WARNINGS[@]}"; do echo "::warning title=$title — policy warning::$w ${SCRIPT_TXT:+(script: $SCRIPT_TXT)}"; done

if [ "$rc" -eq 0 ]; then
  if [ ${#WARNINGS[@]} -gt 0 ]; then verdict="✅ Passed with ${#WARNINGS[@]} policy warning(s)"; else verdict="✅ Passed"; fi
elif [ ${#BLOCKS[@]} -gt 0 ]; then
  verdict="⛔ Blocked by DBmaestro Policy Engine"
elif [ -n "$DRIFT" ]; then
  verdict="⛔ Drift detected: $ENV_LABEL no longer matches what DBmaestro last deployed"
  echo "::error title=$title — drift detected::$ENV_LABEL was changed outside the release pipeline. DBmaestro stopped the deployment before touching it. $(echo "$DRIFT" | head -1)"
else
  verdict="❌ Failed"
  echo "::error title=$title — failed::$(echo "${ERRORS:-see the job log}" | tail -1)"
fi

details=""
for b in "${BLOCKS[@]}";   do details+="⛔ \`$b\`<br>"; done
for w in "${WARNINGS[@]}"; do details+="⚠️ \`$w\`<br>"; done
[ -n "$SCRIPT_TXT" ] && [ -n "$details" ] && details+="in \`$SCRIPT_TXT\`<br>"
[ -n "$DRIFT" ] && [ "$rc" -ne 0 ] && details+="🔍 \`$(echo "$DRIFT" | head -1 | tr '|' '/')\`<br>"

link="${DBMAESTRO_UI_URL:-}/project/${DBMAESTRO_PROJECT_ID:-}/pipeline"
if [ ! -s "$GITHUB_STEP_SUMMARY" ] || ! grep -q "^| Package | Step" "$GITHUB_STEP_SUMMARY"; then
  {
    echo "### DBmaestro · project [$DBMAESTRO_PROJECT_NAME]($link)"
    echo
    echo "| Package | Step | Result | Details |"
    echo "|---|---|---|---|"
  } >> "$GITHUB_STEP_SUMMARY"
fi
row="| **$PKG** | $WHAT | $verdict | ${details:-—} |"
echo "$row" >> "$GITHUB_STEP_SUMMARY"
echo "$row" >> "$RESULTS"

rm -f "$LOG"
exit "$rc"
