# Ratchets in two packages: the web fixture's two, plus a noqa budget in
# packages/api that allows 16 and measures 13. The report should be grouped by
# package.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
web_with_ratchets
cp -r "$(dirname "$0")/../_lib/untracked/packages/api" packages/
mkdir -p packages/api/scripts
cat > packages/api/scripts/noqa-budget.sh <<'SH'
#!/bin/sh
# Fails when the API carries more `# noqa` comments than its budget allows.
set -eu
cd "$(dirname "$0")/.."
MAX_NOQA=16
count=$(grep -r --include='*.py' -c '# noqa' app | awk -F: '{ s += $2 } END { print s }')
echo "noqa comments: $count (budget $MAX_NOQA)"
[ "$count" -le "$MAX_NOQA" ]
SH
chmod +x packages/api/scripts/noqa-budget.sh
cat >> .github/workflows/ci.yml <<'YAML'

  api:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: packages/api/scripts/noqa-budget.sh
YAML
commit "Add the api package with a noqa budget"
