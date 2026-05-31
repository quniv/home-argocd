# ADR-002: Hook Placement — Global + Per-Repo Dual Strategy

**Status:** Accepted  
**Date:** 2026-05-31

---

## Context

Git hooks can be placed in three ways:

1. `.git/hooks/` — local to one clone, not version-controlled.
2. `core.hooksPath` (global) — applies to all repos on this machine.
3. `core.hooksPath` (per-repo) — applies to one repo, version-controlled if in a tracked directory.

`core.hooksPath` is a single-valued setting. A per-repo value **overrides** the global one; they do not stack. Choosing between global and per-repo is a binary decision per-repo.

There are two distinct needs:
- Protect **all repos on this machine** (including repos that never opt in).
- Make the hooks **portable** so any contributor cloning this repo gets the same protection.

---

## Decision

Use a **dual strategy**:

1. **Global** (`~/.config/git/hooks/`): set via `git config --global core.hooksPath`. Installed once per machine by `scripts/install-global-hooks.sh`. Protects all repos by default.
2. **Per-repo** (`.githooks/`): activated per-clone via `.githooks/setup.sh` (`git config core.hooksPath .githooks`). The per-repo setting overrides global for this repo but is identical in content — it makes the hooks travel with the codebase.

---

## Rationale

The global layer ensures protection without requiring any per-repo action. The per-repo layer serves documentation and portability: a contributor cloning the repo can run `bash .githooks/setup.sh` to activate the same hooks without needing the global install. Both layers use identical hook scripts, so there is no divergence risk.

Alternative considered: per-repo only. Rejected because it requires a manual step after every fresh clone and leaves other repos unprotected.

Alternative considered: global only. Rejected because the hooks don't travel with the repo — contributors on other machines get no protection unless they also run the global install.

---

## Consequences

- Per-repo `core.hooksPath` overrides the global setting for this repository. Since the content is identical, there is no functional difference.
- Updating the hooks requires re-running `scripts/install-global-hooks.sh` to refresh the global copies. The per-repo `.githooks/` files update automatically via git pull.
- `git commit --no-verify` / `git push --no-verify` bypass all client-side hooks regardless of placement. True unbypassable enforcement requires a server-side check (CI/CD pipeline — see roadmap Phase 2).
