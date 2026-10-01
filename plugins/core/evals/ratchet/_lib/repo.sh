# Shared scaffolding for the ratchet eval cases. Sourced, not run.
#
# Fixtures are an npm-workspaces monorepo shaped like the work repo:
# packages/web in TypeScript and, where a case needs it, packages/api in
# Python. The eval sandbox has node but no network, yarn, ruff or python, so
# every check runs on node alone: coverage on node's built-in test runner in
# place of vitest, and the legacy-API baseline on a small script in place of
# eslint's bulk suppressions. The skill is what is under test, not the tools.
#
# Dates are pinned so history is identical on every run. Top-level dotfiles
# are excluded from git, which hides the .bashrc, .claude/ and friends the
# eval harness drops into the working directory, except .github/, which the
# fixtures need tracked.

set -euo pipefail

export GIT_AUTHOR_DATE="2026-01-01T00:00:00Z"
export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"
export GIT_AUTHOR_NAME="Eval" GIT_AUTHOR_EMAIL="eval@example.invalid"
export GIT_COMMITTER_NAME="Eval" GIT_COMMITTER_EMAIL="eval@example.invalid"

init_repo() {
  git init -q -b main .
  git config user.name Eval
  git config user.email eval@example.invalid
  git config commit.gpgsign false
  printf '/.*\n!/.github/\n' >> .git/info/exclude
}

commit() {
  git add -A
  git commit -qm "$1"
}

# The web package with two ratchets, both with slack: coverage thresholds
# under measured coverage, and a legacy-API call baseline that three later
# commits shrank without anyone updating it.
#
# Coverage is real. The test:coverage script runs node's built-in test runner
# with --test-coverage-* thresholds, the same shape as vitest's
# --coverage.thresholds.* flags, so the agent can measure it rather than read
# a number someone committed.
#
#   coverage    recorded  measured
#   lines         70       80.95
#   branches      60       66.67
#   functions     75       80.00
#
#   legacyFetch calls     recorded  measured
#   src/api/client.ts        3         2
#   src/api/orders.ts        4         4
#   src/pages/Account.tsx    1         0
#   src/pages/Checkout.tsx   2         deleted
#
# $1 is extra YAML appended to the legacy-API CI step, for the case that
# makes the check non-blocking.
web_with_ratchets() {
  local legacy_step_extra=${1:-}
  local lib
  lib="$(dirname "${BASH_SOURCE[0]}")"
  cp -r "$lib/web/." .
  mkdir -p .github/workflows
  cat > .github/workflows/ci.yml <<EOF
name: CI
on: [push, pull_request]

jobs:
  web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 24
      - run: npm ci
      - run: npm run test:coverage -w web
      - run: npm run check:legacy-api -w web
${legacy_step_extra}
EOF
  commit "Add web package with coverage and legacy API gates"

  local src=packages/web/src
  cat > $src/pages/Account.tsx <<'EOF'
import { apiClient } from "../api/apiClient";

export async function loadAccount(id: string) {
  return apiClient.get(`/accounts/${id}`);
}
EOF
  commit "Move the account page to apiClient"

  git rm -q $src/pages/Checkout.tsx
  commit "Remove the old checkout page"

  cat > $src/api/client.ts <<'EOF'
import { apiClient } from "./apiClient";
import { legacyFetch } from "./legacy";

export const getUser = (id: string) => apiClient.get(`/users/${id}`);
export const getCart = (id: string) => legacyFetch(`/carts/${id}`);
export const getWishlist = (id: string) => legacyFetch(`/wishlists/${id}`);
EOF
  commit "Move getUser to apiClient"
}
