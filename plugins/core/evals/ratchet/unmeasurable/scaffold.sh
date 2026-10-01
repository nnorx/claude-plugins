# The web fixture plus an eslint bulk-suppressions baseline at the repo root,
# where `npx eslint packages/web` in CI finds it. The suppressed patterns are
# really in the code (3 `any` in orders.ts, an unused constant in apiClient.ts),
# so only running eslint could show whether the counts still hold, and eslint
# cannot be installed here: no network. Coverage and the legacy-API check still
# measure fine. The Checkout.tsx entry is the one provably stale entry, since
# that file is deleted. The skill must say it could not measure the rest and
# propose no counts for them.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
web_with_ratchets "      - run: npx eslint packages/web" "$(dirname "$0")/overlay"
