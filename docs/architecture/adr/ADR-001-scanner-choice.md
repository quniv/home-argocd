# ADR-001: Secret Scanner Choice — gitleaks

**Status:** Accepted  
**Date:** 2026-05-31

---

## Context

This GitOps repository drives a home Kubernetes cluster via ArgoCD. Kubernetes manifests, Helm values, and bootstrap scripts regularly reference or could accidentally contain credentials (tokens, API keys, TLS private keys). We need a scanner that runs as a git hook with minimal friction and good coverage.

Three candidates were evaluated: gitleaks, detect-secrets, and trufflehog.

---

## Decision

Use **gitleaks** (v8+).

---

## Rationale

| Criterion | gitleaks | detect-secrets | trufflehog |
|---|---|---|---|
| Git-native staged scan | `--pre-commit --staged` built-in | External wrapper needed | No `--staged` |
| Binary dependency | Single Go binary, no runtime | Python + pip | Go binary + rules DB |
| Speed on commit-range scans | Fast (regexp engine) | Moderate | Slower (entropy scoring) |
| Rule coverage | 200+ built-in rules (v8) | ~30 detectors | Broad + S3/GCS/Jira sources |
| False-positive control | Per-rule allowlists, `# gitleaks:allow` inline | `detect-secrets audit` | `--only-verified` flag |
| Maintenance activity | Active (Anthropic, Alibaba, others) | Maintained by Yelp | Active |
| Config format | `.gitleaks.toml` (TOML) | `.secrets.baseline` (JSON) | CLI flags only |

gitleaks is the only candidate with a first-class `--pre-commit --staged` subcommand that reads directly from the git index, making it the correct tool for a `pre-commit` hook without shell gymnastics. Its single-binary distribution fits the Fedora environment where no package manager (brew, pip) is assumed for CI runners.

detect-secrets offers entropy-based detection as a complement but requires Python and lacks git-index integration. trufflehog's deeper scanning is more appropriate for retrospective audits or CI on large histories, not low-latency per-commit hooks.

---

## Consequences

- gitleaks must be installed by each developer (`brew install gitleaks` or manual binary).
- Hooks exit 1 if gitleaks is not installed — this is intentional (fail closed).
- Rule version follows the installed gitleaks binary; `.gitleaks.toml` in repo root can pin or extend rules.
- The `--pre-commit` flag behavior should be verified against `gitleaks git --help` after install; the v8.19+ CLI is assumed here.
