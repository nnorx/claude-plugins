# Evals

One suite per skill, run with `claude plugin eval`. Each case builds a real
repo from its `scaffold.sh`, gives an agent one prompt, and grades the end
state: file contents and git's reflog where possible, an LLM judge only for
what the agent says.

## Running

From `plugins/core`:

```bash
claude plugin eval . --scaffold --allow-tools Bash Edit Write --judge-model sonnet
```

- `--case` takes one glob, and a repeated flag keeps only the last. Character
  classes like `[cs]` do not match; use `*` or name the case.
- Every run is paired with a run without the plugin, and the report shows the
  difference. Add `--ablation none` to skip that while piloting new cases.
- `--runs 1` for a pilot, the default 3 for a real measurement.
- A run costs about $0.15 to $0.25.

## Gotchas

- **Use a Sonnet judge.** The default Haiku judge failed correct answers,
  three votes to none, even against one-line rubrics.
- **The sandbox needs bubblewrap and socat** on Linux, on the profile's PATH.
  A `nix shell` does not reach the agents, which run through the login shell.
- **No network.** Fixtures can use node, jq, rg and git, and nothing that has
  to be installed.
- **Hooks in the repo under test do not run.** Read outcomes from files the
  tools write anyway, such as `.git/logs/HEAD`.
- **The harness writes dotfiles into the working directory**, including
  `.claude/`. Scaffolds exclude top-level dotfiles from git, and graders on
  the `files` target skip them.
- **"Did not do X" graders pass when the agent does nothing.** Pair each with
  a grader that needs real output.
- **Read the traces before trusting a score.** Most early failures here were
  fixture or grader bugs. When an agent says the fixture is wrong, check
  whether it is.
