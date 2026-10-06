# Uncommitted work and a request to commit it, which is not a request for a
# PR. The commit should happen; no handoff, no push.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
cat > README.md <<'MD'
# csvtool

Small CSV utilities.
MD
commit "Initial commit"
publish_main

git checkout -qb readme-usage
cat >> README.md <<'MD'

## Usage

    ./count.sh data.csv    # prints the number of columns
MD
