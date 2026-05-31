# ADR-002: Single `/custom` Command vs. Specialized Commands

## Status
Accepted

## Context
When building a meta-tool for Claude Code customization, there are two structural options:

**Option A — Single universal command `/custom`**
One skill file that detects artifact type from user input and branches internally.

**Option B — Specialized commands per artifact type**
Separate commands: `/custom-skill`, `/custom-hook`, `/custom-settings`, `/custom-agent`, each focused on one artifact type.

The user's existing skills (`fix`, `architect`, `pr`, `go`) are all single-purpose commands that handle one concern well. However, `/custom` is a meta-tool operating at a different level — it creates other customizations rather than performing domain work.

Key considerations:
- **Discovery**: A user who doesn't know the taxonomy of Claude Code artifacts would have to know to type `/custom-skill` vs `/custom-hook`. One command is discoverable; four are not.
- **Overlap**: Many real requests span artifact types (e.g., "add a skill that also needs a hook to run before it" or "add a permission so my new skill can run npm"). A single command handles combinations naturally.
- **Maintenance**: Four files that share phase logic (plan → confirm → execute → iterate) create duplication. The workflow is identical; only the artifact-type-specific rules differ.
- **Command count**: The global `~/.claude/commands/` already has `architect`, `fix`, `go`, `pr`. Adding four more meta-commands (`custom-skill`, `custom-hook`, `custom-settings`, `custom-agent`) roughly doubles the command count for a feature that could live in one file.

## Decision
Implement a single `/custom` command that detects artifact type from user intent and handles skill, hook, settings, agent, and CLAUDE.md customizations in one file.

## Consequences

**Positive:**
- Single entry point — users type `/custom` and describe what they want in plain language.
- Handles multi-artifact requests (e.g., a skill + permission + hook) without requiring the user to run three separate commands.
- One file to maintain, upgrade, and reason about.
- Reduces command namespace pollution in `~/.claude/commands/`.

**Negative / trade-offs:**
- The skill file is longer and more complex than a single-purpose command.
- Artifact-type detection adds a branching layer. If detection is wrong, the user gets an unexpected plan in Phase 3 (recoverable — they reject it and clarify).
- As artifact types grow (e.g., MCP servers, keybindings), the detection table needs updating.

**Risks:**
- If the skill becomes too large, Claude may miss edge-case instructions buried late in the file. Mitigation: keep phase structure clean and phases short enough to stay in attention.
- If a specialized use case demands very different behavior (e.g., a team-specific `/custom-hook` with company-required patterns), a project-level shadow command can override just that variant without changing the global file.
