# A branch built on another branch whose PR is not merged yet. Its PR has to
# target that branch, so the hand-over is `pr-handoff --base add-parser`,
# and the handoff describes only this branch's own commit.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
cat > README.md <<'MD'
# csvtool

Small CSV utilities. PRs are squash-merged; titles say what changed.
MD
commit "Initial commit"
publish_main

git checkout -qb add-parser
cat > parse.sh <<'SH'
# Splits one CSV line on commas. Quoted fields are not supported yet.
parse_line() { printf '%s\n' "$1" | tr ',' '\n'; }
SH
commit "Add a minimal CSV line parser"
publish_branch add-parser

git checkout -qb add-column-count
cat > count.sh <<'SH'
. ./parse.sh
# Prints how many columns the first line of a file has.
column_count() { head -n 1 "$1" | { read -r line; parse_line "$line" | wc -l; }; }
SH
commit "Add a column count built on the parser"
