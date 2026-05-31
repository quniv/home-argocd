# Secret Scanning Roadmap

## Phase 0 — Local Gate (Now)

**Goal:** Block secrets before they leave the developer's machine.

- [x] Install gitleaks binary (manual, one-time per machine)
- [x] Write `pre-commit` hook — scans staged changes
- [x] Write `pre-push` hook — scans outgoing commit range
- [x] Write `setup.sh` — wires per-repo `core.hooksPath`
- [x] Write `install-global-hooks.sh` — sets global `core.hooksPath`
- [ ] Run `scripts/install-global-hooks.sh` on this machine
- [ ] Run `bash .githooks/setup.sh` for per-repo activation

**Limitation:** hooks are bypassable via `git commit --no-verify` / `git push --no-verify`.

---

## Phase 1 — Per-Repo Adoption

**Goal:** Ensure all contributors to this repo use the same hooks.

- [ ] Add `.gitleaks.toml` at repo root (tune rules, add allowlists for known false positives)
- [ ] Document setup steps in `README.md` (link to `setup.sh`)
- [ ] Add pre-commit framework config (`.pre-commit-config.yaml`) as an alternative entry point for contributors who prefer it
- [ ] Consider a `Makefile` target `make hooks` that calls `setup.sh`

---

## Phase 2 — CI Enforcement (True Hard Block)

**Goal:** Make secret scanning unbypassable — catches anything that slipped past local hooks.

- [ ] Add gitleaks step to `.github/workflows/security.yml` (already exists — augment it)
  ```yaml
  - name: Scan for secrets
    uses: gitleaks/gitleaks-action@v2
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  ```
- [ ] Configure branch protection rule: require the security workflow to pass before merge to `main`
- [ ] Set `GITLEAKS_ENABLE_COMMENTS: true` to annotate PRs with findings inline
- [ ] Rotate any secrets found by CI that were missed by local hooks
- [ ] Alert on scan failures via GitHub Actions notification or Slack webhook

**Note:** Phase 2 is the only truly unbypassable layer. Phase 0 catches the common case fast; Phase 2 is the safety net.
