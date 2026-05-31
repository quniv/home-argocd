# Tech Stack Trade-offs

## Hook Runner

| Option | Pros | Cons | Decision |
|---|---|---|---|
| **Native git hooks** (shell scripts) | Zero dependencies, universal, no install step | No centralized management, easy to skip with `--no-verify` | **Chosen** — simplest for a single-user machine + per-repo use |
| pre-commit framework | Centralized config, language-agnostic hooks, automatic tool install | Extra dependency (`pip install pre-commit`), YAML config overhead | Overkill for a focused gitleaks-only gate |
| Lefthook | Fast parallel execution, YAML config, Go binary | Another binary to install and maintain | Worth reconsidering at team scale |

---

## Scanner

| Option | Pros | Cons | Decision |
|---|---|---|---|
| **gitleaks** | Fast Go binary, 200+ built-in rules, git-native (reads index/log), `--staged` support, active maintenance | Rules are regex-based (no entropy scoring by default) | **Chosen** — see ADR-001 |
| detect-secrets | Entropy + keyword hybrid detection, Python ecosystem friendly | Python dependency, no native `--staged` git integration, slower | — |
| trufflehog | Deep entropy scanning, S3/GCS/Jira sources, Docker image scanning | Heavy (Go binary + DB rules), slower on commits, more false positives | — |
| git-secrets | Lightweight, AWS-focused | AWS-specific rules only, minimal active development | — |

---

## Config Format

| Option | Pros | Cons | Decision |
|---|---|---|---|
| **`.gitleaks.toml`** (gitleaks native) | First-class support, inline `# gitleaks:allow` comments, allowlist per-rule | Repo-specific only (no per-user global config) | **Chosen** — standard gitleaks config |
| Environment variables | Simple overrides | Not version-controlled, per-session only | Supplements only |

---

## Installation Method

| Option | Pros | Cons | Decision |
|---|---|---|---|
| **`core.hooksPath` (global + per-repo)** | Pure git, no extra tooling, composable | Single value — per-repo overrides global (not additive) | **Chosen** — see ADR-002 |
| Symlinks in `.git/hooks/` | Familiar location | Not version-controlled, must re-link after clone | — |
| pre-commit framework auto-install | Transparent for contributors | Requires framework installed | Phase 2 consideration |
| Makefile `make install-hooks` | Discoverable for contributors | Requires `make`, manual invocation | Could wrap `setup.sh` if desired |
