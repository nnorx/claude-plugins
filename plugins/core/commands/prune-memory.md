---
description: Audit stored memories for stale, completed, or redundant facts
argument-hint: [scope]
---

Use the prune-memory skill to audit the memory directory.

If an argument is given, treat it as a project scope (a directory under
`~/.claude/projects/`) and audit that scope instead of the active one.
Otherwise audit the scope whose memories are loaded in this session.

Report findings grouped by classification and stop for approval before
changing anything.
