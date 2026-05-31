# ADR-001: Global Placement for the `/custom` Skill

## Status
Accepted

## Context
Claude Code supports slash commands in two locations:
- **Global** (`~/.claude/commands/<name>.md`) — available in every project and every Claude Code session on this machine
- **Project** (`.claude/commands/<name>.md`) — available only within the repository where the file lives

The `/custom` skill is a meta-tool: its purpose is to *build other customizations*, and it operates equally on global files (`~/.claude/`) and project files (`.claude/`). It needs to run regardless of which project directory the user is currently working in — including brand-new directories with no `.claude/` folder yet.

The user's workflow involves multiple independent projects (`home-argocd`, `vvn-ce`, `lacia`, `devops/`, etc.). Requiring the skill to be installed per-project would mean either copy-pasting it into each repo or missing the command in the many projects that don't have it yet.

## Decision
Place `custom.md` in `~/.claude/commands/` (global scope).

## Consequences

**Positive:**
- Instantly available in all existing and future projects without any per-project setup.
- Can be invoked even before `.claude/` exists in a project (e.g., first time bootstrapping customizations in a new repo).
- Consistent UX — `/custom` always works the same way everywhere.
- Upgrades to the skill propagate to all projects automatically.

**Negative / trade-offs:**
- A single global file means all projects share the same version of the skill. If a project needs a different variant (e.g., team-specific conventions), it would need a separate project-level command that shadows the global one.
- Changes to the global file affect all projects simultaneously. Accidental breakage has wider blast radius than a project-scoped file.

**Risks:**
- The skill reads `.claude/settings.json` and `.claude/commands/` relative to the current working directory. If Claude Code's CWD drifts from the user's project root, reads could target the wrong directory. This is a property of how Claude Code resolves relative paths, not of global vs. project placement.
