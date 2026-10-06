---
name: dispatch
description: Plan a batch of work for parallel background agents, one PR each, so they do not collide. Splits the goal into PR-sized tasks, finds the files each will touch, puts tasks that share a file in sequence rather than in parallel, sets the merge order, and writes a self-contained prompt and a ready-to-run `claude --bg -w` command for each. Use when asked to plan or split work for several agents, dispatch or fan out background agents, run tasks in parallel worktrees, or decide what to review or merge next in a batch already running.
argument-hint: '[goal, or "next" for a batch in flight]'
---

# Dispatch

Starting agents is one command each. The work is in the plan, and the
failure mode is two agents editing the same file: each PR is fine alone,
the second one conflicts once the first merges, and the user rebases and
re-reviews work they already approved. That cost is visible before anything
starts, which is why this skill exists.

Each background agent starts with none of this conversation. Everything it
needs has to be in its prompt.

## 1. Decide whether to split at all

Parallel agents pay off when the tasks are independent and each is worth a
PR. Say so and stop if:

- the work is one change, or a chain where each step needs the last one
  merged; one session, or a sequence, is faster
- the tasks all need the same few files
- the user would have to review more PRs at once than they can keep in
  their head. Three or four running at a time is plenty.

## 2. Survey before splitting

- **The repo's rules.** CLAUDE.md, CONTRIBUTING, and
  `git log --oneline -20 origin/<default>`: what a PR may contain, title
  format, the check to run, and anything merging sets off (a deploy, a
  release). Each prompt has to carry these.
- **What is already in flight.** `git worktree list`, branches ahead of the
  default branch, and handoffs waiting in
  `$(git rev-parse --path-format=absolute --git-common-dir)/pr-handoff/`.
  Their files count as taken. `claude agents --json` can return an empty list
  from inside a sandbox even with agents running, so trust git, not that.
- **The files each task will touch.** Read the code to find them; do not
  guess from names. Include the files a change ripples into: an import list,
  a module registry, a README table, a test fixture.

## 3. Split and order

For each task write down: a short name (kebab-case, it becomes the worktree
and branch), the goal in one sentence, the files it owns, what done means,
and what it depends on.

Then check every pair:

- **Same file: sequence them.** The second waits for the first to merge,
  even when the edits look far apart. Two agents appending to the same list
  conflict every time.
- **Shared hot spots.** Lockfiles, CI workflows, central config, and index
  files that every change touches. Give each one to a single task, or keep
  it out of the batch.
- **Hidden coupling.** One task assumes an option, function or file that
  another adds. That is a dependency even with no shared file.

Group what is left into waves. Wave 1 is everything with no dependency; it
runs now. Each later wave starts after the tasks it depends on merge, off
the new default branch, not stacked on an unmerged one.

The merge order puts dependencies first, then the repo's timing rules (a
change that deploys on merge may need a particular time of day, or another
change merged first), then the lowest-risk changes, so that a slow review
holds up as little as possible. Flag any task that needs something from the
user before it can merge, such as a secret, an account or a manual deploy.

## 4. Write the prompts

One file per task, under the common dir so every worktree sees it and
nothing is committed:

```
<common dir>/agent-plans/<batch>.md          the plan (section 5)
<common dir>/agent-plans/<batch>/<name>.md   one prompt per task
```

Each prompt is written for a reader who knows nothing about this
conversation:

- **The goal and why,** in a few sentences.
- **Scope.** The files it owns. The files other agents own, by name, with an
  instruction not to touch them. If the task cannot be done without them,
  stop and say so rather than editing them.
- **The repo's rules** that matter for this change. Point at the files that
  state them rather than restating them all.
- **How to finish:** run the repo's check; commit; rename the branch from
  `worktree-<name>` to a name that follows the repo's conventions
  (`git branch -m <new>`, and if that fails, keep the old one); write the PR
  handoff, with the pr-handoff skill when the session cannot push; then stop.
  It does not merge, and it does not touch other worktrees.
- **When to stop early:** the scope needs to grow, the check fails for a
  reason outside the task, or a decision belongs to the user. Say what
  happened and wait. A stopped agent costs one look; one that improvised
  costs a review of everything it did.

## 5. Hand over

Write the plan file, then show the user:

- A table: name, goal, files, wave, merge position, and anything it needs
  from them.
- The commands for wave 1, one per task, to run in their own terminal from
  the repo's main checkout:

  ```bash
  claude --bg -w <name> "$(cat '<common dir>/agent-plans/<batch>/<name>.md')"
  ```

- How to watch them: `claude agents` lists every agent; arrows and Enter
  open one; ← goes back to the list; `claude attach <name>` opens one from
  the shell.

Do not start the agents from this session. It is the user's call how many run
at once, and a sandboxed command may not reach the API anyway.

The plan file holds the same table and the waves, so a later session, or the
user, can pick the batch up. It also holds the merge order in exactly this
form, which `agents-status` reads to show what is next, where nix-config
installs it:

```markdown
## Merge order

1. <name>
2. <name>
```

Names here are task names, the worktree's directory under
`.claude/worktrees/`, not branch names, since the agents rename their
branches.

## 6. Next, while the batch runs

When asked what to do next, read the plan file and the state on disk:

- **Done** means a handoff exists for the task's branch. The agent renamed
  that branch, so find it with
  `git -C .claude/worktrees/<name> branch --show-current`. Review in merge
  order, not in the order they finished, so nothing approved waits on
  something unreviewed.
- **After each merge,** fetch, and check the remaining branches against the
  new default branch. A branch that conflicts gets rebased (the rebase skill)
  before it is reviewed, not after.
- **When a wave's dependencies have merged,** write its commands, now based on
  the new default branch.
- **A task that stopped early** is a planning problem. Revise the plan or the
  prompt before restarting it; do not just tell it to continue.
- **Finished agents** come out with `claude rm <id>` once their PR has
  merged. A squash merge leaves the branch's own commits out of the default
  branch, so it may ask to discard them; once the PR is merged, that is
  expected and safe.

## Do not

- Put two tasks that edit the same file in the same wave.
- Write a prompt that depends on this conversation.
- Start, stop, or remove agents yourself.
- Merge, or ask for a merge, outside the plan's order without saying why.
