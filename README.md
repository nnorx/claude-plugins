# claude-plugins

Nick's personal Claude Code marketplace. One git repo holding the skills,
agents, commands, and hooks that should follow him onto every machine.

## Layout

```
.claude-plugin/marketplace.json   marketplace manifest (name: "nnorx")
plugins/core/
  .claude-plugin/plugin.json      plugin manifest
  skills/<name>/SKILL.md          skills
  agents/<name>.md                subagents
  commands/<name>.md              slash commands
  hooks/hooks.json                hooks
```

Add more plugins as sibling directories under `plugins/` and list them in
`marketplace.json` when a group of skills should be enabled independently
(for example a `nix` plugin that only dev hosts turn on).

## Installing

### On a nix host

Nothing to run. `nix-config` takes this repo as a flake input and writes both
the marketplace path and the enabled plugin into `~/.claude/settings.json`,
so a `home-manager switch` is the whole install. The revision is pinned in
`flake.lock`, so machines cannot silently drift.

Update with:

```bash
nix flake update claude-plugins
home-manager switch --flake .#nick
```

### Anywhere else

```bash
claude plugin marketplace add nnorx/claude-plugins
claude plugin install core@nnorx
```

## Gotchas

The marketplace name that `enabledPlugins` must reference comes from the
`name` field in `marketplace.json`, not from whatever key is used in
`extraKnownMarketplaces`. A mismatch fails with a misleading
"Plugin not found".

`claude plugin list` only reports plugins installed with `claude plugin
install`. A plugin enabled declaratively through settings will show nothing
there even though it is loaded. Verify with `claude plugin details core`
instead, which prints the component inventory and token cost.

Every skill in an enabled plugin costs tokens in every session, because its
name and description sit in the system prompt. Run `claude plugin details core`
after adding skills and keep an eye on the always-on number.

## Validating before pushing

```bash
claude plugin validate .
```
