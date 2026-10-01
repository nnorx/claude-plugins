---
name: ratchet
description: Find a repo's ratchets (committed coverage thresholds, lint and type baselines, suppression or warning budgets, allowlists that CI holds so a number can only improve), measure each against the current code, and tighten the slack. When there are none, propose candidates with measured counts. Use when asked to audit, check, find, or tighten ratchets, baselines, thresholds, or budgets, or to lock in progress after cleanup work. Not for explaining what one script or config file does.
argument-hint: '[package path]'
---

# Ratchet

A ratchet is a recorded number that CI holds in one direction: coverage may
not fall below it, suppressions may not rise above it. It works only while
the recorded number tracks reality. Cleanup lands, nobody lowers the number,
and the gap becomes room to regress without CI noticing. Nothing fails, so
nothing flags it.

Every number in this audit comes from running something. Plain reading
miscounts, and a committed report is a snapshot of the past.

With a path argument, scope everything below to that package.

## 1. Map the repo

- **Packages.** Read `workspaces` in the root `package.json`,
  `pnpm-workspace.yaml`, or each `pyproject.toml`. Report per package; a
  monorepo's packages have separate ratchets and separate CI steps.
- **Package manager.** Take it from the `packageManager` field, else the
  lockfile: `yarn.lock`, `pnpm-lock.yaml`, `package-lock.json`. Run scripts
  the way the repo does.
- **CI.** Read the workflow and record the exact command for every check.
  **CI is the source of truth for what is enforced.**

## 2. Find the ratchets

| Kind | Where it lives |
|---|---|
| Coverage minimums | vitest `coverage.thresholds` or `--coverage.thresholds.*`, jest `coverageThreshold`, node `--test-coverage-*`, `--cov-fail-under`, coverage.py `fail_under` |
| Lint baselines | `eslint-suppressions.json`, `--max-warnings N`, `.rubocop_todo.yml`, `.betterer.results` |
| Type baselines | basedpyright baseline file, mypy-baseline |
| Allowlists | knip `ignore*`, audit or vulnerability allowlists (`audit-ci`, `osv-scanner`, `vulnix`, `.snyk`) |
| Size budgets | `.size-limit.*`, bundlesize |
| Custom | any script comparing a count to a committed file. Search for `baseline`, `budget`, `allowlist`, `threshold`, `max`, and `--update` flags |

Check flags against the installed version, not the latest docs.

## 3. Ask three questions of each

1. **Is it enforced?** It must run in CI as a blocking step.
   `continue-on-error`, `|| true`, `allow_failure`, a job that is not required,
   or a warning-only mode all mean it is not. When this fails it is the
   headline finding, because tightening a ratchet that cannot fail changes
   nothing.
2. **What is it today?** Run the check, or the tool behind it, and read the
   current value from its output. Never take the current value from a
   committed coverage summary or cached report. If the measurement cannot run,
   say so and propose no number.
3. **Where is the slack?** Recorded minus measured. For baselines, go entry by
   entry: entries for files that no longer exist, entries above the current
   count, entries whose count is now zero.

Count with a tool (`rg -c`, the linter's own output, `jq`) and report the
number the tool printed.

## 4. Sort what you found

**Enforcement fixes.** Make the step blocking. Confirm the check passes today
first, or making it blocking breaks CI.

**Free tightening.** Move the recorded number to the measured one. No code
changes.

- Never move it past measured; CI would fail. For a minimum, round down.
  For a maximum, round up.
- Prefer the tool's own update path (`eslint --prune-suppressions`, a script's
  `--update`) over hand edits. Read what it does first: a command that
  regenerates the baseline from the current tree also accepts any regression
  in it. Confirm measured is at or below recorded everywhere before running it.
- Rerun the check afterwards and show it passing.

**Paydown.** Actually reducing the count. This is real work: list it with
its size (count and files) and leave it.

## 5. If there are no ratchets

Say so plainly, then measure what can grow without anyone noticing, per
package:

- Suppressions: `eslint-disable`, `@ts-expect-error`, `@ts-ignore`, `# noqa`
  (count bare ones separately; they hide every rule), `# type: ignore`,
  `#[allow(...)]`
- Escape hatches: `any`, `as any`, `cast(Any, ...)`
- Skipped tests: `.skip`, `xit`, `@pytest.mark.skip`
- Coverage that runs in CI with no threshold, and eslint with no `--max-warnings`

Propose the mechanism the tool already has before a custom script:

- eslint bulk suppressions, and `--max-warnings 0`
- ruff `RUF100`, which fails on unused `noqa`, and `PGH004`, which bans bare ones
- a `tsc --noEmit` step, which makes unused `@ts-expect-error` fail
- coverage thresholds at today's measured values, or vitest's
  `thresholds.autoUpdate`

## 6. Report, then stop

Group by package. In each, list enforcement fixes first, then free tightening
(recorded, measured, proposed), then paydown, then candidates. Every number
names the command that produced it.

Then stop and ask. If the request already approved tightening, apply only
the free tightening, rerun the checks, and show the diff.

Which lint rules are on, and whether one inline suppression is justified,
belongs to lint-review. This skill owns the numbers: thresholds, baselines,
budgets, and suppression counts.

## Do not

- Report a number you did not measure or count with a tool.
- Raise a threshold from a committed report or snapshot.
- Set a threshold past the measured value.
- Run a baseline update without first checking that it would not accept a
  regression.
- Change source code as part of tightening. That is paydown.
- Tighten an unenforced ratchet and call the job done.
- Answer a question about one script with a repo-wide audit.
