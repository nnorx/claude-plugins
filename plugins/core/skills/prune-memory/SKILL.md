---
name: prune-memory
description: Audit a Claude Code memory directory for facts that have gone stale, been completed, or become redundant, verifying every claim against the filesystem, git, and gh before proposing changes. Use when asked to prune, audit, clean up, or review memories, to check whether stored memories are still accurate, or after a recalled memory turns out to be wrong.
argument-hint: '[scope]'
---

# Prune memory

Memories are written once and trusted indefinitely. The failure mode is silent:
a memory that was true when written keeps asserting itself every session after
the world moves on, and nothing in the normal flow catches it.

This is a verification pass, not a tidying pass. Never propose deleting a
memory because it is old, long, or uninteresting. Propose a change only where
there is evidence the memory is wrong, finished, or duplicated.

## 1. Pick the scope

Memories live per project root at `~/.claude/projects/<slug>/memory/`, with
`MEMORY.md` as the index that loads every session.

Default to the scope whose memories are loaded in the current session. Other
scopes exist and are not in context:

```bash
ls -d ~/.claude/projects/*/memory/
```

If an argument names a scope (a directory under `~/.claude/projects/`), audit
that one; naming it is the confirmation. Otherwise confirm before auditing a
scope other than the active one.

## 2. Verify every concrete claim

This step is what separates the skill from guessing. Read each memory in full,
then extract the claims that can be checked mechanically:

- File and directory paths
- Host, service, repo, and branch names
- Flags, config keys, environment variables
- Package, function, and command names
- PR and issue numbers
- Anything phrased as pending, planned, in progress, or "as of `<date>`"

Then check them:

| Claim | Check |
|---|---|
| a path | `test -e` |
| a config key or flag | grep the file the memory names |
| a package or version | read the manifest or lockfile |
| a PR or issue | `gh pr view <n> --json state,mergedAt` |
| a branch | `git ls-remote --heads`, or `git branch -a` |
| a pending action | look for the artifact that would exist if it were done |
| a "current state" claim | compare against `git log` since the memory's date |

Report evidence, not impressions. "core3 does not appear in `hosts/`" is a
finding. "This looks out of date" is not.

## 3. Classify

**Stale.** Names something that no longer exists or has changed. Highest
priority, because these actively mislead every session.

**Completed.** Described a pending action that has since happened. Either
delete it or rewrite it as the resulting fact.

**Absorbed.** The repo now records this itself, in CLAUDE.md, a README, a code
comment, or CI config. Memory that duplicates the repo will drift from it.

**Duplicated.** Two memories cover the same ground. Merge into whichever has
the better `description`, and keep the surviving `name:` slug.

**Unfalsifiable.** Contains no checkable claim. Expected for `user` and
`feedback` memories, which record preferences. Suspicious for `project`
memories, which should be concrete enough to verify.

**Sound.** Verified and still true. Say so briefly. A clean bill of health on
the rest of the directory is useful output.

## 4. Check the recall surface

A memory has two layers. The body is read only once the memory is pulled in.
The `description:` and the `MEMORY.md` index line are what get matched and
loaded every session. They drift independently, and drift here is the more
expensive kind: a body can be entirely correct while its description keeps
advertising a problem that was solved weeks ago.

For each memory, check the description against its own body:

- Does it still summarize what the body now says?
- Does it describe as planned or pending something the body records as done?
- Would it match the situations where this memory is actually useful?

Then check the index. `MEMORY.md` loads every session, so an error there costs
more than an error in any single memory file.

- Every `.md` file except `MEMORY.md` has exactly one index line
- No index line points at a missing file
- Each line's hook still matches what its memory now says
- Every `[[wikilink]]` resolves to an existing `name:` slug, or is a
  deliberate placeholder for a memory not yet written

## 5. Propose, do not act

Group findings by classification, most confident first. For each one give the
file, the verdict, the evidence, and the proposed action.

Then stop and ask. Deleting a memory destroys context that by definition could
not be recovered from the repo, which is why it was written down. Apply only
what the user approves.

When updating rather than deleting:

- Keep the `name:` slug stable, since `[[wikilinks]]` point at it
- Rewrite `description:` if the substance changed. It is the text matched
  during recall, so a stale one causes the memory to surface at the wrong times
- Preserve the `**Why:**` line. The reason behind a decision outlives the
  decision itself
- Convert relative dates to absolute
- Update the `MEMORY.md` line in the same pass

## Do not

- Delete on age alone. An old memory that is still true is a good memory.
- Prune something for being obvious. It was written down because it was not.
- Assume a pending item went stale because it is old. Verify whether the work
  actually happened. A memory recording a counter-argument that the code does
  not is doing real work, and reads exactly like a stale TODO.
- Rewrite a `feedback` rule because you disagree with it.
- Trim a `**Why:**` for concision.
- Touch another project scope without being asked.
