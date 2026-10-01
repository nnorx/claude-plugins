# Shared scaffolding for the rebase eval cases. Sourced, not run.
#
# Every case gets the same shape: a working repo checked out on `feature`,
# and a bare `origin` whose main has moved on since the branch was cut. The
# upstream commits are pushed from a second clone, so the working repo's
# origin/main is stale until it fetches. A rebase onto the local ref therefore
# replays onto nothing, which is the failure the skill's "Fetch" step exists
# to prevent.
#
# The remote and the upstream clone live in .eval/. Every top-level dotfile is
# listed in .git/info/exclude, which covers .eval/ and also the .bashrc,
# .claude/ and friends that the eval harness drops into the working directory,
# so `git status` is clean unless a case makes it dirty on purpose.
#
# Graders read the outcome from git's own reflog, .git/logs/HEAD, rather than
# from a hook: the harness does not run hooks from the repo under test. A
# rebase logs "rebase (start)" with the SHA it is replaying onto and
# "rebase (finish)" when it completes. Dates are pinned, so that SHA and the
# pre-rebase SHA are identical on every run and can be graded literally.

set -euo pipefail

export GIT_AUTHOR_DATE="2026-01-01T00:00:00Z"
export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"
export GIT_AUTHOR_NAME="Eval" GIT_AUTHOR_EMAIL="eval@example.invalid"
export GIT_COMMITTER_NAME="Eval" GIT_COMMITTER_EMAIL="eval@example.invalid"

identity() {
  git config user.name Eval
  git config user.email eval@example.invalid
  git config commit.gpgsign false
}

# Start the working repo on main.
init_repo() {
  git init -q -b main .
  identity
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

# Run a function inside a fresh clone of origin, then push its commits to
# origin/main. The working repo does not see them until it fetches.
upstream() {
  local here=$PWD
  git clone -q "$here/.eval/origin.git" .eval/upstream
  (
    cd .eval/upstream
    identity
    "$@"
    git push -q origin main
  )
}
