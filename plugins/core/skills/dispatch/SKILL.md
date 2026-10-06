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
  default branch, their open PRs, and a plan in
  `$(git rev-parse --path-format=absolute --git-common-dir)/agent-plans/`.
  Their files count as taken, and a plan still in flight is extended rather
  than replaced (section 5). `claude agents --json` can return an empty list
  from inside a sandbox even with agents running, so trust git, not that.
- **The files each task will touch.** Read the code to find them; do not
  guess from names. Include the files a change ripples into: an import list,
  a module registry, a README table, a test fixture.

## 3. Split and order

For each task write down: a short name, the goal in one sentence, the files
it owns, what done means, and what it depends on.

The name, in kebab-case, becomes the worktree `.claude/worktrees/<name>`,
the branch `worktree-<name>` and the session's name. Pick one that no branch
or worktree has yet (`git branch --list 'worktree-<name>'`,
`git worktree list`). A branch left over from an earlier task with the same
name can be reset when the new worktree is made, and its commits lost.

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
- **How to finish:** run the repo's check; commit on the branch it is on,
  `worktree-<name>`, without renaming it; open the PR, or, when the session
  cannot push, write the handoff with the pr-handoff skill; then stop. It
  does not merge, and it does not touch other worktrees. The branch name
  never reaches the squashed commit, and a rename can half-fail: in a
  sandbox that locks `.git/config`, `git branch -m` renames the branch and
  then exits with an error.
- **When to stop early:** the scope needs to grow, the check fails for a
  reason outside the task, or a decision belongs to the user. Say what
  happened and wait. A stopped agent costs one look; one that improvised
  costs a review of everything it did.

## 5. Hand over

Write the plan file, then show the user:

- A table: name, goal, files, wave, merge position, and anything it needs
  from them.
- The commands for wave 1, one per task, to run in their own terminal from
  the repo's main checkout (the first entry of `git worktree list`). `-n`
  names the session, so `claude attach <name>` finds it:

  ```bash
  claude --bg -w <name> -n <name> "$(cat '<common dir>/agent-plans/<batch>/<name>.md')"
  ```

- How to watch them: `claude agents` lists every agent; arrows and Enter
  open one; ← goes back to the list; `claude attach <name>` opens one from
  the shell.
- How to publish one that wrote a handoff: `pr-handoff` publishes the branch
  checked out where it runs, so from that worktree,
  `cd <main checkout>/.claude/worktrees/<name> && pr-handoff`, with the main
  checkout's path written out.

Do not start the agents from this session. It is the user's call how many run
at once, and a sandboxed command may not reach the API anyway.

The plan file holds the same table and the waves, so a later session, or the
user, can pick the batch up. It also holds the merge order in exactly this
form, which nix-config's `agents-status` reads, where it is installed, to show
what is next:

```markdown
## Merge order

1. <name>
2. <name>
```

Names here are task names, the worktree's directory under
`.claude/worktrees/`.

There is one plan per repo at a time, because `agents-status` reads only the
newest. To plan more work while a batch is in flight, add to its plan: new
rows, new waves, and the new names appended to its merge order, with their
prompts in the same directory. When everything in a plan has merged, delete
the plan and its prompt directory, so the next batch starts a fresh one.

## 6. Next, while the batch runs

When asked what to do next, read the plan, then the state:

- **If `agents-status` is on PATH,** run it from the main checkout. It reports
  each branch's PR, checks, and conflicts with the default branch and with
  each other, and follows the plan's merge order. Build on what it says
  rather than checking again by hand.
- **Otherwise,** gather the same for each task's branch, `worktree-<name>`:
  the newest PR from it (`gh pr list --head`, or the pr-handoff skill's API
  calls where gh has no login), that PR's checks, and
  `git merge-tree --write-tree origin/<default> <branch>` for conflicts.
  A handoff file is not a sign of progress: an agent that can push opens
  the PR itself and writes none, and `pr-handoff merge` deletes it.

Then:

- **Done** means the task has a PR. Review in merge order, not in the order
  they finished, so nothing approved waits on something unreviewed.
- **Merged** means its PR merged. When every dependency of a later wave has
  merged, write that wave's commands, now based on the new default branch.
- **After each merge,** fetch, and check the rest against the new default
  branch. A branch that now conflicts is rebased before it is reviewed, with
  the rebase skill, and only once its agent has stopped: a rebase under a
  running agent rewrites what it is working on. Run it inside the task's
  worktree, since git will not check out a branch another worktree holds.
  The PR is already published, so republish from the same worktree with
  `pr-handoff --force-with-lease`, or `git push --force-with-lease` where the
  session can push.
- **A task that stopped early** is a planning problem. Revise the plan or the
  prompt before restarting it; do not just tell it to continue.
- **Finished agents** come out with `claude rm <id>` once their PR has
  merged. A squash merge leaves the branch's own commits out of the default
  branch, so it may ask to discard them; once the PR is merged, that is
  expected and safe.
- **When the whole plan has merged,** delete it and its prompt directory.

## Do not

- Put two tasks that edit the same file in the same wave.
- Write a prompt that depends on this conversation.
- Start, stop, or remove agents yourself.
- Rebase a branch whose agent is still running.
- Start a second plan while one is in flight.
- Merge, or ask for a merge, outside the plan's order without saying why.
