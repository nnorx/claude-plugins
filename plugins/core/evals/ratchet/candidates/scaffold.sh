# No ratchets anywhere: coverage runs without thresholds, eslint and ruff run
# with no baseline, and nothing counts suppressions. What does exist is debt
# that can grow unnoticed: 7 @ts-expect-error across 4 files in packages/web,
# and 13 `# noqa` across 5 files in packages/api, 2 of them bare.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
cp -r "$(dirname "$0")/../_lib/untracked/." .
commit "Initial monorepo"
