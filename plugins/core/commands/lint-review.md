---
description: Audit the repo's lint config for gaps, dead suppressions, and rot
argument-hint: [path or "changes"]
---

Use the lint-review skill to audit this repo's linter configuration.

With no argument, audit the whole repo. With `changes`, focus on whether the
current diff calls for a config change. With a path, scope the measurements to
that directory.

Measure every proposal by running the linter, and report before changing
anything.
