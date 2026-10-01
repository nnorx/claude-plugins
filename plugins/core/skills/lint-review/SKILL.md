---
name: lint-review
description: Audit a repo's linter configuration for gaps, dead suppressions, and rules that have rotted against the installed tool version, measuring each proposal by actually running the linter rather than by taste. Use when asked to review lint config, find rules worth enabling, clean up ignores or disables, check whether linting is actually enforced, or decide whether the current changes call for a config change.
argument-hint: '[path or "changes"]'
---

# Lint review

A lint config is written once and then only ever loosened. Rules get suppressed
under deadline, the tool ships new rules that never get adopted, and the config
drifts from the version actually installed. None of this shows up as a failure,
because a linter that is not checking something simply says nothing.

Every claim in this audit is measured by running the linter. A rule is worth
enabling because it produces zero violations today, not because it is a good
idea in general.

With no argument, audit the whole repo. With `changes`, go straight to section
6 and ask whether the current diff calls for a config change. With a path,
scope every measurement below to that directory.

## 1. Find what actually runs

Locate the config, then locate the invocation. They are different questions.

Common config: `biome.json` / `biome.jsonc`, `eslint.config.*`, `.eslintrc*`,
`ruff.toml` or `[tool.ruff]` in `pyproject.toml`, `clippy.toml`,
`.golangci.yml`, `knip.json`, `treefmt.toml`, `.editorconfig`.

Then check `package.json` scripts, the `Justfile` or `Makefile`, and the CI
workflow. **CI is the source of truth for what is enforced.** A config that
exists but is never run in CI is documentation, not a gate, and that gap is
itself a finding. Note any linter that runs locally but not in CI, or that runs
in CI without failing the build.

Record the exact command CI uses. Every measurement below must use it.

## 2. Baseline

Run that command on a clean tree and record the result. Refuse to proceed with
uncommitted changes in the config files you are about to modify, or stash them
explicitly and say so. Everything after this is measured as a delta.

## 3. Find the free wins

This is the core of the audit. For each rule that is off, or not included in
the active preset:

1. Enable it
2. Run the linter
3. Count violations
4. Revert the config

Then classify by what you measured:

- **Zero violations.** A free win. The codebase already complies, so enabling
  it costs nothing and prevents regression. Propose these first.
- **Single digits.** A cheap win. Show the actual violations so the user can
  judge whether they are real.
- **Large counts.** A migration, not a config change. Report the number, do not
  propose it as a quick fix, and note whether an autofix exists.

Work in batches to keep the run count sane, but attribute violations to
specific rules. **Always restore the config when you are done measuring.**
Leaving a mutated config behind is worse than finding nothing.

## 4. Audit suppressions

Find every inline disable (`biome-ignore`, `eslint-disable`, `# noqa`,
`#[allow(...)]`, `// @ts-expect-error`) and every path in an ignore list.

For each, the mechanical test is the same: remove it, run the linter, see
whether anything fires. If nothing does, the suppression is dead and the code
it was protecting is gone.

For the ones that are still live:

- Is it blanket where narrow would do, disabling a whole file or all rules
  where one rule on one line was the problem?
- Does it carry a reason? An unexplained suppression cannot be evaluated by
  anyone later, which is how they become permanent.
- Is the same rule suppressed the same way in many places? That is not a set
  of exceptions, it is a miscalibrated rule. Say so.

## 5. Check for rot

Compare the config against the installed tool version, not the latest release.

- Rules renamed or removed upstream. These usually fail silently, so the config
  reads as if it is enforcing something it is not.
- Deprecated options and schema versions.
- Presets that changed membership between versions, which can silently add or
  drop coverage.
- Config for a tool that is no longer a dependency at all.

## 6. Read the current changes

If there is a diff in progress, ask the reverse question: does the linter fit
the code being written?

- Does the change introduce a pattern the linter should have caught but did not?
  That is a candidate rule with a real, concrete motivation.
- Does the change fight a rule, working around it or suppressing it? A rule
  being suppressed by the person it is supposed to help is miscalibrated.

## 7. Report

Group findings, most actionable first: free wins, cheap wins, dead
suppressions, rot, then calibration changes suggested by the diff.

Give the measured number for every proposal. "Enabling `noUnusedImports`
produces 0 violations" is a finding. "This rule seems useful" is not.

Propose the config diff. Do not apply it without approval, and never apply a
rule change together with the code changes needed to satisfy it in one step.

## Do not

- Propose a rule on taste alone. If you did not run it, do not suggest it.
- Leave the config mutated after measuring.
- Propose style rules that fight the repo's existing formatter. The formatter
  wins; a linter arguing with it produces noise forever.
- Treat a large violation count as a reason to suppress the rule. Report the
  count and let the user decide.
- Silently reformat, autofix, or "clean up while you are in there".
