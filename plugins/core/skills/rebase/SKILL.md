---
name: rebase
description: Rebase a branch onto its default branch, resolving trivial and mechanical conflicts but stopping to ask on semantic ones, with the pre-rebase SHA recorded so the operation is always reversible. Use when asked to rebase, to sync a branch onto main or master, to catch a branch up before a PR, or when a branch has fallen behind and conflicts are expected.
---

# Rebase

Rebasing is one command. The judgment is entirely in the conflicts, and the
failure mode is resolving a conflict by picking whichever side looks tidier,
which silently discards someone's intent and produces a branch that merges
cleanly and behaves wrongly.

Resolve what is mechanically determined. Escalate anything that requires
knowing what the author meant.

## 1. Preflight

Do all of this before touching anything:

- **Record the current SHA.** `git rev-parse HEAD`. State it in your first
  message. Every recovery path below depends on it existing in the transcript.
- **Refuse a dirty tree.** `git status --porcelain` must be empty. Do not stash
  silently; ask, since a stash that gets forgotten during a conflict is its own
  incident.
- **Confirm the branch is not the default branch.** Rebasing main onto itself
  is always a mistake.
- **Check whether the branch is pushed.** `git rev-parse @{u}` succeeding means
  completing this will require a force push, which needs its own approval later.
- **Fetch.** `git fetch origin`. Rebasing onto a stale local ref achieves
  nothing.

## 2. Find the target

Do not assume `main`. Use `gh repo view --json defaultBranchRef -q
.defaultBranchRef.name`, or `git symbolic-ref refs/remotes/origin/HEAD`.
Repos that predate the rename still use `master`, and getting this wrong
produces a rebase onto a branch that has not moved in years.

## 3. Predict the conflicts

Before starting, so the user knows what they are agreeing to:

```bash
git log --oneline <target>..HEAD     # commits being replayed
git log --oneline HEAD..<target>     # what arrived upstream
```

Then intersect the two file sets. Files touched on both sides are where
conflicts will happen, and a diffstat of that intersection is a good estimate
of the work. If the intersection is empty, say so; the rebase is going to be
clean and the user does not need to watch.

## 4. Rebase

```bash
git rebase <target>
```

Interactive rebase is not available in this environment, so never reach for
`-i`. If the history genuinely needs editing, say so and stop.

## 5. Triage each conflict

Classify before resolving. The classification determines who decides.

**Mechanical.** Lockfiles, generated files, snapshots, anything with a
regenerating command. Do not hand-merge these. Take either side, then
regenerate: `pnpm install`, `nix flake lock`, `cargo update -p`, whatever
produces the file. A hand-merged lockfile is a corrupted lockfile that will
appear to work.

**Trivial.** Both sides edited different regions of the same file, or one side
is a pure move, rename, or reformat with no semantic content. Resolve, and note
what you did.

**Semantic.** Both sides changed the same logic with different intent. **Stop.**
Do not resolve. Report:

- What your side was trying to do, with the commit that did it
- What the upstream side was trying to do, with the commit that did it
- Why they collide, specifically, rather than "these overlap"
- The options, if there are clearly only a few

Then wait. Guessing here is the single worst outcome of this skill, because the
result looks correct.

While stopped, `git rebase --abort` returns to the pre-rebase state.

## 6. Verify

A rebase that completes is not a rebase that worked.

- Confirm the net change survived. `git diff <target>...HEAD` should express
  the same intent as the branch did before, minus whatever upstream already
  landed. If the diff shrank, something was dropped in a conflict.
- Run the repo's gate if there is a cheap one: type-check, lint, unit tests.
  A rebase that silently breaks the build is common and easy to catch here.
- Report the before and after SHAs and the commit count.

## 7. Pushing

If the branch was pushed, completing this needs a force push. **Ask first.**

Use `--force-with-lease`, never `--force`. It refuses if the remote moved,
which is the difference between overwriting your own stale ref and overwriting
someone else's work.

If the branch has an open PR with review comments, say so before pushing.
Rebasing detaches existing review threads from their lines.

## Recovery

State these whenever the operation is not going smoothly:

- Mid-rebase: `git rebase --abort`
- After a finished rebase: `git reset --hard <pre-rebase SHA>`
- If the SHA was lost: `git reflog`

## Do not

- Rebase the default branch.
- Resolve a semantic conflict by picking the side that looks cleaner.
- Hand-merge a lockfile or any other generated file.
- Force push without asking, or use `--force` when `--force-with-lease` works.
- Squash, reorder, reword, or drop commits unless explicitly asked. The user
  asked for a rebase, not a history rewrite.
- Continue past a conflict you do not understand in the hope that later commits
  clarify it.
