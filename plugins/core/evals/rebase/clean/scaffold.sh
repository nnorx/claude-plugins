# Upstream and the branch touch disjoint files. The rebase is clean, but only
# if it targets the fetched origin/main rather than the stale local one.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
printf '# widget\n\nA small widget service.\n' > README.md
printf '#!/bin/sh\necho "widget up"\n' > app.sh
commit "Initial commit"
publish_main

git checkout -qb feature
printf '#!/bin/sh\necho "healthy"\n' > health.sh
commit "Add health check script"

on_upstream() {
  printf '# Changelog\n\n- Document the widget service\n' > CHANGELOG.md
  commit "Start a changelog"
}
upstream on_upstream
