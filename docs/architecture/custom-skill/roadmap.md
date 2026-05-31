# Roadmap — `/custom` Skill

## Phase 0 — Create the Skill (now)

**Goal:** Working global skill at `~/.claude/commands/custom.md` with full 5-phase workflow.

- [x] Detect artifact type from user intent
- [x] Inspect live environment (commands, settings, agents) before recommending
- [x] Show plan + preview before touching any files
- [x] Explain every change on execution
- [x] Iterate loop until user confirms done
- [x] Reference table of all artifact locations
- [x] Architecture docs (`README.md`, two ADRs, this roadmap)

---

## Phase 1 — Refine Based on Real Usage

**Trigger:** After the skill has been used on 5+ real customization tasks.

**Likely refinements:**
- Tighten artifact-type detection if ambiguous cases arise frequently
- Improve the Phase 2 environment summary (e.g., show hook counts per event, flag potential conflicts)
- Add examples section at the end of the skill file for common patterns (e.g., "a hook that auto-formats on save")
- Handle keybindings (`~/.claude/keybindings.json`) as a recognized artifact type
- Handle MCP server configuration as a recognized artifact type

**Success criteria:** Fewer clarifying questions needed in Phase 1; Phase 3 plans are accepted on first pass more than 80% of the time.

---

## Phase 2 — Sub-commands or Specialized Variants

**Trigger:** If `/custom` grows to the point where the skill file length causes Claude to miss instructions, or a specific artifact type needs significantly different behavior.

**Options:**
- Extract heavy artifact-specific logic into dedicated project-level shadow commands (e.g., a team repo's `.claude/commands/custom.md` that overrides the global one with team conventions)
- Add sub-command dispatch: `/custom hook <args>`, `/custom skill <args>` (requires explicit prefix parsing in Phase 1)
- Keep the global skill as the dispatcher and delegate to `agents/` configs for complex artifact-specific flows

**Decision point:** Only split if there is a concrete usability problem, not preemptively.

---

## Phase 3 — Team and Multi-User Integration

**Trigger:** If the skill is shared across a team or multiple machines.

**Work items:**
- Document the install step (`cp ~/.claude/commands/custom.md` or symlink from a shared dotfiles repo)
- Define a convention for project-level overrides (scope, naming, expected behavior)
- Consider a versioning comment at the top of `custom.md` so teams can track which version they're running
- Evaluate whether team-specific artifact conventions (approved hook patterns, required settings, standard CLAUDE.md sections) warrant a companion template library
