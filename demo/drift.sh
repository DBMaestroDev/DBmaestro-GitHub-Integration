#!/usr/bin/env bash
# Act 3 helper: simulate (or remove) a DBA's hand-made "hotfix" on Release Source.
#   demo/drift.sh add      ALTER TABLE customers ADD COLUMN hotfix_by_dba TEXT   on github_rs
#   demo/drift.sh remove   drop it again
#   demo/drift.sh show     tables and customers columns in every environment
set -euo pipefail
export MSYS_NO_PATHCONV=1

psql_on() {  # psql_on <db> <sql>
  kubectl exec -n dop db-repo-0 -- env PGPASSWORD=dbmtest123 \
    psql -h localhost -U dbmtest -d "$1" -tAc "$2"
}

case "${1:-show}" in
  add)    psql_on github_rs "ALTER TABLE customers ADD COLUMN hotfix_by_dba TEXT;" && echo "drift added on github_rs" ;;
  remove) psql_on github_rs "ALTER TABLE customers DROP COLUMN hotfix_by_dba;"    && echo "drift removed from github_rs" ;;
  show)
    for db in github_rs github_qa github_prod; do
      printf '%-12s tables: %s\n' "$db" "$(psql_on "$db" "SELECT coalesce(string_agg(table_name, ', ' ORDER BY table_name), '-') FROM information_schema.tables WHERE table_schema='public'")"
      printf '%-12s customers: %s\n' "" "$(psql_on "$db" "SELECT coalesce(string_agg(column_name, ', ' ORDER BY ordinal_position), '-') FROM information_schema.columns WHERE table_name='customers'")"
    done ;;
  *) echo "usage: $0 add|remove|show" >&2; exit 2 ;;
esac
