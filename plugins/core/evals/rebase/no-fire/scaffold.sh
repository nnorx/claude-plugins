# A branch behind main, and a question about it that is not a request to
# rebase. Nothing should move.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
printf '# widget\n\nA small widget service.\n' > README.md
commit "Initial commit"
publish_main

git checkout -qb feature
printf '#!/bin/sh\necho "healthy"\n' > health.sh
commit "Add health check script"
printf '#!/bin/sh\nsleep 1\n' > retry.sh
commit "Add retry helper"

on_upstream() {
  printf '# Changelog\n' > CHANGELOG.md
  commit "Start a changelog"
}
upstream on_upstream
