#!/usr/bin/env bash
# Pushes the three demo branches (no pull requests) so nothing is typed on camera.
# Package numbers are arguments so the script can be re-run after a recording:
#   demo/prepare-branches.sh 6 7 8
# The objects are fixed (loyalty_tier, orders_customer_idx, customers_legacy): before a re-run, roll the
# good and drift packages back (-Rollback -PackageName <n>: this project deploys by tasks, so a rollback
# undoes that one package) so the objects don't already exist. See demo/DEMO-SCRIPT.md, "Reset".
# On GitHub the PR checks run on the PR merge commit, so a branch made before the previous act was merged
# still only shows its own package. No refresh between acts is needed (unlike the GitLab demo).
set -euo pipefail

GOOD=${1:-3}; DRIFT=${2:-4}; DROP=${3:-5}

git switch -q main
git pull -q

make_pkg() {  # make_pkg <version> <branch> <message> <upgrade-sql> <downgrade-sql>
  local v=$1 branch=$2 msg=$3 up=$4 down=$5 f
  f=$(echo "$branch" | tr '[:upper:]' '[:lower:]')     # the CLI lowercases script names
  git switch -q -c "$branch" main
  mkdir -p "packages/V$v/github_rs/Upgrade" "packages/V$v/github_rs/Downgrade"
  printf '%s\n' "$up"   > "packages/V$v/github_rs/Upgrade/01-$f.sql"
  printf '%s\n' "$down" > "packages/V$v/github_rs/Downgrade/01-$f-rollback.sql"
  git add "packages/V$v"
  git commit -q -m "V$v: $msg"
  git push -q -u origin "$branch"
  git switch -q main
  echo "pushed $branch (packages/V$v)"
}

make_pkg "$GOOD" "V$GOOD-customer-loyalty-tier" "add loyalty_tier to customers" \
  "ALTER TABLE customers ADD COLUMN loyalty_tier VARCHAR(20);" \
  "ALTER TABLE customers DROP COLUMN loyalty_tier;"

make_pkg "$DRIFT" "V$DRIFT-orders-customer-index" "index orders by customer" \
  "CREATE INDEX orders_customer_idx ON orders (customer_id);" \
  "DROP INDEX orders_customer_idx;"

make_pkg "$DROP" "V$DROP-retire-customers-legacy" "retire the customers_legacy table" \
  "DROP TABLE customers_legacy;" \
  "CREATE TABLE customers_legacy (id INTEGER PRIMARY KEY, name VARCHAR(100), email VARCHAR(255), migrated_at TIMESTAMP);"
