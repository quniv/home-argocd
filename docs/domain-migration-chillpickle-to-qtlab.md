# Domain Migration: `chillpickle.org` → `qtlab.dev`

**Date:** 2026-06-16  
**Branch:** `feat/migrate-domain-qtlab-16062026`

---

## Phase 0 — Cloudflare DNS (manual, external)

- [x] Add `qtlab.dev` zone to Cloudflare (if not already)
- [x] Create `A` record `*.qtlab.dev` → home IP (same target as current `*.chillpickle.org`)
- [ ] Verify DNS resolves: `dig '*.qtlab.dev'` shows correct IP
- [ ] Keep `*.chillpickle.org` alive until cutover is fully verified

---

## Phase 1 — cert-manager (manual in-cluster apply)

- [ ] Update `bootstrap/4.cert-manager/certificate.yml`: `dnsNames: ['*.qtlab.dev']`
- [ ] Apply: `kubectl apply -f bootstrap/4.cert-manager/certificate.yml`
- [ ] Watch issuance: `kubectl get certificate tls-cert -n cert-manager -w`
- [ ] Confirm secret renewed: `kubectl get secret tls-cert -n cert-manager`

---

## Phase 2 — GitOps manifests (this repo, in worktree)

**DDNS** — `apps/cloudflare-ddns.yaml`
- [ ] `domains: "*.chillpickle.org"` → `domains: "*.qtlab.dev"`

**HTTPRoutes** — `hostnames:` field in each file:
- [ ] `manifests/infra/argocd/httproute.yaml` → `argocd.qtlab.dev`
- [ ] `manifests/monitoring/httproute-grafana.yaml` → `grafana.qtlab.dev`
- [ ] `manifests/monitoring/httproute-prometheus.yaml` → `prometheus.qtlab.dev`
- [ ] `manifests/monitoring/httproute-alertmanager.yaml` → `alertmanager.qtlab.dev`
- [ ] `manifests/hermes/httproute.yaml` → `hermes.qtlab.dev`

**Apps with embedded hostnames:**
- [ ] `apps/argocd.yaml` → `argocd.qtlab.dev`
- [ ] `apps/databasus.yaml` → `databasus.qtlab.dev`
- [ ] `charts/webapp/values/vvn-ce.yaml` → `vvn.qtlab.dev`

**Docs / config:**
- [ ] `CLAUDE.md` — update domain references *(done on this branch)*

**Infisical secrets (out-of-band):**
- [ ] Check vvn-ce env vars for any `chillpickle.org` CORS/callback URLs in Infisical
- [ ] Update them to `qtlab.dev` equivalents before sync

---

## Phase 3 — Push & ArgoCD sync

- [ ] Pull latest `main` into worktree: `git fetch origin main && git rebase origin/main`
- [ ] Commit: `feat: migrate domain chillpickle.org → qtlab.dev`
- [ ] Push branch and open PR → merge to `main`
- [ ] Watch ArgoCD reconcile: `kubectl -n argocd get app -w`
- [ ] Wait for DDNS update cycle (~5 min): `kubectl -n cloudflare-ddns logs -l app=cloudflare-ddns -f`

---

## Phase 4 — Smoke test each service

- [ ] `https://argocd.qtlab.dev` — ArgoCD UI loads, login works
- [ ] `https://grafana.qtlab.dev` — Grafana loads, dashboards visible
- [ ] `https://prometheus.qtlab.dev` — Prometheus UI, targets healthy
- [ ] `https://alertmanager.qtlab.dev` — Alertmanager UI accessible
- [ ] `https://hermes.qtlab.dev` — Hermes responds
- [ ] `https://vvn.qtlab.dev` — vvn-ce backend API responds
- [ ] `https://databasus.qtlab.dev` — Databasus UI loads

---

## Phase 5 — Cleanup (after full verification)

- [ ] Update `bootstrap/` READMEs: replace `chillpickle.org` → `qtlab.dev`
- [ ] Remove `*.chillpickle.org` DNS records from Cloudflare
- [ ] Update bookmarks / Tailscale access shortcuts
- [ ] Archive or delete old `chillpickle.org` zone in Cloudflare (optional)
