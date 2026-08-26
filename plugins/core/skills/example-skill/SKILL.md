---
name: example-skill
description: Inert scaffolding placeholder. Never invoke this skill. Delete it once a real skill exists in this plugin.
---

# Placeholder

This file exists so the `core` plugin has a valid `skills/` directory before any
real skills are written. It is deliberately inert.

To write a real skill, create a sibling directory with its own `SKILL.md`:

    plugins/core/skills/<skill-name>/SKILL.md

The frontmatter needs exactly two fields:

- `name`: must match the directory name.
- `description`: the only text Claude sees when deciding whether to load the
  skill. Write it as a trigger, not a summary: name the concrete situations,
  file types, and phrases that should pull it in.

Everything below the frontmatter is loaded only after the skill fires, so put
the actual procedure there and keep the description tight.

Delete this directory once the first real skill lands.
