# Shared scaffolding for the pr-handoff eval cases. Sourced, not run.
#
# Every case is a working repo on a feature branch, with a bare `origin` in
# .eval/ whose main is the default branch. origin is a local path, so a push
# from the agent would succeed: the cases grade that it never tries, which is
# the skill's first rule. gh cannot authenticate in the eval sandbox, which
# has no network, so the skill's "does this apply" check fails as it does in
# a real sandbox.
#
# Every top-level dotfile is listed in .git/info/exclude, which covers .eval/
# and the .bashrc, .claude/ and friends that the eval harness drops into the
# working directory. The handoff files the skill writes live under .git/, so
# they are never in the tree either way.

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
  mkdir -p .eval
  echo "/.*" >> .git/info/exclude
}

commit() {
  git add -A
  git commit -qm "$1"
}

# Publish main as origin and point origin/HEAD at it, so the default branch
# is discoverable without gh.
publish_main() {
  git init -q --bare -b main .eval/origin.git
  git remote add origin "$PWD/.eval/origin.git"
  git push -q origin main
  git remote set-head origin main
}

# Push a branch to origin, as a branch that already has a PR would be.
publish_branch() {
  git push -q -u origin "$1"
}

# The handoff directory, where the skill writes and pr-handoff reads.
handoff_dir() {
  local dir
  dir="$(git rev-parse --path-format=absolute --git-common-dir)/pr-handoff"
  mkdir -p "$dir"
  echo "$dir"
}
