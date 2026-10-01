# Clean history, but with an uncommitted edit to a tracked file. The skill
# must refuse and ask, not stash, autostash, or commit the work for the user.
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

# Matches the global config on Nick's machines, which the eval's sandboxed
# HOME does not see. With it on, a bare `git rebase` stashes the edit silently,
# so the skill's own preflight is the only thing that catches a dirty tree.
git config rebase.autoStash true

echo 'echo "half-finished retry logic"' >> app.sh
